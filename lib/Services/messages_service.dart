import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rent_house/Models/conversation.dart';
import 'package:rent_house/Models/message.dart';
import 'package:rent_house/Services/NotificationService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Helper pour obtenir l'ID courant
  String? _getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Charge les conversations d'un user (Stream pour real-time)
  /// Utilise la table 'conversations' avec RLS qui filtre automatiquement les conversations du user.
  Stream<List<Conversation>> getUserConversations(String userId) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('lastMessageTime', ascending: false)
        .asyncMap((data) async {
          final List<Conversation> conversations = [];
          for (final item in data) {
            final participants = List<String>.from(item['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != userId,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) continue;

            final otherUserName = await _getUserName(otherUserId);

            // Calculer les non-lus: count messages where conversationId=id AND isRead=false AND senderId!=me
            final unreadCount = await _supabase
                .from('messages')
                .count(CountOption.exact)
                .eq('conversationId', item['id'])
                .eq('isRead', false)
                .neq('senderId', userId);

            conversations.add(Conversation(
              id: item['id'],
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              lastMessage: item['lastMessage'] ?? '',
              timestamp: item['lastMessageTime'] != null
                  ? DateTime.parse(item['lastMessageTime'])
                  : DateTime.now(),
              unreadCount: unreadCount,
            ));
          }
          return conversations;
        });
  }

  /// Marque une conversation comme lue (tous les messages reçus)
  Future<void> markAsRead(String conversationId, String userId) async {
    await _supabase
        .from('messages')
        .update({'isRead': true})
        .eq('conversationId', conversationId)
        .neq('senderId', userId)
        .eq('isRead', false);
  }

  /// Envoie un message dans une conversation
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? imageUrl,
    String? videoUrl,
    required String senderId,
  }) async {
    // 1. Insérer le message
    final messageData = {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': text,
      'mediaUrl': imageUrl ?? videoUrl,
      'mediaType':
          imageUrl != null ? 'image' : (videoUrl != null ? 'video' : 'text'),
      'isRead': false,
      // createdAt est géré par la DB
    };

    await _supabase.from('messages').insert(messageData);

    // 2. Mettre à jour la conversation (dernier message)
    await _supabase.from('conversations').update({
      'lastMessage': text,
      'lastMessageTime': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    // 3. Envoyer notification (Optionnel, logique identique)
    final otherUserId =
        await _getOtherUserInConversation(conversationId, senderId);
    if (otherUserId != null) {
      _sendNotificationToUser(senderId, otherUserId, text, conversationId);
    }
  }

  /// Récupère le token FCM et envoie la notif
  Future<void> _sendNotificationToUser(String senderId, String receiverId,
      String messageText, String conversationId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('fcmToken')
          .eq('uid', receiverId)
          .maybeSingle();

      if (response == null || response['fcmToken'] == null) return;

      final fcmToken = response['fcmToken'] as String;

      // Nom expéditeur
      String senderName = "Nouveau message";
      try {
        final senderProfile = await _supabase
            .from('users')
            .select('firstName, lastName')
            .eq('uid', senderId)
            .maybeSingle();
        if (senderProfile != null) {
          senderName =
              "${senderProfile['firstName']} ${senderProfile['lastName']}";
        }
      } catch (_) {}

      await NotificationService().sendPushNotification(
        fcmToken: fcmToken,
        title: senderName,
        body: messageText,
        data: {
          'type': 'chat_message',
          'conversationId': conversationId,
          'senderId': senderId,
        },
      );
    } catch (e) {
      debugPrint("Erreur notification: $e");
    }
  }

  /// Récupère ou crée une conversation
  Future<String> getOrCreateConversation(String otherUserId, String propertyId,
      {String? currentUserId}) async {
    final uid = currentUserId ?? _getCurrentUserId();
    if (uid == null) throw Exception("User not logged in");

    // 1. Chercher une conversation existante avec ces participants
    // Note: SQL array contains. Sur Supabase Dart, on utilise .contains('participants', [val])
    // Mais pour checker les DEUX, on doit filtrer.
    // Une approche simple: select id from conversations where participants @> {uid, otherUserId}

    final existing = await _supabase
        .from('conversations')
        .select('id, propertyId')
        .contains('participants', [uid, otherUserId]);

    // Filtrer par propertyId si nécessaire (optionnel selon logique métier, ici on suppose une conv par propriété ou unique par paire user?)
    // Si on veut une conversation UNIQUE par paire user/owner pour une propriété donnée:
    if (existing.isNotEmpty) {
      // On cherche celle qui match propertyId
      try {
        final match = existing.firstWhere((e) => e['propertyId'] == propertyId);
        return match['id'] as String;
      } catch (_) {
        // Pas de match exact sur propertyId, on crée ou on retourne une générique?
        // On crée une nouvelle si propertyId diffère.
      }
    }

    return await createConversation(otherUserId, propertyId,
        currentUserId: uid);
  }

  /// Crée une nouvelle conversation
  Future<String> createConversation(String otherUserId, String propertyId,
      {String? currentUserId}) async {
    final uid = currentUserId ?? _getCurrentUserId();
    if (uid == null) throw Exception("User not logged in");

    final res = await _supabase
        .from('conversations')
        .insert({
          'propertyId': propertyId,
          'participants': [uid, otherUserId],
          'lastMessage': '',
          'lastMessageTime': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return res['id'] as String;
  }

  /// Récupère nom user
  Future<String> _getUserName(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('firstName, lastName')
          .eq('uid', userId)
          .maybeSingle();
      if (response != null) {
        return "${response['firstName']} ${response['lastName']}";
      }
      return 'Utilisateur';
    } catch (e) {
      return 'Utilisateur';
    }
  }

  /// Trouve l'autre user dans convo
  Future<String?> _getOtherUserInConversation(
      String conversationId, String currentUserId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('participants')
          .eq('id', conversationId)
          .single();
      final participants = List<String>.from(response['participants'] ?? []);
      return participants.firstWhere((id) => id != currentUserId,
          orElse: () => '');
    } catch (_) {
      return null;
    }
  }

  /// Stream des messages d'une conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversationId', conversationId)
        .order('createdAt', ascending: false)
        .map((data) => data
            .map((json) => Message(
                  id: json['id'],
                  senderId: json['senderId'],
                  text: json['content'] ?? '',
                  timestamp: json['createdAt'] != null
                      ? DateTime.parse(json['createdAt'])
                      : DateTime.now(),
                  imageUrl:
                      json['mediaType'] == 'image' ? json['mediaUrl'] : null,
                  videoUrl:
                      json['mediaType'] == 'video' ? json['mediaUrl'] : null,
                  isRead: json['isRead'] ?? false,
                  readBy: json['readBy'] ?? [],
                ))
            .toList());
  }

  /// Upload image (Supabase Storage)
  Future<String?> uploadMessageImage(
    File imageFile,
    String conversationId,
    void Function(double) onProgress,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'chat/$conversationId/$fileName';

      // Supabase storage upload ne fournit pas de stream de progression natif simple dans le SDK actuel
      // On fait l'upload direct.
      onProgress(0.5); // Fake progress

      await _supabase.storage.from('images').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      onProgress(1.0);

      final url = _supabase.storage.from('images').getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Erreur upload: $e');
      return null;
    }
  }

  /// Upload vidéo
  Future<String?> uploadMessageVideo(
    File videoFile,
    String conversationId,
    void Function(double) onProgress,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = 'chat/$conversationId/videos/$fileName';

      onProgress(0.5);

      await _supabase.storage.from('images').upload(
            path,
            videoFile,
            fileOptions: const FileOptions(contentType: 'video/mp4'),
          );

      onProgress(1.0);
      return _supabase.storage.from('images').getPublicUrl(path);
    } catch (e) {
      debugPrint('Erreur upload video: $e');
      return null;
    }
  }

  Future<void> markContactPaid(String conversationId, String userId) async {
    // TODO: Implémenter logique paiement contact si nécessaire (colonne is_contact_paid dans conversations?)
    // Pour l'instant vide ou ajout colonne SQL nécessaire.
  }
}

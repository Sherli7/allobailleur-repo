import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rent_house/Models/conversation.dart';
import 'package:rent_house/Models/message.dart';

class MessagesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _getConversationsRef(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('conversations');

  CollectionReference<Map<String, dynamic>> _getMessagesRef(
          String conversationId) =>
      _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

  /// Charge les conversations d'un user (Stream pour real-time)
  Stream<List<Conversation>> getUserConversations(String userId) {
    return _getConversationsRef(userId).snapshots().asyncMap((snapshot) async {
      final List<Conversation> conversations = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final otherUserId = data['otherUserId'] as String;
        final otherUserName = await _getUserName(otherUserId);
        final lastMessageRef = data['lastMessageRef'] as DocumentReference?;
        final lastMessageSnap =
            lastMessageRef != null ? await lastMessageRef.get() : null;
        final lastMessage = lastMessageSnap?.data() as Map<String, dynamic>?;
        final unreadCount = data['unreadCount'] ?? 0;

        conversations.add(Conversation(
          id: doc.id,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          lastMessage: lastMessage?['text'] ?? '',
          timestamp:
              (lastMessage?['timestamp'] as Timestamp?) ?? Timestamp.now(),
          unreadCount: unreadCount,
        ));
      }
      // Trie par timestamp descendant
      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return conversations;
    });
  }

  /// Marque une conversation comme lue
  Future<void> markAsRead(String conversationId, String userId) async {
    final batch = _firestore.batch();
    // Update unreadCount à 0 pour ce user
    final userConvRef = _getConversationsRef(userId).doc(conversationId);
    batch.update(userConvRef, {'unreadCount': 0});

    // Marque messages non lus comme lus (subcollection)
    final messagesQuery = _getMessagesRef(conversationId)
        .where('readBy', arrayContains: userId)
        .where('isRead', isEqualTo: false);
    final unreadMessages = await messagesQuery.get();
    for (final msgDoc in unreadMessages.docs) {
      batch.update(msgDoc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Envoie un message dans une conversation (texte, image, ou vidéo)
  Future<void> sendMessage(
    String conversationId,
    String text, {
    String? imageUrl,
    String? videoUrl,
    required String senderId,
  }) async {
    final messageRef = _getMessagesRef(conversationId).doc();
    final messageData = {
      'id': messageRef.id,
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'readBy': [senderId], // Init avec sender
    };

    // Ajoute message
    await messageRef.set(messageData);

    // Update lastMessageRef dans convos des deux users
    final batch = _firestore.batch();
    final otherUserId =
        await _getOtherUserInConversation(conversationId, senderId);
    if (otherUserId != null) {
      // Pour sender
      final senderConvRef = _getConversationsRef(senderId).doc(conversationId);
      batch.update(senderConvRef, {
        'lastMessageRef': messageRef,
        'unreadCount': 0, // Sender a pas unread
      });

      // Pour receiver : inc unread si pas lu
      final receiverConvRef =
          _getConversationsRef(otherUserId).doc(conversationId);
      batch.update(receiverConvRef, {
        'lastMessageRef': messageRef,
        'unreadCount': FieldValue.increment(1),
      });
    }

    await batch.commit();
  }

  /// Crée une nouvelle conversation (ex. quand contact via annonce)
  Future<String> createConversation(
      String otherUserId, String propertyId) async {
    final currentUserId = _auth.currentUser!.uid;
    final conversationId = _firestore.collection('conversations').doc().id;

    // Setup convo doc
    await _firestore.collection('conversations').doc(conversationId).set({
      'id': conversationId,
      'participants': [currentUserId, otherUserId],
      'propertyId': propertyId, // Lien à l'annonce
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Ajoute refs dans users' convos
    final batch = _firestore.batch();
    final currentConvRef =
        _getConversationsRef(currentUserId).doc(conversationId);
    final otherConvRef = _getConversationsRef(otherUserId).doc(conversationId);

    final currentName = await _getUserName(currentUserId);
    final otherName = await _getUserName(otherUserId);

    batch.set(currentConvRef, {
      'otherUserId': otherUserId,
      'otherUserName': otherName,
      'unreadCount': 0,
      'lastMessageRef': null,
    });
    batch.set(otherConvRef, {
      'otherUserId': currentUserId,
      'otherUserName': currentName,
      'unreadCount': 0,
      'lastMessageRef': null,
    });

    await batch.commit();
    return conversationId;
  }

  /// Helper: Récupère nom user via Firestore (assume collection 'users' avec 'name')
  Future<String> _getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['name'] ?? 'Utilisateur inconnu';
    } catch (e) {
      return 'Utilisateur inconnu';
    }
  }

  /// Helper: Trouve l'autre user dans convo
  Future<String?> _getOtherUserInConversation(
      String conversationId, String currentUserId) async {
    final convoDoc =
        await _firestore.collection('conversations').doc(conversationId).get();
    final participants =
        convoDoc.data()?['participants'] as List<dynamic>? ?? [];
    return participants.firstWhere((id) => id != currentUserId,
        orElse: () => null) as String?;
  }

  /// Stream des messages d'une conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _getMessagesRef(conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
  }

  /// Upload image pour message avec progress (retourne URL)
  Future<String?> uploadMessageImage(
    File imageFile,
    String conversationId,
    void Function(double) onProgress,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref =
          _storage.ref().child('messages/$conversationId/$timestamp.jpg');

      final uploadTask = ref.putFile(imageFile);

      // Listen progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Erreur upload message image: $e');
      return null;
    }
  }

  /// Upload vidéo pour message avec progress (retourne URL)
  Future<String?> uploadMessageVideo(
    File videoFile,
    String conversationId,
    void Function(double) onProgress,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('messages/$conversationId/videos/$timestamp.mp4');

      final uploadTask = ref.putFile(videoFile);

      // Listen progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Erreur upload message video: $e');
      return null;
    }
  }

  /// Supprime une conversation (soft delete)
  Future<void> deleteConversation(String conversationId, String userId) async {
    // Soft delete : remove de user's convos
    await _getConversationsRef(userId).doc(conversationId).delete();
  }
}

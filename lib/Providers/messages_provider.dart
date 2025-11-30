import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:rent_house/Services/messages_service.dart';
import 'package:rent_house/Models/conversation.dart';
import 'package:rent_house/Models/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesProvider with ChangeNotifier {
  final MessagesService _messagesService = MessagesService();

  List<Conversation> _conversations = [];
  List<Message> _currentMessages = []; // Messages pour convo courante
  String? _currentConversationId;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;

  // Getters
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  List<Message> get currentMessages => List.unmodifiable(_currentMessages);
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  /// Charge les conversations d'un user (init ou refresh)
  void loadConversations(String userId) {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Cancel previous subscription
    _conversationsSubscription?.cancel();
    _conversationsSubscription =
        _messagesService.getUserConversations(userId).listen(
      (conversations) {
        _conversations = conversations;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Erreur lors du chargement des conversations: $error';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Sélectionne une conversation et charge ses messages
  void selectConversation(String conversationId) {
    if (_currentConversationId == conversationId) return;
    _currentConversationId = conversationId;
    _loadMessagesForConversation(conversationId);
    notifyListeners();
  }

  /// Charge les messages d'une conversation (stream real-time)
  void _loadMessagesForConversation(String conversationId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _messagesService.getMessages(conversationId).listen(
      (messages) {
        _currentMessages = messages;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Erreur lors du chargement des messages: $error';
        notifyListeners();
      },
    );
  }

  /// Envoie un message (texte ou image)
  Future<bool> sendMessage(String conversationId, String text,
      {String? imageUrl, String? videoUrl}) async {
    final userId = _currentUserId;
    if (_isLoading || userId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _messagesService.sendMessage(conversationId, text,
          imageUrl: imageUrl, videoUrl: videoUrl, senderId: userId);
      // Pas de local update needed car stream rebâtira
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'envoi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Marque une conversation comme contact payé
  Future<bool> markContactPaid(String conversationId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _messagesService.markContactPaid(conversationId, userId);
      // Local update
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] =
            _conversations[index].copyWith(isContactPaid: true);
        notifyListeners();
      }
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la marque comme payé: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Marque une conversation comme lue (délégué au service)
  Future<bool> markAsRead(String conversationId) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _messagesService.markAsRead(conversationId, userId);
      // Local update: set unreadCount to 0 for this convo
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
        notifyListeners();
      }
      _isLoading = false;
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors du marquage comme lu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Crée une nouvelle conversation (ex. depuis annonce)
  Future<String?> createConversation(String otherUserId,
      {String? propertyId}) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final convoId = await _messagesService.createConversation(
          otherUserId, propertyId ?? '', currentUserId: userId);
      // Refresh conversations pour inclure la nouvelle
      loadConversations(userId);
      _isLoading = false;
      return convoId;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Désélectionne la convo courante (clear messages)
  void clearSelectedConversation() {
    _currentConversationId = null;
    _currentMessages = [];
    _messagesSubscription?.cancel();
    notifyListeners();
  }
}

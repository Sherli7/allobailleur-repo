import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Models/message.dart';
import 'package:rent_house/Providers/messages_provider.dart';
import 'package:rent_house/Models/AppConstants.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';

class ConversationPage extends StatefulWidget {
  static const String routeName = '/conversationPage';

  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Property? _property;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Map<String, dynamic>) {
      _conversationId = args['conversationId'] as String?;
      _property = args['property'] as Property?;
    } else if (args is Property) {
      // Fallback si seul property est passé (vieux code)
      _property = args;
    }
    
    if (_conversationId != null) {
      context.read<MessagesProvider>().selectConversation(_conversationId!);
    }

    // Pre-fill message if coming from property page for the first time
    if (_property != null && _messageController.text.isEmpty) {
       // On peut préremplir seulement si la conversation est vide ou nouvelle,
       // mais ici on laisse l'utilisateur écrire.
       // _messageController.text = ... 
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final provider = context.read<MessagesProvider>();
    final conversationId = _conversationId ?? provider.currentConversationId;
    
    if (conversationId == null) return;

    final success = await provider.sendMessage(
        conversationId, _messageController.text.trim());
        
    if (success) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesProvider = context.watch<MessagesProvider>();
    final messages = messagesProvider.currentMessages;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          if (_property != null)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Voir le bien',
            onPressed: () {
                Navigator.pushNamed(context, PropertyDetailsPage.routeName,
                    arguments: _property);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty 
                ? const Center(child: Text("Dites bonjour !"))
                : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Afficher les messages du plus ancien au plus récent pour le chat
                    // Mais attention, `getMessages` retourne souvent du plus récent au plus ancien.
                    // On va inverser l'index si nécessaire ou inverser la liste dans le provider.
                    // Ici on assume que `currentMessages` est trié du plus ancien au plus récent 
                    // ou on l'inverse visuellement avec `reverse: true` dans ListView si c'était l'inverse.
                    // Mais `MessagesService` trie par timestamp DESC. Donc index 0 est le plus récent.
                    // Une ListView standard affiche index 0 en haut. 
                    // Pour un chat, on veut index 0 en bas (le plus récent).
                    
                    // Approche standard chat : reverse: true
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                  reverse: true, // Important car la liste arrive souvent triée par date DESC
                ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppConstants.selectedIconColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

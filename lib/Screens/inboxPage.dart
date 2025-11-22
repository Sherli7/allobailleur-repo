import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Providers/messages_provider.dart';
import 'package:rent_house/Models/conversation.dart';
import 'package:rent_house/Screens/chat_details_page.dart';

class InboxPage extends StatefulWidget {
  static const String routeName = '/inboxPageRoute';
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final provider = Provider.of<MessagesProvider>(context, listen: false);
        provider.loadConversations(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Ouvre recherche messages (local filter)
            },
          ),
        ],
      ),
      body: Consumer<MessagesProvider>(
        builder: (context, messagesProvider, _) {
          if (messagesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Conversation> conversations =
              messagesProvider.conversations;

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Aucun message',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Commencez une conversation après réservation !',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade400,
                    child: Text(
                      convo.otherUserName.isNotEmpty
                          ? convo.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(convo.otherUserName.isNotEmpty
                      ? convo.otherUserName
                      : 'Utilisateur inconnu'),
                  subtitle: Text(convo.lastMessage),
                  trailing: convo.unreadCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue,
                          child: Text('${convo.unreadCount}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ChatDetailsPage(conversation: convo)),
                    );
                    messagesProvider.markAsRead(convo.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nouveau message bientôt !')));
        },
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.edit),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Models/conversation.dart'; // Assume un modèle Conversation (à implémenter)
import 'package:rent_house/Providers/messages_provider.dart'; // Provider for messages
import 'package:rent_house/Screens/searchPage.dart'; // Pour bouton "Parcourir"
import 'package:rent_house/Screens/chat_details_page.dart'; // À implémenter pour chat full (optionnel)
import 'package:rent_house/Services/PaymentService.dart';

class ConversationPage extends StatefulWidget {
  static const String routeName = '/messages';
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charge les conversations au init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Use provider to load conversations
        final provider = Provider.of<MessagesProvider>(context, listen: false);
        provider.loadConversations(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implémenter recherche dans conversations
              _searchController.text.isEmpty
                  ? null
                  : _filterConversations(_searchController.text);
            },
          ),
        ],
      ),
      body: Consumer<MessagesProvider>(
        // Assume un Provider pour messages (à créer si pas)
        builder: (context, messagesProvider, child) {
          if (messagesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = messagesProvider.conversations;
          if (conversations.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationCard(context, conversation);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Nav vers nouvelle conversation ou search pour start chat
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nouvelle conversation bientôt !')),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contactez des propriétaires pour démarrer une conversation',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Nav vers SearchPage
              Navigator.pushReplacementNamed(context, SearchPage.routeName);
            },
            icon: const Icon(Icons.search),
            label: const Text('Parcourir les annonces'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
      BuildContext context, Conversation conversation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Text(
            conversation.otherUserName.isNotEmpty
                ? conversation.otherUserName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(conversation.otherUserName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    conversation.unreadCount > 0 ? Colors.black : Colors.grey,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            Text(
              _formatTimestamp(conversation.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: conversation.unreadCount > 0
            ? Chip(
                label: Text('${conversation.unreadCount}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          if (!conversation.isContactPaid) {
            // Proposer le paiement
            _showPaymentDialog(context, conversation);
          } else {
            // Nav vers chat details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatDetailsPage(conversation: conversation),
              ),
            );
            // Marque comme lu via provider
            Provider.of<MessagesProvider>(context, listen: false)
                .markAsRead(conversation.id);
          }
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final date = timestamp;
    final now = DateTime.now();
    if (date.difference(now).inDays.abs() < 1) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  List<Conversation> _filterConversations(String query) {
    // Implémente filtre local
    return []; // Stub
  }

  void _showPaymentDialog(BuildContext context, Conversation conversation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contacter le propriétaire'),
          content: Text(
            'Pour contacter ${conversation.otherUserName}, vous devez payer ${PaymentService.contactFee}€. Ce paiement est unique par conversation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Capture les objets nécessaires avant l'appel asynchrone
                final stateNavigator = Navigator.of(this.context);
                final messagesProvider =
                    Provider.of<MessagesProvider>(this.context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(this.context);

                // Close the dialog immediately using the state's navigator
                stateNavigator.pop();
                try {
                  final paymentService = PaymentService();
                  await paymentService.payForContact(conversation.id);

                  if (!mounted) return;
                  // Marquer comme payé (provider déjà capturé)
                  await messagesProvider.markContactPaid(conversation.id);

                  if (!mounted) return;
                  // Ouvrir le chat
                  stateNavigator.push(
                    MaterialPageRoute(
                      builder: (context) => ChatDetailsPage(
                          conversation:
                              conversation.copyWith(isContactPaid: true)),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Erreur de paiement: $e')),
                  );
                }
              },
              child: const Text('Payer et contacter'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

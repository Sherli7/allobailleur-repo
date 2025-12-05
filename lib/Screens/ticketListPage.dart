import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/ticket.dart';
import 'package:rent_house/Services/ticket_service.dart';
import 'package:intl/intl.dart';
import 'package:rent_house/Screens/createTicketPage.dart';

class TicketListPage extends StatefulWidget {
  static const String routeName = '/tickets';
  final bool isOwnerMode; // Ajout pour ouvrir directement l'onglet propriétaire

  const TicketListPage({super.key, this.isOwnerMode = false});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage>
    with SingleTickerProviderStateMixin {
  final TicketService _ticketService = TicketService();
  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  late TabController _tabController;
  bool _isLoading = true;
  List<Ticket> _myTickets = []; // Tickets que j'ai créés (Locataire)
  List<Ticket> _receivedTickets = []; // Tickets reçus (Bailleur)

  @override
  void initState() {
    super.initState();
    // Si mode proprio, on commence sur le 2ème onglet (index 1)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isOwnerMode ? 1 : 0,
    );
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      // Charger les tickets que j'ai créés
      final myTickets = await _ticketService.getUserTickets(_userId);

      // Charger les tickets reçus (si je suis proprio)
      final receivedTickets = await _ticketService.getOwnerTickets(_userId);

      if (mounted) {
        setState(() {
          _myTickets = myTickets;
          _receivedTickets = receivedTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolu';
      case 'closed':
        return 'Fermé';
      default:
        status;
    }
    return status;
  }

  Widget _buildTicketList(List<Ticket> tickets, {bool isOwnerView = false}) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isOwnerView
                  ? 'Aucun incident signalé pour vos biens'
                  : 'Vous n\'avez signalé aucun incident',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(ticket.status).withAlpha(76),
                        ),
                      ),
                      child: Text(
                        _translateStatus(ticket.status),
                        style: TextStyle(
                          color: _getStatusColor(ticket.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(ticket.createdAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                if (isOwnerView)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (ticket.status != 'resolved' &&
                          ticket.status != 'closed')
                        OutlinedButton(
                          onPressed: () => _updateStatus(ticket.id, 'resolved'),
                          child: const Text('Marquer résolu'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String ticketId, String status) async {
    try {
      await _ticketService.updateTicketStatus(ticketId, status);
      _loadTickets(); // Recharger la liste
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur mise à jour: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Incidents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes Signalements'),
            Tab(text: 'Reçus'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(_myTickets, isOwnerView: false),
                _buildTicketList(_receivedTickets, isOwnerView: true),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            CreateTicketPage.routeName,
          );
          if (result == true) {
            _loadTickets();
          }
        },
        tooltip: 'Signaler un incident',
        child: const Icon(Icons.add),
      ),
    );
  }
}

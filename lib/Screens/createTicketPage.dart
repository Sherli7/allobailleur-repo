import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Services/ticket_service.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/bookingsPage.dart'; // Assurez-vous que le chemin est correct

class CreateTicketPage extends StatefulWidget {
  static const String routeName = '/create-ticket';

  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final TicketService _ticketService = TicketService();

  String _priority = 'medium';
  String? _selectedPropertyId;
  bool _isSubmitting = false;

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Basse'},
    {'value': 'medium', 'label': 'Moyenne'},
    {'value': 'high', 'label': 'Haute'},
    {'value': 'urgent', 'label': 'Urgente'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  void _showPaymentRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paiement Requis'),
        content: const Text(
          'Pour pouvoir contacter le propriétaire, vous devez d\'abord régler les frais de mise en relation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Ferme la dialog
              final property = context
                  .read<PropertyProvider>()
                  .properties
                  ?.firstWhere((p) => p.id == _selectedPropertyId);
              if (property != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookingPage(property: property),
                  ),
                );
              }
            },
            child: const Text('Procéder au Paiement'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une propriété')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await _ticketService.createTicket(
        title: _titleController.text,
        description: _descController.text,
        priority: _priority,
        propertyId: _selectedPropertyId!,
        userId: userId,
        images: [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident signalé avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString();

      if (errorMessage.contains('Paiement requis')) {
        _showPaymentRequiredDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue: $errorMessage')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = context.watch<PropertyProvider>().properties ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signaler un incident'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Détails du problème',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Sélection de la propriété
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Propriété concernée',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                initialValue: _selectedPropertyId,
                items: properties.map((prop) {
                  return DropdownMenuItem(
                    value: prop.id,
                    child: Text(
                      prop.title.length > 30
                          ? '${prop.title.substring(0, 30)}...'
                          : prop.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPropertyId = val),
                validator: (val) => val == null ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'incident',
                  hintText: 'Ex: Fuite d\'eau salle de bain',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Priorité
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Urgence',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                initialValue: _priority,
                items: _priorities.map((p) {
                  return DropdownMenuItem(
                    value: p['value'],
                    child: Text(p['label']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description détaillée',
                  hintText:
                      'Décrivez le problème, sa localisation, depuis quand...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Envoyer le signalement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

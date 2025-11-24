import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';

class OwnerDashboard extends StatefulWidget {
  static const String routeName = '/ownerDashboard';
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await context.read<PropertyProvider>().loadHostProperties(uid);
    }
    setState(() => _loading = false);
  }

  Widget _buildPropertyTile(Property p) {
    final provider = context.read<PropertyProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: p.imageUrls.isNotEmpty
            ? Image.network(p.imageUrls.first,
                width: 64, height: 64, fit: BoxFit.cover)
            : Container(width: 64, height: 64, color: Colors.grey[200]),
        title: Text(p.title),
        subtitle: Text('${p.city} • ${p.price.toStringAsFixed(0)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'mark_rented') {
              final ok = await provider.completeRental(p);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Annonce marquée louée' : "Échec")),
              );
            } else if (value == 'restore') {
              final ok = await provider.restoreProperty(p);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(ok ? 'Annonce remise en ligne' : "Échec")),
              );
            } else if (value == 'delete') {
              final res = await provider.deleteProperty(p.id);
              if (res['success'] == true) {
                // remove locally
                provider.userProperties = (provider.userProperties ?? [])
                    .where((x) => x.id != p.id)
                    .toList();
                provider.properties = (provider.properties ?? [])
                    .where((x) => x.id != p.id)
                    .toList();
                provider.notifyListeners();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Annonce supprimée')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${res['message'] ?? ''}')));
              }
            } else if (value == 'edit') {
              // navigate to edit page if exists
              Navigator.of(context).pushNamed('/editProperty', arguments: p);
            }
          },
          itemBuilder: (context) => [
            if (p.status != 'rented')
              const PopupMenuItem(
                  value: 'mark_rented', child: Text('Marquer loué')),
            if (p.status == 'rented')
              const PopupMenuItem(
                  value: 'restore', child: Text('Remettre en ligne')),
            const PopupMenuItem(value: 'edit', child: Text('Éditer')),
            const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord propriétaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _loading = true);
              await _load();
            },
          )
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          if (_loading) return const Center(child: CircularProgressIndicator());
          final list = provider.userProperties ?? [];
          if (list.isEmpty) {
            return Center(child: Text('Vous n\'avez pas encore d\'annonces.'));
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: list.length,
              itemBuilder: (context, i) => _buildPropertyTile(list[i]),
            ),
          );
        },
      ),
    );
  }
}

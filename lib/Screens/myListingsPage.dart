import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';

class MyListingsPage extends StatefulWidget {
  static const String routeName = '/myListingsPageRoute';

  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final uid = authProvider.firebaseUser?.uid ?? '';
      if (uid.isNotEmpty) {
        propertyProvider.loadHostProperties(uid);
      }
    });
  }

  void _deleteProperty(String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce?'),
        content: const Text(
            'Cette action est irréversible. Êtes-vous sûr de vouloir supprimer cette annonce?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final propertyProvider =
                  Provider.of<PropertyProvider>(context, listen: false);
              propertyProvider.deleteProperty(propertyId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Annonce supprimée')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editProperty(Property property) {
    Navigator.pushNamed(context, EditPropertyPage.routeName,
        arguments: property);
  }

  void _viewAnalytics(Property property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propriété: ${property.title}'),
            const SizedBox(height: 16),
            const Text('Statistiques:'),
            const SizedBox(height: 8),
            Text(
                'Évaluation: ${property.rating}/5 (${property.reviewCount} avis)'),
            const SizedBox(height: 8),
            Text('Disponible: ${property.isAvailable ? "Oui" : "Non"}'),
            const SizedBox(height: 8),
            Text('Statut: ${property.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _onAddListingPressed(BuildContext context) {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final role = authProvider.user?.role ?? 'tenant';

    if (role == 'owner' || role == 'admin') {
      Navigator.pushNamed(context, CreatePropertyPage.routeName);
    } else {
      // Option pour promouvoir ou info
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Accès Propriétaire Requis'),
          content: const Text(
              'Pour créer une annonce, vous devez être propriétaire. Voulez-vous vous promouvoir ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final propertyProvider =
                    Provider.of<PropertyProvider>(context, listen: false);
                final success = await authProvider.promoteToOwner();
                if (!mounted) return;
                nav.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Vous êtes maintenant propriétaire !')),
                  );
                  // Refresh properties
                  propertyProvider
                      .loadHostProperties(authProvider.firebaseUser?.uid ?? '');
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('Impossible de promouvoir pour le moment.')),
                  );
                }
              },
              child: const Text('Devenir Propriétaire'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Annonces'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, _) {
          if (propertyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = propertyProvider.userProperties ?? <Property>[];

          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune annonce publiée',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Consumer<app_auth.AuthProvider>(
                    builder: (context, authProvider, _) {
                      final role = authProvider.user?.role ?? 'tenant';
                      if (role == 'owner' || role == 'admin') {
                        return ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, CreatePropertyPage.routeName),
                          icon: const Icon(Icons.add),
                          label: const Text('Créer une annonce'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700),
                        );
                      }
                      return ElevatedButton.icon(
                        onPressed: () => _onAddListingPressed(context),
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Devenir propriétaire'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final authProvider =
                  Provider.of<app_auth.AuthProvider>(context, listen: false);
              final uid = authProvider.firebaseUser?.uid ?? '';
              if (uid.isNotEmpty) {
                propertyProvider
                    .loadHostProperties(uid); // No await needed since it's void
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return _buildListingCard(property);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<app_auth.AuthProvider>(
        builder: (context, authProvider, _) {
          final role = authProvider.user?.role ?? 'tenant';
          return AnimatedOpacity(
            opacity: (role == 'owner' || role == 'admin') ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton.extended(
              onPressed: () => _onAddListingPressed(context),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle annonce'),
              tooltip: 'Ajouter une nouvelle annonce',
              heroTag: 'add_listing_fab', // Unique for animation conflicts
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildListingCard(Property property) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey.shade300,
                  child: property.imageUrls.isNotEmpty
                      ? Image.network(
                          property.imageUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.image_not_supported,
                                size: 48, color: Colors.grey.shade500),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.home,
                              size: 48, color: Colors.grey.shade500)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: property.isAvailable
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    property.isAvailable ? 'Disponible' : 'Occupée',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    property.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${property.price.toStringAsFixed(0)} ${property.currency}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${property.district}, ${property.city}',
                        style: TextStyle(color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Features
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bed, size: 14),
                        const SizedBox(width: 4),
                        Text('${property.bedrooms}'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bathroom, size: 14),
                        const SizedBox(width: 4),
                        Text('${property.bathrooms}'),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(property.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewAnalytics(property),
                        icon: const Icon(Icons.assessment),
                        label: const Text('Stats'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editProperty(property),
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteProperty(property.id),
                        icon: const Icon(Icons.delete),
                        label: const Text('Supprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

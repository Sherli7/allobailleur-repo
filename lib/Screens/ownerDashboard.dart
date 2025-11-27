import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _shareProperty(Property property) async {
    try {
      // Créer un lien partageable (deep link ou lien web)
      final propertyLink = 'https://allobailleur.app/property/${property.id}';

      final shareText = '''
🏠 ${property.title}

📍 ${property.city}, ${property.district ?? property.country}
💰 ${property.price.toStringAsFixed(0)} ${property.currency}/mois
🏠 ${property.bedrooms} ch. • 🛁 ${property.bathrooms} sdb • 📐 ${property.surface?.toInt() ?? 0} m²

${property.description}

🔗 Voir l'annonce complète : $propertyLink

Découvrez cette propriété sur Allô Bailleur !
#AlloBailleur #Location #${property.city}
      '''
          .trim();

      await Share.share(
        shareText,
        subject: 'Découvrez ma propriété : ${property.title}',
      );
    } catch (e) {
      debugPrint('Erreur lors du partage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du partage')),
        );
      }
    }
  }

  // Widget pour les statistiques
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les actions rapides
  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTile(Property p) {
    final provider = context.read<PropertyProvider>();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (p.status) {
      case 'rented':
        statusColor = Colors.orange;
        statusText = 'Loué';
        statusIcon = Icons.check_circle;
        break;
      case 'active':
        statusColor = Colors.green;
        statusText = 'Actif';
        statusIcon = Icons.visibility;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Inactif';
        statusIcon = Icons.pause_circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigation vers les détails de la propriété
          Navigator.of(context).pushNamed('/propertyDetails', arguments: p);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Image de la propriété
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: p.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(p.imageUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: p.imageUrls.isEmpty ? Colors.grey[200] : null,
                    ),
                    child: p.imageUrls.isEmpty
                        ? const Icon(Icons.home, size: 32, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${p.city}${p.district != null ? ', ${p.district}' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.price.toStringAsFixed(0)} FCFA/mois',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Statut et menu
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          final messenger = ScaffoldMessenger.of(context);
                          if (value == 'mark_rented') {
                            final ok = await provider.completeRental(p);
                            if (mounted) {
                              messenger.showSnackBar(SnackBar(
                                  content: Text(
                                      ok ? 'Annonce marquée louée' : "Échec")));
                              await _load(); // Recharger les données
                            }
                          } else if (value == 'restore') {
                            final ok = await provider.restoreProperty(p);
                            if (mounted) {
                              messenger.showSnackBar(SnackBar(
                                  content: Text(ok
                                      ? 'Annonce remise en ligne'
                                      : "Échec")));
                              await _load(); // Recharger les données
                            }
                          } else if (value == 'delete') {
                            final res = await provider.deleteProperty(p.id);
                            if (res['success'] == true) {
                              await _load(); // Recharger les données
                              if (mounted) {
                                messenger.showSnackBar(const SnackBar(
                                    content: Text('Annonce supprimée')));
                              }
                            } else {
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        'Erreur: ${res['message'] ?? ''}')));
                              }
                            }
                          } else if (value == 'edit') {
                            if (mounted) {
                              Navigator.of(context)
                                  .pushNamed('/editProperty', arguments: p);
                            }
                          } else if (value == 'view_details') {
                            if (mounted) {
                              Navigator.of(context)
                                  .pushNamed('/propertyDetails', arguments: p);
                            }
                          } else if (value == 'share') {
                            if (mounted) {
                              _shareProperty(p);
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'view_details',
                              child: Text('Voir détails')),
                          const PopupMenuItem(
                              value: 'share', child: Text('Partager')),
                          if (p.status != 'rented')
                            const PopupMenuItem(
                                value: 'mark_rented',
                                child: Text('Marquer loué')),
                          if (p.status == 'rented')
                            const PopupMenuItem(
                                value: 'restore',
                                child: Text('Remettre en ligne')),
                          const PopupMenuItem(
                              value: 'edit', child: Text('Éditer')),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Informations supplémentaires
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.king_bed, '${p.bedrooms} ch.'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.bathtub, '${p.bathrooms} sdb'),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                      Icons.square_foot, '${p.surface?.toInt() ?? 0} m²'),
                  const Spacer(),
                  Text(
                    'Créée le ${_formatDate(p.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon tableau de bord'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(CreatePropertyPage.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle annonce'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = provider.userProperties ?? [];
          final activeProperties =
              properties.where((p) => p.status != 'rented').length;
          final rentedProperties =
              properties.where((p) => p.status == 'rented').length;
          final totalRevenue = properties
              .where((p) => p.status == 'rented')
              .fold<double>(0, (sum, p) => sum + p.price);

          return RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              slivers: [
                // Section statistiques
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aperçu général',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total annonces',
                                properties.length.toString(),
                                Icons.home,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Actives',
                                activeProperties.toString(),
                                Icons.visibility,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Louées',
                                rentedProperties.toString(),
                                Icons.check_circle,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Revenus',
                                '${totalRevenue.toInt()} FCFA',
                                Icons.euro,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Section actions rapides
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions rapides',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAction(
                                'Nouvelle annonce',
                                Icons.add_circle,
                                () => Navigator.of(context)
                                    .pushNamed(CreatePropertyPage.routeName),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAction(
                                'Voir réservations',
                                Icons.calendar_today,
                                () => Navigator.of(context)
                                    .pushNamed('/bookingsList'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAction(
                                'Messages',
                                Icons.message,
                                () => Navigator.of(context)
                                    .pushNamed('/inboxPageRoute'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAction(
                                'Voir profil',
                                Icons.person,
                                () => Navigator.of(context)
                                    .pushNamed('/viewProfilePageRoute'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Section propriétés
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Mes annonces (${properties.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(CreatePropertyPage.routeName),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Liste des propriétés
                if (properties.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vous n\'avez pas encore d\'annonces',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(CreatePropertyPage.routeName),
                            icon: const Icon(Icons.add),
                            label: const Text('Créer ma première annonce'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPropertyTile(properties[index]),
                      childCount: properties.length,
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Espace pour le FAB
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

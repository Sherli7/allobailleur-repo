import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Screens/conversationPage.dart'; // Pour contacter proprio
import 'package:rent_house/Screens/searchPage.dart';

class FavoritesPage extends StatefulWidget {
  static const String routeName = '/favorites';
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Charge les favoris si pas déjà (via GuestHomePage init, mais safety)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<PropertyProvider>().loadFavorites(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                context.read<PropertyProvider>().loadFavorites(userId);
              }
            },
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, child) {
          if (propertyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = propertyProvider.favorites ?? [];
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final property = favorites[index];
              return _buildPropertyCard(context, property, propertyProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun favori pour le moment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des annonces à vos favoris pour les retrouver ici',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Nav vers SearchPage (via bottom nav index 0, ou push)
              // Pour simplicité, pop et switch à Search dans GuestHome, mais ici direct push
              Navigator.pushReplacementNamed(context, SearchPage.routeName);
            },
            icon: const Icon(Icons.search),
            label: const Text('Parcourir les annonces'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(
      BuildContext context, Property property, PropertyProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  property.imageUrls.isNotEmpty
                      ? property.imageUrls.first
                      : 'https://via.placeholder.com/300x200?text=No+Image',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              if (property.isNew)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: Chip(
                    label:
                        Text('Nouveau', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    PropertyDetailsPage.routeName,
                    arguments: property,
                  ),
                  child: Text(
                    property.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    '${property.city}, ${property.distance ?? '-'} km du centre'),
                Text(
                    '${property.bedrooms} pièces • ${property.surface ?? '-'} m²'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${property.price} FCFA/mois',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            final success =
                                await provider.toggleFavorite(property);
                            if (!mounted) return;
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Erreur lors de la suppression du favori')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            ConversationPage.routeName,
                            arguments: property, // Ou userId du proprio
                          ),
                        ),
                      ],
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

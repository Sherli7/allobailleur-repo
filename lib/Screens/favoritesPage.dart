import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/ComparePropertiesPage.dart';

class FavoritesPage extends StatefulWidget {
  static const String routeName = '/favorites';
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<PropertyProvider>().loadFavorites(userId);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vous ne pouvez comparer que 3 biens à la fois')),
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  void _compareProperties(List<Property> allFavorites) {
    final selectedProperties = allFavorites
        .where((p) => _selectedIds.contains(p.id))
        .toList();

    if (selectedProperties.length < 2) {
       ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Sélectionnez au moins 2 biens pour comparer')),
          );
      return;
    }

    Navigator.pushNamed(
      context, 
      ComparePropertiesPage.routeName, 
      arguments: selectedProperties
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '${_selectedIds.length} sélectionné(s)'
            : 'Favoris'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Comparer',
              onPressed: _toggleSelectionMode,
            ),
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
      floatingActionButton: _isSelectionMode && _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                 final favorites = context.read<PropertyProvider>().favorites ?? [];
                 _compareProperties(favorites);
              },
              label: const Text('Comparer'),
              icon: const Icon(Icons.compare),
            )
          : null,
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
    final isSelected = _selectedIds.contains(property.id);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleSelection(property.id);
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(property.id);
        } else {
           Navigator.pushNamed(
            context,
            PropertyDetailsPage.routeName,
            arguments: property,
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        shape: isSelected
            ? RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12))
            : null,
        child: Stack(
          children: [
            Column(
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
                          label: Text('Nouveau',
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    if (_isSelectionMode)
                       Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle
                          ),
                          child: isSelected 
                            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 30)
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 30),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          if (!_isSelectionMode)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final success =
                                        await provider.toggleFavorite(property);
                                    if (!mounted) return;
                                    if (!success) {
                                      messenger.showSnackBar(
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
                                    arguments: property,
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
          ],
        ),
      ),
    );
  }
}

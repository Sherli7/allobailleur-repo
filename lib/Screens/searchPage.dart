import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/conversationPage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';

class SearchPage extends StatefulWidget {
  static const String routeName = '/search';
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  double _minPrice = 0; // Pas de filtre prix minimum initial
  double _maxPrice = 10000; // Prix maximum large
  String? _selectedType;
  int _selectedRooms = 0;
  List<Property> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<PropertyProvider?>()
          ?.fetchProperties(); // Assume cette méthode existe
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) => _filterProperties(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, child) {
          if (propertyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Debug logs
          debugPrint(
              'PropertyProvider properties: ${propertyProvider.properties?.length ?? 0} items');
          if (propertyProvider.properties != null) {
            for (var prop in propertyProvider.properties!) {
              debugPrint(
                  'Property: ${prop.id} - ${prop.title} - Price: ${prop.price} - Status: ${prop.status}');
            }
          }

          _filteredProperties =
              _applyFilters(propertyProvider.properties ?? []);
          debugPrint(
              'Filtered properties: ${_filteredProperties.length} items');

          if (_filteredProperties.isEmpty) {
            return const Center(child: Text('Aucun logement trouvé'));
          }
          return ListView.builder(
            itemCount: _filteredProperties.length,
            itemBuilder: (context, index) {
              final property = _filteredProperties[index];
              return _buildPropertyCard(property);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _loadMore(), // Pour "Charger plus d'annonces"
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FiltersBottomSheet(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        selectedType: _selectedType,
        selectedRooms: _selectedRooms,
        onApply: (minP, maxP, type, rooms) {
          setState(() {
            _minPrice = minP;
            _maxPrice = maxP;
            _selectedType = type;
            _selectedRooms = rooms;
          });
          _filterProperties();
          Navigator.pop(context);
        },
      ),
    );
  }

  List<Property> _applyFilters(List<Property> allProperties) {
    debugPrint('Applying filters to ${allProperties.length} properties');
    debugPrint(
        'Filter criteria: minPrice=$_minPrice, maxPrice=$_maxPrice, type=$_selectedType, rooms=$_selectedRooms, search="${_searchController.text}"');

    return allProperties.where((p) {
      if (_searchController.text.isNotEmpty &&
          !p.title
              .toLowerCase()
              .contains(_searchController.text.toLowerCase())) {
        debugPrint('Property ${p.id} filtered out by search text');
        return false;
      }
      if (p.price < _minPrice || p.price > _maxPrice) {
        debugPrint(
            'Property ${p.id} filtered out by price: ${p.price} not in [$_minPrice, $_maxPrice]');
        return false;
      }
      if (_selectedType != null && p.type != _selectedType) {
        debugPrint(
            'Property ${p.id} filtered out by type: ${p.type} != $_selectedType');
        return false;
      }
      if (_selectedRooms > 0 && p.rooms != _selectedRooms) {
        debugPrint(
            'Property ${p.id} filtered out by rooms: ${p.rooms} != $_selectedRooms');
        return false;
      }
      return true;
    }).toList();
  }

  void _filterProperties() {
    setState(() {}); // Trigger rebuild
  }

  void _loadMore() {
    // Implémente pagination via Provider
    context.read<PropertyProvider?>()?.loadMoreProperties();
  }

  Widget _buildPropertyCard(Property property) {
    final imageUrl =
        property.imageUrls.isNotEmpty ? property.imageUrls.first : null;

    // Debug: Afficher les informations sur les images
    debugPrint(
        'Property ${property.id}: imageUrls = ${property.imageUrls}, first imageUrl = $imageUrl');

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        PropertyDetailsPage.routeName,
        arguments: property,
      ),
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: imageUrl != null
                      ? Hero(
                          tag: 'property-image-${property.id}',
                          child: Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                if (property.isNew)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Chip(
                        label: Text('Nouveau',
                            style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.green),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                      '${property.city}, ${property.distance ?? 0} km du centre'),
                  Text('${property.rooms} pièces • ${property.surface} m²'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${property.price} FCFA/mois',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () => _toggleFavorite(property)),
                          IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () => _contactOwner(property)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(Property property) {
    context.read<PropertyProvider?>()?.toggleFavorite(property);
  }

  void _contactOwner(Property property) {
    // Nav vers Messages ou ConversationPage
    Navigator.pushNamed(context, ConversationPage.routeName,
        arguments: property);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _FiltersBottomSheet extends StatelessWidget {
  final double minPrice;
  final double maxPrice;
  final String? selectedType;
  final int selectedRooms;
  final Function(double, double, String?, int) onApply;

  const _FiltersBottomSheet({
    required this.minPrice,
    required this.maxPrice,
    required this.selectedType,
    required this.selectedRooms,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filtres',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Prix mensuel'),
          RangeSlider(
            values: RangeValues(minPrice, maxPrice),
            min: 0,
            max: 2000,
            divisions: 20,
            labels: RangeLabels('$minPrice €', '$maxPrice €'),
            onChanged: (values) {}, // Gère dans parent via callback
          ),
          const Text('Type de bien'),
          Wrap(
            children: ['Appartement', 'Maison', 'Studio']
                .map((type) => FilterChip(
                      label: Text(type),
                      selected: selectedType == type,
                      onSelected: (selected) => onApply(minPrice, maxPrice,
                          selected ? type : null, selectedRooms),
                    ))
                .toList(),
          ),
          const Text('Nombre de pièces'),
          Wrap(
            children: [1, 2, 3, 4, 5]
                .map((rooms) => FilterChip(
                      label: Text('$rooms'),
                      selected: selectedRooms == rooms,
                      onSelected: (selected) => onApply(minPrice, maxPrice,
                          selectedType, selected ? rooms : 0),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                onApply(minPrice, maxPrice, selectedType, selectedRooms),
            child: const Text('Appliquer les filtres'),
          ),
        ],
      ),
    );
  }
}

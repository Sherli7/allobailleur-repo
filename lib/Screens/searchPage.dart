import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/conversation_page.dart';
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
  double _maxPrice = 2000; // Prix maximum correspondant au slider
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

    // Parse natural language query
    final parsedFilters = _parseNaturalLanguageQuery(_searchController.text);

    return allProperties.where((p) {
      // Existing filters
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

      // Natural language filters
      if (parsedFilters['maxPrice'] != null &&
          p.price > parsedFilters['maxPrice']) {
        return false;
      }
      if (parsedFilters['type'] != null &&
          !p.type.toLowerCase().contains(parsedFilters['type'].toLowerCase())) {
        return false;
      }
      if (parsedFilters['rooms'] != null && p.rooms != parsedFilters['rooms']) {
        return false;
      }
      if (parsedFilters['location'] != null &&
          !(p.address
                  ?.toLowerCase()
                  .contains(parsedFilters['location'].toLowerCase()) ??
              false) &&
          !p.title
              .toLowerCase()
              .contains(parsedFilters['location'].toLowerCase())) {
        return false;
      }

      // General search in title and description
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        final titleMatch = p.title.toLowerCase().contains(query);
        final addressMatch =
            (p.address?.toLowerCase().contains(query) ?? false);
        final descriptionMatch = p.description.toLowerCase().contains(query);
        if (!titleMatch && !addressMatch && !descriptionMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Map<String, dynamic> _parseNaturalLanguageQuery(String query) {
    final filters = <String, dynamic>{};
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    // Keywords for types
    const typeKeywords = {
      'appartement': 'Appartement',
      'maison': 'Maison',
      'studio': 'Studio',
      'duplex': 'Duplex',
      'loft': 'Loft',
    };

    // Keywords for rooms
    const roomKeywords = {
      '1': 1,
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      'un': 1,
      'deux': 2,
      'trois': 3,
      'quatre': 4,
      'cinq': 5,
      'chambre': null, // Just indicator
      'pièces': null,
      'pièce': null,
    };

    // Price keywords
    const priceKeywords = ['sous', 'moins de', 'maximum', 'max', '€', 'euros'];

    for (final word in words) {
      // Check for type
      if (typeKeywords.containsKey(word)) {
        filters['type'] = typeKeywords[word];
      }

      // Check for rooms
      if (roomKeywords.containsKey(word)) {
        final rooms = roomKeywords[word];
        if (rooms != null) {
          filters['rooms'] = rooms;
        }
      }

      // Check for price
      if (priceKeywords.any((kw) => word.contains(kw))) {
        // Look for number after
        final index = words.indexOf(word);
        for (int i = index + 1; i < words.length; i++) {
          final numMatch = RegExp(r'(\d+)').firstMatch(words[i]);
          if (numMatch != null) {
            filters['maxPrice'] = double.tryParse(numMatch.group(1)!);
            break;
          }
        }
      }

      // Assume location is any word not matching above (simple heuristic)
      if (!typeKeywords.containsKey(word) &&
          !roomKeywords.containsKey(word) &&
          !priceKeywords.any((kw) => word.contains(kw)) &&
          word.length > 2) {
        filters['location'] = word;
      }
    }

    return filters;
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

class _FiltersBottomSheet extends StatefulWidget {
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
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  late RangeValues _priceRange;
  late String? _selectedType;
  late int _selectedRooms;
  late double _minPriceLimit;
  late double _maxPriceLimit;

  @override
  void initState() {
    super.initState();
    // Définir les limites dynamiques basées sur les données disponibles
    _minPriceLimit = 0;
    _maxPriceLimit = 5000; // Prix maximum possible

    // S'assurer que les valeurs initiales sont dans les limites
    double startPrice = widget.minPrice.clamp(_minPriceLimit, _maxPriceLimit);
    double endPrice = widget.maxPrice.clamp(_minPriceLimit, _maxPriceLimit);

    // Si les valeurs sont identiques ou invalides, utiliser une plage par défaut
    if (startPrice >= endPrice) {
      startPrice = _minPriceLimit;
      endPrice = _maxPriceLimit;
    }

    _priceRange = RangeValues(startPrice, endPrice);
    _selectedType = widget.selectedType;
    _selectedRooms = widget.selectedRooms;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec titre et bouton fermer
            Row(
              children: [
                const Text(
                  'Filtres de recherche',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section Prix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.euro, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Prix mensuel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_priceRange.start.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} - ${_priceRange.end.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RangeSlider(
                    values: _priceRange,
                    min: _minPriceLimit,
                    max: _maxPriceLimit,
                    divisions: 50,
                    activeColor: Colors.green,
                    inactiveColor: Colors.green[100],
                    labels: RangeLabels(
                      '${_priceRange.start.round()} FCFA',
                      '${_priceRange.end.round()} FCFA',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_minPriceLimit.round()} FCFA',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '${_maxPriceLimit.round()} FCFA',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Type de bien
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Type de bien',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Appartement',
                      'Maison',
                      'Studio',
                      'Bureau',
                      'Commerce'
                    ]
                        .map((type) => FilterChip(
                              label: Text(type),
                              selected: _selectedType == type,
                              checkmarkColor: Colors.white,
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _selectedType == type
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: _selectedType == type
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedType = selected ? type : null;
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Nombre de pièces
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.king_bed,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Nombre de pièces',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [1, 2, 3, 4, 5]
                        .map((rooms) => FilterChip(
                              label:
                                  Text('$rooms pièce${rooms > 1 ? 's' : ''}'),
                              selected: _selectedRooms == rooms,
                              checkmarkColor: Colors.white,
                              selectedColor: Colors.orange,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _selectedRooms == rooms
                                      ? Colors.orange
                                      : Colors.grey[300]!,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: _selectedRooms == rooms
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedRooms = selected ? rooms : 0;
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Réinitialiser les filtres
                      setState(() {
                        _priceRange =
                            RangeValues(_minPriceLimit, _maxPriceLimit);
                        _selectedType = null;
                        _selectedRooms = 0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(
                      _priceRange.start,
                      _priceRange.end,
                      _selectedType,
                      _selectedRooms,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Appliquer',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

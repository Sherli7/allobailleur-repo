import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:rent_house/Services/NaturalSearchService.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchPage extends StatefulWidget {
  static const String routeName = '/search';
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final NaturalSearchService _naturalSearchService = NaturalSearchService();

  double _minPrice = 0;
  double _maxPrice = 1000000;
  String? _selectedType;
  int _selectedRooms = 0;
  List<Property> _searchedProperties = [];
  bool _isSearching = false;

  // Mode de recherche: 'local' (filtres classiques) ou 'natural' (requête API via NaturalSearchService)
  bool _isNaturalSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider?>()?.fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Ex: Studio à Mendong < 50000...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onSubmitted: (value) => _performSearch(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                
                final List<Property> propertiesToDisplay;
                
                if (_isNaturalSearch) {
                  // Si recherche naturelle activée, on utilise les résultats de l'API
                  propertiesToDisplay = _searchedProperties;
                } else {
                   // Sinon on filtre localement la liste du provider
                   final allProperties = propertyProvider.properties ?? [];
                   propertiesToDisplay = _applyLocalFilters(allProperties);
                }

                if (propertiesToDisplay.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun logement trouvé',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          if (_isNaturalSearch)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isNaturalSearch = false;
                                  _searchController.clear();
                                });
                              }, 
                              child: const Text('Voir toutes les annonces')
                            )
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: propertiesToDisplay.length,
                  itemBuilder: (context, index) {
                    final property = propertiesToDisplay[index];
                    return _buildPropertyCard(property);
                  },
                );
              },
            ),
    );
  }

  /// Lance la recherche
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isNaturalSearch = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Si la requête semble être une phrase complexe, on utilise le service naturel
    // Sinon (juste un mot), on pourrait filtrer localement, mais utilisons le service pour la cohérence
    // ou mixons les deux. Ici, on priorise le service naturel qui interroge Supabase.
    
    final results = await _naturalSearchService.searchProperties(query);
    
    setState(() {
      _searchedProperties = results;
      _isNaturalSearch = true;
      _isSearching = false;
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            // Si on applique des filtres manuels, on désactive la recherche naturelle pure
            // et on applique ces filtres sur les propriétés locales
            _isNaturalSearch = false; 
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Filtres classiques (Slider prix, Chips type...) appliqués sur la liste locale
  List<Property> _applyLocalFilters(List<Property> allProperties) {
    return allProperties.where((p) {
      // Filtre Prix
      if (p.price < _minPrice || p.price > _maxPrice) return false;
      
      // Filtre Type
      if (_selectedType != null && p.type != _selectedType) return false;
      
      // Filtre Chambres
      if (_selectedRooms > 0 && p.rooms != _selectedRooms) return false;

      // Filtre Texte simple si on n'est pas en mode "Natural Search" mais qu'il y a du texte
      // (Cas où l'utilisateur tape juste un mot clé sans lancer la grosse recherche API)
      if (!_isNaturalSearch && _searchController.text.isNotEmpty) {
         final query = _searchController.text.toLowerCase();
         final match = p.title.toLowerCase().contains(query) ||
                       p.description.toLowerCase().contains(query) ||
                       (p.address?.toLowerCase().contains(query) ?? false) ||
                       p.city.toLowerCase().contains(query);
         if (!match) return false;
      }

      return true;
    }).toList();
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final words = query.toLowerCase().split(RegExp(r'\s+'));
    // On ne surligne que les mots significatifs (>2 lettres)
    final validWords = words.where((w) => w.length > 2).toList();
    
    if (validWords.isEmpty) return Text(text);

    String lowerText = text.toLowerCase();
    List<TextSpan> spans = [];
    int start = 0;

    // Pour simplifier, on cherche la première occurrence de n'importe quel mot clé
    // Une implémentation plus robuste découperait le texte plus finement.
    // Ici on fait simple : on affiche le texte tel quel, sauf si on trouve un match exact.
    
    // Approche simple: split par mot et reconstruction
    final textWords = text.split(' ');
    for(var word in textWords) {
       bool isMatch = validWords.any((q) => word.toLowerCase().contains(q));
       spans.add(TextSpan(
         text: '$word ',
         style: isMatch 
           ? const TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.yellow)
           : const TextStyle(color: Colors.black),
       ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildPropertyCard(Property property) {
    final imageUrl = property.imageUrls.isNotEmpty ? property.imageUrls.first : null;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        PropertyDetailsPage.routeName,
        arguments: property,
      ),
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrl != null
                      ? Hero(
                          tag: 'property-image-${property.id}',
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 50),
                        ),
                ),
                if (property.isNew)
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: Chip(
                      label: Text('Nouveau', style: TextStyle(color: Colors.white, fontSize: 10)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            
            // Détails
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlightText(property.title, _searchController.text),
                  const SizedBox(height: 4),
                  Text('${property.city} • ${property.type}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.bed, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${property.rooms} ch.'),
                      const SizedBox(width: 12),
                      const Icon(Icons.bathtub, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${property.bathrooms} sdb.'),
                      const SizedBox(width: 12),
                      const Icon(Icons.square_foot, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${property.surface ?? 0} m²'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${property.price.toStringAsFixed(0)} ${property.currency}/mois',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          context.read<PropertyProvider>().favorites?.any((p) => p.id == property.id) ?? false
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: context.read<PropertyProvider>().favorites?.any((p) => p.id == property.id) ?? false
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () => context.read<PropertyProvider?>()?.toggleFavorite(property),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Bottom Sheet pour les filtres manuels (inchangé ou adapté)
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
  final double _limitMax = 2000000;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
        widget.minPrice.clamp(0, _limitMax), 
        widget.maxPrice.clamp(0, _limitMax)
    );
    _selectedType = widget.selectedType;
    _selectedRooms = widget.selectedRooms;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
            ],
          ),
          const Divider(),
          const Text('Fourchette de prix', style: TextStyle(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _limitMax,
            divisions: 20,
            labels: RangeLabels(
              '${_priceRange.start.round()}', 
              '${_priceRange.end.round()}'
            ),
            onChanged: (val) => setState(() => _priceRange = val),
          ),
          Text('${_priceRange.start.round()} FCFA - ${_priceRange.end.round()} FCFA'),
          
          const SizedBox(height: 20),
          const Text('Type de propriété', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(
            spacing: 8,
            children: ['Appartement', 'Maison', 'Studio', 'Bureau'].map((type) {
              return ChoiceChip(
                label: Text(type),
                selected: _selectedType == type,
                onSelected: (selected) => setState(() => _selectedType = selected ? type : null),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text('Chambres minimum', style: TextStyle(fontWeight: FontWeight.w600)),
           Wrap(
            spacing: 8,
            children: [1, 2, 3, 4, 5].map((num) {
              return ChoiceChip(
                label: Text('$num+'),
                selected: _selectedRooms == num,
                onSelected: (selected) => setState(() => _selectedRooms = selected ? num : 0),
              );
            }).toList(),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(
                _priceRange.start,
                _priceRange.end,
                _selectedType,
                _selectedRooms
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white
              ),
              child: const Text('Appliquer les filtres'),
            ),
          )
        ],
      ),
    );
  }
}

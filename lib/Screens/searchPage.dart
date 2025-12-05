import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Widgets/property_card.dart';

class SearchPage extends StatefulWidget {
  static const String routeName = '/search';
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Tout';
  RangeValues _priceRange = const RangeValues(0, 500000);
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    // L'appel au provider pour filtrer sera fait dans le build via le Consumer
    setState(() {});
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true, // Clavier automatique
          textInputAction:
              TextInputAction.search, // Bouton "Rechercher" du clavier
          onSubmitted: (_) => _performSearch(),
          decoration: InputDecoration(
            hintText: 'Rechercher (ex: Bastos, Studio...)',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.primaryColor),
            onPressed: _performSearch,
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _showFilters ? theme.primaryColor : Colors.grey,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres expandables
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 160 : 0,
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Type de bien",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            'Tout',
                            'Appartement',
                            'Maison',
                            'Studio',
                            'Villa',
                            'Bureau',
                          ].map((type) {
                            final isSelected = _selectedType == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedType = selected ? type : 'Tout';
                                  });
                                },
                                selectedColor: theme.primaryColor.withAlpha(51),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.primaryColor
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Budget (FCFA)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000000,
                    divisions: 20,
                    activeColor: theme.primaryColor,
                    labels: RangeLabels(
                      '${_priceRange.start.round()}',
                      '${_priceRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_showFilters) const Divider(height: 1),

          // Liste des résultats
          Expanded(
            child: Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var properties = provider.properties ?? [];
                final query = _searchController.text.toLowerCase();

                // Filtrage local avec sécurité null renforcée
                final filteredProperties = properties.where((p) {
                  final title = p.title.toLowerCase();
                  final city = p.city.toLowerCase();
                  final description = p.description.toLowerCase();

                  final matchesQuery =
                      title.contains(query) ||
                      city.contains(query) ||
                      description.contains(query);

                  final matchesType =
                      _selectedType == 'Tout' ||
                      p.type.toLowerCase() == _mapLabelToType(_selectedType);

                  final matchesPrice =
                      p.price >= _priceRange.start &&
                      p.price <= _priceRange.end;

                  return matchesQuery && matchesType && matchesPrice;
                }).toList();

                if (filteredProperties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun résultat trouvé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedType = 'Tout';
                              _priceRange = const RangeValues(0, 1000000);
                            });
                          },
                          child: const Text("Réinitialiser les filtres"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProperties.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PropertyCard(property: filteredProperties[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _mapLabelToType(String label) {
    switch (label) {
      case 'Appartement':
        return 'apartment';
      case 'Maison':
        return 'house';
      case 'Studio':
        return 'studio';
      case 'Villa':
        return 'villa';
      case 'Bureau':
        return 'office';
      default:
        return label.toLowerCase();
    }
  }
}

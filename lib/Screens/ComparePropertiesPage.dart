import 'package:flutter/material.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Views/text_widgets.dart';
import 'package:intl/intl.dart';

class ComparePropertiesPage extends StatelessWidget {
  static const String routeName = '/compareProperties';

  final List<Property> properties;

  const ComparePropertiesPage({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'fr_XAF', symbol: 'XAF', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: AppBarText(key: UniqueKey(), text: 'Comparateur'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: properties.isEmpty
          ? const Center(child: Text("Aucun bien à comparer"))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  columns: [
                    const DataColumn(
                        label: Text('Caractéristiques',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    ...properties.map((property) => DataColumn(
                          label: Container(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: Text(
                              property.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )),
                  ],
                  rows: [
                    // Image Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Aperçu')),
                        ...properties.map((property) => DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: property.imageUrls.isNotEmpty
                                    ? Image.network(
                                        property.imageUrls.first,
                                        width: 100,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image_not_supported),
                                      )
                                    : const Icon(Icons.image, size: 50),
                              ),
                            )),
                      ],
                    ),
                    // Price Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Prix')),
                        ...properties.map((property) => DataCell(
                              Text(
                                currencyFormat.format(property.price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            )),
                      ],
                    ),
                    // City Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Ville')),
                        ...properties.map((property) => DataCell(Text(property.city))),
                      ],
                    ),
                     // Type Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Type')),
                        ...properties.map((property) => DataCell(Text(property.type))),
                      ],
                    ),
                    // Surface Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Surface')),
                        ...properties.map((property) => DataCell(
                              Text(property.surface != null
                                  ? '${property.surface} m²'
                                  : '-'),
                            )),
                      ],
                    ),
                    // Rooms Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Chambres')),
                        ...properties.map((property) =>
                            DataCell(Text(property.rooms.toString()))),
                      ],
                    ),
                    // Bathrooms Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Douches')),
                        ...properties.map((property) =>
                            DataCell(Text(property.bathrooms.toString()))),
                      ],
                    ),
                    // Rating Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Note')),
                        ...properties.map((property) => DataCell(Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                Text(
                                    ' ${property.rating.toStringAsFixed(1)} (${property.reviewCount})'),
                              ],
                            ))),
                      ],
                    ),
                     // Amenities Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Équipements')),
                        ...properties.map((property) {
                          final amenities = property.amenities;
                          final displayAmenities = amenities.take(3).toList();
                          final remaining = amenities.length - 3;
                          
                          return DataCell(
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...displayAmenities.map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
                                if (remaining > 0)
                                  Text('et $remaining de plus...', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                              ],
                            ),
                          )
                        );
                        }),
                      ],
                    ),
                    // Action Row
                    DataRow(
                      cells: [
                        const DataCell(Text('Action')),
                        ...properties.map((property) => DataCell(
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context, 
                                    PropertyDetailsPage.routeName, 
                                    arguments: property
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(60, 30)
                                ),
                                child: const Text('Voir', style: TextStyle(fontSize: 12)),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

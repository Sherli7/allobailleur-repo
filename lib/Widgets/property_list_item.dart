// lib/Widgets/property_list_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';

class PropertyListItem extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyListItem({
    super.key,
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: property.imageUrls.isNotEmpty
                  ? Image.network(
                property.imageUrls[0],
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 130,
                    height: 130,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 130,
                  height: 130,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              )
                  : Container(
                width: 130,
                height: 130,
                color: Colors.grey[300],
                child: const Icon(Icons.home, size: 50),
              ),
            ),

            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${property.city} • ${property.rooms} chambre${property.rooms > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    if (property.distance != null)
                      Text(
                        '${property.distance!.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${property.price.toInt().toString()} ${property.currency}/mois',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton favori
            Consumer<PropertyProvider>(
              builder: (context, provider, child) {
                final isFavorite = provider.favorites.any((p) => p.id == property.id);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => provider.toggleFavorite(property),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// lib/Widgets/property_grid_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';

class PropertyGridItem extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyGridItem({
    super.key,
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            // Image principale
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                AspectRatio(
                  aspectRatio: 1.3, // format presque carré (très esthétique)
                  child: property.imageUrls.isNotEmpty
                      ? Image.network(
                    property.imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  )
                      : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.home, size: 60, color: Colors.white70),
                  ),
                ),

                // Infos en bas
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.city,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${property.price.toInt()} ${property.currency}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          if (property.distance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${property.distance!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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

            // Bouton favori en haut à droite
            Positioned(
              top: 8,
              right: 8,
              child: Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  final isFavorite = provider.favorites.any((p) => p.id == property.id);
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                      ],
                    ),
                    child: IconButton(
                      iconSize: 22,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[700],
                      ),
                      onPressed: () => provider.toggleFavorite(property),
                    ),
                  );
                },
              ),
            ),

            // Badge "Meublé" ou "Haut standing" si applicable
            if (property.style == 'meublé' || property.style == 'haut_standing')
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: property.style == 'meublé' ? Colors.orange : Colors.purple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    property.style == 'meublé' ? 'Meublé' : 'Haut standing',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:share_plus/share_plus.dart';

// Nouveau StatefulWidget pour la carte avec slider d'images
class PropertyCard extends StatefulWidget {
  final Property property;

  const PropertyCard({super.key, required this.property});

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareProperty() async {
    try {
      final property = widget.property;
      // Créer un lien partageable (deep link ou lien web)
      final propertyLink = 'https://allobailleur.app/property/${property.id}';

      final shareText = '''
🏠 ${property.title}

📍 ${property.city}, ${property.district ?? property.country}
💰 ${property.price.toStringAsFixed(0)} FCFA/mois
🏠 ${property.bedrooms} ch. • 🛁 ${property.bathrooms} sdb • 📐 ${property.surface?.toInt() ?? 0} m²

🔗 Voir l'annonce complète : $propertyLink

Découvrez cette propriété sur Allô Bailleur !
#AlloBailleur #Location #${property.city}
      '''
          .trim();

      await Share.share(
        shareText,
        subject: 'Découvrez cette propriété : ${property.title}',
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

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.property.imageUrls;
    final hasMultipleImages = imageUrls.length > 1;

    return Hero(
      tag:
          'property-${widget.property.id}', // Pour animations fluides vers détails
      child: Card(
        elevation: 4, // Réduit pour subtilité
        color: Theme.of(context).colorScheme.surface, // Surface MD3
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pushNamed(
              PropertyDetailsPage.routeName,
              arguments: widget.property,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slider d'images avec indicateurs
              SizedBox(
                height: 140, // Augmenté pour de meilleures proportions
                child: Stack(
                  children: [
                    // PageView pour le slider
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: imageUrls.isEmpty ? 1 : imageUrls.length,
                      itemBuilder: (context, index) {
                        if (imageUrls.isEmpty) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 48, // Agrandi l'icône
                            ),
                          );
                        }
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            image: DecorationImage(
                              image: NetworkImage(imageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                    // Badge 'Nouveau'
                    if (widget.property.status == 'published' &&
                        DateTime.now()
                                .difference(widget.property.createdAt)
                                .inDays <
                            7)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.8 * 255).round()), // Primaire MD3
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Nouveau',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Indicateurs de page (dots)
                    if (hasMultipleImages)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            imageUrls.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Infos avec rating
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16), // Augmenté le padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titre de la propriété
                      Text(
                        widget.property.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                        maxLines: 2, // Permettre 2 lignes pour le titre
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Localisation
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.property.city}, ${widget.property.country}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.3,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Prix et rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.property.price.toStringAsFixed(0)} FCFA/mois',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Rating avec étoiles et bouton partage
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.property.rating.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _shareProperty,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.share,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Caractéristiques (surface, chambres)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.property.surface ?? 0} m² • ${widget.property.bedrooms} ch • ${widget.property.bathrooms} sdb',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/conversationPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';

class GuestHomePage extends StatefulWidget {
  static const String routeName = '/home';
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  // Navigator keys for nested navigators (one per tab)
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(6, (index) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContentPage(), // Page d'accueil dynamique
      const SearchPage(),
      const FavoritesPage(),
      const CreatePropertyPage(),
      const ConversationPage(),
      const ViewProfilePage(),
    ];
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        context.read<PropertyProvider>().loadFavorites(userId);
      }
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use nested navigators so routes pushed inside a tab keep the bottom bar
      body: Stack(
        children: List.generate(_pages.length, (index) {
          return Offstage(
            offstage: _currentIndex != index,
            child: Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (settings) {
                // initial route -> the tab root widget
                if (settings.name == Navigator.defaultRouteName) {
                  return MaterialPageRoute(
                      builder: (_) => _pages[index], settings: settings);
                }

                // handle inner named routes for details/booking
                if (settings.name == '/propertyDetails' ||
                    settings.name == PropertyDetailsPage.routeName) {
                  final prop = settings.arguments as Property?;
                  if (prop != null) {
                    return MaterialPageRoute(
                        builder: (_) => PropertyDetailsPage(property: prop),
                        settings: settings);
                  }
                }

                if (settings.name == '/booking' ||
                    settings.name == BookingPage.routeName) {
                  final prop = settings.arguments as Property?;
                  if (prop != null) {
                    return MaterialPageRoute(
                        builder: (_) => BookingPage(property: prop),
                        settings: settings);
                  }
                }

                // fallback to tab root
                return MaterialPageRoute(
                    builder: (_) => _pages[index], settings: settings);
              },
            ),
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) {
            // pop to first route in the nested navigator when tapping active tab
            _navigatorKeys[index]
                .currentState
                ?.popUntil((route) => route.isFirst);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Pour un hero overlay plus immersif
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AlloBailleur',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Naviguer vers la page de recherche
              Navigator.of(context).pushNamed(SearchPage.routeName);
            },
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, child) {
          if (propertyProvider.isLoading) {
            return Stack(
              children: [
                // Background neutre pour loading
                Container(
                  color: Colors.grey,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          final properties = propertyProvider.properties ?? [];

          return Container(
            color: Theme.of(context)
                .colorScheme
                .surface, // Utilise la surface MD3 pour fond neutre
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100), // Espace pour AppBar hero

                    // Section de bienvenue avec hero image overlay
                    Hero(
                      tag: 'hero-welcome',
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80', // Image exemple duplex lumineux
                            ),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .shadow, // Ombre MD3
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bienvenue sur AlloBailleur',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Trouvez votre logement idéal à Nice',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistiques supprimées par demande
                    const SizedBox(height: 12),

                    // Section des propriétés populaires avec titre animé
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Propriétés populaires',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall, // Style MD3
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(SearchPage.routeName);
                          },
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Voir tout'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Grille des propriétés populaires (2 colonnes pour plus d'engagement)
                    if (properties.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline, // Outline MD3
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune propriété disponible pour le moment',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: properties.length > 4
                            ? 4
                            : properties
                                .length, // Augmenté à 4 pour plus de contenu
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          return PropertyCard(
                              property:
                                  property); // Utilise le nouveau widget avec slider
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Stat cards removed per product requirement.
}

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Slider d'images avec indicateurs
              SizedBox(
                height: 120,
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
                              size: 40,
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
                                .withOpacity(0.8), // Primaire MD3
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
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium, // Title MD3
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          Expanded(
                            child: Text(
                              '${widget.property.city}, ${widget.property.country}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.property.price} €/mois',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (starIndex) {
                              final isFilled =
                                  starIndex < widget.property.rating.floor();
                              return Icon(
                                isFilled ? Icons.star : Icons.star_border,
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withOpacity(0.7), // Tertiaire MD3 atténué
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.property.surface ?? 0} m² • ${widget.property.bedrooms} ch',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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

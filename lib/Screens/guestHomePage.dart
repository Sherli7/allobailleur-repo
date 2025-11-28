import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:rent_house/Widgets/property_card.dart';

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
      List.generate(4, (index) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContentPage(), // Page d'accueil dynamique
      const SearchPage(),
      const FavoritesPage(),
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
      appBar: AppBar(
        title: const Text('Allô Bailleur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, CreatePropertyPage.routeName);
            },
            tooltip: 'Publier une annonce',
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.pushNamed(context, ConversationPage.routeName);
            },
            tooltip: 'Messages',
          ),
        ],
      ),
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
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } catch (e) {
      // Handle error
      debugPrint('Error getting location: $e');
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLng = (lng2 - lng1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  List<Property> _sortPropertiesByDistance(List<Property> properties) {
    if (_userLat == null || _userLng == null) return properties;
    final sorted = List<Property>.from(properties);
    sorted.sort((a, b) {
      final distA =
          _calculateDistance(_userLat!, _userLng!, a.latitude, a.longitude);
      final distB =
          _calculateDistance(_userLat!, _userLng!, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    return sorted;
  }

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
          final sortedProperties = _sortPropertiesByDistance(properties);

          return Container(
            color: Theme.of(context)
                .colorScheme
                .surface, // Utilise la surface MD3 pour fond neutre
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            24), // Espace pour AppBar étendue + padding confortable

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
                                Color.fromRGBO(0, 0, 0, 0.4),
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
                                  "Trouvez votre logement idéal n'importe où au Cameroun",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromRGBO(255, 255, 255, 0.9),
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
                      children: [
                        Expanded(
                          child: Text(
                            'Les locations les plus proches de vous...',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall, // Style MD3
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

                    if (sortedProperties.isEmpty)
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
                                          .onSurface,
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
                          // Améliorer le ratio pour de meilleures proportions
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: sortedProperties.length > 4
                            ? 4
                            : sortedProperties
                                .length, // Augmenté à 4 pour plus de contenu
                        itemBuilder: (context, index) {
                          final property = sortedProperties[index];
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Constants/svg_assets.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/bookPostingPage.dart';
import 'package:rent_house/Screens/inboxPage.dart';
import 'package:rent_house/Screens/nearbyMapPage.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Services/AuthService.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:rent_house/Widgets/property_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class GuestHomePage extends StatefulWidget {
  static const String routeName = '/home';
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    3,
    (index) => GlobalKey<NavigatorState>(),
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContentPage(),
      const InboxPage(),
      Builder(
        builder: (context) {
          final firebaseUser = _auth.currentUser;
          final supabaseUser =
              supabase.Supabase.instance.client.auth.currentUser;

          if (firebaseUser == null && supabaseUser == null) {
            // Redirection asynchrone pour éviter les problèmes de build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, LoginPage.routeName);
            });
            return const SizedBox(); // Retourne un widget vide temporaire
          }
          return const ViewProfilePage();
        },
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        context.read<PropertyProvider>().loadFavorites(userId);
      }
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  Future<void> _handleBecomeHost(BuildContext context) async {
    final user = _auth.currentUser;
    // Note: Become Host logic might need to support Supabase user too eventually
    if (user == null) {
      Navigator.pushNamed(context, LoginPage.routeName);
      return;
    }

    final isHost =
        user.displayName?.contains('host') == true ||
        user.email?.contains('owner') == true;

    if (isHost) {
      Navigator.pushNamed(context, CreatePropertyPage.routeName);
    } else {
      final shouldBecomeHost = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Devenez Bailleur'),
          content: const Text(
            'Pour publier une propriété, vous devez activer votre compte Bailleur.\n\n'
            'Cela vous permettra de gérer vos annonces et de recevoir des réservations.\n'
            'C\'est gratuit et instantané.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Activer maintenant',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldBecomeHost == true) {
        try {
          await AuthService().becomeHost();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Félicitations ! Vous êtes maintenant Bailleur.'),
              ),
            );
            Navigator.pushNamed(context, CreatePropertyPage.routeName);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          }
        }
      }
    }
  }

  Future<bool> _isUserLoggedIn() async {
    final firebaseUser = _auth.currentUser;
    final supabaseUser = supabase.Supabase.instance.client.auth.currentUser;

    if (firebaseUser != null) {
      debugPrint('Utilisateur connecté via Firebase: ${firebaseUser.uid}');
      return true;
    }

    if (supabaseUser != null) {
      debugPrint('Utilisateur connecté via Supabase: ${supabaseUser.id}');
      return true;
    }

    debugPrint('Aucun utilisateur connecté.');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(_pages.length, (index) {
          return Offstage(
            offstage: _currentIndex != index,
            child: Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (settings) {
                if (settings.name == Navigator.defaultRouteName) {
                  return MaterialPageRoute(
                    builder: (_) => _pages[index],
                    settings: settings,
                  );
                }
                if (settings.name == '/propertyDetails' ||
                    settings.name == PropertyDetailsPage.routeName) {
                  final prop = settings.arguments as Property?;
                  if (prop != null) {
                    return MaterialPageRoute(
                      builder: (_) => PropertyDetailsPage(property: prop),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == BookPostingPage.routeName) {
                  final prop = settings.arguments as Property?;
                  if (prop != null) {
                    return MaterialPageRoute(
                      builder: (_) => BookPostingPage(property: prop),
                      settings: settings,
                    );
                  }
                }
                return MaterialPageRoute(
                  builder: (_) => _pages[index],
                  settings: settings,
                );
              },
            ),
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          onTap: (index) async {
            if (index == 2) {
              final isLoggedIn = await _isUserLoggedIn();
              if (!isLoggedIn) {
                Navigator.pushNamed(context, LoginPage.routeName);
                return;
              }
            }
            if (index == _currentIndex) {
              _navigatorKeys[index].currentState?.popUntil(
                (route) => route.isFirst,
              );
            } else {
              setState(() => _currentIndex = index);
            }
          },
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[400],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explorer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'guestHomeFab',
              onPressed: () => _handleBecomeHost(context),
              child: const Icon(Icons.add),
              tooltip: 'Publier',
            )
          : null,
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
  String _selectedCategory = 'Tout';
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tout', 'icon': Icons.grid_view},
    {'label': 'Appartement', 'icon': Icons.apartment},
    {'label': 'Maison', 'icon': Icons.home_work_outlined},
    {'label': 'Studio', 'icon': Icons.single_bed},
    {'label': 'Villa', 'icon': Icons.villa},
    {'label': 'Bureau', 'icon': Icons.business_center_outlined},
    {'label': 'Chambre', 'icon': Icons.bed_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371;
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLng = (lng2 - lng1) * (pi / 180);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  String _mapTypeToLabel(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return 'Appartement';
      case 'house':
        return 'Maison';
      case 'studio':
        return 'Studio';
      case 'villa':
        return 'Villa';
      case 'office':
        return 'Bureau';
      case 'room':
        return 'Chambre';
      default:
        return 'Autre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Modern App Bar with Search & Hero Image
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1470&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 80,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOGO INTEGRATION
                        Row(
                          children: [
                            SizedBox(
                              height: 40,
                              width: 40,
                              child: SvgPicture.string(
                                appLogoSvg,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Allô Bailleur',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trouvez votre chez-vous au Cameroun',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                height: 70,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed(SearchPage.routeName),
                  child: Hero(
                    tag: 'searchBar',
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(35),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                        ),
                        padding: const EdgeInsets.only(left: 20, right: 8),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: theme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Essayez "Studio à Bastos..."',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Integration de l'icône Map
                            Tooltip(
                              message: 'Voir la carte',
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(NearbyMapPage.routeName);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.map_outlined,
                                    size: 22,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Category Chips
          SliverToBoxAdapter(
            child: Container(
              height: 110,
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['label'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat['label']),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? theme.primaryColor.withOpacity(0.4)
                                      : Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: isSelected
                                  ? null
                                  : Border.all(color: Colors.grey.shade200),
                            ),
                            child: Icon(
                              cat['icon'],
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? theme.primaryColor
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Properties List Title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'Tout'
                        ? 'Recommandés pour vous'
                        : 'Nos $_selectedCategory'
                              's',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_userLat != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Proche de moi",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // 4. Property Grid
          Consumer<PropertyProvider>(
            builder: (context, propertyProvider, child) {
              if (propertyProvider.isLoading) {
                return SliverToBoxAdapter(child: _buildShimmerGrid(context));
              }

              var properties = propertyProvider.properties ?? [];

              // Calcul de la distance pour chaque propriété
              if (_userLat != null && _userLng != null) {
                for (var p in properties) {
                  p.distance = _calculateDistance(
                    _userLat!,
                    _userLng!,
                    p.latitude,
                    p.longitude,
                  );
                }
                // Tri par distance
                properties.sort(
                  (a, b) => (a.distance ?? double.infinity).compareTo(
                    b.distance ?? double.infinity,
                  ),
                );
              }

              // Filtrage par catégorie
              if (_selectedCategory != 'Tout') {
                properties = properties
                    .where((p) => _mapTypeToLabel(p.type) == _selectedCategory)
                    .toList();
              }

              if (properties.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun bien trouvé dans cette catégorie',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        PropertyCard(property: properties[index]),
                    childCount: properties.length,
                  ),
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}

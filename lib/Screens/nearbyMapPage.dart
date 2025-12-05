import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:rent_house/Screens/propertyDetailsPage.dart';

class NearbyMapPage extends StatefulWidget {
  static const String routeName = '/nearbyMapRoute';
  const NearbyMapPage({super.key});

  @override
  State<NearbyMapPage> createState() => _NearbyMapPageState();
}

class _NearbyMapPageState extends State<NearbyMapPage> {
  final MapController _mapController = MapController();
  // Position par défaut (Yaoundé) utilisée uniquement en cas d'échec total
  LatLng _currentPosition = const LatLng(3.8480, 11.5021); 
  bool _isLoadingLocation = true;
  double _searchRadiusKm = 5.0;
  bool _showSatellite = false;

  // Tuiles OpenStreetMap standards
  final String _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  // Tuiles Satellite (Esri World Imagery)
  final String _satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veuillez activer le GPS pour voir votre position réelle")),
          );
          setState(() => _isLoadingLocation = false);
        }
        // On continue quand même avec la position par défaut ou dernière connue si possible
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Permission de localisation refusée")),
            );
            setState(() => _isLoadingLocation = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      // 1. Tenter d'abord la dernière position connue (rapide) - UNIQUEMENT SUR MOBILE
      if (!kIsWeb) {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          setState(() {
            _currentPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
          });
          // On centre déjà la carte sur la dernière connue
          _zoomToRadius();
        }
      }

      // 2. Récupérer la position actuelle précise
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        // Réajuster le zoom avec la position précise
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _zoomToRadius();
        });
      }
    } catch (e) {
      debugPrint("Erreur localisation: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _zoomToRadius() {
    // Calculer les bornes (bounds) correspondant au rayon
    // 1 degré latitude ~= 111 km
    const double degreesPerKm = 1 / 111.32;
    double latDelta = _searchRadiusKm * degreesPerKm;
    double lonDelta = _searchRadiusKm * degreesPerKm / math.cos(_currentPosition.latitude * (math.pi / 180));

    LatLngBounds bounds = LatLngBounds(
      LatLng(_currentPosition.latitude - latDelta, _currentPosition.longitude - lonDelta),
      LatLng(_currentPosition.latitude + latDelta, _currentPosition.longitude + lonDelta),
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  double _calculateDistance(LatLng pos1, LatLng pos2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((pos2.latitude - pos1.latitude) * p) / 2 +
        c(pos1.latitude * p) *
            c(pos2.latitude * p) *
            (1 - c((pos2.longitude - pos1.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final allProperties = propertyProvider.properties ?? [];

    // Filtrer les propriétés proches
    final nearbyProperties = allProperties.where((p) {
      final propLoc = LatLng(p.latitude, p.longitude);
      final dist = _calculateDistance(_currentPosition, propLoc);
      return dist <= _searchRadiusKm;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _showSatellite ? _satelliteUrl : _osmUrl,
                userAgentPackageName: 'com.example.rent_house',
              ),

              // Cercle visualisant le rayon de recherche
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentPosition,
                    radius: _searchRadiusKm * 1000, // Convertir km en mètres
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue.withOpacity(0.6),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  // Ma position
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 5, color: Colors.black26)
                            ],
                          ),
                          child: const Icon(Icons.my_location,
                              color: Colors.blue, size: 20),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Moi',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Propriétés
                  ...nearbyProperties.map((prop) => Marker(
                        point: LatLng(prop.latitude, prop.longitude),
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) =>
                                  _buildPropertyPreview(context, prop),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 5, color: Colors.black38)
                                  ],
                                ),
                                child: const Icon(Icons.home,
                                    color: Colors.white, size: 20),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 2, color: Colors.black12)
                                  ],
                                ),
                                child: Text(
                                  "${prop.price} FCFA",
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),

              // Copyright
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),

          // Barre supérieure (Recherche + Filtres + Satellite Toggle)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton Retour
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Carte Controls
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radar,
                                  size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text("Rayon: ${_searchRadiusKm.toInt()} km"),
                              Expanded(
                                child: Slider(
                                  value: _searchRadiusKm,
                                  min: 1,
                                  max: 20,
                                  divisions: 19,
                                  label: "${_searchRadiusKm.toInt()} km",
                                  onChanged: (val) {
                                    setState(() => _searchRadiusKm = val);
                                  },
                                  onChangeEnd: (val) {
                                    // Ajuster le zoom une fois que l'utilisateur relâche le slider
                                    _zoomToRadius();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Vue Satellite",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              Switch(
                                value: _showSatellite,
                                onChanged: (val) =>
                                    setState(() => _showSatellite = val),
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton Recentrer
          Positioned(
            right: 16,
            bottom: 30,
            child: FloatingActionButton(
              heroTag: "recenterMapBtn",
              onPressed: () => _zoomToRadius(),
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
          
          if (_isLoadingLocation)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyPreview(BuildContext context, Property property) {
    final double distance = _calculateDistance(
      _currentPosition,
      LatLng(property.latitude, property.longitude),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          Row(
            children: [
              const Icon(Icons.directions_walk, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "À ${distance.toStringAsFixed(1)} km de votre position",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                property.imageUrls.isNotEmpty
                    ? property.imageUrls.first
                    : 'https://via.placeholder.com/400x200',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.home, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${property.price} FCFA / mois",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    PropertyDetailsPage.routeName,
                    arguments: property,
                  );
                },
                child: const Text("Voir l'annonce"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

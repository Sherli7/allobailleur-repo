import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Providers/property_provider.dart';

class MapPage extends StatefulWidget {
  static const String routeName = '/mapPageRoute';

  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final LatLng _centerLocation =
      const LatLng(3.8667, 11.5167); // Yaoundé, Cameroon

  @override
  void initState() {
    super.initState();
    // Charger les propriétés
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      propertyProvider.loadAllProperties();
    });
  }

  void _updateMarkers(List<Property> properties) {
    _markers.clear();

    for (final property in properties) {
      final marker = Marker(
        markerId: MarkerId(property.id),
        position: LatLng(property.latitude, property.longitude),
        infoWindow: InfoWindow(
          title: property.title,
          snippet:
              '${property.price} ${property.currency}/mois - ${property.bedrooms} chambre(s)',
          onTap: () {
            _navigateToDetails(property);
          },
        ),
        onTap: () {
          _navigateToDetails(property);
        },
      );
      _markers.add(marker);
    }
  }

  void _navigateToDetails(Property property) {
    Provider.of<PropertyProvider>(context, listen: false)
        .selectProperty(property);
    Navigator.pushNamed(
      context,
      '/propertyDetailsRoute', // À adapter avec le bon routeName
      arguments: property,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des biens'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, child) {
          // Mettre à jour les markers quand les propriétés changent (protection null)
          final props = propertyProvider.properties ?? <Property>[];
          if (props.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMarkers(props);
            });
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                initialCameraPosition: CameraPosition(
                  target: _centerLocation,
                  zoom: 12.0,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              ),
              if (propertyProvider.isLoading)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              if (propertyProvider.errorMessage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      propertyProvider.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

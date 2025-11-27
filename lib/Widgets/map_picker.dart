import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapPickerResult {
  final double lat;
  final double lng;
  final String? city;
  final String? displayName;

  MapPickerResult({
    required this.lat,
    required this.lng,
    this.city,
    this.displayName,
  });
}

class MapPickerPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapPickerPage({
    super.key,
    this.initialLat = 3.8667,
    this.initialLng = 11.5167,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final MapController _mapController;
  LatLng? _selected;
  bool _isReverseLoading = false;
  String? _city;
  String? _displayName;
  bool _isGettingPosition = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() {
      _isReverseLoading = true;
      _city = null;
      _displayName = null;
    });
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}');
      final res = await http.get(url,
          headers: {'User-Agent': 'AlloBailleur/1.0 (+https://example.com)'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final address = body['address'] as Map<String, dynamic>?;
        String? city;
        if (address != null) {
          city = address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['county'] as String?;
        }
        setState(() {
          _city = city;
          _displayName = body['display_name'] as String?;
        });
      }
    } catch (_) {
      // ignore errors, reverse geocoding is best-effort
    } finally {
      if (mounted) setState(() => _isReverseLoading = false);
    }
  }

  void _onTapTap(TapPosition tapPosition, LatLng latlng) async {
    setState(() {
      _selected = latlng;
    });
    await _reverseGeocode(latlng);
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _useMyLocation() async {
    setState(() => _isGettingPosition = true);
    try {
      final pos = await _determinePosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Impossible d\'obtenir la position. Activer la localisation.')));
        }
        return;
      }
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _selected = latlng;
      });
      _mapController.move(latlng, 15.0);
      await _reverseGeocode(latlng);
    } finally {
      if (mounted) setState(() => _isGettingPosition = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = LatLng(widget.initialLat, widget.initialLng);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir l\'emplacement'),
        actions: [
          IconButton(
            tooltip: 'Ma position',
            onPressed: _isGettingPosition ? null : _useMyLocation,
            icon: _isGettingPosition
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
          TextButton(
            onPressed: _selected == null
                ? null
                : () {
                    final res = MapPickerResult(
                      lat: _selected!.latitude,
                      lng: _selected!.longitude,
                      city: _city,
                      displayName: _displayName,
                    );
                    Navigator.of(context).pop(res);
                  },
            child:
                const Text('Confirmer', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _selected ?? initial,
                zoom: 13.0,
                onTap: _onTapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 48,
                        height: 48,
                        builder: (ctx) => const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      )
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 6,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected == null
                            ? 'Aucun emplacement sélectionné'
                            : 'Lat: ${_selected!.latitude.toStringAsFixed(5)}, Lng: ${_selected!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (_isReverseLoading)
                        const Text('Recherche de l\'adresse...')
                      else if (_city != null)
                        Text(_city!)
                      else if (_displayName != null)
                        Text(_displayName!)
                      else
                        const Text(
                            'Appuyez sur la carte pour placer un marqueur'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          final res = MapPickerResult(
                            lat: _selected!.latitude,
                            lng: _selected!.longitude,
                            city: _city,
                            displayName: _displayName,
                          );
                          Navigator.of(context).pop(res);
                        },
                  child: const Text('Utiliser'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

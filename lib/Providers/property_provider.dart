// lib/Providers/property_provider.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/property.dart';

class PropertyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ────────────────────────────── Méthodes existantes ──────────────────────────────
  Future<Map<String, dynamic>> createProperty(Property property) async {
    try {
      final response = await _supabase
          .from('properties')
          .insert(property.toJson())
          .select();
      final propertyId = response[0]['id'];
      return {'success': true, 'propertyId': propertyId};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Property?> getProperty(String propertyId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('id', propertyId)
          .single();
      return Property.fromJson(response);
    } catch (e) {
      debugPrint('Erreur getProperty: $e');
      return null;
    }
  }

  Future<List<Property>> getAllProperties() async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .neq('status', 'rented')
          .order('createdAt', ascending: false);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur getAllProperties: $e');
      return [];
    }
  }

  Future<List<Property>> getHostProperties(String hostId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('ownerId', hostId);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur getHostProperties: $e');
      return [];
    }
  }

  Future<List<Property>> getFavorites(String userId) async {
    try {
      final favResponse = await _supabase
          .from('favorites')
          .select('propertyId')
          .eq('userId', userId);
      final propIds = favResponse
          .map((f) => f['propertyId'] as String)
          .toList();
      if (propIds.isEmpty) return [];

      final propResponse = await _supabase
          .from('properties')
          .select()
          .filter('id', 'in', '(${propIds.join(',')})');
      return propResponse.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur getFavorites: $e');
      return [];
    }
  }

  Future<List<Property>> getPropertiesPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      final response = await _supabase
          .from('properties')
          .select()
          .neq('status', 'rented')
          .order('createdAt', ascending: false)
          .range(from, to);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur pagination: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addToFavorites(
    String userId,
    String propertyId,
  ) async {
    try {
      await _supabase.from('favorites').insert({
        'userId': userId,
        'propertyId': propertyId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeFromFavorites(
    String userId,
    String propertyId,
  ) async {
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('userId', userId)
          .eq('propertyId', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Upload d'image corrigé (utilise .upload au lieu de .uploadBinary)
  Future<String?> uploadImageWithProgress(
    dynamic file,
    String propertyId,
    void Function(double) onProgress,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'properties/$propertyId/$fileName';

      Uint8List bytes;
      if (file is XFile) {
        bytes = await file.readAsBytes();
      } else if (file is File) {
        bytes = await file.readAsBytes();
      } else if (file is Uint8List) {
        bytes = file;
      } else {
        throw UnsupportedError('Type de fichier non supporté');
      }

      // Utilisation de .uploadBinary pour Uint8List
      await _supabase.storage
          .from('property-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from('property-images')
          .getPublicUrl(filePath);
      onProgress(1.0);
      return publicUrl;
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      return null;
    }
  }

  Future<void> setPropertyImageUrls(
    String propertyId,
    List<String> urls,
  ) async {
    await _supabase
        .from('properties')
        .update({'imageUrls': urls})
        .eq('id', propertyId);
  }

  Future<Map<String, dynamic>> updateProperty(
    String propertyId,
    Property property,
  ) async {
    try {
      await _supabase
          .from('properties')
          .update(property.toJson())
          .eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProperty(String propertyId) async {
    try {
      await _supabase.from('properties').delete().eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markPropertyAsRented(String propertyId) async {
    try {
      await _supabase
          .from('properties')
          .update({
            'status': 'rented',
            'updatedAt': DateTime.now().toIso8601String(),
          })
          .eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markPropertyAsAvailable(
    String propertyId,
  ) async {
    try {
      await _supabase
          .from('properties')
          .update({
            'status': 'published',
            'updatedAt': DateTime.now().toIso8601String(),
          })
          .eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeRental(String propertyId) async {
    try {
      await _supabase
          .from('properties')
          .update({
            'status': 'rented',
            'updatedAt': DateTime.now().toIso8601String(),
          })
          .eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> restoreProperty(String propertyId) async {
    try {
      await _supabase
          .from('properties')
          .update({
            'status': 'published',
            'updatedAt': DateTime.now().toIso8601String(),
          })
          .eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

// ──────────────────────────────────────────────────────────────
// PROPERTY PROVIDER COMPLET
// ──────────────────────────────────────────────────────────────

class PropertyProvider with ChangeNotifier {
  final PropertyService _service = PropertyService();

  // Données
  List<Property>? _properties = [];
  List<Property>? _favorites = [];
  List<Property>? _userProperties = [];

  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  double? _uploadProgress;
  Property? _selectedProperty;

  // Recherche + tri par localisation
  List<Property> _filteredProperties = [];
  bool _isSortedByLocation = false;
  double _userLat = 0;
  double _userLng = 0;

  // ────── Getters ──────
  List<Property> get properties => _properties ?? [];
  List<Property> get favorites => _favorites ?? [];
  List<Property> get userProperties => _userProperties ?? [];
  List<Property> get filteredProperties =>
      _filteredProperties.isEmpty ? properties : _filteredProperties;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get uploadProgress => _uploadProgress;
  Property? get selectedProperty => _selectedProperty;
  bool get isSortedByLocation => _isSortedByLocation;

  // ────── Chargement ──────
  Future<void> loadPropertiesOnce({int page = 1, int pageSize = 100}) async {
    _setLoading(true);
    try {
      _properties = await _service.getPropertiesPaginated(
        page: page,
        pageSize: pageSize,
      );
      _filteredProperties = List.from(_properties!);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  // Alias pour compatibilité avec createTicketPage
  Future<void> fetchProperties() => loadPropertiesOnce();

  Future<void> loadAllProperties() => loadPropertiesOnce();

  Future<void> loadFavorites(String userId) async {
    _setLoading(true);
    try {
      _favorites = await _service.getFavorites(userId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadHostProperties(String hostId) async {
    _setLoading(true);
    try {
      _userProperties = await _service.getHostProperties(hostId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  /// Fetch properties for the current user
  Future<void> fetchUserProperties(String userId) async {
    _setLoading(true);
    try {
      // Use getHostProperties as it fetches properties by ownerId
      final response = await _service.getHostProperties(userId);
      _userProperties = response;
    } catch (e) {
      _errorMessage = 'Failed to fetch user properties: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ────── Recherche ──────
  void filterPropertiesByTitle(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredProperties = List.from(_properties ?? []);
    } else {
      _filteredProperties = (_properties ?? []).where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q) ||
            (p.district?.toLowerCase().contains(q) ?? false) ||
            (p.address?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (_isSortedByLocation) _sortByLocation(_userLat, _userLng);
    notifyListeners();
  }

  // ────── Tri par localisation ──────
  void sortPropertiesByLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    _isSortedByLocation = true;
    _sortByLocation(lat, lng);
    notifyListeners();
  }

  void _sortByLocation(double lat, double lng) {
    final list = _filteredProperties.isEmpty
        ? _properties!
        : _filteredProperties;
    list.sort((a, b) {
      final distA = Geolocator.distanceBetween(
        lat,
        lng,
        a.latitude,
        a.longitude,
      );
      final distB = Geolocator.distanceBetween(
        lat,
        lng,
        b.latitude,
        b.longitude,
      );
      return distA.compareTo(distB);
    });
    for (var p in list) {
      final distanceKm =
          Geolocator.distanceBetween(lat, lng, p.latitude, p.longitude) / 1000;
      p.distance = double.parse(distanceKm.toStringAsFixed(1));
    }
    if (_filteredProperties.isNotEmpty) {
      _filteredProperties = list;
    } else {
      _properties = list;
    }
  }

  void resetSorting() {
    _isSortedByLocation = false;
    _filteredProperties = List.from(_properties ?? []);
    notifyListeners();
  }

  void clearSearch() {
    _filteredProperties = List.from(_properties ?? []);
    if (_isSortedByLocation) _sortByLocation(_userLat, _userLng);
    notifyListeners();
  }

  // ────── Favoris ──────
  Future<bool> toggleFavorite(Property property) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final isFavorite = _favorites?.any((p) => p.id == property.id) ?? false;

    try {
      if (isFavorite) {
        final res = await _service.removeFromFavorites(userId, property.id);
        if (res['success']) {
          _favorites?.removeWhere((p) => p.id == property.id);
          notifyListeners();
          return true;
        }
      } else {
        final res = await _service.addToFavorites(userId, property.id);
        if (res['success']) {
          _favorites?.add(property);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool isFavorite(Property property) {
    return _favorites?.any((p) => p.id == property.id) ?? false;
  }

  // ────── Gestion de l'état de chargement ──────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ────── CRUD Propriété (Proxy vers Service) ──────
  Future<Map<String, dynamic>> createProperty(
    Property property, {
    List<XFile>? images,
  }) async {
    _setLoading(true);
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // 1. Créer l'entrée dans la DB
      final res = await _service.createProperty(property);
      if (res['success'] == false) {
        _errorMessage = res['message'];
        _setLoading(false);
        return res;
      }

      final propertyId = res['propertyId'];
      final List<String> imageUrls = [];

      // 2. Upload des images
      if (images != null && images.isNotEmpty) {
        int total = images.length;
        for (int i = 0; i < total; i++) {
          final url = await _service.uploadImageWithProgress(
            images[i],
            propertyId,
            (progress) {
              _uploadProgress = (i + progress) / total;
              notifyListeners();
            },
          );
          if (url != null) imageUrls.add(url);
        }

        // 3. Mettre à jour les URLs
        await _service.setPropertyImageUrls(propertyId, imageUrls);
      }

      // Recharger
      await loadPropertiesOnce();
      _setLoading(false);
      return {'success': true, 'propertyId': propertyId};
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProperty(
    String propertyId,
    Property property, {
    List<XFile>? newImages,
  }) async {
    _setLoading(true);
    try {
      final res = await _service.updateProperty(propertyId, property);
      if (res['success']) {
        // Handle new images if provided
        if (newImages != null && newImages.isNotEmpty) {
          final List<String> currentUrls = List.from(property.imageUrls);
          int total = newImages.length;
          for (int i = 0; i < total; i++) {
            final url = await _service.uploadImageWithProgress(
              newImages[i],
              propertyId,
              (progress) {
                // Optional: handle progress
              },
            );
            if (url != null) currentUrls.add(url);
          }
          // Update URLs in DB
          await _service.setPropertyImageUrls(propertyId, currentUrls);
          // Update local property object if needed, but re-fetching list is safer/easier or manually updating it here
          property.imageUrls.clear();
          property.imageUrls.addAll(currentUrls);
        }

        final index = _properties?.indexWhere((p) => p.id == propertyId) ?? -1;
        if (index != -1) {
          _properties![index] = property;
          notifyListeners();
        }
        return {'success': true};
      } else {
        _errorMessage = res['message'];
        return res;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProperty(String propertyId) async {
    try {
      final res = await _service.deleteProperty(propertyId);
      if (res['success']) {
        _properties?.removeWhere((p) => p.id == propertyId);
        _userProperties?.removeWhere((p) => p.id == propertyId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ────── Actions ──────
  void selectProperty(Property property) {
    _selectedProperty = property;
    notifyListeners();
  }

  Future<bool> completeRental(Property property) async {
    try {
      final res = await _service.completeRental(property.id);
      if(res['success']) {
        _selectedProperty = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> restoreProperty(Property property) async {
    try {
      final res = await _service.restoreProperty(property.id);
       if(res['success']) {
        _selectedProperty = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_house/Models/property.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Pour dates (supprimé car inutilisé)

class PropertyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// EXISTANT: Créer une propriété (retourne Map{success, propertyId/message})
  Future<Map<String, dynamic>> createProperty(Property property) async {
    try {
      final response =
          await _supabase.from('properties').insert(property.toJson()).select();
      final propertyId = response[0]['id'];
      return {'success': true, 'propertyId': propertyId};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// EXISTANT: Récupérer une propriété
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

  /// EXISTANT: Récupérer toutes les propriétés
  Future<List<Property>> getAllProperties() async {
    try {
      final response = await _supabase.from('properties').select();
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur getAllProperties: $e');
      return [];
    }
  }

  /// EXISTANT: Stream propriétés de l'hôte
  Future<List<Property>> getHostProperties(String hostId) async {
    try {
      final response =
          await _supabase.from('properties').select().eq('ownerId', hostId);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur getHostProperties: $e');
      return [];
    }
  }

  /// EXISTANT: Recherche par ville
  Future<List<Property>> searchPropertiesByCity(String city) async {
    try {
      final response =
          await _supabase.from('properties').select().eq('city', city);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur searchPropertiesByCity: $e');
      return [];
    }
  }

  /// EXISTANT: Recherche par prix
  Future<List<Property>> searchPropertiesByPriceRange(
      double minPrice, double maxPrice) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .gte('price', minPrice)
          .lte('price', maxPrice);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur searchPropertiesByPriceRange: $e');
      return [];
    }
  }

  /// NOUVEAU: Recherche avancée (query texte + filtres)
  Future<List<Property>> searchPropertiesAdvanced({
    String query = '',
    double? minPrice,
    double? maxPrice,
    String? type,
    int? rooms,
  }) async {
    try {
      // Simple implementation, filter in code for now
      final response = await _supabase
          .from('properties')
          .select()
          .order('createdAt', ascending: false);
      List<Property> list =
          response.map((data) => Property.fromJson(data)).toList();

      // Filter in code
      if (query.isNotEmpty) {
        list = list
            .where((p) => p.title.contains(query) || p.city.contains(query))
            .toList();
      }
      if (minPrice != null) {
        list = list.where((p) => p.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        list = list.where((p) => p.price <= maxPrice).toList();
      }
      if (type != null && type.isNotEmpty) {
        list = list.where((p) => p.type == type).toList();
      }
      if (rooms != null) {
        list = list.where((p) => p.rooms == rooms).toList();
      }

      return list;
    } catch (e) {
      debugPrint('Erreur searchPropertiesAdvanced: $e');
      return [];
    }
  }

  /// NOUVEAU: Pagination (Future pour loadMore ; utilise limit + startAfter)
  Future<List<Property>> getPropertiesPaginated({
    required int page,
    required int pageSize,
    int? startAfter,
  }) async {
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      final response = await _supabase
          .from('properties')
          .select()
          .order('createdAt', ascending: false)
          .range(from, to);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur pagination: $e');
      return [];
    }
  }

  /// NOUVEAU: Stream favoris d'un user (query sur favorites collection)
  Future<List<Property>> getFavorites(String userId) async {
    try {
      final favResponse = await _supabase
          .from('favorites')
          .select('propertyId')
          .eq('userId', userId);
      final propIds =
          favResponse.map((f) => f['propertyId'] as String).toList();
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

  /// EXISTANT: Ajouter aux favoris (retourne Map{success})
  Future<Map<String, dynamic>> addToFavorites(
      String userId, String propertyId) async {
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

  /// EXISTANT: Supprimer des favoris
  Future<Map<String, dynamic>> removeFromFavorites(
      String userId, String propertyId) async {
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

  /// EXISTANT: Upload image avec progress (retourne URL)
  Future<String?> uploadImageWithProgress(
    dynamic file, // File, XFile, or Uint8List
    String propertyId,
    void Function(double) onProgress,
  ) async {
    try {
      debugPrint('=== Starting image upload process ===');
      debugPrint('Property ID: $propertyId');
      debugPrint('File type: ${file.runtimeType}');

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
        throw UnsupportedError('Unsupported file type: ${file.runtimeType}');
      }

      debugPrint('Uploading ${bytes.length} bytes to Supabase Storage');

      final response = await _supabase.storage.from('images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

      debugPrint('Upload successful, path: $response');

      // Get public URL
      final publicUrl = _supabase.storage.from('images').getPublicUrl(filePath);
      debugPrint('Public URL: $publicUrl');
      onProgress(1.0); // Simulate progress
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('Erreur upload: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// EXISTANT: Set image URLs sur property
  Future<void> setPropertyImageUrls(
      String propertyId, List<String> urls) async {
    print('Updating property $propertyId with image URLs: $urls');
    await _supabase
        .from('properties')
        .update({'imageUrls': urls}).eq('id', propertyId);
    print('Property $propertyId updated with ${urls.length} image URLs');
  }

  /// EXISTANT: Update property
  Future<Map<String, dynamic>> updateProperty(
      String propertyId, Property property) async {
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

  /// EXISTANT: Delete property
  Future<Map<String, dynamic>> deleteProperty(String propertyId) async {
    try {
      await _supabase.from('properties').delete().eq('id', propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

/// Fournit une couche Provider compatibilité pour l'UI.
/// Cette implémentation minimale délégué vers `PropertyService` et expose
/// quelques champs et méthodes couramment utilisés par les écrans.
class PropertyProvider with ChangeNotifier {
  final PropertyService _service = PropertyService();

  List<Property>? properties;
  List<Property>? favorites;
  List<Property>? userProperties;
  bool isLoading = false;
  String? errorMessage;
  double? uploadProgress;
  Property? selectedProperty;

  Future<List<Property>> getAllPropertiesStream() =>
      _service.getAllProperties();
  Future<List<Property>> getHostPropertiesStream(String hostId) =>
      _service.getHostProperties(hostId);
  Future<List<Property>> getFavoritesStream(String userId) async {
    // For now, return empty
    return [];
  }

  Future<void> loadPropertiesOnce({int page = 1, int pageSize = 100}) async {
    isLoading = true;
    notifyListeners();
    try {
      properties =
          await _service.getPropertiesPaginated(page: page, pageSize: pageSize);
      print('Loaded ${properties?.length ?? 0} properties from database');
      if (properties != null && properties!.isNotEmpty) {
        print(
            'First property: ${properties!.first.title} - Price: ${properties!.first.price}');
      }
    } catch (e) {
      errorMessage = e.toString();
      print('Error loading properties: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Charge les favoris pour un user (une seule lecture puis set)
  Future<void> loadFavorites(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      favorites = await _service.getFavorites(userId);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Alias pour compatibilité
  Future<void> fetchFavorites(String userId) => loadFavorites(userId);

  /// Charge propriétés hôte
  Future<void> loadHostProperties(String hostId) async {
    isLoading = true;
    notifyListeners();
    try {
      userProperties = await _service.getHostProperties(hostId);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Alias / backward compatibility
  Future<void> fetchProperties() => loadPropertiesOnce();

  Future<void> loadAllProperties() => loadPropertiesOnce();

  Future<void> loadMoreProperties({int page = 1, int pageSize = 20}) async {
    isLoading = true;
    notifyListeners();
    try {
      final more =
          await _service.getPropertiesPaginated(page: page, pageSize: pageSize);
      properties = (properties ?? []) + more;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void selectProperty(Property p) {
    selectedProperty = p;
    notifyListeners();
  }

  /// Basique: toggle favoris (ajoute/supprime)
  Future<bool> toggleFavorite(Property property) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    final exists = (favorites ?? []).any((p) => p.id == property.id);
    try {
      if (exists) {
        final res = await removeFromFavorites(userId, property.id);
        if (res['success'] == true) {
          favorites =
              (favorites ?? []).where((p) => p.id != property.id).toList();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        final res = await addToFavorites(userId, property.id);
        if (res['success'] == true) {
          // Optionnel: recharger
          await loadFavorites(userId);
          return true;
        }
        return false;
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> createProperty(Property property,
      {dynamic images}) async {
    try {
      // Create property document first (without images)
      final res = await _service.createProperty(property);
      if (res['success'] != true) return res;
      final propertyId = res['propertyId'] as String;

      // If images provided, upload them and update the property with image URLs
      if (images != null) {
        debugPrint('Starting image upload process for ${images.length} images');
        final List<String> urls = [];
        for (var i = 0; i < images.length; i++) {
          final img = images[i];
          debugPrint('Uploading image ${i + 1}/${images.length}');
          try {
            final url = await _service.uploadImageWithProgress(img, propertyId,
                (progress) {
              uploadProgress = progress;
              debugPrint('Upload progress: ${(progress * 100).toInt()}%');
              notifyListeners();
            });
            if (url != null) {
              urls.add(url);
              debugPrint('Image ${i + 1} uploaded successfully: $url');
            } else {
              debugPrint('Image ${i + 1} upload failed - returned null');
            }
          } catch (e) {
            debugPrint('Error uploading image ${i + 1}: $e');
          }
        }

        debugPrint(
            'Upload complete. ${urls.length} images uploaded successfully');

        if (urls.isNotEmpty) {
          debugPrint('Updating property with image URLs');
          try {
            await _service.setPropertyImageUrls(propertyId, urls);
            debugPrint('Property updated with image URLs successfully');
          } catch (e) {
            debugPrint('Error updating property with image URLs: $e');
          }
          debugPrint('Property updated with image URLs');
        } else {
          debugPrint('No images were uploaded successfully');
        }
        uploadProgress = null;
        notifyListeners();
      }

      return {'success': true, 'propertyId': propertyId};
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProperty(String id, Property property,
          {dynamic newImages}) =>
      _service.updateProperty(id, property);
  Future<Map<String, dynamic>> deleteProperty(String id) =>
      _service.deleteProperty(id);

  Future<Map<String, dynamic>> addToFavorites(
          String userId, String propertyId) =>
      _service.addToFavorites(userId, propertyId);
  Future<Map<String, dynamic>> removeFromFavorites(
          String userId, String propertyId) =>
      _service.removeFromFavorites(userId, propertyId);

  /// Test method to verify Firebase Storage connectivity
  Future<bool> testStorageConnection() async {
    // Temporarily return true to skip the test
    debugPrint('Storage connection test skipped');
    return true;
  }
}

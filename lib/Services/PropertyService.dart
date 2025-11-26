import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:rent_house/Models/property.dart';

class PropertyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Créer une nouvelle propriété
  Future<Map<String, dynamic>> createProperty(Property property) async {
    try {
      final response =
          await _supabase.from('properties').insert(property.toJson()).select();
      final propertyId = response[0]['id'];

      return {
        'success': true,
        'message': 'Propriété créée avec succès',
        'propertyId': propertyId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la création: $e',
      };
    }
  }

  /// Récupérer une propriété par ID
  Future<Property?> getProperty(String propertyId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('id', propertyId)
          .single();
      return Property.fromJson(response);
    } catch (e) {
      // Log error to a real logging service
      return null;
    }
  }

  /// Récupérer toutes les propriétés disponibles
  Future<List<Property>> getAllProperties() async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('is_available', true)
          .order('created_at', ascending: false);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupérer les propriétés de l'hôte
  Future<List<Property>> getHostProperties(String hostId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('owner_id', hostId)
          .order('created_at', ascending: false);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Rechercher des propriétés par ville
  Future<List<Property>> searchPropertiesByCity(String city) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('city', city)
          .eq('is_available', true);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Rechercher par prix
  Future<List<Property>> searchPropertiesByPriceRange(
      double minPrice, double maxPrice) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .gte('price', minPrice)
          .lte('price', maxPrice)
          .eq('is_available', true);
      return response.map((data) => Property.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mettre à jour une propriété
  Future<Map<String, dynamic>> updateProperty(
    String propertyId,
    Property property,
  ) async {
    try {
      await _supabase
          .from('properties')
          .update(property.copyWith(updatedAt: DateTime.now()).toJson())
          .eq('id', propertyId);

      return {
        'success': true,
        'message': 'Propriété mise à jour',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      };
    }
  }

  /// Supprimer une propriété
  Future<Map<String, dynamic>> deleteProperty(String propertyId) async {
    try {
      await _supabase.from('properties').delete().eq('id', propertyId);

      return {
        'success': true,
        'message': 'Propriété supprimée',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la suppression: $e',
      };
    }
  }

  /// Ajouter une propriété aux favoris
  Future<Map<String, dynamic>> addToFavorites(
    String userId,
    String propertyId,
  ) async {
    try {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'property_id': propertyId,
      });

      return {
        'success': true,
        'message': 'Ajouté aux favoris',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Supprimer des favoris
  Future<Map<String, dynamic>> removeFromFavorites(
    String userId,
    String propertyId,
  ) async {
    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('property_id', propertyId);

      return {
        'success': true,
        'message': 'Retiré des favoris',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Ajouter une évaluation
  Future<Map<String, dynamic>> addReview(
    String propertyId,
    double rating,
    String comment,
    String userId,
  ) async {
    try {
      await _supabase.from('reviews').insert({
        'property_id': propertyId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      });

      // Mettre à jour la note moyenne et le nombre d'avis
      final response = await _supabase
          .from('properties')
          .select('rating, review_count')
          .eq('id', propertyId)
          .single();
      final currentRating = response['rating'] as double;
      final currentReviewCount = response['review_count'] as int;

      final newReviewCount = currentReviewCount + 1;
      final newRating =
          (currentRating * currentReviewCount + rating) / newReviewCount;

      await _supabase.from('properties').update({
        'rating': newRating,
        'review_count': newReviewCount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', propertyId);

      return {
        'success': true,
        'message': 'Avis ajouté',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer les avis
  Future<List<Map<String, dynamic>>> getReviews(String propertyId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select()
          .eq('property_id', propertyId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      return [];
    }
  }

  /// Uploader une image vers Supabase Storage
  /// Supporte `String` path, `File`, et `XFile` (image_picker).
  /// Retourne l'URL publique de l'image téléchargée
  Future<String?> uploadImage(dynamic imageFile, String propertyId) async {
    try {
      if (imageFile == null) return null;

      // Générer un nom unique pour le fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'property_$propertyId/image_$timestamp.jpg';

      // Préparer les données bytes
      List<int> bytes;
      if (imageFile is String) {
        bytes = await File(imageFile).readAsBytes();
      } else if (imageFile is File) {
        bytes = await imageFile.readAsBytes();
      } else {
        // Try XFile or other objects with readAsBytes()
        try {
          final data = await imageFile.readAsBytes();
          bytes = data;
        } catch (e) {
          // Fallback: try to treat as path string
          bytes = await File(imageFile.toString()).readAsBytes();
        }
      }

      // Uploader vers Supabase Storage
      await _supabase.storage
          .from('images')
          .uploadBinary(fileName, Uint8List.fromList(bytes));

      // Obtenir l'URL publique
      final downloadUrl =
          _supabase.storage.from('images').getPublicUrl(fileName);
      return downloadUrl;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
  }

  /// Variante de `uploadImage` fournissant des événements de progression.
  /// `onProgress` reçoit une valeur entre 0.0 et 1.0.
  Future<String?> uploadImageWithProgress(dynamic imageFile, String propertyId,
      void Function(double) onProgress) async {
    try {
      if (imageFile == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'property_$propertyId/image_$timestamp.jpg';

      List<int> bytes;
      if (imageFile is String) {
        bytes = await File(imageFile).readAsBytes();
      } else if (imageFile is File) {
        bytes = await imageFile.readAsBytes();
      } else {
        try {
          final data = await imageFile.readAsBytes();
          bytes = data;
        } catch (e) {
          bytes = await File(imageFile.toString()).readAsBytes();
        }
      }

      onProgress(0.5); // Simuler progression
      await _supabase.storage
          .from('images')
          .uploadBinary(fileName, Uint8List.fromList(bytes));
      onProgress(1.0);

      final downloadUrl =
          _supabase.storage.from('images').getPublicUrl(fileName);
      return downloadUrl;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de l\'image (progress): $e');
      try {
        onProgress(0.0);
      } catch (_) {}
      return null;
    }
  }

  /// Mettre à jour uniquement la liste `imageUrls` d'une propriété
  Future<Map<String, dynamic>> setPropertyImageUrls(
      String propertyId, List<String> urls) async {
    try {
      await _supabase.from('properties').update({
        'image_urls': urls,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', propertyId);

      return {'success': true, 'message': 'Image URLs mises à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur mise à jour images: $e'};
    }
  }
}

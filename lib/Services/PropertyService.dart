import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:rent_house/Models/property.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Créer une nouvelle propriété
  Future<Map<String, dynamic>> createProperty(Property property) async {
    try {
      final docRef = await _firestore.collection('properties').add(
            property.toFirestore(),
          );

      return {
        'success': true,
        'message': 'Propriété créée avec succès',
        'propertyId': docRef.id,
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
      final doc =
          await _firestore.collection('properties').doc(propertyId).get();
      if (doc.exists) {
        return Property.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Log error to a real logging service
      return null;
    }
  }

  /// Récupérer toutes les propriétés disponibles
  Stream<List<Property>> getAllProperties() {
    return _firestore
        .collection('properties')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    });
  }

  /// Récupérer les propriétés de l'hôte
  Stream<List<Property>> getHostProperties(String hostId) {
    return _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    });
  }

  /// Rechercher des propriétés par ville
  Stream<List<Property>> searchPropertiesByCity(String city) {
    return _firestore
        .collection('properties')
        .where('city', isEqualTo: city)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    });
  }

  /// Rechercher par prix
  Stream<List<Property>> searchPropertiesByPriceRange(
      double minPrice, double maxPrice) {
    return _firestore
        .collection('properties')
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    });
  }

  /// Mettre à jour une propriété
  Future<Map<String, dynamic>> updateProperty(
    String propertyId,
    Property property,
  ) async {
    try {
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .update(property.copyWith(updatedAt: DateTime.now()).toFirestore());

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
      await _firestore.collection('properties').doc(propertyId).delete();

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
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayUnion([propertyId])
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
      await _firestore.collection('users').doc(userId).update({
        'favorites': FieldValue.arrayRemove([propertyId])
      });

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
      await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('reviews')
          .add({
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      // Mettre à jour la note moyenne et le nombre d'avis
      final doc =
          await _firestore.collection('properties').doc(propertyId).get();
      final property = Property.fromFirestore(doc);

      final newReviewCount = property.reviewCount + 1;
      final newRating =
          (property.rating * property.reviewCount + rating) / newReviewCount;

      await _firestore.collection('properties').doc(propertyId).update({
        'rating': newRating,
        'reviewCount': newReviewCount,
      });

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
  Stream<List<Map<String, dynamic>>> getReviews(String propertyId) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Uploader une image vers Firebase Storage
  /// Supporte `String` path, `File`, et `XFile` (image_picker).
  /// Retourne l'URL publique de l'image téléchargée
  Future<String?> uploadImage(dynamic imageFile, String propertyId) async {
    try {
      if (imageFile == null) return null;

      // Générer un nom unique pour le fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'property_$propertyId/image_$timestamp.jpg';

      // Créer une référence vers le fichier dans Storage
      final storageRef = _storage.ref().child(fileName);

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

      // Uploader les bytes
      final uploadTask = storageRef.putData(Uint8List.fromList(bytes));
      await uploadTask;

      // Obtenir l'URL de téléchargement publique
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
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
      final storageRef = _storage.ref().child(fileName);

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

      final uploadTask = storageRef.putData(Uint8List.fromList(bytes));

      // Écouter les événements de progression
      uploadTask.snapshotEvents.listen((snapshot) {
        final transferred = snapshot.bytesTransferred.toDouble();
        final total = snapshot.totalBytes.toDouble();
        final progress = total > 0 ? (transferred / total) : 0.0;
        try {
          onProgress(progress.clamp(0.0, 1.0));
        } catch (_) {}
      });

      // Attendre la fin
      await uploadTask;

      final downloadUrl = await storageRef.getDownloadURL();
      onProgress(1.0);
      return downloadUrl;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image (progress): $e');
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
      await _firestore.collection('properties').doc(propertyId).update({
        'imageUrls': urls,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return {'success': true, 'message': 'Image URLs mises à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur mise à jour images: $e'};
    }
  }
}

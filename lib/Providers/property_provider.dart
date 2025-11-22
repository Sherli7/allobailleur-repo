import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rent_house/Models/property.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Pour dates (supprimé car inutilisé)

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // FirebaseAuth instance not used here; use FirebaseAuth.instance directly where needed

  CollectionReference<Map<String, dynamic>> get _propertiesRef =>
      _firestore.collection('properties');
  CollectionReference<Map<String, dynamic>> get _favoritesRef =>
      _firestore.collection('favorites');

  /// EXISTANT: Créer une propriété (retourne Map{success, propertyId/message})
  Future<Map<String, dynamic>> createProperty(Property property) async {
    try {
      final docRef = await _propertiesRef.add(property.toFirestore());
      return {'success': true, 'propertyId': docRef.id};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// EXISTANT: Récupérer une propriété
  Future<Property?> getProperty(String propertyId) async {
    try {
      final doc = await _propertiesRef.doc(propertyId).get();
      if (doc.exists) {
        return Property.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur getProperty: $e');
      return null;
    }
  }

  /// EXISTANT: Stream toutes les propriétés
  Stream<List<Property>> getAllProperties() {
    return _propertiesRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
  }

  /// EXISTANT: Stream propriétés de l'hôte
  Stream<List<Property>> getHostProperties(String hostId) {
    return _propertiesRef.where('hostId', isEqualTo: hostId).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
  }

  /// EXISTANT: Recherche par ville
  Stream<List<Property>> searchPropertiesByCity(String city) {
    return _propertiesRef.where('city', isEqualTo: city).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
  }

  /// EXISTANT: Recherche par prix
  Stream<List<Property>> searchPropertiesByPriceRange(
      double minPrice, double maxPrice) {
    return _propertiesRef
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList());
  }

  /// NOUVEAU: Recherche avancée (query texte + filtres ; utilise where + orderBy)
  Stream<List<Property>> searchPropertiesAdvanced({
    String query = '',
    double? minPrice,
    double? maxPrice,
    String? type,
    int? rooms,
  }) {
    Query queryRef = _propertiesRef.orderBy('createdAt', descending: true);

    // Recherche texte (sur title/city ; Firestore full-text approx via array-contains-any ou where)
    if (query.isNotEmpty) {
      // Assume champ 'searchTerms' array dans Property (populate avec mots-clés à la création)
      queryRef = queryRef
          .where('searchTerms', arrayContainsAny: [query.toLowerCase()]);
    }

    // Filtres
    if (minPrice != null) {
      queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (type != null && type.isNotEmpty) {
      queryRef = queryRef.where('type', isEqualTo: type);
    }
    if (rooms != null) queryRef = queryRef.where('rooms', isEqualTo: rooms);

    return queryRef.snapshots().map((snapshot) => snapshot.docs.map((doc) {
          return Property.fromFirestore(doc);
        }).toList());
  }

  /// NOUVEAU: Pagination (Future pour loadMore ; utilise limit + startAfter)
  Future<List<Property>> getPropertiesPaginated({
    required int page,
    required int pageSize,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query =
          _propertiesRef.orderBy('createdAt', descending: true).limit(pageSize);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Property.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Erreur pagination: $e');
      return [];
    }
  }

  /// NOUVEAU: Stream favoris d'un user (query sur favorites collection)
  Stream<List<Property>> getFavorites(String userId) {
    return _favoritesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final propIds =
          snapshot.docs.map((doc) => doc['propertyId'] as String).toList();
      if (propIds.isEmpty) return <Property>[];

      // Fetch properties correspondantes
      final propSnapshot = await _propertiesRef
          .where(FieldPath.documentId, whereIn: propIds)
          .get();
      return propSnapshot.docs
          .map((doc) => Property.fromFirestore(doc))
          .toList();
    });
  }

  /// EXISTANT: Ajouter aux favoris (retourne Map{success})
  Future<Map<String, dynamic>> addToFavorites(
      String userId, String propertyId) async {
    try {
      await _favoritesRef.add({
        'userId': userId,
        'propertyId': propertyId,
        'createdAt': FieldValue.serverTimestamp(),
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
      final query = await _favoritesRef
          .where('userId', isEqualTo: userId)
          .where('propertyId', isEqualTo: propertyId)
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// EXISTANT: Upload image avec progress (retourne URL)
  Future<String?> uploadImageWithProgress(
    dynamic file, // File ou Uint8List
    String propertyId,
    void Function(double) onProgress,
  ) async {
    try {
      final ref = _storage.ref().child(
          'properties/$propertyId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask =
          ref.putFile(File(file.path)); // Assume File ; adapte si Uint8List

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur upload: $e');
      return null;
    }
  }

  /// EXISTANT: Set image URLs sur property
  Future<void> setPropertyImageUrls(
      String propertyId, List<String> urls) async {
    await _propertiesRef.doc(propertyId).update({'imageUrls': urls});
  }

  /// EXISTANT: Update property
  Future<Map<String, dynamic>> updateProperty(
      String propertyId, Property property) async {
    try {
      await _propertiesRef.doc(propertyId).update(property.toFirestore());
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// EXISTANT: Delete property
  Future<Map<String, dynamic>> deleteProperty(String propertyId) async {
    try {
      await _propertiesRef.doc(propertyId).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// EXISTANT: Add review (assume subcollection reviews sous property)
  Future<Map<String, dynamic>> addReview(
      String propertyId, double rating, String comment, String userId) async {
    try {
      final reviewRef =
          _propertiesRef.doc(propertyId).collection('reviews').doc();
      await reviewRef.set({
        'rating': rating,
        'comment': comment,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update average rating (trigger ou calc local)
      await _updatePropertyRating(propertyId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Helper: Update rating average
  Future<void> _updatePropertyRating(String propertyId) async {
    final reviewsSnapshot =
        await _propertiesRef.doc(propertyId).collection('reviews').get();
    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (final doc in reviewsSnapshot.docs) {
      totalRating += doc['rating'] as double;
    }
    final avg = totalRating / reviewsSnapshot.docs.length;

    await _propertiesRef.doc(propertyId).update({
      'rating': avg,
      'reviewCount': reviewsSnapshot.docs.length,
    });
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

  Stream<List<Property>> getAllPropertiesStream() =>
      _service.getAllProperties();
  Stream<List<Property>> getHostPropertiesStream(String hostId) =>
      _service.getHostProperties(hostId);
  Stream<List<Property>> getFavoritesStream(String userId) =>
      _service.getFavorites(userId);

  Future<void> loadPropertiesOnce({int page = 1, int pageSize = 100}) async {
    isLoading = true;
    notifyListeners();
    try {
      properties =
          await _service.getPropertiesPaginated(page: page, pageSize: pageSize);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Charge les favoris pour un user (une seule lecture puis set)
  Future<void> loadFavorites(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      favorites = await _service.getFavorites(userId).first;
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
      userProperties = await _service.getHostProperties(hostId).first;
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
        final List<String> urls = [];
        for (var img in images) {
          final url = await _service.uploadImageWithProgress(img, propertyId,
              (progress) {
            uploadProgress = progress;
            notifyListeners();
          });
          if (url != null) urls.add(url);
        }

        if (urls.isNotEmpty) {
          await _service.setPropertyImageUrls(propertyId, urls);
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

  Future<String?> uploadImage(
          dynamic file, String propertyId, void Function(double) onProgress) =>
      _service.uploadImageWithProgress(file, propertyId, onProgress);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rent_house/Models/booking.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer une nouvelle réservation
  Future<Map<String, dynamic>> createBooking(Booking booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(
            booking.toFirestore(),
          );

      return {
        'success': true,
        'message': 'Réservation créée',
        'bookingId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Récupérer une réservation
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Log error to a real logging service
      return null;
    }
  }

  /// Récupérer les réservations de l'utilisateur (invité)
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('guestId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Récupérer les réservations pour l'hôte
  Stream<List<Booking>> getHostBookings(String hostId) {
    return _firestore
        .collection('bookings')
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Récupérer les réservations pour une propriété
  Stream<List<Booking>> getPropertyBookings(String propertyId) {
    return _firestore
        .collection('bookings')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Vérifier la disponibilité
  Future<bool> isPropertyAvailable(
    String propertyId,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('propertyId', isEqualTo: propertyId)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();

      for (var doc in snapshot.docs) {
        final booking = Booking.fromFirestore(doc);
        
        // Vérifier les chevauchements
        if ((checkInDate.isBefore(booking.checkOutDate) &&
            checkOutDate.isAfter(booking.checkInDate))) {
          return false;
        }
      }
      return true;
    } catch (e) {
      // Log error to a real logging service
      return false;
    }
  }

  /// Mettre à jour une réservation
  Future<Map<String, dynamic>> updateBooking(
    String bookingId,
    Booking booking,
  ) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update(booking.copyWith(updatedAt: DateTime.now()).toFirestore());

      return {
        'success': true,
        'message': 'Réservation mise à jour',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Annuler une réservation
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      return {
        'success': true,
        'message': 'Réservation annulée',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Confirmer une réservation
  Future<Map<String, dynamic>> confirmBooking(String bookingId) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'confirmed',
        'updatedAt': Timestamp.now(),
      });

      return {
        'success': true,
        'message': 'Réservation confirmée',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Supprimer une réservation
  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();

      return {
        'success': true,
        'message': 'Réservation supprimée',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }
}

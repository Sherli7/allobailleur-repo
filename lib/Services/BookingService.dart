import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/booking.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Créer une nouvelle réservation
  Future<Map<String, dynamic>> createBooking(Booking booking) async {
    try {
      final response =
          await _supabase.from('bookings').insert(booking.toJson()).select();
      final bookingId = response[0]['id'];

      return {
        'success': true,
        'message': 'Réservation créée',
        'bookingId': bookingId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la création: $e',
      };
    }
  }

  /// Récupérer une réservation
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();
      return Booking.fromJson(response);
    } catch (e) {
      // Log error to a real logging service
      return null;
    }
  }

  /// Récupérer les réservations de l'utilisateur (invité)
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('guest_id', userId)
          .order('created_at', ascending: false);
      return response.map((data) => Booking.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupérer les réservations pour l'hôte
  Future<List<Booking>> getHostBookings(String hostId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('host_id', hostId)
          .order('created_at', ascending: false);
      return response.map((data) => Booking.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupérer les réservations pour une propriété
  Future<List<Booking>> getPropertyBookings(String propertyId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('property_id', propertyId);
      return response.map((data) => Booking.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Vérifier la disponibilité
  Future<bool> isPropertyAvailable(
    String propertyId,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('property_id', propertyId)
          .or('status.eq.confirmed,status.eq.pending');

      for (var data in response) {
        final booking = Booking.fromJson(data);

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
      await _supabase
          .from('bookings')
          .update(booking.copyWith(updatedAt: DateTime.now()).toJson())
          .eq('id', bookingId);

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
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

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
      await _supabase.from('bookings').update({
        'status': 'confirmed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

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
      await _supabase.from('bookings').delete().eq('id', bookingId);

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

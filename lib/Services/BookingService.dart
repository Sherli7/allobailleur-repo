import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/booking.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Commission de la plateforme (0% — paiements de location hors plateforme)
  static const double platformCommissionRate = 0.0;

  /// Calculer les frais de plateforme et le payout de l'hôte
  static Map<String, double> calculateFees(double totalPrice) {
    final platformFee = totalPrice * platformCommissionRate;
    final hostPayout = totalPrice - platformFee;
    return {
      'platformFee': platformFee,
      'hostPayout': hostPayout,
    };
  }

  /// Créer une nouvelle réservation
  Future<Map<String, dynamic>> createBooking(Booking booking) async {
    try {
      // Calculer les frais si non fournis
      final fees = calculateFees(booking.totalPrice);
      final updatedBooking = booking.copyWith(
        platformFee: booking.platformFee > 0
            ? booking.platformFee
            : fees['platformFee']!,
        hostPayout:
            booking.hostPayout > 0 ? booking.hostPayout : fees['hostPayout']!,
      );

      final response = await _supabase
          .from('bookings')
          .insert(updatedBooking.toJson())
          .select();
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
      return false;
    }
  }

  /// Mettre à jour le statut d'une réservation
  Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String status) async {
    try {
      await _supabase.from('bookings').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      return {
        'success': true,
        'message': 'Statut mis à jour',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e',
      };
    }
  }

  /// Mettre à jour une réservation (détails)
  Future<Map<String, dynamic>> updateBooking(
      String bookingId, Booking booking) async {
    try {
      await _supabase
          .from('bookings')
          .update(booking.toJson())
          .eq('id', bookingId);
      return {
        'success': true,
        'message': 'Réservation mise à jour',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      };
    }
  }

  /// Annuler une réservation
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    return await updateBookingStatus(bookingId, 'cancelled');
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

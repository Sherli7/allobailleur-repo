import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/booking.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Commission de la plateforme (10%)
  static const double platformCommissionRate = 0.10;

  /// Calculer les frais de plateforme et le payout de l'hôte
  static Map<String, double> calculateFees(double totalPrice) {
    final platformFee = totalPrice * platformCommissionRate;
    final hostPayout = totalPrice - platformFee;
    return {
      'platformFee': platformFee,
      'hostPayout': hostPayout,
    };
  }

  /// Simulation de processus de paiement
  Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required double amount,
    required String method, // 'card', 'momo', 'om'
  }) async {
    // TODO: Intégrer Stripe, OM, MOMO ici
    await Future.delayed(const Duration(seconds: 2)); // Simuler latence réseau

    // Simuler succès (90% du temps)
    // if (amount > 1000000) return {'success': false, 'message': 'Plafond dépassé'};

    return {
      'success': true,
      'transactionId': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      'message': 'Paiement de $amount FCFA effectué via $method',
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

  /// Récupérer toutes les dates réservées pour une propriété
  Future<List<DateTime>> getBookingDatesForProperty(String propertyId) async {
    try {
      final bookings = await getPropertyBookings(propertyId);
      final List<DateTime> bookedDates = [];

      for (final booking in bookings) {
        // On ne considère que les réservations confirmées ou en attente
        if (booking.status == 'confirmed' || booking.status == 'pending') {
          DateTime start = booking.checkInDate;
          // Si la date de fin est nulle (durée indéterminée), on bloque 
          // arbitrairement une longue période (ex: 2 ans) pour l'affichage
          DateTime end = booking.checkOutDate ?? 
              start.add(const Duration(days: 730)); 

          // Ajouter toutes les dates de l'intervalle [start, end]
          for (int i = 0; i <= end.difference(start).inDays; i++) {
            bookedDates.add(start.add(Duration(days: i)));
          }
        }
      }
      return bookedDates;
    } catch (e) {
      return [];
    }
  }

  /// Vérifier la disponibilité
  Future<bool> isPropertyAvailable(
    String propertyId,
    DateTime checkInDate,
    DateTime? checkOutDate,
  ) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('property_id', propertyId)
          .or('status.eq.confirmed,status.eq.pending');

      for (var data in response) {
        final booking = Booking.fromJson(data);

        // Cas 1: La réservation existante est à durée indéterminée
        // Elle commence avant ou pendant la nouvelle demande -> conflit
        if (booking.checkOutDate == null) {
            // Si la nouvelle réservation commence après le début de celle indéterminée
            if (checkInDate.isAfter(booking.checkInDate) || checkInDate.isAtSameMomentAs(booking.checkInDate)) {
                return false;
            }
            // Si la nouvelle réservation se termine après le début de celle indéterminée
             if (checkOutDate != null && (checkOutDate.isAfter(booking.checkInDate) || checkOutDate.isAtSameMomentAs(booking.checkInDate))) {
                return false;
            }
        }

        // Cas 2: La nouvelle demande est à durée indéterminée (checkOutDate == null)
        if (checkOutDate == null) {
             // Si la nouvelle demande commence avant la fin d'une réservation existante
             if (booking.checkOutDate != null && checkInDate.isBefore(booking.checkOutDate!)) {
                 return false;
             }
             // Si elle commence avant ou pendant une autre réservation indéterminée (déjà géré par Cas 1, mais bon)
              if (booking.checkOutDate == null && (checkInDate.isAfter(booking.checkInDate) || checkInDate.isAtSameMomentAs(booking.checkInDate))) {
                 return false;
             }
        }


        // Cas 3: Comparaison standard de deux intervalles finis
        if (checkOutDate != null && booking.checkOutDate != null) {
            // (StartA < EndB) and (EndA > StartB)
            if (checkInDate.isBefore(booking.checkOutDate!) &&
                checkOutDate.isAfter(booking.checkInDate)) {
              return false;
            }
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

  /// Annuler une réservation avec calcul de remboursement (Politique Flexible)
  /// Flexible : Remboursement intégral si annulé 48h avant Check-in
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final booking = await getBooking(bookingId);
      if (booking == null) return {'success': false, 'message': 'Réservation non trouvée'};

      final now = DateTime.now();
      final checkIn = booking.checkInDate;
      double refundAmount = 0.0;

      // Logique d'annulation
      if (booking.status == 'confirmed') {
        if (now.isBefore(checkIn.subtract(const Duration(hours: 48)))) {
          // Plus de 48h avant : Remboursement 100% (moins frais de service éventuels si on veut)
          refundAmount = booking.totalPrice;
        } else if (now.isBefore(checkIn)) {
          // Moins de 48h avant : Remboursement 50%
          refundAmount = booking.totalPrice * 0.5;
        } else {
          // Après le check-in : Pas de remboursement
          refundAmount = 0.0;
        }
      }

      // Mettre à jour statut
      await updateBookingStatus(bookingId, 'cancelled');

      // Ici on déclencherait le remboursement via l'API de paiement
      // await _refundPayment(booking.paymentIntentId, refundAmount);

      return {
        'success': true,
        'message': 'Réservation annulée.',
        'refundAmount': refundAmount,
      };
    } catch (e) {
      return {
         'success': false,
         'message': 'Erreur annulation: $e'
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

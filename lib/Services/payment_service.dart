import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const double contactFee = 5.0; // 5€ pour contacter l'hôte

  /// Créer un PaymentIntent avec commission
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amount, // En centimes
    required String bookingId,
    required String hostId,
    String currency = 'eur',
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call({
        'amount': amount,
        'currency': currency,
        'bookingId': bookingId,
        'hostId': hostId,
      });

      return result.data;
    } catch (e) {
      throw Exception('Erreur lors de la création du paiement: $e');
    }
  }

  /// Confirmer le paiement
  Future<Map<String, dynamic>> confirmPayment(String paymentIntentId) async {
    try {
      final callable = _functions.httpsCallable('confirmPayment');
      final result = await callable.call({
        'paymentIntentId': paymentIntentId,
      });

      return result.data;
    } catch (e) {
      throw Exception('Erreur lors de la confirmation du paiement: $e');
    }
  }

  /// Initier le paiement avec Stripe SDK
  Future<void> processPayment({
    required int amount,
    required String bookingId,
    required String hostId,
  }) async {
    final paymentData = await createPaymentIntent(
      amount: amount,
      bookingId: bookingId,
      hostId: hostId,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: paymentData['clientSecret'],
        merchantDisplayName: 'Allô Bailleur',
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // Confirmer après paiement réussi
    await confirmPayment(paymentData['paymentIntentId']);
  }

  /// Créer un abonnement Stripe
  Future<Map<String, dynamic>> createStripeSubscription({
    required String customerId,
    required String plan,
  }) async {
    try {
      final callable = _functions.httpsCallable('createSubscription');
      final result = await callable.call({
        'customerId': customerId,
        'plan': plan,
      });

      return result.data;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'abonnement: $e');
    }
  }

  /// Pay for contacting a host (single fixed fee)
  Future<void> payForContact(String conversationId) async {
    final int amount = (contactFee * 100).toInt();
    // Reuse processPayment flow. bookingId is used as a reference here.
    await processPayment(amount: amount, bookingId: conversationId, hostId: '');
  }
}

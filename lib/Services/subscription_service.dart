import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rent_house/Models/subscription.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const Map<String, double> subscriptionPrices = {
    'monthly': 9.99,
    'semesterly': 49.99, // ~8.33€/mois
  };

  /// Créer un abonnement
  Future<Map<String, dynamic>> createSubscription(
      Subscription subscription) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .insert(subscription.toJson())
          .select();
      return {
        'success': true,
        'subscriptionId': response[0]['id'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la création: $e',
      };
    }
  }

  /// Récupérer l'abonnement actif d'un utilisateur
  Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1);
      if (response.isNotEmpty) {
        return Subscription.fromJson(response[0]);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Annuler un abonnement
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _supabase
          .from('subscriptions')
          .update({'status': 'cancelled'}).eq('id', subscriptionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculer la date de fin selon le plan
  static DateTime calculateEndDate(String plan, DateTime startDate) {
    switch (plan) {
      case 'monthly':
        return startDate.add(const Duration(days: 30));
      case 'semesterly':
        return startDate.add(const Duration(days: 180));
      default:
        return startDate.add(const Duration(days: 30));
    }
  }
}

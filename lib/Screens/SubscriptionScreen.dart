import 'package:flutter/material.dart';
// removed unused import 'provider' (not used in this screen)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Services/payment_service.dart';
import 'package:rent_house/Services/subscription_service.dart';
import 'package:rent_house/Models/subscription.dart';

class SubscriptionScreen extends StatefulWidget {
  static const String routeName = '/subscription';

  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _subscribe(String plan) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Créer un customer Stripe (à implémenter côté serveur)
      // Pour l'instant, simuler
      const customerId = 'cus_example'; // Remplacer par vrai ID

      final paymentService = PaymentService();
      final subscriptionData = await paymentService.createStripeSubscription(
        customerId: customerId,
        plan: plan,
      );

      // Présenter le paiement
      await paymentService.processPayment(
        amount: (SubscriptionService.subscriptionPrices[plan]! * 100).toInt(),
        bookingId: '',
        hostId: '',
      );

      // Créer l'abonnement en DB
      final subscription = Subscription(
        id: '',
        userId: user.uid,
        plan: plan,
        price: SubscriptionService.subscriptionPrices[plan]!,
        currency: 'EUR',
        startDate: DateTime.now(),
        endDate: SubscriptionService.calculateEndDate(plan, DateTime.now()),
        status: 'active',
        stripeSubscriptionId: subscriptionData['subscriptionId'],
      );

      final subscriptionService = SubscriptionService();
      await subscriptionService.createSubscription(subscription);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement activé !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement Hôte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez votre abonnement pour publier des annonces',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              'Mensuel',
              '9,99€/mois',
              'Accès illimité aux publications',
              'monthly',
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              'Semestriel',
              '49,99€/6 mois',
              'Économisez 17€ par rapport au mensuel',
              'semesterly',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      String title, String price, String description, String plan) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(price,
                style: const TextStyle(fontSize: 24, color: Colors.green)),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _subscribe(plan),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Souscrire'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

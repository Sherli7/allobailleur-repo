import 'package:flutter/material.dart';
import 'package:rent_house/Models/property.dart';

/// Simplified placeholder for booking flow.
/// The real payment/booking implementation has external dependencies
/// (Stripe, payment pages). To keep the app analyzable, provide a
/// minimal stub UI that can be replaced later by the full flow.
class BookingPage extends StatelessWidget {
  final Property property;
  const BookingPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Réservation temporairement désactivée',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'La fonctionnalité de paiement a été désactivée pour l\'analyse statique.\n\nRevenez plus tard pour compléter la réservation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

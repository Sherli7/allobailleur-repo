import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/booking_provider.dart'; // Assume BookingProvider
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;

class TripsPage extends StatefulWidget {
  static const String routeName = '/tripsPageRoute';
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  @override
  void initState() {
    super.initState();
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    final uid = authProvider.firebaseUser?.uid ?? '';
    if (uid.isNotEmpty) {
      bookingProvider.loadUserBookings(uid); // Charge réservations user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Voyages'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, _) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = bookingProvider.userBookings;

          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight_land, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun voyage réservé',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Réservez votre prochaine location !'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.hotel, color: Colors.green),
                  title: Text('Annonce: ${booking.propertyId}'),
                  subtitle: Text(
                      '${booking.checkInDate.toLocal().toIso8601String().split("T").first} - ${booking.checkOutDate?.toLocal().toIso8601String().split("T").first ?? 'Indéterminé'} (${booking.nights} nuits)'),
                  trailing: Text(booking.totalPrice.toStringAsFixed(0)),
                  onTap: () {
                    // Navigue vers détails booking
                    // Navigator.pushNamed(context, BookingDetailsPage.routeName, arguments: booking);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

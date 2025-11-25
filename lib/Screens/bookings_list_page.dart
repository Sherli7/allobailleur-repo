import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:rent_house/Models/booking.dart';

class BookingsListPage extends StatefulWidget {
  static const String routeName = '/bookingsList';
  const BookingsListPage({super.key});

  @override
  State<BookingsListPage> createState() => _BookingsListPageState();
}

class _BookingsListPageState extends State<BookingsListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final bookingProvider =
            Provider.of<BookingProvider>(context, listen: false);
        await bookingProvider.loadUserBookings(uid);
        await bookingProvider.loadHostBookings(uid);
      }
      if (mounted) setState(() => _loading = false);
    });
  }

  Widget _buildBookingTile(Booking b) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text('Propriété: ${b.propertyId}'),
        subtitle: Text(
            '${b.checkInDate.toLocal().toString().split(' ')[0]} → ${b.checkOutDate.toLocal().toString().split(' ')[0]}\nStatus: ${b.status}'),
        isThreeLine: true,
        trailing: Text('${b.totalPrice.toStringAsFixed(0)} €'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes réservations'),
            Tab(text: 'Réservations reçues')
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<BookingProvider>(builder: (context, provider, child) {
              return TabBarView(
                controller: _tabController,
                children: [
                  // Guest bookings
                  provider.userBookings.isEmpty
                      ? const Center(child: Text('Aucune réservation'))
                      : ListView.builder(
                          itemCount: provider.userBookings.length,
                          itemBuilder: (context, i) =>
                              _buildBookingTile(provider.userBookings[i]),
                        ),
                  // Host bookings
                  provider.hostBookings.isEmpty
                      ? const Center(child: Text('Aucune réservation reçue'))
                      : ListView.builder(
                          itemCount: provider.hostBookings.length,
                          itemBuilder: (context, i) =>
                              _buildBookingTile(provider.hostBookings[i]),
                        ),
                ],
              );
            }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rent_house/Models/property.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookPostingPage extends StatefulWidget {
  static const String routeName = '/bookPostingPageRoute';
  final Property property;

  const BookPostingPage({super.key, required this.property});

  @override
  State<BookPostingPage> createState() => _MyBookPostingPageState();
}

class _MyBookPostingPageState extends State<BookPostingPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isBooking = false;

  Future<void> _selectDates() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _checkInDate != null && _checkOutDate != null
          ? DateTimeRange(start: _checkInDate!, end: _checkOutDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end;
      });
    }
  }

  Future<void> _bookProperty() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner les dates')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final days = _checkOutDate!.difference(_checkInDate!).inDays;
      final totalPrice = days * widget.property.price;

      await Supabase.instance.client.from('bookings').insert({
        'guest_id': user.id,
        'property_id': widget.property.id,
        'host_id': widget.property.ownerId,
        'check_in_date': _checkInDate!.toIso8601String(),
        'check_out_date': _checkOutDate!.toIso8601String(),
        'total_price': totalPrice,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation créée avec succès')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Réserver ${widget.property.title}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prix: ${widget.property.price} ${widget.property.currency}/nuit',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Sélectionnez vos dates:'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selectDates,
              child: Text(
                _checkInDate == null || _checkOutDate == null
                    ? 'Choisir les dates'
                    : '${_checkInDate!.toLocal().toString().split(' ')[0]} - ${_checkOutDate!.toLocal().toString().split(' ')[0]}',
              ),
            ),
            if (_checkInDate != null && _checkOutDate != null) ...[
              const SizedBox(height: 20),
              Text(
                'Nombre de nuits: ${_checkOutDate!.difference(_checkInDate!).inDays}',
              ),
              Text(
                'Prix total: ${_checkOutDate!.difference(_checkInDate!).inDays * widget.property.price} ${widget.property.currency}',
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _bookProperty,
                child: _isBooking
                    ? const CircularProgressIndicator()
                    : const Text('Réserver maintenant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Models/booking.dart';
import 'package:rent_house/Services/BookingService.dart';
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingPage extends StatefulWidget {
  static const String routeName = '/booking';
  final Property property;

  const BookingPage({super.key, required this.property});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final BookingService _bookingService = BookingService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<DateTime> _bookedDates = [];
  bool _isLoading = true;
  bool _isIndefinite = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
  }

  Future<void> _loadBookedDates() async {
    final dates =
        await _bookingService.getBookingDatesForProperty(widget.property.id);
    if (mounted) {
      setState(() {
        _bookedDates = dates;
        _isLoading = false;
      });
    }
  }

  bool _isDayBooked(DateTime day) {
    // Normaliser la date pour ignorer l'heure
    final normalizedDay = DateTime(day.year, day.month, day.day);
    for (var date in _bookedDates) {
      final normalizedBooked = DateTime(date.year, date.month, date.day);
      if (normalizedBooked.isAtSameMomentAs(normalizedDay)) {
        return true;
      }
    }
    return false;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_isDayBooked(selectedDay)) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _isIndefinite = false;
    });
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _isIndefinite = false;
    });
  }

  double _calculateTotalPrice() {
    if (_isIndefinite && _rangeStart != null) {
      // Pour une durée indéterminée, on peut afficher le prix mensuel par exemple
      // ou ne pas afficher de total fixe. Ici, prenons 1 mois comme base indicative.
      return widget.property.price.toDouble();
    }

    if (_rangeStart != null && _rangeEnd != null) {
      final duration = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      // Ici, on simplifie en considérant le prix comme "par mois"
      // et on calcule au prorata des jours.
      // Prix journalier approximatif :
      final dailyPrice = widget.property.price / 30.0;
      return dailyPrice * duration;
    }
    return 0.0;
  }

  Future<void> _confirmBooking() async {
    if (_rangeStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de début')),
      );
      return;
    }

    if (!_isIndefinite && _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de fin')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final user = authProvider.firebaseUser;

      if (user == null) {
        Navigator.of(context).pushNamed('/login');
        return;
      }

      // Vérifier à nouveau la disponibilité côté serveur pour être sûr
      final isAvailable = await _bookingService.isPropertyAvailable(
        widget.property.id,
        _rangeStart!,
        _isIndefinite ? null : _rangeEnd!,
      );

      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Ces dates ne sont plus disponibles. Veuillez en choisir d\'autres.')),
          );
        }
        return;
      }

      final totalPrice = _calculateTotalPrice();

      final booking = Booking(
        id: '', // Sera généré par Supabase
        guestId: user.uid,
        propertyId: widget.property.id,
        hostId: widget.property.ownerId,
        checkInDate: _rangeStart!,
        checkOutDate: _isIndefinite ? null : _rangeEnd!,
        totalPrice: totalPrice,
        platformFee: 0.0,
        hostPayout: totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final success = await bookingProvider.createBooking(booking);

      if (success) {
        // Optionnel : Mettre à jour l'état local de la propriété si nécessaire
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande de réservation envoyée !')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erreur lors de la réservation: ${bookingProvider.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.property.currency.isNotEmpty
        ? widget.property.currency
        : 'XAF';

    return Scaffold(
      appBar: AppBar(title: const Text('Réserver')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 730)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  rangeStartDay: _rangeStart,
                  rangeEndDay: _rangeEnd,
                  rangeSelectionMode: RangeSelectionMode.toggledOn,
                  enabledDayPredicate: (day) => !_isDayBooked(day),
                  onDaySelected: _onDaySelected,
                  onRangeSelected: _onRangeSelected,
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    disabledDecoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    rangeHighlightColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    rangeStartDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _isIndefinite,
                              onChanged: (value) {
                                setState(() {
                                  _isIndefinite = value ?? false;
                                  if (_isIndefinite) {
                                    _rangeEnd = null; // Reset end date
                                  }
                                });
                              },
                            ),
                            const Text('Durée indéterminée'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_rangeStart != null) ...[
                          Text(
                            'Début : ${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          if (!_isIndefinite && _rangeEnd != null)
                            Text(
                              'Fin : ${_rangeEnd!.day}/${_rangeEnd!.month}/${_rangeEnd!.year}',
                              style: const TextStyle(fontSize: 16),
                            )
                          else if (_isIndefinite)
                            const Text(
                              'Fin : Indéterminée',
                              style: TextStyle(fontSize: 16),
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total estimé :',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    '${_calculateTotalPrice().toStringAsFixed(0)} $currency',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_isIndefinite)
                                    const Text(
                                      '(Prix mensuel)',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed:
                                    _isSubmitting ? null : _confirmBooking,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Text('Confirmer'),
                              ),
                            ],
                          ),
                        ] else
                          const Center(
                            child: Text(
                              'Sélectionnez vos dates sur le calendrier',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

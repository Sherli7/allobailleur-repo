import 'package:flutter/material.dart';
import 'package:rent_house/Models/property.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingPage extends StatefulWidget {
  // Renamed from BookingsPage
  static const String routeName = '/booking';
  final Property property;

  const BookingPage({super.key, required this.property}); // Renamed

  @override
  State<BookingPage> createState() => _BookingPageState(); // Renamed
}

class _BookingPageState extends State<BookingPage> {
  // Renamed
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isIndefinite = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    // Placeholder for fetching bookings
  }

  bool _isDayBooked(DateTime day) {
    return false; // Placeholder
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
    });
  }

  double _calculateTotalPrice() {
    double price = widget.property.price;
    if (_isIndefinite) {
      double deposit = widget.property.deposit ?? 0.0;
      return price + deposit;
    }

    if (_rangeStart != null && _rangeEnd != null) {
      int days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      if (days < 30) {
        return (price / 30) * days;
      } else {
        return price * (days / 30);
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              enabledDayPredicate: (day) => !_isDayBooked(day),
            ),
          ),
          SliverToBoxAdapter(
            child: const Divider(),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                          value: _isIndefinite,
                          onChanged: (val) {
                            setState(() {
                              _isIndefinite = val ?? false;
                              if (_isIndefinite) {
                                _rangeStart = DateTime.now();
                                _rangeEnd = null;
                              } else {
                                _rangeStart = null;
                              }
                            });
                          }),
                      const Text('Location longue durée (Indéterminée)'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_rangeStart != null || _isIndefinite) ...[
                    Text(
                      _isIndefinite
                          ? 'Début du bail: ${_rangeStart.toString().split(' ')[0]}'
                          : 'Du: ${_rangeStart.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (!_isIndefinite && _rangeEnd != null)
                      Text(
                        'Au: ${_rangeEnd.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total estimé :',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${_calculateTotalPrice().toStringAsFixed(0)} XAF',
                              style: const TextStyle(
                                  fontSize: 20, color: Colors.blue),
                            ),
                            if (_isIndefinite)
                              const Text('(1er mois + Caution)',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Demande de réservation envoyée !')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Réserver'),
                        ),
                      ],
                    ),
                  ] else
                    const Center(
                      child: Text(
                        'Sélectionnez une période ou cochez "Longue durée"',
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

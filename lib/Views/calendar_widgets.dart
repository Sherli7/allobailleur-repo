import 'package:flutter/material.dart';

class CalendarMonthWidget extends StatelessWidget {
  final int montIndex;

  const CalendarMonthWidget({super.key, required this.montIndex});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final month = montIndex + 1; // Assuming montIndex 0 is January
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    final List<String> dayNames = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    return Column(
      children: [
        // Month title
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${_getMonthName(month)} $year',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: dayNames
              .map((day) => Expanded(
                    child: Center(
                        child: Text(day,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                  ))
              .toList(),
        ),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayNumber =
                  index - startingWeekday + 2; // Adjust for 1-based and weekday
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              return Center(
                child: Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    color: dayNumber == now.day && month == now.month
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

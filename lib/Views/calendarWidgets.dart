import 'package:flutter/material.dart';

import '../Models/AppConstants.dart';

class CalendarMonthWidget extends StatefulWidget{
  final int montIndex;
  const CalendarMonthWidget({super.key,required this.montIndex});

  @override
  State<CalendarMonthWidget> createState() => _CalendarMonthState();

}

class _CalendarMonthState extends State<CalendarMonthWidget> {
  List<MonthTile> _monthtile = [];
  late int _currentMonthInt;
  late int _currentYearInt;

  @override
  void initState() {
    super.initState();
    _currentMonthInt = ((DateTime.now().month + widget.montIndex - 1) % 12) + 1;
    _currentYearInt = DateTime.now().year;
    if (_currentMonthInt < DateTime.now().month) {
      _currentYearInt++;
    }
    _setUpMonthTile();
  }

  void _setUpMonthTile() {
    int daysInMonth = AppConstants.daysInMonths[_currentMonthInt]!;
    DateTime firstDayOfMonth = DateTime(_currentYearInt, _currentMonthInt, 1);
    int firstWeekDayOfMonth = firstDayOfMonth.weekday;

    _monthtile.clear();
    if (firstDayOfMonth.weekday != 7) {
      for (int i = 0; i < firstWeekDayOfMonth; i++) {
        _monthtile.add(MonthTile(date: null));
      }
    }
    for (int i = 1; i <= daysInMonth; i++) {
      _monthtile.add(MonthTile(date: DateTime(_currentYearInt, _currentMonthInt, i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Text("${AppConstants.monthDict[_currentMonthInt]!} - $_currentYearInt"),
        ),
        GridView.builder(
          itemCount: _monthtile.length,
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1 / 1,
          ),
          itemBuilder: (context, index) {
            MonthTile monthTile = _monthtile[index];
            return MaterialButton(
              onPressed: () {},
              child: monthTile,
            );
          },
        ),
      ],
    );
  }
}

class MonthTile extends StatelessWidget {
  final DateTime? date; // Made nullable

  MonthTile({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Text(date == null ? "" : date!.day.toString());
  }
}

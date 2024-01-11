import 'package:flutter/material.dart';
import 'package:rent_house/Models/AppConstants.dart';

class CalendarMonthWidget extends StatefulWidget{
  final int montIndex;
  const CalendarMonthWidget({super.key,required this.montIndex});

  @override
  State<CalendarMonthWidget> createState() => _CalendarMonthState();

}

class _CalendarMonthState extends State<CalendarMonthWidget> {
  late List<MonthTile> _monthtile;

  @override
  void initState() {
    _monthtile = [];
    super.initState();
    // Assuming each month has 30 days for simplicity. Update this logic based on actual month length.
    for (int i = 0; i < 31; i++) {
      _monthtile.add(MonthTile(date: DateTime.now()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('August'), // Replace with actual month name
        GridView.builder(
          itemCount: 31, // Updated to match the length of _monthtile
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1 / 1,
          ),
          itemBuilder: (context, index) {
            return _monthtile[index]; // Directly return the MonthTile
          },
        ),
      ],
    );
  }
}



class MonthTile extends StatelessWidget {

  final DateTime date;

  MonthTile({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Text(this.date == null ? "" : date.day.toString());
  }


}
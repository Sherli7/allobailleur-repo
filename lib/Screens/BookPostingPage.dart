import 'package:flutter/material.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Views/TextWidgets.dart';
import 'package:rent_house/Views/calendarWidgets.dart';

class BookPostingPage extends StatefulWidget {
  static const String routeName = '/bookPostingPageRoute';

  const BookPostingPage({super.key});


  @override
  State<BookPostingPage> createState() => _MyBookPostingPageState();
}

class _MyBookPostingPageState extends State<BookPostingPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Book a Posting'),
      ),
      body:Padding(
        padding: const EdgeInsets.fromLTRB(25, 25,25, 0),
        child: Column(

          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget> [
                Text('Sun'),
                Text('Mon'),
                Text('Tues'),
                Text('Wed'),
                Text('Thu'),
                Text('Fri'),
                Text('Sat'),
              ],
            ),
            Container(
              height: MediaQuery.of(context).size.height/1.8,
              child: PageView.builder(
                itemCount: 12,
                itemBuilder: (context,index){
                  return CalendarMonthWidget(montIndex: index,);
                },
              ),
            ),
            MaterialButton(
                onPressed: (){

                },
              child: Text('Book Now!'),
              minWidth: double.infinity,
              height: MediaQuery.of(context).size.height/14,
              color: Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }
}

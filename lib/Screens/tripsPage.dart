import 'package:flutter/material.dart';

class TripsPage extends StatefulWidget {

  const TripsPage({super.key});


  @override
  State<TripsPage> createState() => _MyTripsPageEState();
}

class _MyTripsPageEState extends State<TripsPage> {
  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.fromLTRB(25,25,0,0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget> [
            Padding(
              padding: const EdgeInsets.only(top:25.0),
              child: const Text('Upcoming Trips',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                ),),
            ),
           Padding(
             padding: const EdgeInsets.only(top:15,bottom: 25.0),
             child: Container(
                height: MediaQuery.of(context).size.height/3,
              ),
           ),
            Text('Previous Trips',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold
              ),),
            Padding(
              padding: const EdgeInsets.only(top:15,bottom: 25.0),
              child: Container(
                height: MediaQuery.of(context).size.height/3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

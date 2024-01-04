import 'package:flutter/material.dart';
import 'package:rent_house/Views/gridWidets.dart';

class TripsPage extends StatefulWidget {
  TripsPage({Key? key}) : super(key: key); // Updated for null safety

  @override
  _TripsPageState createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: EdgeInsets.fromLTRB(25,25,0,0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget> [
            Text('Upcoming Trips',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),),
            Padding(
              padding: const EdgeInsets.only(top:15,bottom: 25.0),
              child: Container(
                height: MediaQuery.of(context).size.height/3,
                child: ListView.builder(
                  itemBuilder: (context,index){
                    return Padding(
                      padding: const EdgeInsets.only(right:25.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width/2.5,
                        child: TripGridTile(),
                      ),
                    );
                  },
                  itemCount: 3,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,),
              ),
            ),
            Text('Previous Trips',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),),
            Padding(
              padding: const EdgeInsets.only(top:15,bottom: 25.0),
              child: Container(
                height: MediaQuery.of(context).size.height/3,
                child: ListView.builder(
                  itemBuilder: (context,index){
                    return Padding(
                      padding: const EdgeInsets.only(right:25.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width/2.5,
                        child: TripGridTile(),
                      ),
                    );
                  },
                  itemCount: 2,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

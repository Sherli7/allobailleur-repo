import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_house/Models/AppConstants.dart';

class PositingGridTile extends StatefulWidget {
  const PositingGridTile({super.key});

  @override
  MyPositingGridTileState createState() => MyPositingGridTileState();
}

class MyPositingGridTileState extends State<PositingGridTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
           AspectRatio(
            aspectRatio: 3/2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/house.jpeg'),
                  fit: BoxFit.fill
                )
              ),
            ),
          ),
          const AutoSizeText('Apartement - Yaounde,YDE',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const AutoSizeText('Awesome Apartment',
            style: TextStyle(
            fontSize: 12.0,
            color: Colors.black,
          ),),
          //SizedBox(height: 1), // Espaceur
          const Text('850000 FCFA / month'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget> [
            RatingBar.builder(
                    initialRating: 4.5,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 20.0,
                    itemBuilder: (context, _) =>  Icon(
                      Icons.star,
                      color: AppConstants.toColor('fb5607'),
                    ),
                    onRatingUpdate: (rating) {
                      print(rating);
                    },
                  ),
          ],
        ),
        ],
    );
  }
}

class TripGridTile extends StatefulWidget {
  const TripGridTile({super.key});

  @override
  MyTripGridTileState createState() => MyTripGridTileState();
}

class MyTripGridTileState extends State<TripGridTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 3/2,
          child: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/images/house.jpeg'),
                    fit: BoxFit.fill
                )
            ),
          ),
        ),
        const AutoSizeText('Yaounde,YDE',
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const AutoSizeText('Awesome Apartment',
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.black,
          ),),
        //SizedBox(height: 1), // Espaceur
        const Text(
            '850000 FCFA / month',
        ),
        const Text(
          'January 10, 2024 -',
          style: TextStyle(
              fontWeight: FontWeight.bold
          ),
        ),
        const Text(
          'January 12, 2024',
          style: TextStyle(
              fontWeight: FontWeight.bold
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget> [
            RatingBar.builder(
              initialRating: 4.5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 20.0,
              itemBuilder: (context, _) =>  Icon(
                Icons.star,
                color: AppConstants.toColor('fb5607'),
              ),
              onRatingUpdate: (rating) {
                print(rating);
              },
            ),
          ],
        ),
      ],
    );
  }
}

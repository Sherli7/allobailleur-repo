import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_house/Models/AppConstants.dart';

class PositingGridTile extends StatefulWidget {
  PositingGridTile({super.key});

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
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/house.jpeg'),
                  fit: BoxFit.fill
                )
              ),
            ),
          ),
          AutoSizeText('Apartement - Yaounde,YDE',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          AutoSizeText('Awesome Apartment',
            style: TextStyle(
            fontSize: 12.0,
            color: Colors.black,
          ),),
          //SizedBox(height: 1), // Espaceur
          Text('85000 FCFA / month'),
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

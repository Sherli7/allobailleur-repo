import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewListTitle extends StatefulWidget {
  const ReviewListTitle({required Key key}) : super(key: key);

  @override
  ReviewListTitleState createState() => ReviewListTitleState();
}

class ReviewListTitleState extends State<ReviewListTitle> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(
              backgroundImage: const AssetImage('assets/images/sherli7.jpg'),
              radius: MediaQuery.of(context).size.width /15,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 15.0, right: 15.0),
              child: AutoSizeText(
                  'Sherli7',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0
                ),
              ),
            ),
            RatingBar.builder(
              initialRating: 4.5, // Example rating value
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 30.0, // Size of each star
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                print(rating);
              },
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top:5.0, bottom: 15.0),
          child: AutoSizeText(
            'Great guy, really enjoyed his time at this place, would definitely recommend him to other people.',
            style: TextStyle(
                fontSize: 18.0
            ),
          ),
        ),
      ],
    );
  }
}

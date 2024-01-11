import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';

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
                color: Colors.deepOrange,
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

class ConversationListTilePage extends StatefulWidget{

  ConversationListTilePage({super.key});


  @override
  State<ConversationListTilePage> createState() => ConversationListTileState();


}

class ConversationListTileState extends State<ConversationListTilePage>{

  @override
  Widget build(BuildContext context) {
   return ListTile(
     leading: GestureDetector(
       onTap: (){
         Navigator.pushNamed(context, ViewProfilePage.routeName);
       },
       child: CircleAvatar(
         backgroundImage: AssetImage('assets/images/defaultAvatar.jpg'),
         radius: MediaQuery.of(context).size.width/13.0,
       ),
     ),
     title: Text(
       'Lionel',
       style: TextStyle(
         fontSize: 22.5,
         fontWeight: FontWeight.bold
       ),
     ),
     subtitle: Text(
       'Hey, How\'s it going?',
       style:TextStyle(
           fontSize: 20.0,
       ),
     ),
     trailing: Text(
       '30 Août',
       style:TextStyle(
         fontSize: 20.0,
       ),
     ),
     contentPadding: EdgeInsets.fromLTRB(25.0,15.0,25.0,15.0),
   );
  }

}
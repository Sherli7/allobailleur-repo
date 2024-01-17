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
         radius: MediaQuery.of(context).size.width/14.0,
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


class MessageListTile extends StatelessWidget{
  MessageListTile({super.key});
  @override
  Widget build(BuildContext context) {
/*   return Padding(
      padding: const EdgeInsets.fromLTRB(15,15,35,15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          GestureDetector(
            onTap: (){
              Navigator.pushNamed(context,
                ViewProfilePage.routeName
              );
            },
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/defaultAvatar.jpg'),
              radius: MediaQuery.of(context).size.width/20,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                          'This is really long message that is supposed to test the proper message functionality and make sure thant everything is working and wrapping properly.',
                          style: TextStyle(
                            fontSize: 15.0,
                          ),
                          textWidthBasis: TextWidthBasis.parent,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text('10 janvier')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );*/

    return Padding(
      padding: const EdgeInsets.fromLTRB(35,15,15,15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        'This is really long message that is supposed to test the proper message functionality and make sure thant everything is working and wrapping properly.',
                        style: TextStyle(
                          fontSize: 15.0,
                        ),
                        textWidthBasis: TextWidthBasis.parent,
                      ),
                    ),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: Text('10 janvier')),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: (){
              Navigator.pushNamed(context,
                  ViewProfilePage.routeName
              );
            },
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/defaultAvatar.jpg'),
              radius: MediaQuery.of(context).size.width/20,
            ),
          ),
        ],
      ),
    );
  }
  
}
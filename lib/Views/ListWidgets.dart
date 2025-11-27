import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/view_profile_page.dart';

class ReviewListTitle extends StatefulWidget {
  const ReviewListTitle({super.key});

  @override
  State<ReviewListTitle> createState() => ReviewListTitleState();
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
              radius: MediaQuery.of(context).size.width / 15,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 15.0, right: 15.0),
              child: AutoSizeText(
                'Sherli7',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
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
                // Print statement removed
              },
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 5.0, bottom: 15.0),
          child: AutoSizeText(
            'Great guy, really enjoyed his time at this place, would definitely recommend him to other people.',
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      ],
    );
  }
}

class ConversationListTilePage extends StatefulWidget {
  const ConversationListTilePage({super.key});

  @override
  State<ConversationListTilePage> createState() => ConversationListTileState();
}

class ConversationListTileState extends State<ConversationListTilePage> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, ViewProfilePage.routeName);
        },
        child: CircleAvatar(
          radius: MediaQuery.of(context).size.width / 14.0,
          child: const Icon(Icons.person),
        ),
      ),
      title: const Text(
        'Lionel',
        style: TextStyle(fontSize: 22.5, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text(
        'Hey, How\'s it going?',
        style: TextStyle(
          fontSize: 20.0,
        ),
      ),
      trailing: const Text(
        '30 Août',
        style: TextStyle(
          fontSize: 20.0,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(25.0, 15.0, 25.0, 15.0),
    );
  }
}

class MessageListTile extends StatelessWidget {
  const MessageListTile({super.key});
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
      padding: const EdgeInsets.fromLTRB(35, 15, 15, 15),
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
                child: const Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.0),
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
            onTap: () {
              Navigator.pushNamed(context, ViewProfilePage.routeName);
            },
            child: CircleAvatar(
              backgroundImage:
                  const AssetImage('assets/images/defaultAvatar.jpg'),
              radius: MediaQuery.of(context).size.width / 20,
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyListingTile extends StatelessWidget {
  final Property property;

  const PropertyListingTile({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias, // To clip the image corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 180,
            width: double.infinity,
            child: (property.imageUrls.isNotEmpty
                ? Image.network(
                    property.imageUrls[0],
                    fit: BoxFit.cover,
                    // Loading and error handling for network image
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/house.jpeg',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/house.jpeg', // Placeholder if no photo
                    fit: BoxFit.cover,
                  )),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  property.city,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${property.price} FCFA / mois',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

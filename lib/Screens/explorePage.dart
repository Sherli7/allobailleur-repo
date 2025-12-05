import 'package:flutter/material.dart';
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Views/gridWidets.dart';
import 'package:rent_house/Screens/nearbyMapPage.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  MyExplorePageState createState() => MyExplorePageState();
}

class MyExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
          child: TextField(
            readOnly: true,
            onTap: () {
              Navigator.pushNamed(context, SearchPage.routeName);
            },
            decoration: InputDecoration(
              hintText: 'Rechercher',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map_outlined),
                onPressed: () {
                  Navigator.pushNamed(context, NearbyMapPage.routeName);
                },
                tooltip: 'Voir la carte',
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 2.0),
              ),
              contentPadding: const EdgeInsets.all(5.0),
            ),
            style: const TextStyle(fontSize: 20.0, color: Colors.black),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                return InkResponse(
                  enableFeedback: true,
                  child: const PostingGridTile(),
                  onTap: () => Navigator.pushNamed(context, ViewPostingPage.routeName),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

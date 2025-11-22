import 'package:flutter/material.dart';
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Views/gridWidets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  MyExplorePageState createState() => MyExplorePageState();
}

class MyExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return Column(  // Column borné comme body principal (standard pour Scaffold)
      children: [
        // Header avec padding spécifique
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),  // Padding localisé
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 2.0),
              ),
              contentPadding: EdgeInsets.all(5.0),
            ),
            style: TextStyle(fontSize: 20.0, color: Colors.black),
          ),
        ),
        // Contenu principal : Expanded pour hauteur finie
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),  // Padding latéral seulement
            child: GridView.builder(
              // Pas de shrinkWrap (défaut false) pour perf ; Expanded gère la hauteur
              physics: const NeverScrollableScrollPhysics(),  // Pas de scroll si dans Tab/parent scrollable
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
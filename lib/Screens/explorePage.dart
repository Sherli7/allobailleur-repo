import 'package:flutter/material.dart';
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Views/gridWidets.dart'; // Ensure this path is correct

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  MyExplorePageState createState() => MyExplorePageState();
}

class MyExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 10, bottom: 50.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 2.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(5.0),
                ),
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
              ),
            ),
            GridView.builder(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                return InkResponse(
                  enableFeedback: true,
                  child: PositingGridTile(),
                  onTap: () {
                    // Replace 'routeName' with your actual route name
                    Navigator.pushNamed(
                        context,
                        ViewPostingPage.routeName,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {

  const ExplorePage({super.key});

  @override
  MyExplorePageState createState()=>MyExplorePageState();
}

class MyExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: Column(
        children:<Widget>[
          TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderSide:BorderSide(
                  color:Colors.grey,
                  width: 2.0
                ),
              ),
              contentPadding: EdgeInsets.all(5.0),
            ),
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
          ),
          //GridView.builder(gridDelegate: null, itemBuilder: null)
        ],
      ),
    );
  }
}

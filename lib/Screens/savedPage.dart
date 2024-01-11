import 'package:flutter/material.dart';
import 'package:rent_house/Screens/viewPostingPage.dart';

import '../Views/gridWidets.dart';

class SavedPage extends StatefulWidget {

  const SavedPage({super.key});


  @override
  State<SavedPage> createState() => _MySavedPageState();
}

class _MySavedPageState extends State<SavedPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(25,50,25,0),
      child: GridView.builder(
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        itemCount: 2,
        gridDelegate:  const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 3/4
        ),
        itemBuilder: (context,index){
          return Stack(
            children: [
            InkResponse(
            enableFeedback: true,
            child: const PositingGridTile(),
            onTap: () {
              // Replace 'routeName' with your actual route name
              Navigator.pushNamed(
                context,
                ViewPostingPage.routeName,
              );
            },
          ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Container(
                    width: 30.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(0.0),
                        onPressed: (){},
                        icon: const Icon(Icons.clear,color: Colors.black,)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

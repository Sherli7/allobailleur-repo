import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Views/ListWidgets.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class ViewProfilePage extends StatefulWidget {
  static const String routeName = '/viewProfilePageRoute';

  const ViewProfilePage({super.key});


  @override
  State<ViewProfilePage> createState() => _MyViewProfilePageState();
}

class _MyViewProfilePageState extends State<ViewProfilePage> {

  void _signup(){
    Navigator.pushNamed(context, GuestHomePage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'View Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(35,50,35,35),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:<Widget> [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                   Container(
                      width: MediaQuery.of(context).size.width * 3/5,
                      child: const AutoSizeText(
                        'Hi my name is Sherli7',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: MediaQuery.of(context).size.width / 9.5,
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 10,
                        backgroundImage: const AssetImage('assets/images/sherli7.jpg'),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Text(
                    'About me: ',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: AutoSizeText(
                    'I am a guy who likes travelling and having fun while I see cool stuff around the world.',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 20.0, 10, 0),
                  child: Row(
                    children:<Widget> [
                      Icon(Icons.home),
                      Padding(
                        padding: EdgeInsets.only(left: 20.0),
                        child: AutoSizeText(
                          'Lives in Yaounde,Cameroon',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child:ListView.builder(
                    itemCount: 2,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(top:10.0, bottom: 10.0),
                        child: ReviewListTitle(key: UniqueKey()),
                      ); // Adjust this according to how ReviewListTitle is defined
                    },
                  ),
                ),
                ],
            ),
          ),
        ),
      ),
    );
  }
}

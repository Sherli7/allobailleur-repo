import 'package:flutter/material.dart';
import 'package:rent_house/Models/AppConstants.dart';
import 'package:rent_house/Screens/accountPage.dart';
import 'package:rent_house/Screens/explorePage.dart';
import 'package:rent_house/Screens/inboxPage.dart';
import 'package:rent_house/Screens/savedPage.dart';
import 'package:rent_house/Screens/tripsPage.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class GuestHomePage extends StatefulWidget {
  static const String routeName = 'loginPageRoute';

  const GuestHomePage({Key? key}) : super(key: key); // Changed to optional key

  @override
  GuestHomePageState createState() => GuestHomePageState();
}

class GuestHomePageState extends State<GuestHomePage> {
  int _selectedIndex=4;
  final List<String> pageTitle=[
    'Explore',
    'Saved',
    'Trips',
    'Inbox',
    'Profile'
  ];

  final List<Widget> _page=[
    const ExplorePage(),
    const SavedPage(),
    const TripsPage(),
    const InboxPage(),
    const AccountPage()
  ];
  BottomNavigationBarItem _buildNavigationItem(int index, IconData iconData, String text){
    return BottomNavigationBarItem(
      icon: Icon(iconData, color: AppConstants.nonselectedIconColor),
      activeIcon: Icon(iconData, color: AppConstants.selectedIconColor),
      label: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: pageTitle[_selectedIndex]),
      ),
      body: _page[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index){
          setState(() {
            _selectedIndex=index;
          });
        },
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          _buildNavigationItem(0, Icons.search, pageTitle[0]),
          _buildNavigationItem(1, Icons.favorite_border, pageTitle[1]),
          _buildNavigationItem(1, Icons.hotel, pageTitle[2]),
          _buildNavigationItem(1, Icons.message, pageTitle[3]),
          _buildNavigationItem(1, Icons.person_outline, pageTitle[4]),
        ],
      ),
    );
  }
}

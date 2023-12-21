import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';

class AccountPage extends StatefulWidget {
  //static const String routeName = '/profilePageRoute';
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<AccountPage> {
  void _logout(){
    Navigator.pushNamed(context, LoginPage.routeName);
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 50, 15, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                MaterialButton(
                  onPressed: () {
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: MediaQuery.of(context).size.width / 9.5,
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width / 10,
                      backgroundImage: const AssetImage('assets/images/sherli7.jpg'),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AutoSizeText(
                        'Sherli7',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      AutoSizeText(
                        'lelionlionel117@gmail.com',
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                MaterialButton(
                  height:MediaQuery.of(context).size.height / 9.0,
                  onPressed: () {
                    Navigator.pushNamed(context, PersonalInfoPage.routeName);
                  },
                  child: const AccountPageListViewItem(
                    text: 'Personal Information',
                    iconData: Icons.person,
                  ),
                ),
                MaterialButton(
                  height:MediaQuery.of(context).size.height / 9.0,
                  onPressed: () {
                    // Your onPressed logic here
                  },
                  child: const AccountPageListViewItem(
                    text: 'Become a Host',
                    iconData: Icons.hotel,
                  ),
                ),
                MaterialButton(
                  height:MediaQuery.of(context).size.height / 9.0,
                  onPressed: _logout,
                  child: const AccountPageListViewItem(
                    text: 'Log out',
                    iconData: null,
                  ),
                ),
                // Add more items here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountPageListViewItem extends StatelessWidget {
  final String text;
  final IconData? iconData;  // Make IconData nullable

  const AccountPageListViewItem({Key? key, required this.text, this.iconData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0.0),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.normal
        ),
      ),
      trailing: iconData != null ? Icon(  // Handle null case for iconData
        iconData,
        size: 35.0,
      ) : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class PersonalInfoPage extends StatefulWidget {
  static const String routeName = '/personalInfoPageRoute';

  const PersonalInfoPage({super.key});


  @override
  State<PersonalInfoPage> createState() => _MyPersonalInfoPageState();
}

class _MyPersonalInfoPageState extends State<PersonalInfoPage> {

  void _saveInfo(){
    Navigator.pushNamed(context, GuestHomePage.routeName);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Personal Information'),
        actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.save,color: Colors.white,),
              onPressed: _saveInfo,
            )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25,25,25,0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Form(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top:35.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'First name'
                          ),
                          style: const TextStyle(
                              fontSize: 25.0
                          ),

                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:25.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'email'
                          ),
                          style: const TextStyle(
                              fontSize: 20.0
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:25.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Password'
                          ),
                          style: const TextStyle(
                              fontSize: 25.0
                          ),

                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:25.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'City'
                          ),
                          style: const TextStyle(
                              fontSize: 20.0
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:25.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Country'
                          ),
                          style: const TextStyle(
                              fontSize: 20.0
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:25.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Bio'
                          ),
                          style: const TextStyle(
                              fontSize: 20.0
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top:30.0,bottom:40.0),
                  child: MaterialButton(
                    onPressed: () {
                      // Your onPressed logic here
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: MediaQuery.of(context).size.width / 4.8,
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 5,
                        backgroundImage: const AssetImage('assets/images/sherli7.jpg'),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

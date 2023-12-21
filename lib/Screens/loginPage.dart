import 'package:flutter/material.dart';
import 'package:rent_house/Models/AppConstants.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Screens/signUpPage.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/loginPageRoute';

  const LoginPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<LoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<LoginPage> {

  void _signup(){
    Navigator.pushNamed(context, SignUpPage.routeName);
  }

  void _login(){
    Navigator.pushNamed(context, GuestHomePage.routeName);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Login page'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50,100,50,0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
             const Text(
               'Welcome to ${AppConstants.appName}!',
               style: TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 30.0
               ),
               textAlign: TextAlign.center,
             ),
             Form(
               child: Column(
                 children: [
                   Padding(
                     padding: const EdgeInsets.only(top:35.0),
                     child: TextFormField(
                       decoration: const InputDecoration(
                         labelText: 'Username/email'
                       ),
                       style: const TextStyle(
                           fontSize: 25.0
                       ),
                     ),
                   ),
                   Padding(
                     padding: const EdgeInsets.only(top:35.0),
                     child: TextFormField(
                       decoration: const InputDecoration(
                         labelText: 'password'
                     ),
                       style: const TextStyle(
                           fontSize: 20.0
                       ),
                     ),
                   ),
                 ],
               ),
             ),
              Padding(
                padding: const EdgeInsets.only(top:30.0),
                child: MaterialButton(
                  onPressed: ()=>{
                    _login(),
                  },
                  color:AppConstants.toColor("219ebc"),
                  height: MediaQuery.of(context).size.height/12,
                  minWidth: double.infinity,
                  child: const Text(
                      'Login',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top:20.0),
                child: MaterialButton(
                  onPressed: ()=>{
                    _signup()
                  },
                  color: AppConstants.toColor("caf0f8"),
                  height: MediaQuery.of(context).size.height/12,
                  minWidth: double.infinity,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: const Text(
                      'Sign up',
                       style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

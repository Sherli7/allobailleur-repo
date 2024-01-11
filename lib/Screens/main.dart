import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rent_house/Models/AppConstants.dart';
import 'package:rent_house/Screens/BookPostingPage.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';
import 'package:rent_house/Screens/signUpPage.dart';
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';

void main() {  runApp(const MyApp());}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: AppConstants.appName),
      routes: {
        LoginPage.routeName: (context) => const LoginPage(title: AppConstants.appName),
        SignUpPage.routeName:(context)=> const SignUpPage(),
        GuestHomePage.routeName:(context)=> const GuestHomePage(),
        PersonalInfoPage.routeName:(context)=>const PersonalInfoPage(),
        ViewProfilePage.routeName:(context)=>const ViewProfilePage(),
        ViewPostingPage.routeName:(context)=> const ViewPostingPage(),
        BookPostingPage.routeName:(context)=> const BookPostingPage(),
      },
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    Timer(
      const Duration(seconds: 2),
          () {
        Navigator.pushNamed(context, LoginPage.routeName);
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.hotel,
              size: 80,
            ),
            Padding(
              padding: EdgeInsets.only(top: 25),
              child: Text(
                AppConstants.appName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          ],
        ),
      ),
    );
  }
}

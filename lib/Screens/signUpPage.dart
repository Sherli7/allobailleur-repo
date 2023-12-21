import 'package:flutter/material.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class SignUpPage extends StatefulWidget {
  static const String routeName = '/signUpPageRoute';

  const SignUpPage({super.key});


  @override
  State<SignUpPage> createState() => _MySignUpPageState();
}

class _MySignUpPageState extends State<SignUpPage> {

  void _signup(){
    Navigator.pushNamed(context, GuestHomePage.routeName);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Sign up'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25,50,25,0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Please enter the following information:',
                  style: TextStyle(
                      fontSize: 25.0
                  ),
                  textAlign: TextAlign.center,
                ),
                Form(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top:25.0),
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
                              labelText: 'Last name'
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
                    onPressed: ()=>{
                      _signup(),
                    },
                    color: Colors.blue,
                    height: MediaQuery.of(context).size.height/12,
                    minWidth: double.infinity,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25.0,
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

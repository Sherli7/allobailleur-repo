import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Models/AppConstants.dart';
import 'package:rent_house/Providers/auth_provider.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Screens/signUpPage.dart';
import 'package:rent_house/Views/TextWidgets.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/loginPageRoute';

  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _signup(){
    Navigator.pushNamed(context, SignUpPage.routeName);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final success = await authProvider.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        navigator.pushReplacementNamed(GuestHomePage.routeName);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Login failed')),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      navigator.pushReplacementNamed(GuestHomePage.routeName);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Google sign-in failed')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarText(key: UniqueKey(), text: 'Login page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('assets/images/house.jpeg', height: 150),
                const SizedBox(height: 20),
               const Text(
                 'Welcome to ${AppConstants.appName}!',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   fontSize: 30.0
                 ),
                 textAlign: TextAlign.center,
               ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top:35.0),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Username/email'
                          ),
                          style: const TextStyle(
                              fontSize: 25.0
                          ),
                          validator: (value) => value!.isEmpty ? 'Please enter your email' : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:35.0),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'password'
                        ),
                          style: const TextStyle(
                              fontSize: 20.0
                          ),
                          obscureText: true,
                           validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (authProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(top:30.0),
                    child: MaterialButton(
                      onPressed: _login,
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
                      onPressed: _googleSignIn,
                      color: Colors.white,
                      elevation: 5.0,
                      height: MediaQuery.of(context).size.height/12,
                      minWidth: double.infinity,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.google, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top:20.0),
                    child: MaterialButton(
                      onPressed: _signup,
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
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Services/AuthService.dart';

import 'package:rent_house/Models/AppConstants.dart';
import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/BookPostingPage.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';
import 'package:rent_house/Screens/signUpPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart'
    show PropertyDetailsPage, BookingPage;
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/myListingsPage.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/firebase_options.dart';

import 'conversationPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Allô bailleur',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        onGenerateRoute: _generateRoute, // Centralise la génération de routes
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Page non trouvée')),
          ),
        ),
        routes: {
          // Routes simples sans args
          SignUpPage.routeName: (context) => const SignUpPage(),
          GuestHomePage.routeName: (context) => const GuestHomePage(),
          PersonalInfoPage.routeName: (context) => const PersonalInfoPage(),
          ViewProfilePage.routeName: (context) => const ViewProfilePage(),
          BookPostingPage.routeName: (context) => const BookPostingPage(),
          ConversationPage.routeName: (context) => const ConversationPage(),
          CreatePropertyPage.routeName: (context) => const CreatePropertyPage(),
          SearchPage.routeName: (context) => const SearchPage(),
          FavoritesPage.routeName: (context) => const FavoritesPage(),
          MyListingsPage.routeName: (context) => const MyListingsPage(),
        },
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    // Routes avec args (Property) – centralisé pour éviter la redondance
    Widget? page;
    final args = settings.arguments as Property?;
    switch (settings.name) {
      case PropertyDetailsPage.routeName:
        page = args != null
            ? PropertyDetailsPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
      case BookingPage.routeName:
        page = args != null
            ? BookingPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
      case ViewPostingPage.routeName:
        page = args != null
            ? ViewPostingPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
      case EditPropertyPage.routeName:
        page = args != null
            ? EditPropertyPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
    }
    return MaterialPageRoute(
        builder: (context) => page ?? _errorPage('Route inconnue'));
  }

  Widget _errorPage(String message) =>
      Scaffold(body: Center(child: Text(message)));
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser == null) {
      return const LoginPage(title: AppConstants.appName);
    }

    // Ajout d'un loader si besoin (ex. pendant fetch profile dans AuthProvider)
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const GuestHomePage();
      },
    );
  }
}

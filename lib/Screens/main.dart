import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart';
import 'package:rent_house/Services/AuthService.dart';

import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';
import 'package:rent_house/Screens/signUpPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/myListingsPage.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:rent_house/Screens/inboxPage.dart';
import 'package:rent_house/Screens/nearbyMapPage.dart';

import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/messages_provider.dart';
import 'package:rent_house/firebase_options.dart';

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
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Allô Bailleur',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          fontFamily: 'Roboto', // optionnel, mais propre
        ),

        // Plus de localisation = plus d'erreur
        home: const AuthWrapper(),

        // Routes nommées simples
        routes: {
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignUpPage(),
          '/home': (_) => const GuestHomePage(),
          '/personal-info': (_) => const PersonalInfoPage(),
          '/profile': (_) => const ViewProfilePage(),
          '/create-property': (_) => const CreatePropertyPage(),
          '/search': (_) => const SearchPage(),
          '/favorites': (_) => const FavoritesPage(),
          '/my-listings': (_) => const MyListingsPage(),
          '/nearbyMapRoute': (_) => const NearbyMapPage(),
          ConversationPage.routeName: (_) => const ConversationPage(),
          InboxPage.routeName: (_) => const InboxPage(),
        },

        // Routes avec arguments (Property)
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case PropertyDetailsPage.routeName:
              final property = settings.arguments as Property;
              return MaterialPageRoute(
                builder: (_) => PropertyDetailsPage(property: property),
              );

            case '/view-posting':
              final property = settings.arguments as Property;
              return MaterialPageRoute(
                builder: (_) => ViewPostingPage(property: property),
              );

            case EditPropertyPage.routeName:
              final property = settings.arguments as Property;
              return MaterialPageRoute(
                builder: (_) => EditPropertyPage(property: property),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Page non trouvée')),
                ),
              );
          }
        },
      ),
    );
  }
}

// Gestion de l'authentification au démarrage
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const LoginPage();
    }

    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const GuestHomePage(); // ou OwnerDashboard si tu veux
      },
    );
  }
}

// Ajout de logs pour capturer les tags des widgets Hero dans l'arbre des widgets
void debugPrintHeroTag(String tag) {
  print('[Hero] tag: $tag');
}

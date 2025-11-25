import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Services/AuthService.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/myListingsPage.dart';
import 'package:rent_house/Screens/ownerDashboard.dart';
import 'package:rent_house/Screens/bookings_list_page.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:rent_house/Providers/messages_provider.dart';
import 'package:rent_house/firebase_options.dart';

import 'Screens/conversationPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/images/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase (replace Firebase DB/Storage)
  await Supabase.initialize(
    url: 'https://iaiwhqfdisfiyhxpcasr.supabase.co', // Votre URL Supabase
    anonKey: dotenv.env['SUPABASE_KEY']!, // Clé depuis .env
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth state stream (Firebase User)
        StreamProvider<firebase_auth.User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
        // App-level AuthProvider (profile, business logic)
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
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
          // Owner dashboard
          OwnerDashboard.routeName: (context) => const OwnerDashboard(),
          // Bookings list (guest & host)
          BookingsListPage.routeName: (context) => const BookingsListPage(),
          PropertyDetailsPage.routeName: (context) {
            final property = ModalRoute.of(context)?.settings.arguments;
            if (property != null) {
              return PropertyDetailsPage(property: property as Property);
            }
            return const Scaffold(
                body: Center(child: Text('Propriété non trouvée')));
          },
          BookingPage.routeName: (context) {
            final property = ModalRoute.of(context)?.settings.arguments;
            if (property != null) {
              return BookingPage(property: property as Property);
            }
            return const Scaffold(
                body: Center(child: Text('Propriété non trouvée')));
          },
          ViewPostingPage.routeName: (context) {
            final property = ModalRoute.of(context)?.settings.arguments;
            if (property != null) {
              return ViewPostingPage(property: property as Property);
            }
            return const Scaffold(
                body: Center(child: Text('Propriété non trouvée')));
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();

    if (firebaseUser != null) {
      return const GuestHomePage();
    }
    return const LoginPage();
  }
}

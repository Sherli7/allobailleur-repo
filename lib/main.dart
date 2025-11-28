import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Services/AuthService.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

import 'package:rent_house/theme/app_theme.dart';

import 'Screens/conversation_page.dart';

import 'package:rent_house/Screens/SubscriptionScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "images/.env");
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
        title: 'Allô Bailleur',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        routes: {
          LoginPage.routeName: (context) => const LoginPage(),
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
          SubscriptionScreen.routeName: (context) => const SubscriptionScreen(),
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final Connectivity _connectivity = Connectivity();
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final isOffline = result == ConnectivityResult.none;
    if (isOffline != _isOffline) {
      setState(() {
        _isOffline = isOffline;
      });
      if (isOffline) {
        _showOfflineDialog();
      }
    }
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connexion perdue'),
          content: const Text(
            'Vous avez perdu la connexion internet. Veuillez vérifier votre connexion et réessayer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkInitialConnectivity(); // Recheck
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();

    if (firebaseUser != null) {
      return const GuestHomePage();
    }
    return const LoginPage();
  }
}

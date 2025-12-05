import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/theme_provider.dart';
import 'package:rent_house/Services/AuthService.dart';
import 'package:rent_house/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:rent_house/Models/property.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Screens/loginPage.dart';
import 'package:rent_house/Screens/personalInfoPage.dart';
import 'package:rent_house/Screens/signUpPage.dart';
import 'package:rent_house/Screens/viewProfilePage.dart';
import 'package:rent_house/Screens/createPropertyPage.dart';
import 'package:rent_house/Screens/searchPage.dart';
import 'package:rent_house/Screens/propertyDetailsPage.dart'
    show PropertyDetailsPage;
import 'package:rent_house/Screens/viewPostingPage.dart';
import 'package:rent_house/Screens/editPropertyPage.dart';
import 'package:rent_house/Screens/favoritesPage.dart';
import 'package:rent_house/Screens/myListingsPage.dart';
import 'package:rent_house/Screens/nearbyMapPage.dart';
import 'package:rent_house/Screens/inboxPage.dart';
import 'package:rent_house/Screens/settingsPage.dart';
import 'package:rent_house/Screens/ticketListPage.dart';
import 'package:rent_house/Screens/createTicketPage.dart';
import 'package:rent_house/Screens/helpSupportPage.dart';
import 'package:rent_house/Screens/conversation_page.dart';
import 'package:rent_house/Screens/ComparePropertiesPage.dart';
import 'package:rent_house/Providers/auth_provider.dart' as app_auth;
import 'package:rent_house/Providers/booking_provider.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Providers/messages_provider.dart';
import 'package:rent_house/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Supabase
  await Supabase.initialize(
    url: 'https://iaiwhqfdisfiyhxpcasr.supabase.co',
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<firebase_auth.User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Ajout du ThemeProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Allô bailleur',
            theme: AppTheme.lightTheme, // Thème clair par défaut
            darkTheme: AppTheme.darkTheme, // Thème sombre
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            onGenerateRoute: _generateRoute, // Centralise la génération de routes
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (context) =>
                  const Scaffold(body: Center(child: Text('Page non trouvée'))),
            ),
            routes: {
              // Routes simples sans args
              SignUpPage.routeName: (context) => const SignUpPage(),
              LoginPage.routeName: (context) => const LoginPage(),
              GuestHomePage.routeName: (context) => const GuestHomePage(),
              PersonalInfoPage.routeName: (context) => const PersonalInfoPage(),
              ViewProfilePage.routeName: (context) => const ViewProfilePage(),
              CreatePropertyPage.routeName: (context) => const CreatePropertyPage(),
              SearchPage.routeName: (context) => const SearchPage(),
              FavoritesPage.routeName: (context) => const FavoritesPage(),
              MyListingsPage.routeName: (context) => const MyListingsPage(),
              NearbyMapPage.routeName: (context) => const NearbyMapPage(),
              InboxPage.routeName: (context) => const InboxPage(),
              SettingsPage.routeName: (context) => const SettingsPage(),
              TicketListPage.routeName: (context) => const TicketListPage(),
              CreateTicketPage.routeName: (context) => const CreateTicketPage(),
              HelpSupportPage.routeName: (context) => const HelpSupportPage(),
            },
          );
        },
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    // Routes avec args (Property) – centralisé pour éviter la redondance
    Widget? page;
    final args = settings.arguments;
    
    switch (settings.name) {
      case PropertyDetailsPage.routeName:
        page = args is Property 
            ? PropertyDetailsPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
      case ViewPostingPage.routeName:
        page = args is Property
            ? ViewPostingPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
      case EditPropertyPage.routeName:
        page = args is Property
            ? EditPropertyPage(property: args)
            : _errorPage('Propriété non trouvée');
        break;
      case ConversationPage.routeName:
        // ConversationPage récupère les arguments via ModalRoute dans didChangeDependencies
        // Pas de paramètres dans le constructeur
        page = const ConversationPage();
        break;
      case ComparePropertiesPage.routeName:
        page = args is List<Property>
            ? ComparePropertiesPage(properties: args)
            : _errorPage('Comparaison impossible');
        break;
    }
    return MaterialPageRoute(
      settings: settings, // Important pour que la page reçoive les arguments
      builder: (context) => page ?? _errorPage('Route inconnue'),
    );
  }

  Widget _errorPage(String message) =>
      Scaffold(body: Center(child: Text(message)));
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<firebase_auth.User?>();

    if (firebaseUser == null) {
      return const LoginPage();
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

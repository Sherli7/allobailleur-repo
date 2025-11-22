# 🔥 Guide d'Intégration Firebase - Allô Bailleur

## 📋 Table des matières
1. [Configuration initiale](#configuration-initiale)
2. [Architecture](#architecture)
3. [Services Firebase](#services-firebase)
4. [Utilisation dans les écrans](#utilisation-dans-les-écrans)
5. [Règles Firestore](#règles-firestore)

---

## 🚀 Configuration initiale

### Étape 1 : Ajouter les dépendances
Les dépendances ont déjà été ajoutées au `pubspec.yaml` :
```yaml
firebase_core: ^2.24.0
firebase_auth: ^4.14.0
cloud_firestore: ^4.14.0
firebase_storage: ^11.5.0
provider: ^6.1.0
```

### Étape 2 : Configurer Firebase
1. Créez un projet Firebase sur [Firebase Console](https://console.firebase.google.com)
2. Téléchargez et configurez les fichiers :
   - **Android**: `google-services.json` → `android/app/`
   - **iOS**: `GoogleService-Info.plist` → `ios/Runner/`
   - **Web**: Les clés sont dans `firebase_options.dart`

### Étape 3 : Mettre à jour firebase_options.dart
Remplacez `YOUR_*` par vos vraies données Firebase:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

---

## 🏗️ Architecture

### Structure des fichiers créés
```
lib/
├── Models/
│   ├── Users.dart (✏️ MODIFIÉ)
│   ├── Property.dart (➕ NOUVEAU)
│   ├── Booking.dart (➕ NOUVEAU)
│   └── AppConstants.dart (existant)
│
├── Services/
│   ├── AuthService.dart (➕ NOUVEAU)
│   ├── PropertyService.dart (➕ NOUVEAU)
│   └── BookingService.dart (➕ NOUVEAU)
│
├── Providers/
│   ├── AuthProvider.dart (➕ NOUVEAU)
│   ├── PropertyProvider.dart (➕ NOUVEAU)
│   └── BookingProvider.dart (➕ NOUVEAU)
│
├── Screens/
│   ├── main.dart (✏️ MODIFIÉ)
│   └── ... (autres écrans)
│
└── firebase_options.dart (➕ NOUVEAU)
```

### Architecture en couches

```
┌─────────────────────────────────────┐
│         UI LAYER (Screens)          │
│  (loginPage, explorePage, etc)      │
└────────────────┬────────────────────┘
                 │
┌─────────────────▼────────────────────┐
│      PROVIDER LAYER (State Mgmt)     │
│  (AuthProvider, PropertyProvider)    │
└────────────────┬────────────────────┘
                 │
┌─────────────────▼────────────────────┐
│      SERVICE LAYER (Business Logic)  │
│  (AuthService, PropertyService)      │
└────────────────┬────────────────────┘
                 │
┌─────────────────▼────────────────────┐
│       FIREBASE (Backend)             │
│  (Authentication, Firestore, Storage)│
└─────────────────────────────────────┘
```

---

## 🔌 Services Firebase

### 1. AuthService - Authentification

#### Inscription
```dart
final result = await authService.signUp(
  email: 'user@example.com',
  password: 'password123',
  firstName: 'John',
  lastName: 'Doe',
  city: 'Paris',
  country: 'France',
  bio: 'I love traveling',
);
```

#### Connexion
```dart
final result = await authService.login(
  email: 'user@example.com',
  password: 'password123',
);
```

#### Déconnexion
```dart
await authService.logout();
```

#### Mettre à jour le profil
```dart
await authService.updateUserProfile(
  userId: userId,
  user: updatedUser,
);
```

### 2. PropertyService - Gestion des propriétés

#### Créer une propriété
```dart
final property = Property(
  id: '', // Auto-généré
  ownerId: userId,
  title: 'Cosy Apartment in Paris',
  description: 'Beautiful 2-bedroom apartment',
  city: 'Paris',
  country: 'France',
  price: 150.0,
  bedrooms: 2,
  bathrooms: 1,
  rating: 0.0,
  reviewCount: 0,
  imageUrls: ['url1', 'url2'],
  amenities: ['WiFi', 'TV', 'Kitchen'],
  latitude: 48.8566,
  longitude: 2.3522,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  isAvailable: true,
);

await propertyService.createProperty(property);
```

#### Récupérer les propriétés
```dart
// Toutes les propriétés disponibles
propertyService.getAllProperties().listen((properties) {
  print('Propriétés: $properties');
});

// Propriétés de l'hôte
propertyService.getHostProperties(hostId).listen((properties) {
  print('Mes propriétés: $properties');
});

// Rechercher par ville
propertyService.searchPropertiesByCity('Paris').listen((properties) {
  print('Propriétés à Paris: $properties');
});
```

#### Mettre à jour/Supprimer
```dart
await propertyService.updateProperty(propertyId, updatedProperty);
await propertyService.deleteProperty(propertyId);
```

#### Favoris et avis
```dart
// Ajouter aux favoris
await propertyService.addToFavorites(userId, propertyId);

// Ajouter un avis
await propertyService.addReview(propertyId, 4.5, 'Great place!', userId);
```

### 3. BookingService - Gestion des réservations

#### Créer une réservation
```dart
final booking = Booking(
  id: '',
  guestId: userId,
  propertyId: propertyId,
  hostId: hostId,
  checkInDate: DateTime(2024, 12, 15),
  checkOutDate: DateTime(2024, 12, 20),
  totalPrice: 750.0,
  status: 'pending',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await bookingService.createBooking(booking);
```

#### Vérifier la disponibilité
```dart
final isAvailable = await bookingService.isPropertyAvailable(
  propertyId,
  checkInDate,
  checkOutDate,
);
```

#### Gérer les réservations
```dart
// Charger les réservations de l'utilisateur
bookingService.getUserBookings(userId).listen((bookings) {
  print('Mes réservations: $bookings');
});

// Confirmer une réservation
await bookingService.confirmBooking(bookingId);

// Annuler une réservation
await bookingService.cancelBooking(bookingId);
```

---

## 📱 Utilisation dans les écrans

### Exemple avec loginPage.dart

```dart
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/auth_provider.dart';

class _MyLoginPageState extends State<LoginPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, GuestHomePage.routeName);
      }
    } else {
      // Afficher le message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Exemple avec explorePage.dart

```dart
import 'package:provider/provider.dart';
import 'package:rent_house/Providers/property_provider.dart';

class MyExplorePageState extends State<ExplorePage> {
  @override
  void initState() {
    super.initState();
    // Charger les propriétés au démarrage
    Provider.of<PropertyProvider>(context, listen: false).loadAllProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, _) {
        if (propertyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (propertyProvider.properties.isEmpty) {
          return const Center(child: Text('Aucune propriété trouvée'));
        }

        return ListView.builder(
          itemCount: propertyProvider.properties.length,
          itemBuilder: (context, index) {
            final property = propertyProvider.properties[index];
            return ListTile(
              title: Text(property.title),
              subtitle: Text('${property.price}€ / nuit'),
              onTap: () {
                propertyProvider.selectProperty(property);
                Navigator.pushNamed(context, ViewPostingPage.routeName);
              },
            );
          },
        );
      },
    );
  }
}
```

---

## 🔐 Règles Firestore

Configurez ces règles dans Firebase Console → Firestore Database → Rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId || request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }

    // Properties collection
    match /properties/{propertyId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth.uid == resource.data.ownerId;

      // Reviews subcollection
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update: if request.auth.uid == resource.data.userId;
        allow delete: if request.auth.uid == resource.data.userId;
      }
    }

    // Bookings collection
    match /bookings/{bookingId} {
      allow read: if request.auth.uid == resource.data.guestId || 
                     request.auth.uid == resource.data.hostId;
      allow create: if request.auth.uid == request.resource.data.guestId;
      allow update: if request.auth.uid == resource.data.guestId || 
                       request.auth.uid == resource.data.hostId;
      allow delete: if request.auth.uid == resource.data.guestId || 
                       request.auth.uid == resource.data.hostId;
    }
  }
}
```

---

## 📊 Structure Firestore

### Collection: users
```json
{
  "uid": "...",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "city": "Paris",
  "country": "France",
  "bio": "I love traveling",
  "profileImageUrl": "",
  "isHost": false,
  "favorites": ["propertyId1", "propertyId2"],
  "createdAt": "2024-11-16T...",
  "updatedAt": "2024-11-16T..."
}
```

### Collection: properties
```json
{
  "ownerId": "...",
  "title": "Cosy Apartment",
  "description": "...",
  "city": "Paris",
  "country": "France",
  "price": 150.0,
  "bedrooms": 2,
  "bathrooms": 1,
  "rating": 4.5,
  "reviewCount": 12,
  "imageUrls": ["url1", "url2"],
  "amenities": ["WiFi", "TV"],
  "latitude": 48.8566,
  "longitude": 2.3522,
  "isAvailable": true,
  "createdAt": "2024-11-16T...",
  "updatedAt": "2024-11-16T..."
}
```

### Collection: bookings
```json
{
  "guestId": "...",
  "propertyId": "...",
  "hostId": "...",
  "checkInDate": "2024-12-15T...",
  "checkOutDate": "2024-12-20T...",
  "totalPrice": 750.0,
  "status": "pending",
  "createdAt": "2024-11-16T...",
  "updatedAt": "2024-11-16T..."
}
```

---

## ✅ Checklist d'implémentation

- [ ] Créer un projet Firebase
- [ ] Télécharger les fichiers de configuration
- [ ] Mettre à jour `firebase_options.dart`
- [ ] Installer les dépendances: `flutter pub get`
- [ ] Tester l'authentification
- [ ] Implémenter les écrans avec Providers
- [ ] Configurer les règles Firestore
- [ ] Tester la création de propriétés
- [ ] Tester les réservations
- [ ] Déployer en production

---

## 🐛 Dépannage

### Erreur: "Target of URI doesn't exist"
**Cause**: Dépendances Firebase non installées
**Solution**: Exécutez `flutter pub get`

### Erreur: "FirebaseException: An error occurred when calling the Cloud Firestore API"
**Cause**: Règles Firestore restrictives
**Solution**: Mettez à jour les règles dans Firebase Console

### Erreur: "MissingPluginException"
**Cause**: Plugins Firebase non compilés correctement
**Solution**: 
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📚 Ressources supplémentaires

- [Firebase Console](https://console.firebase.google.com)
- [Firebase Documentation](https://firebase.flutter.dev)
- [Firestore Documentation](https://cloud.google.com/firestore/docs)
- [Provider Documentation](https://pub.dev/packages/provider)

---

**Créé le**: 16/11/2024
**Version**: 1.0.0

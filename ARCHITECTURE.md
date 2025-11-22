# 🏗️ Architecture Technique - Allô Bailleur

## 📁 Arborescence du Projet

```
allobailleur-repo/
├── lib/
│   ├── main.dart                           # Point d'entrée de l'application
│   ├── firebase_options.dart               # Configuration Firebase
│   ├── structure.txt                       # Fichier de structure
│   │
│   ├── Models/                             # Modèles de données
│   │   ├── AppConstants.dart               # Constantes globales
│   │   ├── Users.dart                      # Modèle utilisateur
│   │   ├── property.dart                   # Modèle propriété
│   │   └── booking.dart                    # Modèle réservation
│   │
│   ├── Providers/                          # Gestion d'état (Provider Pattern)
│   │   ├── auth_provider.dart              # AuthProvider (authentification, profil)
│   │   ├── property_provider.dart          # PropertyProvider (CRUD propriétés, images)
│   │   └── booking_provider.dart           # BookingProvider (gestion réservations)
│   │
│   ├── Services/                           # Logique métier et Firebase
│   │   ├── AuthService.dart                # Opérations d'authentification Firebase
│   │   ├── PropertyService.dart            # CRUD Firestore + Storage (images)
│   │   ├── BookingService.dart             # CRUD réservations
│   │   ├── google_sign_in_wrapper.dart     # Abstraction Google Sign-In
│   │   ├── google_sign_in_wrapper_mobile.dart  # Impl. native (iOS/Android)
│   │   ├── google_sign_in_wrapper_web.dart    # Impl. web
│   │   └── web_wrapper.dart                # Wrapper utilitaire web
│   │
│   ├── Screens/                            # Écrans (Pages UI)
│   │   ├── main.dart                       # Splash/Auth wrapper
│   │   ├── loginPage.dart                  # Connexion
│   │   ├── signUpPage.dart                 # Inscription avec sélection de rôle
│   │   ├── guestHomePage.dart              # Navigation principale (Bottom navbar)
│   │   ├── explorePage.dart                # Découverte propriétés (grid)
│   │   ├── searchPage.dart                 # Recherche par ville/prix
│   │   ├── mapPage.dart                    # Découverte par carte (Google Maps)
│   │   ├── propertyDetailsPage.dart        # Détails + booking d'une propriété
│   │   ├── viewPostingPage.dart            # Vue propriété (alternative)
│   │   ├── createPropertyPage.dart         # Création annonce (Stepper multi-étapes)
│   │   ├── editPropertyPage.dart           # Édition annonce avec gestion images
│   │   ├── myListingsPage.dart             # Mes annonces (CRUD, analytics)
│   │   ├── myPostingPage.dart              # Mes annonces (alternative/legacy)
│   │   ├── favoritesPage.dart              # Favoris utilisateur
│   │   ├── bookingsPage.dart               # Mes réservations
│   │   ├── tripsPage.dart                  # Historique voyages
│   │   ├── accountPage.dart                # Profil utilisateur
│   │   ├── accountPage_updated.dart        # Profil utilisateur (version mise à jour)
│   │   ├── personalInfoPage.dart           # Infos personnelles
│   │   ├── viewProfilePage.dart            # Vue profil public
│   │   ├── bookPostingPage.dart            # Réservation annonce
│   │   ├── inboxPage.dart                  # Messagerie
│   │   ├── conversationPage.dart           # Vue conversation
│   │   ├── hostHomePage.dart               # Home pour les hôtes
│   │   └── savedPage.dart                  # Annonces sauvegardées
│   │
│   └── Views/                              # Widgets réutilisables
│       ├── gridWidets.dart                 # Widget grille d'annonces
│       ├── ListWidgets.dart                # Widgets de liste
│       ├── TextWidgets.dart                # Widgets de texte
│       ├── calendarWidgets.dart            # Widgets calendrier (réservations)
│       └── formWidgets.dart                # Widgets formulaires réutilisables
│
├── android/                                # Configuration Android
│   ├── app/
│   │   ├── build.gradle
│   │   ├── google-services.json            # Firebase config (Android)
│   │   └── src/
│   ├── settings.gradle                     # Dépôts Gradle + fallback maven
│   └── gradle/
│
├── ios/                                    # Configuration iOS
│   ├── Runner/
│   │   ├── GoogleService-Info.plist        # Firebase config (iOS)
│   │   └── [autres fichiers iOS]
│   └── [structure Xcode]
│
├── web/                                    # Configuration web
│   ├── index.html
│   ├── manifest.json
│   └── icons/
│
├── assets/                                 # Ressources statiques
│   └── images/
│
├── test/                                   # Tests unitaires
│   └── widget_test.dart
│
├── pubspec.yaml                            # Dépendances Flutter + métadonnées
├── pubspec.lock                            # Versions verrouillées des dépendances
├── analysis_options.yaml                   # Configuration analyse statique
├── devtools_options.yaml                   # Options DevTools
├── firebase.json                           # Configuration Firebase CLI
├── firestore.rules                         # Règles Firestore (sécurité)
│
├── ARCHITECTURE.md                         # Ce fichier
├── README.md                               # Documentation générale
├── FEATURES_SUMMARY.md                     # Résumé des fonctionnalités
├── TESTING_PLAN.md                         # Plan de tests E2E
├── FIREBASE_INTEGRATION_GUIDE.md           # Guide d'intégration Firebase
├── FIREBASE_SETUP_CHECKLIST.md             # Checklist configuration Firebase
├── README_FIREBASE.md                      # Documentation Firebase
├── IMPLEMENTATION_EXAMPLES.md              # Exemples d'implémentation
├── CHANGELIST.md                           # Historique des changements
├── MISSION_ACCOMPLIE.md                    # Tâches complétées
├── FICHIERS_CREES.md                       # Fichiers créés/modifiés
├── INDEX.md                                # Index du projet
├── COMMENCER_ICI.md                        # Point de départ pour dev
└── RECAP_VISUAL.md                         # Récapitulatif visuel
```

---

## Vue d'ensemble de l'architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      COUCHE PRÉSENTATION (UI)                  │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ Screens/                                                   │ │
│ │ ├─ main.dart (SplashScreen + MyApp)                       │ │
│ │ ├─ loginPage.dart                                         │ │
│ │ ├─ signUpPage.dart                                        │ │
│ │ ├─ guestHomePage.dart (Navigation)                       │ │
│ │ ├─ explorePage.dart (Affiche propriétés)                │ │
│ │ ├─ accountPage.dart (Profil utilisateur)                │ │
│ │ ├─ bookPostingPage.dart (Créer annonce)                 │ │
│ │ ├─ viewPostingPage.dart (Détails propriété)            │ │
│ │ └─ ... (autres écrans)                                   │ │
│ └────────────────────────────────────────────────────────────┘ │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│               COUCHE STATE MANAGEMENT (Provider)                │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ Providers/                                                 │ │
│ │ ├─ AuthProvider (extends ChangeNotifier)                 │ │
│ │ │  ├─ signUp()         → crée compte + profil            │ │
│ │ │  ├─ login()          → connexion                        │ │
│ │ │  ├─ logout()         → déconnexion                      │ │
│ │ │  ├─ updateProfile()  → mise à jour données             │ │
│ │ │  └─ States: user, isLoading, errorMessage             │ │
│ │ │                                                         │ │
│ │ ├─ PropertyProvider                                       │ │
│ │ │  ├─ createProperty()                                   │ │
│ │ │  ├─ loadAllProperties()                                │ │
│ │ │  ├─ loadHostProperties()                               │ │
│ │ │  ├─ searchByCity() / searchByPrice()                   │ │
│ │ │  ├─ updateProperty() / deleteProperty()                │ │
│ │ │  ├─ addToFavorites() / removeFromFavorites()           │ │
│ │ │  └─ States: properties, isLoading, error              │ │
│ │ │                                                         │ │
│ │ └─ BookingProvider                                        │ │
│ │    ├─ createBooking()                                    │ │
│ │    ├─ loadUserBookings() / loadHostBookings()            │ │
│ │    ├─ checkAvailability()                                │ │
│ │    ├─ cancelBooking() / confirmBooking()                 │ │
│ │    └─ States: bookings, isLoading, error                │ │
│ └────────────────────────────────────────────────────────────┘ │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│                  COUCHE LOGIQUE MÉTIER (Services)               │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ Services/                                                  │ │
│ │ ├─ AuthService                                            │ │
│ │ │  ├─ Firebase Auth Integration                          │ │
│ │ │  ├─ Gestion des sessions                               │ │
│ │ │  ├─ Validation emails                                  │ │
│ │ │  └─ Récupération d'utilisateur                         │ │
│ │ │                                                         │ │
│ │ ├─ PropertyService                                        │ │
│ │ │  ├─ Opérations CRUD Firestore                          │ │
│ │ │  ├─ Recherche (ville, prix)                            │ │
│ │ │  ├─ Gestion favoris                                    │ │
│ │ │  └─ Système d'avis                                     │ │
│ │ │                                                         │ │
│ │ └─ BookingService                                         │ │
│ │    ├─ Opérations CRUD réservations                       │ │
│ │    ├─ Vérification disponibilité                         │ │
│ │    ├─ Gestion du statut                                  │ │
│ │    └─ Gestion des conflits de dates                      │ │
│ └────────────────────────────────────────────────────────────┘ │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│                    COUCHE MODÈLES (Models)                      │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ Models/                                                    │ │
│ │ ├─ User                                                   │ │
│ │ │  ├─ uid, email, firstName, lastName                    │ │
│ │ │  ├─ city, country, bio, profileImageUrl                │ │
│ │ │  ├─ isHost, favorites                                  │ │
│ │ │  ├─ toFirestore() / fromFirestore()                    │ │
│ │ │  └─ copyWith() pour immutabilité                       │ │
│ │ │                                                         │ │
│ │ ├─ Property                                               │ │
│ │ │  ├─ id, ownerId, title, description                    │ │
│ │ │  ├─ price, bedrooms, bathrooms                         │ │
│ │ │  ├─ rating, reviews, imageUrls, amenities             │ │
│ │ │  ├─ location (latitude, longitude)                     │ │
│ │ │  ├─ isAvailable                                        │ │
│ │ │  ├─ toFirestore() / fromFirestore()                    │ │
│ │ │  └─ copyWith()                                         │ │
│ │ │                                                         │ │
│ │ ├─ Booking                                                │ │
│ │ │  ├─ id, guestId, propertyId, hostId                    │ │
│ │ │  ├─ checkInDate, checkOutDate                          │ │
│ │ │  ├─ totalPrice, status                                 │ │
│ │ │  ├─ toFirestore() / fromFirestore()                    │ │
│ │ │  ├─ copyWith()                                         │ │
│ │ │  └─ nights (getter pour durée)                         │ │
│ │ │                                                         │ │
│ │ └─ AppConstants                                           │ │
│ │    ├─ Couleurs, API keys                                 │ │
│ │    ├─ Constantes métier                                  │ │
│ │    └─ Dictionnaires (mois, jours)                        │ │
│ └────────────────────────────────────────────────────────────┘ │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│              COUCHE DONNÉES (Firebase Backend)                  │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ Firebase Services:                                         │ │
│ │ ├─ Authentication                                         │ │
│ │ │  └─ Email/Password, Google Sign-In                     │ │
│ │ │                                                         │ │
│ │ ├─ Firestore Database                                     │ │
│ │ │  ├─ Collection: users                                  │ │
│ │ │  ├─ Collection: properties                             │ │
│ │ │  │  └─ Subcollection: reviews                          │ │
│ │ │  └─ Collection: bookings                               │ │
│ │ │                                                         │ │
│ │ ├─ Cloud Storage                                          │ │
│ │ │  └─ Images de propriétés, avatars                      │ │
│ │ │                                                         │ │
│ │ └─ Real-time Sync                                         │ │
│ │    └─ Streams pour données temps réel                    │ │
│ └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Flux de données détaillé

### 1️⃣ Flux d'authentification

```
USER ACTION (Clic bouton connexion)
    ↓
Widget (loginPage.dart)
    ↓ [Récupère AuthProvider]
AuthProvider.login(email, password)
    ↓
AuthService.login(email, password)
    ↓
FirebaseAuth.signInWithEmailAndPassword()
    ↓
[Succès/Erreur]
    ↓
AuthProvider.notifyListeners() [Rebuild widgets]
    ↓
Consumer<AuthProvider> [Widget rebuilt]
    ↓
Navigation vers GuestHomePage
```

### 2️⃣ Flux de chargement de propriétés

```
Page visitée (explorePage.dart)
    ↓
initState() → PropertyProvider.loadAllProperties()
    ↓
PropertyService.getAllProperties()
    ↓
Firestore.collection('properties').where(...).snapshots()
    ↓
Stream<List<Property>> [Real-time updates]
    ↓
PropertyProvider.notifyListeners()
    ↓
Consumer<PropertyProvider> [Widget rebuilt avec données]
    ↓
GridView affiche les propriétés
```

### 3️⃣ Flux de création de réservation

```
USER ACTION (Clic "Réserver")
    ↓
BookingProvider.checkAvailability()
    ↓
BookingService.isPropertyAvailable() [Vérification Firestore]
    ↓
[Disponible?] → Oui
    ↓
BookingProvider.createBooking(booking)
    ↓
BookingService.createBooking()
    ↓
Firestore.collection('bookings').add()
    ↓
[Succès]
    ↓
BookingProvider.notifyListeners()
    ↓
SnackBar "Réservation créée!"
```

---

## Diagramme de dépendances

```
Screens (UI Layer)
    ├─ Dépend de → Providers
    ├─ Dépend de → Models (pour typage)
    └─ Dépend de → AppConstants

Providers
    ├─ Dépend de → Services
    ├─ Dépend de → Models
    └─ Dépend de → Firebase

Services
    ├─ Dépend de → Firebase
    ├─ Dépend de → Models
    └─ Dépend de → AppConstants

Models
    └─ Autonomes (aucune dépendance)

Firebase (Backend)
    └─ Autonome
```

---

## Patterns utilisés

### 1. Provider Pattern
```dart
// Création
ChangeNotifierProvider(create: (_) => AuthProvider())

// Utilisation simple
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Utilisation réactive
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Text(authProvider.user?.fullName ?? 'Guest');
  },
)
```

### 2. Repository Pattern (Services)
```dart
// Les Services agissent comme des repositories
// Ils cachent l'implémentation Firebase
// Les Providers les utilisent sans connaître les détails

AuthService → Firebase Auth
PropertyService → Firestore
BookingService → Firestore
```

### 3. Factory Pattern (Models)
```dart
// fromFirestore: Firebase Doc → Model
factory Property.fromFirestore(DocumentSnapshot doc) { ... }

// toFirestore: Model → Firebase Doc
Map<String, dynamic> toFirestore() { ... }
```

### 4. Builder Pattern (copyWith)
```dart
// Créer une copie avec modifications
final updatedUser = user.copyWith(
  firstName: 'New Name',
  bio: 'New Bio',
  // Les autres champs conservent leur valeur
);
```

---

## Scénarios d'utilisation complets

### Scénario 1: Un nouvel utilisateur s'inscrit

```
1. loginPage.dart
   └─ User clique "S'inscrire"
      
2. signUpPage.dart
   └─ User remplit le formulaire
      
3. Consumer<AuthProvider>
   └─ onPressed: authProvider.signUp(...)
      
4. AuthProvider.signUp()
   ├─ isLoading = true
   ├─ Appelle AuthService.signUp()
   │
5. AuthService.signUp()
   ├─ FirebaseAuth.createUserWithEmailAndPassword()
   ├─ Crée doc user dans Firestore
   └─ Retourne {success: true, uid: ...}
   
6. AuthProvider
   ├─ isLoading = false
   ├─ notifyListeners() [Rebuild]
   
7. Consumer<AuthProvider>
   ├─ success ? Navigator.pushReplacementNamed(GuestHomePage)
   └─ error ? Afficher SnackBar d'erreur
   
8. FirebaseAuth.authStateChanges stream
   └─ Détecte nouvel utilisateur connecté
      
9. AuthProvider reçoit l'événement
   ├─ Récupère les données utilisateur
   └─ notifyListeners()
```

### Scénario 2: Utilisateur cherche une propriété

```
1. explorePage.dart - initState()
   └─ PropertyProvider.loadAllProperties()
      
2. PropertyProvider.loadAllProperties()
   ├─ isLoading = true
   ├─ Appelle PropertyService.getAllProperties()
      
3. PropertyService.getAllProperties()
   └─ Firestore.collection('properties')
      .where('isAvailable', isEqualTo: true)
      .snapshots() [Stream en temps réel]
      
4. Consumer<PropertyProvider>
   ├─ isLoading ? CircularProgressIndicator()
   ├─ properties.isEmpty ? Aucune trouvée
   └─ else : GridView affiche les propriétés
      
5. User tape une ville dans la recherche
   └─ PropertyProvider.searchByCity('Paris')
      
6. PropertyService.searchPropertiesByCity('Paris')
   └─ Firestore filtre et retourne un nouveau stream
      
7. Consumer<PropertyProvider>
   └─ GridView se met à jour automatiquement
      
8. User clique sur une propriété
   ├─ PropertyProvider.selectProperty()
   └─ Navigate ViewPostingPage avec propriété
```

---

## Gestion des erreurs

```
Chaque niveau gère les erreurs:

Screens
└─ Affichent les erreurs à l'utilisateur (SnackBar, Dialog)

Providers
└─ Stockent les erreurs dans errorMessage
└─ Gèrent les états de loading

Services
└─ Try/catch pour capturer les exceptions Firebase
└─ Retournent {success: bool, message: String}

Firebase
└─ Levée des exceptions (FirebaseAuthException, etc)

Flux d'erreur vers le haut:
Firebase Exception
    ↓
Service (try/catch)
    ↓
Provider (stocke errorMessage)
    ↓
Consumer<Provider>
    ↓
UI (affiche le message)
```

---

## Performance et optimisations

### 1. Streams pour temps réel
```dart
// Les données se mettent à jour automatiquement
propertyService.getAllProperties() // Retourne un Stream
    .listen((properties) {
      propertyProvider.properties = properties;
      propertyProvider.notifyListeners();
    });
```

### 2. Provider avec listen: false
```dart
// Si on n'a pas besoin de rebuild
final provider = Provider.of<AuthProvider>(context, listen: false);
// Plus performant qu'un Consumer si on appelle juste une méthode
```

### 3. Consumer au plus bas niveau
```dart
// Consumer au niveau du widget qui en a besoin
// Pas au niveau du parent pour éviter les rebuilds inutiles
GridView(
  itemBuilder: (context, index) {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        return PropertyCard(property: provider.properties[index]);
      },
    );
  },
)
```

---

## Sécurité - Règles Firestore

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users: lecture/écriture par l'utilisateur lui-même
    match /users/{userId} {
      allow read: if request.auth.uid == userId || request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }

    // Properties: lecture publique, écriture par propriétaire
    match /properties/{propertyId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth.uid == resource.data.ownerId;

      // Reviews: lecture publique, création par users auth
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update: if request.auth.uid == resource.data.userId;
        allow delete: if request.auth.uid == resource.data.userId;
      }
    }

    // Bookings: lecture/écriture par guest ou host
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

**Architecture créée le**: 16/11/2024  
**Version**: 1.0.0  
**Status**: ✅ Production Ready


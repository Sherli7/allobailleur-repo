# 🚀 Checklist Configuration Firebase

Utiliser cette checklist pour configurer Firebase correctement pour votre projet **Allô Bailleur**.

---

## 1. 🔐 Création du projet Firebase

### Étape 1.1: Créer le projet
- [ ] Aller sur https://console.firebase.google.com
- [ ] Cliquer sur "Add project"
- [ ] Nom du projet: `allobailleur` (ou similaire)
- [ ] Sélectionner la région: Europe
- [ ] Activer Google Analytics (optionnel)
- [ ] Cliquer "Create project"

### Étape 1.2: Activer l'authentification
- [ ] Dans Firebase Console, aller à **Authentication**
- [ ] Cliquer "Get started"
- [ ] Ajouter la méthode **Email/Password**
  - [ ] Activer "Email/Password"
  - [ ] Enregistrer

### Étape 1.3: Créer Firestore Database
- [ ] Aller à **Firestore Database**
- [ ] Cliquer "Create database"
- [ ] Région: `eur3` (Europe)
- [ ] Mode: **Production** (mais nous mettrons des règles ouvertes pour le dev)
- [ ] Cliquer "Create"

### Étape 1.4: Configurer Cloud Storage
- [ ] Aller à **Storage**
- [ ] Cliquer "Get started"
- [ ] Région: `eur3`
- [ ] Cliquer "Done"

---

## 2. 📱 Configuration Android

### Étape 2.1: Télécharger google-services.json
- [ ] Dans Firebase Console, aller à **Project Settings**
- [ ] Aller à l'onglet **Your apps**
- [ ] Sélectionner l'app Android
- [ ] Cliquer "Download google-services.json"
- [ ] Placer le fichier dans: `android/app/google-services.json`

### Étape 2.2: Configurer build.gradle
**android/build.gradle:**
```gradle
// À ajouter dans le bloc buildscript > dependencies
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

**android/app/build.gradle:**
```gradle
// À ajouter à la fin du fichier
apply plugin: 'com.google.gms.google-services'
```

- [ ] Ajouter google-services plugin

### Étape 2.3: Configurer AndroidManifest.xml
- [ ] Vérifier que la version minimale est >= 21:
```xml
<uses-sdk
    android:minSdkVersion="21"
    android:targetSdkVersion="33" />
```

- [ ] Ajouter Internet permission:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 3. 🍎 Configuration iOS

### Étape 3.1: Télécharger GoogleService-Info.plist
- [ ] Dans Firebase Console, aller à **Project Settings**
- [ ] Sélectionner l'app iOS
- [ ] Cliquer "Download GoogleService-Info.plist"
- [ ] Placer le fichier dans: `ios/Runner/GoogleService-Info.plist`

### Étape 3.2: Ajouter le fichier à Xcode
- [ ] Ouvrir `ios/Runner.xcworkspace` dans Xcode
- [ ] Faire un clic droit sur "Runner" → "Add Files to Runner"
- [ ] Sélectionner `GoogleService-Info.plist`
- [ ] Cocher "Copy items if needed"
- [ ] Sélectionner "Runner" comme cible
- [ ] Cliquer "Add"

### Étape 3.3: Mettre à jour podfile
**ios/Podfile:**
```ruby
# À ajouter après 'platform :ios'
platform :ios, '11.0'
```

- [ ] Vérifier la plateforme iOS minimum >= 11.0

### Étape 3.4: Mettre à jour Info.plist
- [ ] Vérifier que `GoogleService-Info.plist` est bien inclus dans Xcode

---

## 4. 🌐 Configuration Web (Optionnel)

### Étape 4.1: Obtenir les clés Firebase
- [ ] Firebase Console → **Project Settings**
- [ ] Aller à l'onglet **Your apps** → **Web**
- [ ] Copier le `firebaseConfig`

### Étape 4.2: Mettre à jour firebase_options.dart
```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_WEB_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_AUTH_DOMAIN',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

- [ ] Remplir tous les champs avec vos vraies valeurs

---

## 5. 📱 Configuration Flutter

### Étape 5.1: Installer les dépendances
```bash
flutter pub get
```
- [ ] Exécuter cette commande

### Étape 5.2: Mettre à jour firebase_options.dart
**Récupérer les clés pour chaque plateforme:**

**Android:**
- [ ] Firebase Console → Project Settings → Apps Android
- [ ] Copier: `apiKey`, `appId`, `messagingSenderId`, `projectId`
- [ ] Remplir dans `firebase_options.dart`

**iOS:**
- [ ] Firebase Console → Project Settings → Apps iOS
- [ ] Copier: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `iosBundleId` (com.rent.house)
- [ ] Remplir dans `firebase_options.dart`

### Étape 5.3: Test de compilation
```bash
flutter clean
flutter pub get
flutter run
```
- [ ] Compiler et tester sur Android/iOS

---

## 6. 🔐 Configurer les règles Firestore

### Étape 6.1: Accéder aux règles Firestore
- [ ] Firebase Console → **Firestore Database**
- [ ] Aller à l'onglet **Rules**

### Étape 6.2: Copier les règles
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users - lecture/écriture par l'utilisateur lui-même
    match /users/{userId} {
      allow read: if request.auth.uid == userId || request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }

    // Properties - lecture publique, écriture par propriétaire
    match /properties/{propertyId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth.uid == resource.data.ownerId;
      
      // Reviews
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow delete: if request.auth.uid == resource.data.userId;
      }
    }

    // Bookings
    match /bookings/{bookingId} {
      allow read: if request.auth.uid == resource.data.guestId || 
                     request.auth.uid == resource.data.hostId;
      allow create: if request.auth.uid == request.resource.data.guestId;
      allow update: if request.auth.uid == resource.data.guestId || 
                       request.auth.uid == resource.data.hostId;
      allow delete: if request.auth.uid == resource.data.guestId;
    }
  }
}
```
- [ ] Copier les règles dans Firestore
- [ ] Cliquer "Publish"

### Étape 6.3: Pour le développement (OPTIONNEL - À NE PAS UTILISER EN PRODUCTION)
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```
- [ ] Cette règle permet tout pour le DEV
- [ ] À REMPLACER par les vraies règles avant la production

---

## 7. 🔌 Configurer l'authentification

### Étape 7.1: Activer Email/Password
- [ ] Firebase Console → **Authentication**
- [ ] Onglet **Sign-in method**
- [ ] Cliquer sur **Email/Password**
- [ ] Activer "Email/Password"
- [ ] Enregistrer

### Étape 7.2: (Optionnel) Ajouter Google Sign-In
- [ ] Firebase Console → **Authentication**
- [ ] Cliquer sur **Google**
- [ ] Activer
- [ ] Enregistrer

---

## 8. ☁️ Configurer Cloud Storage

### Étape 8.1: Activer Storage
- [ ] Firebase Console → **Storage**
- [ ] Cliquer "Get started"
- [ ] Région: `eur3`
- [ ] Cliquer "Done"

### Étape 8.2: Configurer les règles Storage
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```
- [ ] Mettre à jour les règles Storage

---

## 9. ✅ Test de la configuration

### Test 1: Inscription
- [ ] Ouvrir l'app
- [ ] Aller à l'écran d'inscription
- [ ] Créer un compte avec email/password
- [ ] Vérifier dans Firebase Console → Authentication que l'utilisateur apparaît
- [ ] Vérifier que le document utilisateur est créé dans Firestore

### Test 2: Connexion
- [ ] Se déconnecter
- [ ] Se reconnecter avec le même email/password
- [ ] Vérifier que ça fonctionne

### Test 3: Propriétés
- [ ] Créer une propriété
- [ ] Vérifier dans Firestore qu'elle apparaît
- [ ] Modifier la propriété
- [ ] Vérifier les changements

### Test 4: Réservations
- [ ] Créer une réservation
- [ ] Vérifier dans Firestore
- [ ] Annuler la réservation
- [ ] Vérifier le changement de statut

---

## 10. 🚨 Dépannage

| Problème | Cause | Solution |
|----------|-------|----------|
| `FirebaseException` | Règles Firestore restrictives | Vérifier et mettre à jour les règles |
| `MissingPluginException` | Plugins non compilés | `flutter clean && flutter pub get` |
| `PlatformException` | Clés Firebase incorrectes | Vérifier firebase_options.dart |
| Authentification échoue | Email/Password non activé | Activer dans Firebase Console |
| Images ne se chargent pas | Storage non configuré | Configurer Cloud Storage |

---

## 11. 📊 Monitoring et Analytics

### Étape 11.1: Activer Google Analytics (Optionnel)
- [ ] Firebase Console → **Analytics**
- [ ] Créer des événements personnalisés pour tracker le comportement utilisateur

### Étape 11.2: Surveiller Firestore
- [ ] Firebase Console → **Firestore Database**
- [ ] Onglet **Stats** pour voir l'utilisation

### Étape 11.3: Surveiller l'authentification
- [ ] Firebase Console → **Authentication**
- [ ] Voir le nombre d'utilisateurs
- [ ] Voir les tentatives de connexion échouées

---

## 12. 🔒 Sécurité

- [ ] **NE JAMAIS** committer google-services.json ou GoogleService-Info.plist
- [ ] Ajouter à `.gitignore`:
```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart  # Optionnel, selon votre approche
```

- [ ] Vérifier que les règles Firestore sont sécurisées
- [ ] Activer l'authentification multi-facteurs pour l'accès à Firebase Console
- [ ] Activer les alertes de sécurité Firebase

---

## ✅ Checklist finale

- [ ] Projet Firebase créé
- [ ] google-services.json placé (Android)
- [ ] GoogleService-Info.plist placé (iOS)
- [ ] firebase_options.dart rempli
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Authentification Email/Password activée
- [ ] Firestore créé et configuré
- [ ] Règles Firestore publiées
- [ ] Cloud Storage configuré
- [ ] App compilée et testée
- [ ] Inscription/Connexion fonctionnelle
- [ ] Propriétés créables/visibles
- [ ] Réservations fonctionnelles

---

## 📞 Support

- Firebase Documentation: https://firebase.flutter.dev
- Firestore Rules: https://firebase.google.com/docs/firestore/security/get-started
- Firebase Console: https://console.firebase.google.com

---

**Dernière mise à jour**: 16/11/2024  
**Version**: 1.0.0


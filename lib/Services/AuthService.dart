import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:rent_house/Services/google_sign_in_wrapper.dart';
import 'package:rent_house/Models/Users.dart' as AppUserModel;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Notes / checklist for Google OAuth setup
  /// - Android: ensure `google-services.json` is present and SHA-1/SHA-256 fingerprints
  ///   are registered in Firebase console and OAuth client. Add correct package name.
  /// - iOS: ensure `GoogleService-Info.plist` is added and reversed client id is set.
  /// - Web: enable the OAuth client in Firebase console and add authorized domains/origins.
  /// - For web, `signInWithPopup` or `signInWithRedirect` are recommended; mobile uses
  ///   the `google_sign_in` plugin.

  // Compatibilité: expose l'ancien nom attendu par les providers
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Ancien alias utilisé ailleurs
  Stream<User?> get user => authStateChanges;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _firebaseAuth.currentUser;

  /// Inscription email/password et création du document Firestore
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    required String country,
    String bio = '',
    String role = 'tenant',
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Échec de la création du compte.'};
      }

      final userDoc = _firestore.collection('users').doc(user.uid);
      final appUser = AppUserModel.User(
        uid: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        // Persist optional profile fields provided during signup
        city: city.isNotEmpty ? city : null,
        country: country.isNotEmpty ? country : null,
        bio: bio.isNotEmpty ? bio : null,
        createdAt: DateTime.now(),
      );

      await userDoc.set(appUser.toFirestore());

      // Set the Firebase user's display name for convenience
      try {
        await user.updateDisplayName('$firstName $lastName');
        await user.reload();
      } catch (e) {
        debugPrint('[AuthService] failed to update displayName: $e');
      }

      return {'success': true, 'message': 'Compte créé avec succès.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inscription: $e'};
    }
  }

  /// Connexion email/password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return {'success': true, 'message': 'Connexion réussie.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  /// Connexion Google (retourne Map attendu)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Use the platform-specific wrapper to sign in.
      final userCredential = await signInWithGoogleWrapped();

      if (userCredential == null || userCredential.user == null) {
        return {'success': false, 'message': 'Connexion Google annulée.'};
      }

      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          await userDoc.set(AppUserModel.User(
            uid: user.uid,
            email: user.email ?? '',
            firstName: user.displayName?.split(' ').first ?? '',
            lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
            createdAt: DateTime.now(),
          ).toFirestore());
        }
      }

      return {'success': true, 'message': 'Connexion Google réussie.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de la connexion Google: $e'
      };
    }
  }

  /// Déconnexion (alias logout attendu)
  Future<void> logout() async {
    try {
      if (kIsWeb) {
        debugPrint('[AuthService] Web logout: FirebaseAuth.signOut()');
        await _firebaseAuth.signOut();
        return;
      }

      // Mobile / desktop: sign out via wrapper (which handles google_sign_in)
      try {
        await signOutGoogleWrapped();
      } catch (e) {
        debugPrint('[AuthService] signOutGoogleWrapped failed: $e');
      }

      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('[AuthService] logout error: $e');
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
    }
  }

  /// Réinitialisation du mot de passe
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Email de réinitialisation envoyé.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur reset password: $e'};
    }
  }

  /// Mettre à jour le profil utilisateur (conserve l'ancienne signature)
  Future<String> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return 'Profil mis à jour avec succès.';
    } catch (e) {
      return 'Erreur lors de la mise à jour du profil: $e';
    }
  }

  /// Récupérer les données utilisateur en tant que modèle
  Future<AppUserModel.User?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUserModel.User.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Supprimer le compte utilisateur (attend uid) et renvoie Map
  Future<Map<String, dynamic>> deleteAccount(String uid) async {
    try {
      // Supprimer le document Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Supprimer l'utilisateur authentifié si c'est le même
      final user = _firebaseAuth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      }

      return {'success': true, 'message': 'Compte supprimé avec succès.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur suppression compte: $e'};
    }
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:rent_house/Services/google_sign_in_wrapper.dart';
import 'package:rent_house/Models/Users.dart' as AppUserModel;

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Notes / checklist for Google OAuth setup
  /// - Android: ensure `google-services.json` is present and SHA-1/SHA-256 fingerprints
  ///   are registered in Firebase console and OAuth client. Add correct package name.
  /// - iOS: ensure `GoogleService-Info.plist` is added and reversed client id is set.
  /// - Web: enable the OAuth client in Firebase console and add authorized domains/origins.
  /// - For web, `signInWithPopup` or `signInWithRedirect` are recommended; mobile uses
  ///   the `google_sign_in` plugin.

  // Compatibilité: expose l'ancien nom attendu par les providers
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Ancien alias utilisé ailleurs
  Stream<firebase_auth.User?> get user => authStateChanges;

  // Obtenir l'utilisateur actuel
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Inscription email/password et création du document Supabase
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

      await _supabase.from('users').insert(appUser.toMap());

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

      final firebase_auth.User? user = userCredential.user;

      if (user != null) {
        final response =
            await _supabase.from('users').select().eq('uid', user.uid);
        if (response.isEmpty) {
          await _supabase.from('users').insert(AppUserModel.User(
                uid: user.uid,
                email: user.email ?? '',
                firstName: user.displayName?.split(' ').first ?? '',
                lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
                createdAt: DateTime.now(),
              ).toMap());
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
      await _supabase.from('users').update(data).eq('uid', uid);
      return 'Profil mis à jour avec succès.';
    } catch (e) {
      return 'Erreur lors de la mise à jour du profil: $e';
    }
  }

  /// Récupérer les données utilisateur en tant que modèle
  Future<AppUserModel.User?> getUserData(String uid) async {
    try {
      final response =
          await _supabase.from('users').select().eq('uid', uid).single();
      return AppUserModel.User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Upload and set a profile image for the current user.
  /// Accepts a File, XFile or Uint8List and stores it in Supabase Storage
  /// under `profiles/<uid>/<timestamp>.jpg`, then updates the user's
  /// `profileImageUrl` in the `users` table and returns the public URL.
  Future<String?> uploadProfileImage(dynamic file) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      final uid = user.uid;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profiles/$uid/$fileName';

      Uint8List bytes;
      if (file is XFile) {
        bytes = await file.readAsBytes();
      } else if (file is String) {
        // path string -> File
        bytes = await File(file).readAsBytes();
      } else if (file is List<int>) {
        bytes = Uint8List.fromList(file);
      } else if (file is Uint8List) {
        bytes = file;
      } else if (file is File) {
        bytes = await file.readAsBytes();
      } else {
        throw UnsupportedError('Unsupported file type: ${file.runtimeType}');
      }

      await _supabase.storage.from('images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = _supabase.storage.from('images').getPublicUrl(filePath);

      // Update user record
      await updateUserProfile(uid, {'profileImageUrl': publicUrl});

      return publicUrl;
    } catch (e) {
      debugPrint('[AuthService] uploadProfileImage failed: $e');
      return null;
    }
  }

  /// Supprimer le compte utilisateur (attend uid) et renvoie Map
  Future<Map<String, dynamic>> deleteAccount(String uid) async {
    try {
      // Supprimer le document Supabase
      await _supabase.from('users').delete().eq('uid', uid);

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

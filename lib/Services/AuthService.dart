import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:rent_house/Services/google_sign_in_wrapper.dart';
import 'package:rent_house/Models/Users.dart' as user_model;
import 'package:firebase_messaging/firebase_messaging.dart';

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
      debugPrint('[AuthService] signUp called for email: $email');
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Échec de la création du compte.'};
      }

      // Inscrire aussi dans Supabase Auth pour la cohérence des IDs et Policies
      try {
          await _supabase.auth.signUp(
            email: email,
            password: password, // Idéalement on ne devrait pas stocker le mdp deux fois, mais ici on synchronise
            // Si le but est une migration, c'est complexe. 
            // Pour l'instant, on se concentre sur la DB 'users'.
            // Mais 'becomeHost' et 'createProperty' utilisent Supabase Auth.
            // Donc il faut un compte Supabase Auth.
          );
      } catch (e) {
          debugPrint('Erreur création compte Supabase Auth (peut-être déjà existant): $e');
      }

      // Insert user profile directly to Supabase
      try {
        debugPrint('[AuthService] inserting user profile to Supabase');
        final userMap = {
          'uid': user.uid, // On garde l'UID Firebase comme clé primaire logique
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'city': city,
          'country': country,
          'bio': bio,
          'role': role,
          'isHost': role == 'owner', // Définit isHost si le rôle est owner
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // On utilise upsert pour éviter les erreurs si existe déjà
        await _supabase.from('users').upsert(userMap);
      } catch (insertEx) {
        debugPrint('[AuthService] Supabase insert error: $insertEx');
        return {
          'success': false,
          'message': 'Erreur création profil Supabase: $insertEx'
        };
      }

      // Set the Firebase user's display name for convenience
      try {
        await user.updateDisplayName('$firstName $lastName');
        await user.reload();
      } catch (e) {
        debugPrint('[AuthService] failed to update displayName: $e');
      }

      // Try to update FCM token separately
      _updateFcmToken(user.uid);

      return {'success': true, 'message': 'Compte créé avec succès.'};
    } catch (e, st) {
      debugPrint('[AuthService] signUp error: $e');
      debugPrint(st.toString());
      return {'success': false, 'message': 'Erreur inscription: $e'};
    }
  }

  /// Connexion email/password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] login called for email: $email');
      // Connexion Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
          
      // Connexion Supabase (pour les tokens d'accès RLS)
      try {
         await _supabase.auth.signInWithPassword(email: email, password: password);
      } catch (e) {
         debugPrint('Erreur connexion Supabase Auth (non critique si RLS désactivé): $e');
      }
      
      // Mettre à jour le token FCM à la connexion
      if (credential.user != null) {
        _updateFcmToken(credential.user!.uid);
      }
          
      return {'success': true, 'message': 'Connexion réussie.'};
    } catch (e, st) {
      debugPrint('[AuthService] login error: $e');
      debugPrint(st.toString());
      return {'success': false, 'message': 'Erreur connexion: $e'};
    }
  }

  /// Helper pour mettre à jour le token FCM
  Future<void> _updateFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _supabase.from('users').update({'fcmToken': token}).eq('uid', uid);
        debugPrint('[AuthService] FCM token updated for user $uid');
      }
    } catch (e) {
      debugPrint('[AuthService] Failed to update FCM token (non-critical): $e');
    }
  }

  /// Connexion Google (retourne Map attendu)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final userCredential = await signInWithGoogleWrapped();

      if (userCredential == null || userCredential.user == null) {
        return {'success': false, 'message': 'Connexion Google annulée.'};
      }

      final firebase_auth.User? user = userCredential.user;

      if (user != null) {
        final response =
            await _supabase.from('users').select().eq('uid', user.uid).maybeSingle();
            
        if (response == null) {
          final userMap = {
            'uid': user.uid,
            'email': user.email ?? '',
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
            'createdAt': DateTime.now().toIso8601String(),
            // Par défaut, Google sign-in crée un compte locataire
          };
          await _supabase.from('users').insert(userMap);
        }
        
        _updateFcmToken(user.uid);
      }

      return {'success': true, 'message': 'Connexion Google réussie.'};
    } catch (e, st) {
      debugPrint('[AuthService] signInWithGoogle error: $e');
      debugPrint(st.toString());
      return {
        'success': false,
        'message': 'Erreur lors de la connexion Google: $e'
      };
    }
  }

  /// Déconnexion (alias logout attendu)
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut(); // Logout Supabase
      if (kIsWeb) {
        await _firebaseAuth.signOut();
        return;
      }
      try {
        await signOutGoogleWrapped();
      } catch (e) {
        debugPrint('[AuthService] signOutGoogleWrapped failed: $e');
      }
      await _firebaseAuth.signOut();
    } catch (e) {
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

  /// Mettre à jour le profil utilisateur
  Future<String> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('uid', uid);
      return 'Profil mis à jour avec succès.';
    } catch (e) {
      return 'Erreur lors de la mise à jour du profil: $e';
    }
  }

  /// Fonction pour devenir hôte (Become Host)
  Future<Map<String, dynamic>> becomeHost() async {
    try {
      // On supporte Supabase Auth et Firebase Auth
      final user = _supabase.auth.currentUser ?? 
          ( _firebaseAuth.currentUser != null 
             ? User(id: _firebaseAuth.currentUser!.uid, appMetadata: {}, userMetadata: {}, aud: '', createdAt: '') // Fake user for ID
             : null
          );
          
      final uid = _supabase.auth.currentUser?.id ?? _firebaseAuth.currentUser?.uid;

      if (uid == null) {
        return {'success': false, 'message': 'Utilisateur non connecté.'};
      }
      
      await _supabase.from('users').update({
        'role': 'owner',
        'isHost': true,
      }).eq('uid', uid);
      
      // Refresh metadata if using Supabase Auth
      if (_supabase.auth.currentUser != null) {
          await _supabase.auth.refreshSession();
      }
      
      return {'success': true, 'message': 'Félicitations ! Vous êtes maintenant bailleur.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur lors de la mise à jour du rôle: $e'};
    }
  }

  /// Récupérer les données utilisateur
  Future<user_model.User?> getUserData(String uid) async {
    try {
      debugPrint('[AuthService] fetching user data for uid: $uid');
      final response =
          await _supabase.from('users').select().eq('uid', uid).maybeSingle();
      
      if (response == null) {
        debugPrint('[AuthService] No user data found for uid: $uid');
        return null;
      }

      final user = user_model.User.fromJson(response);

      final hasActive = await hasActiveSubscription(uid);
      return user.copyWith(hasActiveSubscription: hasActive);
    } catch (e) {
      debugPrint('[AuthService] getUserData error: $e');
      return null;
    }
  }

  /// Check if user has an active subscription
  Future<bool> hasActiveSubscription(String uid) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('userId', uid)
          .eq('status', 'active')
          .gte('endDate', now.toIso8601String());
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Upload and set a profile image for the current user.
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

      bytes = await _compressImage(bytes);

      await _supabase.storage.from('images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = _supabase.storage.from('images').getPublicUrl(filePath);

      await updateUserProfile(uid, {'profileImageUrl': publicUrl});

      return publicUrl;
    } catch (e) {
      debugPrint('[AuthService] uploadProfileImage failed: $e');
      return null;
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes.isEmpty || compressedBytes.length >= bytes.length) {
        if (bytes.length > 500 * 1024) {
          final aggressiveCompress =
              await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 600,
            minHeight: 600,
            quality: 70,
            format: CompressFormat.jpeg,
          );
          if (aggressiveCompress.isNotEmpty &&
              aggressiveCompress.length < bytes.length) {
            return aggressiveCompress;
          }
        }
        return bytes;
      }
      return compressedBytes;
    } catch (e) {
      return bytes;
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String uid) async {
    try {
      await _supabase.from('users').delete().eq('uid', uid);
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

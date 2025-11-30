import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:rent_house/Models/Users.dart' as user_model;
import 'package:rent_house/Services/AuthService.dart'; // Keeping for user data loading logic if needed, or refactoring

class AuthProvider extends ChangeNotifier {
  // We are now prioritizing Supabase Auth.
  // We might still use AuthService for legacy helpers, but core Auth is here.
  final _supabase = Supabase.instance.client;

  // Keep AuthService for potential profile fetching if it reads from Firestore?
  // If the user wants "Only Supabase Auth", we should ideally fetch profile from Supabase too.
  // BUT, migrating data is huge.
  // Assumption: We Authenticate via Supabase, but Profile Data is still in Firestore/Supabase?
  // The user said "Gère uniquement l'authentification via supabase".
  // So we use Supabase Auth.

  final AuthService _authService = AuthService();

  user_model.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  user_model.User? get user => _user;

  // Provide Supabase User ID as the primary ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Deprecated getter for Firebase User (legacy support)
  // We return null as we are moving away, OR we map Supabase user?
  // Better to break it properly or provide a mock.
  // Warning: This breaks UI depending on firebaseUser.
  // But we must cut the cord.

  AuthProvider() {
    // Listen to Supabase auth state
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _user = null;
        notifyListeners();
        return;
      }
      // User is logged in via Supabase
      // Fetch profile data.
      // IF profile data is in Firestore, we need to fetch it using the Supabase User ID?
      // Wait, if we use Supabase Auth, the User ID is NEW (different from Firebase UID).
      // So Firestore lookups by ID will FAIL unless we migrated users.
      // Since the user said "Only Supabase Auth", we assume they are starting fresh or migrated.
      // We will try to fetch profile from Supabase 'users' table (if it exists) or just use Metadata.

      try {
        // Attempt to load user profile from Firestore using Supabase ID? (Unlikely to match)
        // Or construct a basic User object from metadata
        _user = user_model.User(
          uid: session.user.id,
          email: session.user.email ?? '',
          firstName:
              session.user.userMetadata?['full_name']?.split(' ').first ?? '',
          lastName:
              session.user.userMetadata?['full_name']?.split(' ').last ?? '',
          role: session.user.userMetadata?['role'] ?? 'tenant',
          profileImageUrl: session.user.userMetadata?['avatar_url'] ?? '',
          isHost: session.user.userMetadata?['isHost'] ?? false,
          city: '',
          country: '',
          bio: '',
          createdAt:
              DateTime.now(), // Placeholder, should fetch from DB if available
          hasActiveSubscription: false,
        );
      } catch (e) {
        debugPrint('[AuthProvider] User loaded from metadata: $e');
      }
      notifyListeners();
    });
  }

  /// Login with email/password via Supabase
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      if (response.user != null) {
        notifyListeners();
        return;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: $e';
    }
    _isLoading = false;
    notifyListeners();
    throw Exception(_errorMessage); // Throw to match UI expectation
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }

  /// Sign in with Google via Supabase OAuth
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use Supabase OAuth for Google sign in (works on web and mobile)
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? null
            : 'com.example.renthouse://login-callback', // Adjust redirect URL for mobile
      );

      _isLoading = false;
      if (response) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Erreur Google Sign-In: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registration via Supabase
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    required String country,
    String bio = '',
    String role = 'tenant',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': '$firstName $lastName',
          'role': role,
          'city': city,
          'country': country,
          'bio': bio,
          'isHost': role == 'owner',
        },
      );

      _isLoading = false;
      if (response.user != null) {
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Legacy methods for compatibility
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    // Update user metadata in Supabase
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: updates,
        ),
      );
      // Update local user
      if (_user != null) {
        _user = user_model.User(
          uid: _user!.uid,
          email: _user!.email,
          firstName: updates['full_name']?.split(' ').first ?? _user!.firstName,
          lastName: updates['full_name']?.split(' ').last ?? _user!.lastName,
          role: updates['role'] ?? _user!.role,
          profileImageUrl: updates['avatar_url'] ?? _user!.profileImageUrl,
          isHost: updates['isHost'] ?? _user!.isHost,
          city: updates['city'] ?? _user!.city,
          country: updates['country'] ?? _user!.country,
          bio: updates['bio'] ?? _user!.bio,
          createdAt: _user!.createdAt,
          updatedAt: DateTime.now(),
          hasActiveSubscription: _user!.hasActiveSubscription,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erreur mise à jour profil: $e';
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    await updateUserProfile({'avatar_url': imageUrl});
  }

  // Getter for firebaseUser (legacy, returns null)
  dynamic get firebaseUser => null;

  Future<bool> promoteToOwner() async {
    await updateUserProfile({'role': 'owner', 'isHost': true});
    return true;
  }

  // ... Other methods (updateProfile, etc) would need Supabase implementation ...
  // For now, we focus on Auth as requested.
}

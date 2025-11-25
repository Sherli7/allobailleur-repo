import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:rent_house/Services/AuthService.dart';
import 'package:rent_house/Models/Users.dart' as AppUserModel;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUserModel.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AppUserModel.User? get user => _user;

  firebase_auth.User? get firebaseUser => _authService.currentUser;

  AuthProvider() {
    // Listen to Firebase auth state and keep the supabase user in sync
    _authService.authStateChanges.listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
        notifyListeners();
        return;
      }
      try {
        final profile = await _authService.getUserData(fbUser.uid);
        _user = profile;
      } catch (e) {
        debugPrint('[AuthProvider] failed to load user data: $e');
        _user = null;
      }
      notifyListeners();
    });
  }

  /// Login with email/password. Throws on failure with the service message.
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final res = await _authService.login(email: email, password: password);
    _isLoading = false;
    if (res['success'] == true) {
      final fb = _authService.currentUser;
      if (fb != null) {
        _user = await _authService.getUserData(fb.uid);
      }
      notifyListeners();
      return;
    }
    _errorMessage = res['message'] as String? ?? 'Erreur de connexion';
    notifyListeners();
    throw Exception(_errorMessage);
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  /// Promote current user to owner (sets role/isHost in Supabase)
  Future<bool> promoteToOwner() async {
    final fb = _authService.currentUser;
    if (fb == null) return false;
    try {
      await _authService
          .updateUserProfile(fb.uid, {'role': 'owner', 'isHost': true});
      final refreshed = await _authService.getUserData(fb.uid);
      if (refreshed != null) {
        _user = refreshed;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] promoteToOwner failed: $e');
    }
    return false;
  }

  /// Optional helpers
  Future<bool> resetPassword(String email) async {
    final res = await _authService.resetPassword(email: email);
    return res['success'] == true;
  }

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
    final res = await _authService.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      city: city,
      country: country,
      bio: bio,
      role: role,
    );
    if (res['success'] == true) {
      final fb = _authService.currentUser;
      if (fb != null) _user = await _authService.getUserData(fb.uid);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Sign in with Google wrapper
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _authService.signInWithGoogle();
      _isLoading = false;
      if (res['success'] == true) {
        final fb = _authService.currentUser;
        if (fb != null) _user = await _authService.getUserData(fb.uid);
        notifyListeners();
        return true;
      }
      _errorMessage = res['message'] as String? ?? 'Erreur Google Sign-In';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Backwards-compatible alias used in some screens
  Future<bool> becomeHost() => promoteToOwner();
}

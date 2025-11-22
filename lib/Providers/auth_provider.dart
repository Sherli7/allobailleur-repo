import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:rent_house/Models/Users.dart';
import 'package:rent_house/Services/AuthService.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  auth.User? _firebaseUser;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  auth.User? get firebaseUser => _firebaseUser;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialiser l'authentification
  void _initializeAuth() {
    _authService.authStateChanges.listen((auth.User? firebaseUser) async {
      _firebaseUser = firebaseUser;
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  /// Inscription
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

    final result = await _authService.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      city: city,
      country: country,
      bio: bio,
      role: role,
    );

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();

    return result['success'];
  }

  /// Connexion
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
    );

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();

    return result['success'];
  }

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signInWithGoogle();

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();

    return result['success'];
  }

  /// Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    _firebaseUser = null;
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Réinitialiser le mot de passe
  Future<bool> resetPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.resetPassword(email: email);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();

    return result['success'];
  }

  /// Mettre à jour le profil (Corrigé)
  Future<bool> updateUserProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(
        _firebaseUser!.uid,
        updatedUser.toFirestore(), // Convertir l'objet User en Map
      );
      _user = updatedUser; // Mettre à jour l'état local en cas de succès
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          "Une erreur est survenue lors de la mise à jour du profil: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Devenir hôte
  Future<bool> becomeHost() async {
    if (_user == null) return false;

    return updateUserProfile(_user!.copyWith(isHost: true));
  }

  /// Promouvoir l'utilisateur au rôle 'owner' (propriétaire)
  Future<bool> promoteToOwner() async {
    if (_user == null || _firebaseUser == null) return false;

    final updated = _user!.copyWith(role: 'owner');
    final success = await updateUserProfile(updated);
    if (success) {
      _user = updated;
      notifyListeners();
    }
    return success;
  }

  /// Supprimer le compte (Corrigé)
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_firebaseUser == null) {
      _errorMessage = "Aucun utilisateur à supprimer.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final result = await _authService.deleteAccount(_firebaseUser!.uid);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    } else {
      // Si la suppression réussit, l'état de l'auth changera via le stream,
      // donc pas besoin de mettre _user et _firebaseUser à null ici.
    }
    notifyListeners();

    return result['success'];
  }

  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

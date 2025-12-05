import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:rent_house/Models/Users.dart' as user_model;
import 'package:cross_file/cross_file.dart';

class AuthProvider extends ChangeNotifier {
  // We are now prioritizing Supabase Auth.
  final _supabase = Supabase.instance.client;

  user_model.User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  user_model.User? get user => _user;

  // Provide Supabase User ID as the primary ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Ensure `currentUserId` is not null before using it in queries
  String get safeCurrentUserId => currentUserId ?? '';

  AuthProvider() {
    // Listen to Supabase auth state
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _user = null;
        notifyListeners();
        return;
      }

      try {
        // Construct a basic User object from metadata
        _user = user_model.User(
          uid: session.user.id,
          id: session.user.id, // Add the required 'id' argument
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
          createdAt: DateTime.now(),
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
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // On success, the onAuthStateChange listener will handle user state.
    } on AuthException catch (e) {
      _errorMessage = e.message;
      throw Exception(_errorMessage); // Rethrow for the UI
    } catch (e) {
      _errorMessage = 'Erreur inattendue: $e';
      throw Exception(_errorMessage); // Rethrow for the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.renthouse://login-callback',
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

  /// Fetch user profile from Supabase
  Future<void> fetchUserProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('users')
          .select()
          .eq(
            'id',
            safeCurrentUserId,
          ) // Use safeCurrentUserId to avoid null issues
          .single();

      if (response != null) {
        _user = user_model.User(
          uid: response['id'],
          id: response['id'],
          email: response['email'],
          firstName: response['first_name'],
          lastName: response['last_name'],
          profilePicture: response['profile_picture'],
          profileImageUrl: response['profile_picture'] ?? '',
          role: response['role'],
          city: response['city'],
          country: response['country'],
          bio: response['bio'],
          createdAt: DateTime.parse(response['created_at']),
          updatedAt: response['updated_at'] != null
              ? DateTime.parse(response['updated_at'])
              : null,
          isHost: response['is_host'],
          hasActiveSubscription: response['has_active_subscription'],
          isVerified: response['is_verified'],
          kycStatus: response['kyc_status'],
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch user profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Legacy methods for compatibility
  Future<void> updateUserProfile({
    String? fullName,
    String? email,
    String? city,
    String? country,
    String? bio,
    String? avatarUrl,
    String? role,
    bool? isHost,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (email != null) updates['email'] = email;
    if (city != null) updates['city'] = city;
    if (country != null) updates['country'] = country;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (role != null) updates['role'] = role;
    if (isHost != null) updates['isHost'] = isHost;

    try {
      await _supabase.auth.updateUser(
        UserAttributes(email: email, data: updates),
      );
      if (_user != null) {
        _user = user_model.User(
          uid: _user!.uid,
          id: _user!.uid, // Add the required 'id' argument
          email: email ?? _user!.email,
          firstName: fullName?.split(' ').first ?? _user!.firstName,
          lastName: fullName?.split(' ').last ?? _user!.lastName,
          role: role ?? _user!.role,
          profileImageUrl: avatarUrl ?? _user!.profileImageUrl,
          isHost: isHost ?? _user!.isHost,
          city: city ?? _user!.city,
          country: country ?? _user!.country,
          bio: bio ?? _user!.bio,
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

  Future<bool> updateProfileImage(dynamic pickedFile) async {
    try {
      late Uint8List fileBytes;
      String fileName;

      if (pickedFile is XFile) {
        fileBytes = await pickedFile.readAsBytes();
        fileName = pickedFile.name;
      } else {
        throw 'Unsupported file type';
      }

      final userId = currentUserId;
      if (userId == null) throw 'User not logged in';

      final filePath = 'avatars/$userId/$fileName';
      await _supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = _supabase.storage.from('images').getPublicUrl(filePath);

      await updateUserProfile(avatarUrl: imageUrl);
      return true;
    } catch (e) {
      _errorMessage = 'Erreur upload image: $e';
      notifyListeners();
      return false;
    }
  }

  dynamic get firebaseUser => null;

  Future<bool> promoteToOwner() async {
    await updateUserProfile(role: 'owner', isHost: true);
    return true;
  }

  Future<bool> becomeHost() async {
    await updateUserProfile(isHost: true);
    return true;
  }
}

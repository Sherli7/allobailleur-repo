import 'package:firebase_auth/firebase_auth.dart';

// Temporary stub implementation for mobile Google Sign-In wrapper.
// Returning `null` here means Google sign-in will be treated as "cancelled".
// This keeps the project compiling while we reintroduce a proper mobile
// implementation later (matching the installed `google_sign_in` version).
Future<UserCredential?> signInWithGoogleWrapped() async {
  return null;
}

Future<void> signOutGoogleWrapped() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}
}

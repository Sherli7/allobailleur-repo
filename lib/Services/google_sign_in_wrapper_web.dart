import 'package:firebase_auth/firebase_auth.dart';

/// Web implementation using FirebaseAuth JS interop (`signInWithPopup`).
/// Returns a [UserCredential] on success.
Future<UserCredential?> signInWithGoogleWrapped() async {
  final provider = GoogleAuthProvider();
  return await FirebaseAuth.instance.signInWithPopup(provider);
}

Future<void> signOutGoogleWrapped() async {
  await FirebaseAuth.instance.signOut();
}

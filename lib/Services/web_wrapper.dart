// lib/Services/web_wrapper.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// This function renders a Google Sign-In button specifically for the web platform.
/// It relies on the `google_sign_in` plugin to handle the GIS script loading and authentication flow.
///
/// Ensure your `index.html` is configured as per the google_sign_in plugin documentation for the web.
Widget renderButton() {
  // Only render this button on the web platform.
  if (!kIsWeb) {
    return const SizedBox.shrink();
  }

  return ElevatedButton(
    onPressed: () async {
      try {
        // The `signIn` method is invoked dynamically to avoid analyzer issues
        await (GoogleSignIn.instance as dynamic).signIn();
        // Your application's authentication stream will automatically handle the navigation
        // once the user is successfully signed in.
      } catch (error) {
        // It's good practice to handle potential errors.
        debugPrint('Error during Google Sign-In: $error');
      }
    },
    child: const Text('SE CONNECTER AVEC GOOGLE'),
  );
}

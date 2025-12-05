import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50), // Vert principal
      brightness: Brightness.light,
      primary: const Color(0xFF4CAF50),
      secondary: const Color(0xFFFFC107), // Ambre
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[50],
      foregroundColor: Colors.black87,
      elevation: 0.5,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    cardTheme: const CardThemeData(
      // Corrected type to CardThemeData
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50), // Vert principal
      brightness: Brightness.dark,
      primary: const Color(0xFF66BB6A), // Vert plus clair pour le mode sombre
      secondary: const Color(0xFFFFCA28), // Ambre plus clair
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

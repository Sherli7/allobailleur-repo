import 'package:flutter/material.dart';

class AppColors {
  // Couleurs primaires
  static const Color primary = Color(0xFF004D40); // Vert Foncé
  static const Color secondary = Color(0xFF26A69A); // Vert Turquoise

  // Couleurs neutres
  static const Color neutral = Color(0xFFE1F5FE); // Bleu Clair
  static const Color accentPositive = Color(0xFFFFF9C4); // Jaune Clair
  static const Color accentDynamic = Color(0xFFFF8F00); // Orange

  // Couleurs de base
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF757575);

  // Variations (atténuées de 20%)
  static const Color primaryHover = Color(0xFF00695C); // 20% plus foncé
  static const Color secondaryHover = Color(0xFF4DB6AC); // 20% plus clair
  static const Color neutralHover = Color(0xFFB3E5FC); // 20% plus foncé
  static const Color accentPositiveHover = Color(0xFFFFF59D); // 20% plus foncé
  static const Color accentDynamicHover = Color(0xFFFFA726); // 20% plus clair

  // États disabled (50% d'opacité)
  static const Color primaryDisabled = Color(0x80004D40);
  static const Color secondaryDisabled = Color(0x8026A69A);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Couleurs principales
      primaryColor: AppColors.primary,
      secondaryHeaderColor: AppColors.secondary,

      // ColorScheme Material 3
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.neutral,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.accentPositive,
        onSecondaryContainer: AppColors.secondary,
        tertiary: AppColors.accentDynamic,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.accentPositive,
        onTertiaryContainer: AppColors.accentDynamic,
        error: Colors.red,
        onError: AppColors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: AppColors.white,
        onSurface: AppColors.grey,
        surfaceContainerHighest: AppColors.neutral,
        onSurfaceVariant: AppColors.grey,
        outline: AppColors.grey,
        outlineVariant: Color(0xFFC4C7C5),
        inverseSurface: AppColors.primary,
        onInverseSurface: AppColors.white,
        inversePrimary: AppColors.secondary,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      ),

      // Typographie
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: AppColors.primary,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.primary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: AppColors.primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: AppColors.primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: AppColors.grey,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: AppColors.grey,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: AppColors.grey,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: AppColors.secondary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.secondary,
        ),
      ),

      // Composants Material 3
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: const BorderSide(color: AppColors.secondary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.white,
        shadowColor: AppColors.primary.withValues(alpha: 0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: AppColors.grey.withValues(alpha: 0.5), width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.grey,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: AppColors.grey.withValues(alpha: 0.7),
          fontSize: 16,
        ),
      ),

      // Animations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ColorScheme sombre
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondary, // Inversé pour sombre
        onPrimary: AppColors.primary,
        primaryContainer: AppColors.primary,
        onPrimaryContainer: AppColors.white,

        secondary: AppColors.accentDynamic,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.primary,
        onSecondaryContainer: AppColors.white,

        tertiary: AppColors.accentPositive,
        onTertiary: AppColors.primary,
        tertiaryContainer: AppColors.neutral,
        onTertiaryContainer: AppColors.primary,

        error: Colors.red,
        onError: AppColors.white,
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),

        surface: AppColors.primary,
        onSurface: AppColors.white,
        surfaceContainerHighest: AppColors.primaryHover,
        onSurfaceVariant: AppColors.white,

        outline: AppColors.grey,
        outlineVariant: Color(0xFF8E918F),

        inverseSurface: AppColors.white,
        onInverseSurface: AppColors.primary,
        inversePrimary: AppColors.secondary,

        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      ),

      // Typographie sombre (même structure)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: AppColors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.white,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: AppColors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: AppColors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: AppColors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: AppColors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: AppColors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: AppColors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: AppColors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: AppColors.secondary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.secondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: AppColors.secondary,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardThemeData(
        color: AppColors.primaryHover,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Animations utilitaires
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration staggered = Duration(milliseconds: 400);

  static const Curve easeInOut = Curves.easeInOut;

  // Animation de fade in
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeInOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation de slide up
  static Widget slideUp({
    required Widget child,
    Duration duration = normal,
    Curve curve = easeInOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation scale & pulse
  static Widget scalePulse({
    required Widget child,
    Duration duration = fast,
    Curve curve = easeInOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.05),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation color shift
  static Widget colorShift({
    required Widget child,
    required Color fromColor,
    required Color toColor,
    Duration duration = slow,
    Curve curve = easeInOut,
  }) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: fromColor, end: toColor),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(value ?? fromColor, BlendMode.srcIn),
          child: child,
        );
      },
      child: child,
    );
  }

  // Animation staggered entry pour les listes
  static Widget staggeredList({
    required List<Widget> children,
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration:
              Duration(milliseconds: staggered.inMilliseconds + (index * 100)),
          curve: easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }
}

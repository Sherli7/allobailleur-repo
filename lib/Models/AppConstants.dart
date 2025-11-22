import 'package:flutter/material.dart';

class AppConstants {
  // Méthode utilitaire (pour runtime, non-const)
  static Color toColor(String color) {
    final buffer = StringBuffer();
    if (color.length == 6 || color.length == 7) buffer.write('ff');
    buffer.write(color.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static const String googleMapsAPIKey = "AIzaSyA9N4US-35zEuRemX0ppXCRtSsOiHgG5T0";
  static const String appName = 'Allô Bailleur';

  // Couleurs const pré-calculées (0xff + hex pour opacité pleine)
  static const Color selectedIconColor = Color(0xfff95738);
  static const Color nonselectedIconColor = Color(0xff0a0908);
  static const Color ratingStarColor = Color(0xfffb5607); // Pour les étoiles du rating

  static const Map<int, String> monthDict = {
    1: "Janvier",
    2: "Février",
    3: "Mars",
    4: "Avril",
    5: "Mai",
    6: "Juin",
    7: "Juillet",
    8: "Août",
    9: "Septembre",
    10: "Octobre",
    11: "Novembre",
    12: "Décembre",
  };

  static final Map<int, int> daysInMonths = {
    1: 31,
    2: DateTime.now().year % 4 == 0 ? 29 : 28,
    3: 31,  // Corrigez si besoin
    4: 30,
    5: 31,
    6: 30,
    7: 31,
    8: 31,
    9: 30,
    10: 31,
    11: 30,
    12: 31,
  };
}
import 'package:flutter/material.dart';

class AppConstants {
  static Color toColor(String color) {
    final buffer = StringBuffer();
    if (color.length == 6 || color.length == 7) buffer.write('ff');
    buffer.write(color.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static const String googleMapsAPIKey = "AIzaSyA9N4US-35zEuRemX0ppXCRtSsOiHgG5T0";
  static const String appName = 'Allô Bailleur';
  static final Color selectedIconColor = toColor('f95738');
  static final Color nonselectedIconColor = toColor('0a0908');
}

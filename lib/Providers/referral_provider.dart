import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../Models/property.dart';

class ReferralProvider with ChangeNotifier {
  Future<bool> referProperty(Property property, String email) async {
    final subject = 'Référencement de bien immobilier: ${property.title}';
    final body = '''
Bonjour,

Je vous recommande ce bien immobilier :

Titre: ${property.title}
Prix: ${property.price} FCFA/mois
Ville: ${property.city}
Description: ${property.description}

Cordialement,
    ''';

    try {
      await Share.share('$subject\n\n$body');
      return true;
    } catch (e) {
      debugPrint('Error sharing property: $e');
      return false;
    }
  }
}

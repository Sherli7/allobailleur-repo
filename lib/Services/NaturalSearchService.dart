import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../Models/property.dart';

class NaturalSearchService {
  final SupabaseClient _supabase;

  NaturalSearchService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Parse la requête textuelle et retourne les filtres
  Map<String, dynamic> parseQuery(String query) {
    final normalizedQuery = query.toLowerCase();
    final filters = <String, dynamic>{};

    // 1. Extraction des Chambres
    final bedroomRegex = RegExp(r'(\d+)\s*(?:chambres?|pièces?|chb)');
    final bedroomMatch = bedroomRegex.firstMatch(normalizedQuery);
    if (bedroomMatch != null) {
      filters['rooms'] = int.parse(bedroomMatch.group(1)!);
    }

    // 2. Extraction des Salles de bain
    final bathroomRegex = RegExp(r'(\d+)\s*(?:salle?s? de bains?|sdb|douches?)');
    final bathroomMatch = bathroomRegex.firstMatch(normalizedQuery);
    if (bathroomMatch != null) {
      filters['bathrooms'] = int.parse(bathroomMatch.group(1)!);
    }

    // 3. Extraction du Prix
    final priceRegex = RegExp(r'(\d+)\s*(?:fcfa|frs|xaf)?\s*(?:max|maximum|minimum|min)?');
    final priceMatches = priceRegex.allMatches(normalizedQuery);
    for (var match in priceMatches) {
      final number = int.parse(match.group(1)!);
      final context = normalizedQuery.substring(
        (match.start - 10).clamp(0, match.start),
        (match.end + 10).clamp(match.end, normalizedQuery.length)
      );
      
      if (context.contains('min') || context.contains('plus de') || context.contains('>')) {
        filters['min_price'] = number;
      } else if (context.contains('max') || context.contains('moins de') || context.contains('<')) {
        filters['max_price'] = number;
      } else {
         filters['max_price'] = number; 
      }
    }

    // 4. Extraction de la Superficie
    final surfaceRegex = RegExp(r'(\d+)\s*(?:m2|m²|mètres carrés?)');
    final surfaceMatch = surfaceRegex.firstMatch(normalizedQuery);
    if (surfaceMatch != null) {
       filters['min_surface'] = int.parse(surfaceMatch.group(1)!);
    }

    // 5. Détection Géolocalisation "Proche de moi"
    if (normalizedQuery.contains('proche') || 
        normalizedQuery.contains('près de moi') || 
        normalizedQuery.contains('autour de moi') ||
        normalizedQuery.contains('à proximité')) {
      filters['near_me'] = true;
    }

    // 6. Extraction des Villes/Quartiers (si pas "proche de moi")
    if (!filters.containsKey('near_me')) {
      final cities = ['yaoundé', 'douala', 'bafoussam', 'garoua', 'kribi', 'mendong', 'bastos', 'odza', 'biyem-assi', 'ekounou'];
      for (var city in cities) {
        if (normalizedQuery.contains(city)) {
          filters['city_contains'] = city;
          break;
        }
      }
    }

    // 7. Extraction du Type de bien
    if (normalizedQuery.contains('studio')) filters['type'] = 'studio';
    else if (normalizedQuery.contains('appartement')) filters['type'] = 'apartment';
    else if (normalizedQuery.contains('maison') || normalizedQuery.contains('villa')) filters['type'] = 'house';
    else if (normalizedQuery.contains('chambre')) filters['type'] = 'room';
    else if (normalizedQuery.contains('bureau')) filters['type'] = 'office';

    // 8. Extraction du Standing / Style
    if (normalizedQuery.contains('haut standing') || normalizedQuery.contains('luxe')) {
      filters['style'] = 'haut_standing';
    } else if (normalizedQuery.contains('moderne')) {
      filters['style'] = 'modern';
    } else if (normalizedQuery.contains('meublé')) {
      filters['style'] = 'meuble';
    }

    // 9. Extraction des Équipements (Amenities)
    if (normalizedQuery.contains('wifi')) filters['amenity_wifi'] = true;
    if (normalizedQuery.contains('parking')) filters['amenity_parking'] = true;
    if (normalizedQuery.contains('piscine') || normalizedQuery.contains('pool')) filters['amenity_pool'] = true;
    if (normalizedQuery.contains('clim') || normalizedQuery.contains('ac')) filters['amenity_ac'] = true;
    if (normalizedQuery.contains('cuisine') || normalizedQuery.contains('kitchen')) filters['amenity_kitchen'] = true;

    // 10. Extraction des Conditions Spécifiques
    if (normalizedQuery.contains('prépayé') || normalizedQuery.contains('prepaid')) filters['power_type'] = 'prepaid';
    if (normalizedQuery.contains('forage')) filters['water_supplier'] = 'forage';
    if (normalizedQuery.contains('camwater')) filters['water_supplier'] = 'camwater';
    if (normalizedQuery.contains('pas de caution') || normalizedQuery.contains('sans caution')) filters['no_deposit'] = true;

    return filters;
  }

  /// Exécute la recherche basée sur le texte naturel
  Future<List<Property>> searchProperties(String naturalQuery) async {
    try {
      final filters = parseQuery(naturalQuery);
      // Correction: "isAvailable" (avec guillemets pour respecter la casse si la colonne a été créée avec des guillemets dans Postgres)
      // ou tout en minuscule si c'est standard. Dans seed_data.sql, c'est "isAvailable".
      // Supabase Postgrest est sensible à la casse pour les colonnes entre guillemets.
      // Essayons avec la notation exacte de la base de données.
      var query = _supabase.from('properties').select().eq('"isAvailable"', true);

      // Application des filtres basiques
      if (filters.containsKey('rooms')) query = query.gte('bedrooms', filters['rooms']);
      if (filters.containsKey('bathrooms')) query = query.gte('bathrooms', filters['bathrooms']);
      if (filters.containsKey('min_price')) query = query.gte('price', filters['min_price']);
      if (filters.containsKey('max_price')) query = query.lte('price', filters['max_price']);
      if (filters.containsKey('min_surface')) query = query.gte('surface', filters['min_surface']);
      if (filters.containsKey('type')) query = query.eq('type', filters['type']);
      
      // Filtre de style / standing
      if (filters.containsKey('style')) {
        final styleTerm = filters['style'];
        // Recherche dans le champ style structuré ou dans la description
        query = query.or('style.eq.$styleTerm,description.ilike.%${naturalQuery.contains('haut standing') ? 'haut standing' : styleTerm}%');
      }

      // Filtre sur les équipements (Amenities)
      // Note: Supabase Postgres permet de filtrer les tableaux JSONB ou text[] avec .cs (contains)
      // On suppose ici que 'amenities' est un tableau de texte
      if (filters.containsKey('amenity_wifi')) query = query.contains('amenities', ['wifi']);
      if (filters.containsKey('amenity_parking')) query = query.contains('amenities', ['parking']);
      if (filters.containsKey('amenity_pool')) query = query.contains('amenities', ['pool']);
      if (filters.containsKey('amenity_ac')) query = query.contains('amenities', ['ac']);
      if (filters.containsKey('amenity_kitchen')) query = query.contains('amenities', ['kitchen']);

      // Filtres spécifiques (Conditions)
      if (filters.containsKey('power_type')) {
         query = query.eq('"powerType"', filters['power_type']);
      }
      if (filters.containsKey('water_supplier')) {
         query = query.eq('"waterSupplier"', filters['water_supplier']);
      }
       if (filters.containsKey('no_deposit')) {
         query = query.eq('"furnishedNoDeposit"', true);
      }

      // Filtre géographique textuel (Ville)
      if (filters.containsKey('city_contains')) {
        final term = filters['city_contains'];
        query = query.or('city.ilike.%$term%,district.ilike.%$term%,address.ilike.%$term%');
      }

      // Exécution de la requête
      final response = await query;
      final List<dynamic> data = response as List<dynamic>;
      var properties = data.map((json) => Property.fromJson(json)).toList();

      // Traitement Géolocalisation "Proche de moi"
      if (filters.containsKey('near_me') && filters['near_me'] == true) {
        final position = await _determinePosition();
        if (position != null) {
          // Calcul de la distance pour chaque propriété
          for (var prop in properties) {
            prop.distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              prop.latitude,
              prop.longitude,
            );
          }
          
          // Tri par distance croissante
          properties.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
          
          // Optionnel : Ne garder que les biens dans un rayon de 20km ?
          // properties = properties.where((p) => (p.distance ?? 0) < 20000).toList();
        }
      }

      return properties;

    } catch (e) {
      print('Erreur recherche naturelle: $e');
      return [];
    }
  }

  /// Récupère la position actuelle de l'utilisateur avec gestion des permissions
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Les services de localisation sont désactivés.
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }
}

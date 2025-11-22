import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String type; // 'studio', 'apartment', 'house', 'room', 'office'
  final String city;
  final String? district; // quartier
  final String? address; // adresse complète
  final String country;
  final double price;
  final String currency; // 'XAF', 'EUR', etc.
  final double? surface; // surface en m²
  final int rooms; // Renommé de bedrooms
  final int bathrooms;
  final int? balconies;
  final int? leaseMonths; // durée minimale en mois (ex: 12)
  final double? deposit; // montant de la caution
  final String? powerType; // 'prepaid' or 'normal'
  final String? waterSupplier; // 'camwater' or 'forage' or other
  final String? furnishedPeriodUnit; // 'day','week','month','year' pour meublé
  final bool? furnishedNoDeposit; // si le meublé n'a pas de caution
  final String? listingPurpose; // 'rent' or 'sale'
  final String?
      style; // pour studio/apartment: e.g. 'simple','modern','meublé','haut_standing'
  final Map<String, dynamic>? conditions; // caution, charges, durée min, etc.
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final List<String> amenities;
  final double latitude;
  final double longitude;
  final String status; // 'draft', 'published', 'disabled', 'rented'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;

  // Champs non-persistants
  bool isNew;
  double? distance;

  // Compatibilité: alias pour les anciens noms utilisés dans l'UI
  int get bedrooms => rooms;
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls[0] : null;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.city,
    this.district,
    this.address,
    required this.country,
    required this.price,
    this.currency = 'XAF',
    this.surface,
    int? rooms,
    int? bedrooms,
    required this.bathrooms,
    this.balconies,
    this.leaseMonths,
    this.deposit,
    this.powerType,
    this.waterSupplier,
    this.furnishedPeriodUnit,
    this.furnishedNoDeposit,
    this.listingPurpose,
    this.style,
    this.conditions,
    required this.rating,
    required this.reviewCount,
    required this.imageUrls,
    required this.amenities,
    required this.latitude,
    required this.longitude,
    this.status = 'published',
    required this.createdAt,
    required this.updatedAt,
    required this.isAvailable,
    this.isNew = false, // Valeur par défaut
    this.distance, // Optionnel
  }) : rooms = rooms ?? bedrooms ?? 0;

  factory Property.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Property(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'apartment',
      city: data['city'] ?? '',
      district: data['district'],
      address: data['address'],
      country: data['country'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'XAF',
      surface: (data['surface'] as num?)?.toDouble(),
      rooms: data['bedrooms'] ?? 0, // Lecture depuis 'bedrooms'
      bathrooms: data['bathrooms'] ?? 0,
      balconies: data['balconies'] ?? (data['conditions']?['balconies']),
      leaseMonths: data['leaseMonths'] ?? (data['conditions']?['leaseMonths']),
      deposit: (data['deposit'] as num?)?.toDouble() ??
          (data['conditions']?['deposit'] as num?)?.toDouble(),
      powerType: data['powerType'] ?? (data['conditions']?['powerType']),
      waterSupplier:
          data['waterSupplier'] ?? (data['conditions']?['waterSupplier']),
      furnishedPeriodUnit: data['furnishedPeriodUnit'] ??
          (data['conditions']?['furnishedPeriodUnit']),
      furnishedNoDeposit: data['furnishedNoDeposit'] ??
          (data['conditions']?['furnishedNoDeposit']),
      listingPurpose: data['listingPurpose'] ??
          (data['conditions']?['listingPurpose']) ??
          'rent',
      style: data['style'] ?? (data['conditions']?['style']),
      conditions: data['conditions'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'published',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'city': city,
      'district': district,
      'address': address,
      'country': country,
      'price': price,
      'currency': currency,
      'surface': surface,
      'bedrooms': rooms, // Écriture vers 'bedrooms'
      'bathrooms': bathrooms,
      'balconies': balconies,
      'leaseMonths': leaseMonths,
      'deposit': deposit,
      'powerType': powerType,
      'waterSupplier': waterSupplier,
      'furnishedPeriodUnit': furnishedPeriodUnit,
      'furnishedNoDeposit': furnishedNoDeposit,
      'listingPurpose': listingPurpose,
      'style': style,
      'conditions': conditions,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrls': imageUrls,
      'amenities': amenities,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
    };
  }

  Property copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    String? type,
    String? city,
    String? district,
    String? address,
    String? country,
    double? price,
    String? currency,
    double? surface,
    int? rooms,
    int? bathrooms,
    int? balconies,
    int? leaseMonths,
    double? deposit,
    String? powerType,
    String? waterSupplier,
    String? furnishedPeriodUnit,
    bool? furnishedNoDeposit,
    String? listingPurpose,
    String? style,
    Map<String, dynamic>? conditions,
    double? rating,
    int? reviewCount,
    List<String>? imageUrls,
    List<String>? amenities,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isNew,
    double? distance,
  }) {
    return Property(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      city: city ?? this.city,
      district: district ?? this.district,
      address: address ?? this.address,
      country: country ?? this.country,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      surface: surface ?? this.surface,
      rooms: rooms ?? this.rooms,
      bathrooms: bathrooms ?? this.bathrooms,
      balconies: balconies ?? this.balconies,
      leaseMonths: leaseMonths ?? this.leaseMonths,
      deposit: deposit ?? this.deposit,
      powerType: powerType ?? this.powerType,
      waterSupplier: waterSupplier ?? this.waterSupplier,
      furnishedPeriodUnit: furnishedPeriodUnit ?? this.furnishedPeriodUnit,
      furnishedNoDeposit: furnishedNoDeposit ?? this.furnishedNoDeposit,
      listingPurpose: listingPurpose ?? this.listingPurpose,
      style: style ?? this.style,
      conditions: conditions ?? this.conditions,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrls: imageUrls ?? this.imageUrls,
      amenities: amenities ?? this.amenities,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isNew: isNew ?? this.isNew,
      distance: distance ?? this.distance,
    );
  }
}

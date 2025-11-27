import 'dart:convert';

class User {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'tenant' | 'owner' | 'admin'
  final String profileImageUrl;
  final bool isHost;
  final String? city;
  final String? country;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasActiveSubscription; // Pour les hôtes

  User({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'tenant',
    this.profileImageUrl = '',
    this.isHost = false,
    this.city,
    this.country,
    this.bio,
    required this.createdAt,
    this.updatedAt,
    this.hasActiveSubscription = false,
  });

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? profileImageUrl,
    bool? isHost,
    String? city,
    String? country,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasActiveSubscription,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isHost: isHost ?? this.isHost,
      city: city ?? this.city,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'isHost': isHost,
      'city': city,
      'country': country,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'hasActiveSubscription': hasActiveSubscription,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      role: map['role'] ?? 'tenant',
      profileImageUrl: map['profileImageUrl'] ?? '',
      isHost: map['isHost'] ?? false,
      city: map['city'],
      country: map['country'],
      bio: map['bio'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      hasActiveSubscription: map['hasActiveSubscription'] ?? false,
    );
  }

  factory User.fromJson(Map<String, dynamic> data) {
    return User.fromMap(data);
  }

  // Alias for compatibility
  factory User.fromFirestore(Map<String, dynamic> data) => User.fromJson(data);

  String toJsonString() => json.encode(toMap());

  factory User.fromJsonString(String source) {
    final Map<String, dynamic> map =
        json.decode(source) as Map<String, dynamic>;
    return User.fromMap(map);
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, firstName: $firstName, lastName: $lastName, profileImageUrl: $profileImageUrl, isHost: $isHost, city: $city, country: $country, bio: $bio, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

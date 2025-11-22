import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    // Safely access the data, providing an empty map as a fallback.
    final data = doc.data() ?? {};
    return User.fromMap(data);
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, firstName: $firstName, lastName: $lastName, profileImageUrl: $profileImageUrl, isHost: $isHost, city: $city, country: $country, bio: $bio, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

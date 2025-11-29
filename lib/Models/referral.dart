class Referral {
  final String id;
  final String userId;
  final String propertyId;
  final String? referredTo;
  final DateTime createdAt;

  Referral({
    required this.id,
    required this.userId,
    required this.propertyId,
    this.referredTo,
    required this.createdAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'],
      userId: json['userId'],
      propertyId: json['propertyId'],
      referredTo: json['referredTo'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'propertyId': propertyId,
      'referredTo': referredTo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

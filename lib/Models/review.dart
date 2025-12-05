class Review {
  final String id;
  final String propertyId;
  final String userId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String? userName; // Optional, for display
  final List<String> photos; // Photos ajoutées à l'avis

  Review({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.userName,
    this.photos = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      propertyId: json['propertyId'],
      userId: json['userId'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      userName: json['userName'],
      photos: List<String>.from(json['photos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'photos': photos,
    };
  }
}

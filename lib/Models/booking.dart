class Booking {
  final String id;
  final String guestId;
  final String propertyId;
  final String hostId;
  final DateTime checkInDate;
  final DateTime? checkOutDate;
  final double totalPrice;
  final double platformFee; // Commission de la plateforme (ex: 3%)
  final double hostPayout; // Montant versé à l'hôte (totalPrice - platformFee)
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.guestId,
    required this.propertyId,
    required this.hostId,
    required this.checkInDate,
    this.checkOutDate,
    required this.totalPrice,
    required this.platformFee,
    required this.hostPayout,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> data) {
    final double totalPrice = (data['total_price'] as num?)?.toDouble() ?? 0.0;
    final double platformFee = (data['platform_fee'] as num?)?.toDouble() ??
        (totalPrice * 0.03); // 3% commission par défaut
    final double hostPayout =
        (data['host_payout'] as num?)?.toDouble() ?? (totalPrice - platformFee);
    return Booking(
      id: data['id'] ?? '',
      guestId: data['guest_id'] ?? '',
      propertyId: data['property_id'] ?? '',
      hostId: data['host_id'] ?? '',
      checkInDate: data['check_in_date'] != null
          ? DateTime.parse(data['check_in_date'])
          : DateTime.now(),
      checkOutDate: data['check_out_date'] != null
          ? DateTime.parse(data['check_out_date'])
          : null,
      totalPrice: totalPrice,
      platformFee: platformFee,
      hostPayout: hostPayout,
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'guest_id': guestId,
      'property_id': propertyId,
      'host_id': hostId,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate?.toIso8601String(),
      'total_price': totalPrice,
      'platform_fee': platformFee,
      'host_payout': hostPayout,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Alias for compatibility
  factory Booking.fromFirestore(Map<String, dynamic> data) =>
      Booking.fromJson(data);

  Booking copyWith({
    String? id,
    String? guestId,
    String? propertyId,
    String? hostId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? totalPrice,
    double? platformFee,
    double? hostPayout,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      propertyId: propertyId ?? this.propertyId,
      hostId: hostId ?? this.hostId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      totalPrice: totalPrice ?? this.totalPrice,
      platformFee: platformFee ?? this.platformFee,
      hostPayout: hostPayout ?? this.hostPayout,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get nights => checkOutDate != null
      ? checkOutDate!.difference(checkInDate).inDays
      : 30; // Default for indefinite
}

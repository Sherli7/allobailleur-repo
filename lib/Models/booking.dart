import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String guestId;
  final String propertyId;
  final String hostId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.guestId,
    required this.propertyId,
    required this.hostId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      guestId: data['guestId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      hostId: data['hostId'] ?? '',
      checkInDate:
          (data['checkInDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkOutDate:
          (data['checkOutDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'guestId': guestId,
      'propertyId': propertyId,
      'hostId': hostId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Booking copyWith({
    String? id,
    String? guestId,
    String? propertyId,
    String? hostId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? totalPrice,
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
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get nights => checkOutDate.difference(checkInDate).inDays;
}

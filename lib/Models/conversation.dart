import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final Timestamp timestamp;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': unreadCount,
    };
  }

  /// Crée une instance à partir d'un Map Firestore
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? 'Utilisateur inconnu',
      lastMessage: json['lastMessage'] as String? ?? '',
      timestamp: json['timestamp'] as Timestamp? ?? Timestamp.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  /// Copie l'instance avec des valeurs optionnelles modifiées (immutabilité)
  Conversation copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? lastMessage,
    Timestamp? timestamp,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

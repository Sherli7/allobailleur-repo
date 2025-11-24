class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });

  /// Convertit l'instance en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'last_message': lastMessage,
      'timestamp': timestamp.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  /// Crée une instance à partir d'un Map JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? '',
      otherUserId: json['other_user_id'] as String? ?? '',
      otherUserName:
          json['other_user_name'] as String? ?? 'Utilisateur inconnu',
      lastMessage: json['last_message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  /// Copie l'instance avec des valeurs optionnelles modifiées (immutabilité)
  Conversation copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? lastMessage,
    DateTime? timestamp,
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

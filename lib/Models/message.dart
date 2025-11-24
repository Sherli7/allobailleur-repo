enum MessageType {
  text,
  image,
  video,
  mixed
} // AJOUTÉ: video et mixed (texte+vidéo)

class Message {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? videoUrl; // NOUVEAU: URL vidéo uploadée
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.videoUrl, // Optionnel
    required this.timestamp,
    required this.isRead,
    required this.readBy,
  });

  /// Type de message (dérivé des champs)
  MessageType get type {
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      return text.isNotEmpty ? MessageType.mixed : MessageType.video;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return text.isNotEmpty ? MessageType.mixed : MessageType.image;
    }
    return MessageType.text;
  }

  /// Convertit l'instance en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl, // Seulement si présent
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'read_by': readBy,
    };
  }

  /// Crée une instance à partir d'un Map JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?, // Peut être null
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      readBy: List<String>.from(json['read_by'] ?? []),
    );
  }

  /// Copie l'instance avec des valeurs optionnelles modifiées
  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    String? videoUrl,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
    );
  }
}

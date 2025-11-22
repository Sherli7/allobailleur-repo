import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Timestamp timestamp;
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

  /// Convertit l'instance en Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl, // Seulement si présent
      'timestamp': timestamp,
      'isRead': isRead,
      'readBy': readBy,
    };
  }

  /// Crée une instance à partir d'un Map Firestore
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?, // Peut être null
      timestamp: json['timestamp'] as Timestamp? ?? Timestamp.now(),
      isRead: json['isRead'] as bool? ?? false,
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }

  /// Copie l'instance avec des valeurs optionnelles modifiées
  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    String? videoUrl,
    Timestamp? timestamp,
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

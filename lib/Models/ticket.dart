class Ticket {
  final String id;
  final String title;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String createdBy;
  final String propertyId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    required this.propertyId,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'medium',
      createdBy: json['created_by']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      images: (json['images'] as List<dynamic>?)
              ?.whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'created_by': createdBy,
      'property_id': propertyId,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'images': images,
    };
  }
}

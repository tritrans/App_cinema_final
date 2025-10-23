class Violation {
  final int id;
  final int userId;
  final String type; // 'spam', 'inappropriate', 'harassment', 'other'
  final String description;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final String? resolution;
  final int? reviewedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  Violation({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.status,
    this.resolution,
    this.reviewedBy,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      resolution: json['resolution'],
      reviewedBy: json['reviewed_by'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'description': description,
      'status': status,
      'resolution': resolution,
      'reviewed_by': reviewedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  Violation copyWith({
    int? id,
    int? userId,
    String? type,
    String? description,
    String? status,
    String? resolution,
    int? reviewedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Violation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isReviewed => status == 'reviewed';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';

  @override
  String toString() {
    return 'Violation(id: $id, userId: $userId, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Violation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

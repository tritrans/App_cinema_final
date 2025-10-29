class Comment {
  final int id;
  final int movieId;
  final int userId;
  final int? parentId;
  final String name;
  final String email;
  final String? avatar;
  final String content;
  final bool isHidden;
  final String? hiddenReason;
  final DateTime? hiddenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.movieId,
    required this.userId,
    this.parentId,
    required this.name,
    required this.email,
    this.avatar,
    required this.content,
    this.isHidden = false,
    this.hiddenReason,
    this.hiddenAt,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      movieId: json['movie_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      parentId: json['parent_id'],
      name: json['name'] ?? 'Người dùng ẩn danh',
      email: json['email'] ?? '',
      avatar: _processAvatarUrl(json['avatar']),
      content: json['content'] ?? '',
      isHidden: json['is_hidden'] == true || json['is_hidden'] == 1,
      hiddenReason: json['hidden_reason'],
      hiddenAt:
          json['hidden_at'] != null ? DateTime.parse(json['hidden_at']) : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((reply) => Comment.fromJson(reply))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'user_id': userId,
      'parent_id': parentId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'content': content,
      'is_hidden': isHidden,
      'hidden_reason': hiddenReason,
      'hidden_at': hiddenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String get displayName {
    return name.isNotEmpty ? name : 'Người dùng ẩn danh';
  }

  String get avatarUrl {
    return avatar ?? '';
  }

  // Aliases for compatibility
  String get userName => name;
  String? get userAvatar => avatar;

  bool get isReply {
    return parentId != null;
  }

  static String? _processAvatarUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) {
      return null;
    }

    const String androidEmulatorIp = '10.0.2.2';
    const String apiPort = '8000';
    const String webAppPort = '8001';

    String processedUrl = originalUrl;

    // Replace 8001 with 8000 if present
    if (processedUrl.contains(':$webAppPort')) {
      processedUrl = processedUrl.replaceAll(':$webAppPort', ':$apiPort');
    }

    // Replace 127.0.0.1 with Android emulator IP if present
    if (processedUrl.contains('127.0.0.1')) {
      processedUrl = processedUrl.replaceAll('127.0.0.1', androidEmulatorIp);
    }

    // Ensure it starts with http
    if (!processedUrl.startsWith('http')) {
      processedUrl = 'http://$androidEmulatorIp:$apiPort/storage/$processedUrl';
    }

    return processedUrl;
  }
}

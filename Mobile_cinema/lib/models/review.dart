class Review {
  final int id;
  final int movieId;
  final int userId;
  final String userName;
  final String userEmail;
  final String? userAvatarUrl;
  final double rating;
  final String comment;
  final bool isHidden;
  final String? hiddenReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Review> replies;

  Review({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatarUrl,
    required this.rating,
    required this.comment,
    this.isHidden = false,
    this.hiddenReason,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      movieId: json['movie_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Người dùng ẩn danh',
      userEmail: json['user_email'] ?? '',
      userAvatarUrl: _processAvatarUrl(json['user_avatar_url']),
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      isHidden: json['is_hidden'] == true || json['is_hidden'] == 1,
      hiddenReason: json['hidden_reason'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      replies: json['replies'] != null
          ? (json['replies'] as List).map((replyJson) {
              // Convert comment to review format for replies
              return Review(
                id: replyJson['id'] ?? 0,
                movieId: replyJson['movie_id'] ?? 0,
                userId: replyJson['user_id'] ?? 0,
                userName: replyJson['user_name'] ?? 'Người dùng ẩn danh',
                userEmail: replyJson['user_email'] ?? '',
                userAvatarUrl: replyJson['user_avatar_url'],
                rating: (replyJson['rating'] ?? 0.0).toDouble(),
                comment: replyJson['comment'] ?? '',
                isHidden: replyJson['is_hidden'] == true ||
                    replyJson['is_hidden'] == 1,
                hiddenReason: replyJson['hidden_reason'],
                createdAt: DateTime.parse(replyJson['created_at'] ??
                    DateTime.now().toIso8601String()),
                updatedAt: DateTime.parse(replyJson['updated_at'] ??
                    DateTime.now().toIso8601String()),
                replies: [], // Replies don't have nested replies
              );
            }).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_avatar_url': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'is_hidden': isHidden,
      'hidden_reason': hiddenReason,
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
    return userName.isNotEmpty ? userName : 'Người dùng ẩn danh';
  }

  String get avatarUrl {
    return userAvatarUrl ?? '';
  }

  // Alias for compatibility
  String? get userAvatar => userAvatarUrl;

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

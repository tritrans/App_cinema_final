import 'package:flutter/foundation.dart';

class Comment {
  final int id;
  final int movieId;
  final int userId;
  final int? parentId; // For replies
  final String content;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.movieId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      movieId: json['movie_id'] as int,
      userId: json['user_id'] as int,
      parentId: json['parent_id'] as int?,
      content: json['content'] as String,
      userName:
          json['name'] as String? ?? 'Anonymous', // API returns 'name' for user
      userAvatar: json['avatar'] as String?, // API returns 'avatar' for user
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'user_id': userId,
      'parent_id': parentId,
      'content': content,
      'name': userName,
      'avatar': userAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

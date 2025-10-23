import 'package:flutter/foundation.dart';

class Review {
  final int id;
  final int movieId;
  final int userId;
  final double rating;
  final String? comment;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    required this.id,
    required this.movieId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      movieId: json['movie_id'] as int,
      userId: json['user_id'] as int,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      userName: json['user_name'] as String? ??
          'Anonymous', // API returns 'user_name' for user
      userAvatar:
          json['user_avatar'] as String?, // API returns 'user_avatar' for user
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

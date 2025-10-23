import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../services/api_service_enhanced.dart';

class CommentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  // Get movie comments
  Future<void> getMovieComments(int movieId, {int page = 1}) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getMovieComments(movieId, page: page);

      if (response['success'] == true && response['data'] != null) {
        if (page == 1) {
          // First page - replace existing comments
          _comments = (response['data'] as List)
              .map((commentJson) => Comment.fromJson(commentJson))
              .toList();
        } else {
          // Additional pages - append to existing comments
          final newComments = (response['data'] as List)
              .map((commentJson) => Comment.fromJson(commentJson))
              .toList();
          _comments.addAll(newComments);
        }

        // Sort comments by creation date (newest first)
        _comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải bình luận');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải bình luận');
      }
    }
  }

  // Create comment
  Future<bool> createComment({
    required int movieId,
    required String content,
    int? parentId,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.createComment(
        movieId: movieId,
        content: content,
        parentId: parentId,
      );

      if (response['success'] == true && response['data'] != null) {
        final newComment = Comment.fromJson(response['data']);

        // Add to the beginning of the list
        _comments.insert(0, newComment);

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể tạo bình luận');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tạo bình luận');
      }
      return false;
    }
  }

  // Create comment reply
  Future<bool> createCommentReply({
    required int commentId,
    required String content,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.createCommentReply(
        commentId: commentId,
        content: content,
      );

      if (response['success'] == true && response['data'] != null) {
        final newReply = Comment.fromJson(response['data']);

        // Find the parent comment and add the reply
        final parentIndex = _comments.indexWhere((c) => c.id == commentId);
        if (parentIndex != -1) {
          // For simplicity, we'll just re-fetch comments or update the list
          // A more complex solution would involve adding a 'replies' list to the Comment model
          // and updating it here. For now, we'll just refresh the list.
          getMovieComments(_comments[parentIndex].movieId);
        } else {
          // If it's a reply to a reply, or parent not found, just refresh all comments
          // This might be inefficient for deep reply trees, but simple for now.
          // A better approach would be to have a nested Comment structure.
          getMovieComments(newReply.movieId);
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể tạo phản hồi');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tạo phản hồi');
      }
      return false;
    }
  }

  // Update comment
  Future<bool> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.updateComment(
        commentId: commentId,
        content: content,
      );

      if (response['success'] == true && response['data'] != null) {
        final updatedComment = Comment.fromJson(response['data']);

        // Update in the list
        final index = _comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          _comments[index] = updatedComment;
        } else {
          // If it's a reply, we'll need to refresh the whole list for simplicity
          // A more robust solution would involve nested comment updates.
          if (updatedComment.parentId != null) {
            final parentIndex =
                _comments.indexWhere((c) => c.id == updatedComment.parentId);
            if (parentIndex != -1) {
              getMovieComments(_comments[parentIndex].movieId);
            }
          }
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể cập nhật bình luận');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi cập nhật bình luận');
      }
      return false;
    }
  }

  // Delete comment
  Future<bool> deleteComment(int commentId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.deleteComment(commentId);

      if (response['success'] == true) {
        // Remove from the list
        _comments.removeWhere((c) => c.id == commentId);

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể xóa bình luận');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi xóa bình luận');
      }
      return false;
    }
  }

  // Clear comments
  void clearComments() {
    _comments = [];
    notifyListeners();
  }
}

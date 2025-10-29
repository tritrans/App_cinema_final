import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../services/api_service_enhanced.dart';

class CommentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  int _currentMovieId = 0;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error; // Alias for compatibility

  // Get comments for a specific movie
  Future<void> getMovieComments(int movieId) async {
    if (_currentMovieId == movieId && _comments.isNotEmpty) {
      return; // Already loaded
    }

    _isLoading = true;
    _error = null;
    _currentMovieId = movieId;
    notifyListeners();

    try {
      final response = await _apiService.getMovieComments(movieId);
      if (response['success'] == true) {
        // Handle both List and Map responses
        List<dynamic> commentsData;
        if (response['data'] is List) {
          commentsData = response['data'] as List;
        } else if (response['data'] is Map &&
            response['data']['data'] is List) {
          commentsData = response['data']['data'] as List;
        } else {
          commentsData = [];
        }

        _comments = commentsData.map((json) => Comment.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Không thể tải bình luận';
      }
    } catch (e) {
      _error = 'Lỗi: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tạo comment mới cho phim
  ///
  /// [movieId] - ID của phim
  /// [content] - Nội dung bình luận
  /// [parentId] - ID của comment gốc (nếu là reply)
  /// [token] - JWT token để xác thực
  ///
  /// Trả về true nếu tạo thành công, false nếu có lỗi
  Future<bool> createComment(int movieId, String content,
      {int? parentId, String? token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createComment(
        movieId: movieId,
        content: content,
        parentId: parentId,
      );
      if (response['success'] == true) {
        // Refresh comments after adding
        await getMovieComments(movieId);
        return true;
      } else {
        _error = response['message'] ?? 'Không thể thêm bình luận';
        return false;
      }
    } catch (e) {
      _error = 'Lỗi: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reply to a comment
  Future<bool> replyToComment(
      int commentId, String content, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createCommentReply(
        commentId: commentId,
        content: content,
      );
      if (response['success'] == true) {
        // Refresh comments after replying
        await getMovieComments(_currentMovieId);
        return true;
      } else {
        _error = response['message'] ?? 'Không thể trả lời bình luận';
        return false;
      }
    } catch (e) {
      _error = 'Lỗi: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear comments and reset state
  void clearComments() {
    _comments.clear();
    _error = null;
    _currentMovieId = 0;
    notifyListeners();
  }

  // Get main comments (not replies)
  List<Comment> get mainComments {
    return _comments.where((comment) => !comment.isReply).toList();
  }

  // Get replies for a specific comment
  List<Comment> getRepliesForComment(int parentId) {
    return _comments.where((comment) => comment.parentId == parentId).toList();
  }

  // Get comment count
  int get commentCount => _comments.length;

  // Get main comment count (excluding replies)
  int get mainCommentCount => mainComments.length;
}

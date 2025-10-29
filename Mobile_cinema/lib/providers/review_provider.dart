import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../services/api_service_enhanced.dart';

class ReviewProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;
  int _currentMovieId = 0;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error; // Alias for compatibility

  // Get reviews for a specific movie
  Future<void> getMovieReviews(int movieId) async {
    if (_currentMovieId == movieId && _reviews.isNotEmpty) {
      return; // Already loaded
    }

    _isLoading = true;
    _error = null;
    _currentMovieId = movieId;
    notifyListeners();

    try {
      final response = await _apiService.getMovieReviews(movieId);
      if (response['success'] == true) {
        // Handle both List and Map responses
        List<dynamic> reviewsData;
        if (response['data'] is List) {
          reviewsData = response['data'] as List;
        } else if (response['data'] is Map &&
            response['data']['data'] is List) {
          reviewsData = response['data']['data'] as List;
        } else {
          reviewsData = [];
        }

        _reviews = reviewsData.map((json) => Review.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Không thể tải đánh giá';
      }
    } catch (e) {
      _error = 'Lỗi: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tạo đánh giá mới cho phim
  ///
  /// [movieId] - ID của phim
  /// [rating] - Điểm đánh giá (1-5)
  /// [comment] - Nội dung đánh giá
  /// [token] - JWT token để xác thực
  ///
  /// Trả về true nếu tạo thành công, false nếu có lỗi
  Future<bool> createReview(
      int movieId, double rating, String comment, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createReview(
        movieId: movieId,
        rating: rating,
        comment: comment,
      );
      if (response['success'] == true) {
        // Refresh reviews after adding
        await getMovieReviews(movieId);
        return true;
      } else {
        if (response['message']?.contains('already reviewed') == true) {
          _error = 'Bạn đã đánh giá phim này rồi';
        } else {
          _error = response['message'] ?? 'Không thể thêm đánh giá';
        }
        return false;
      }
    } catch (e) {
      if (e.toString().contains('already reviewed')) {
        _error = 'Bạn đã đánh giá phim này rồi';
      } else {
        _error = 'Lỗi: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reply to a review
  Future<bool> replyToReview(int reviewId, String content, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createReviewReply(
        reviewId: reviewId,
        content: content,
      );
      if (response['success'] == true) {
        // Refresh reviews after replying
        await getMovieReviews(_currentMovieId);
        return true;
      } else {
        _error = response['message'] ?? 'Không thể trả lời đánh giá';
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

  // Clear reviews and reset state
  void clearReviews() {
    _reviews.clear();
    _error = null;
    _currentMovieId = 0;
    notifyListeners();
  }

  // Get average rating
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;

    final totalRating =
        _reviews.fold(0.0, (sum, review) => sum + review.rating);
    return totalRating / _reviews.length;
  }

  // Get rating count
  int get ratingCount => _reviews.length;

  // Get rating distribution
  Map<int, int> get ratingDistribution {
    final distribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      distribution[i] =
          _reviews.where((review) => review.rating.round() == i).length;
    }
    return distribution;
  }
}

import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../services/api_service_enhanced.dart';

class ReviewProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Review> _reviews = [];
  Review? _userReview;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Review> get reviews => _reviews;
  Review? get userReview => _userReview;
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

  // Get movie reviews
  Future<void> getMovieReviews(int movieId, {int page = 1}) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getMovieReviews(movieId, page: page);

      if (response['success'] == true && response['data'] != null) {
        if (page == 1) {
          // First page - replace existing reviews
          _reviews = (response['data'] as List)
              .map((reviewJson) => Review.fromJson(reviewJson))
              .toList();
        } else {
          // Additional pages - append to existing reviews
          final newReviews = (response['data'] as List)
              .map((reviewJson) => Review.fromJson(reviewJson))
              .toList();
          _reviews.addAll(newReviews);
        }

        // Sort reviews by creation date (newest first)
        _reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải đánh giá');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải đánh giá');
      }
    }
  }

  // Create review
  Future<bool> createReview({
    required int movieId,
    required double rating,
    String? comment,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.createReview(
        movieId: movieId,
        rating: rating,
        comment: comment,
      );

      if (response['success'] == true && response['data'] != null) {
        final newReview = Review.fromJson(response['data']);

        // Add to the beginning of the list
        _reviews.insert(0, newReview);

        // Set as user review
        _userReview = newReview;

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể tạo đánh giá');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tạo đánh giá');
      }
      return false;
    }
  }

  // Get user movie review
  Future<void> getUserMovieReview(int movieId) async {
    try {
      final response = await _apiService.getUserMovieReview(movieId);

      if (response['success'] == true && response['data'] != null) {
        _userReview = Review.fromJson(response['data']);
        notifyListeners();
      } else {
        _userReview = null;
        notifyListeners();
      }
    } catch (e) {
      _userReview = null;
      notifyListeners();
    }
  }

  // Update review
  Future<bool> updateReview({
    required int reviewId,
    required double rating,
    String? comment,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );

      if (response['success'] == true && response['data'] != null) {
        final updatedReview = Review.fromJson(response['data']);

        // Update in the list
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = updatedReview;
        }

        // Update user review if it's the same
        if (_userReview?.id == reviewId) {
          _userReview = updatedReview;
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể cập nhật đánh giá');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi cập nhật đánh giá');
      }
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(int reviewId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.deleteReview(reviewId);

      if (response['success'] == true) {
        // Remove from the list
        _reviews.removeWhere((r) => r.id == reviewId);

        // Clear user review if it's the same
        if (_userReview?.id == reviewId) {
          _userReview = null;
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể xóa đánh giá');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi xóa đánh giá');
      }
      return false;
    }
  }

  // Get average rating from reviews
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold(0.0, (sum, review) => sum + review.rating);
    return total / _reviews.length;
  }

  // Get rating distribution
  Map<int, int> get ratingDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final review in _reviews) {
      final rating = review.rating.round();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }
    return distribution;
  }

  // Get reviews with comments only
  List<Review> get reviewsWithComments {
    return _reviews
        .where((review) => review.comment != null && review.comment!.isNotEmpty)
        .toList();
  }

  // Check if user has reviewed the movie
  bool get hasUserReviewed => _userReview != null;

  // Clear reviews
  void clearReviews() {
    _reviews = [];
    _userReview = null;
    notifyListeners();
  }

  // Clear all data
  void clearAll() {
    _reviews = [];
    _userReview = null;
    notifyListeners();
  }
}

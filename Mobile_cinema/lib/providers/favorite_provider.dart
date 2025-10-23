import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../services/api_service_enhanced.dart';

class FavoriteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Movie> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Movie> get favorites => _favorites;
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

  // Get user favorites
  Future<void> getFavorites() async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getFavorites();

      if (response['success'] == true && response['data'] != null) {
        _favorites = (response['data'] as List)
            .map((movieJson) => Movie.fromJson(movieJson))
            .toList();
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải danh sách yêu thích');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách yêu thích');
      }
    }
  }

  // Add to favorites
  Future<bool> addToFavorites(int movieId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.addToFavorites(movieId: movieId);

      if (response['success'] == true) {
        // Refresh favorites list
        await getFavorites();
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể thêm vào yêu thích');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi thêm vào yêu thích');
      }
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(int movieId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.removeFromFavorites(movieId: movieId);

      if (response['success'] == true) {
        // Refresh favorites list
        await getFavorites();
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể xóa khỏi yêu thích');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi xóa khỏi yêu thích');
      }
      return false;
    }
  }

  // Check if movie is favorite
  bool isFavorite(int movieId) {
    return _favorites.any((movie) => movie.id == movieId);
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(int movieId) async {
    if (isFavorite(movieId)) {
      return await removeFromFavorites(movieId);
    } else {
      return await addToFavorites(movieId);
    }
  }
}

import 'package:flutter/material.dart';
import '../models/favorite.dart';
import '../services/api_service_enhanced.dart';
import 'auth_provider.dart';

class FavoriteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;

  List<Favorite> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Favorite> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Update AuthProvider reference
  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
    if (_authProvider?.isLoggedIn == true) {
      loadFavorites();
    } else {
      clearFavorites();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Kiểm tra phim có trong danh sách yêu thích không
  bool isFavorite(int movieId) {
    return _favorites.any((fav) => fav.movieId == movieId.toString());
  }

  // Thêm/xóa phim khỏi danh sách yêu thích
  Future<bool> toggleFavorite(int movieId) async {
    if (_authProvider?.user?.token == null) {
      _setError("Bạn cần đăng nhập để thực hiện chức năng này");
      return false;
    }
    _clearError();

    try {
      final isFav = isFavorite(movieId);

      if (isFav) {
        // Xóa khỏi yêu thích
        final response =
            await _apiService.removeFromFavorites(movieId: movieId);
        if (response['success'] == true) {
          _favorites.removeWhere((fav) => fav.movieId == movieId.toString());
          notifyListeners();
          return true;
        } else {
          _setError(response['message'] ?? 'Không thể xóa khỏi yêu thích');
          return false;
        }
      } else {
        // Thêm vào yêu thích
        final response = await _apiService.addToFavorites(
          movieId: movieId,
        );
        if (response['success'] == true && response['data'] != null) {
          final newFavorite = Favorite.fromJson(response['data']);
          _favorites.add(newFavorite);
          notifyListeners();
          return true;
        } else {
          _setError(response['message'] ?? 'Không thể thêm vào yêu thích');
          return false;
        }
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Tải danh sách yêu thích
  Future<void> loadFavorites() async {
    if (_authProvider?.user?.token == null) return;
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getFavorites();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> favData = response['data'];
        _favorites = favData.map((data) => Favorite.fromJson(data)).toList();
      } else {
        _setError(response['message'] ?? 'Không thể tải danh sách yêu thích');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Xóa tất cả yêu thích (khi đăng xuất)
  void clearFavorites() {
    _favorites.clear();
    _error = null;
    notifyListeners();
  }

  // Lấy số lượng yêu thích
  int get favoriteCount => _favorites.length;

  // Lấy danh sách ID phim yêu thích
  Set<String> get favoriteMovieIds {
    return _favorites.map((fav) => fav.movieId).toSet();
  }
}

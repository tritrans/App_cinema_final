import 'package:flutter/foundation.dart';
import '../models/cast.dart';
import '../services/api_service_enhanced.dart';

class CastProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Cast> _movieCast = [];
  List<Cast> _directors = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Cast> get movieCast => _movieCast;
  List<Cast> get directors => _directors;
  List<Cast> get actors =>
      _movieCast.where((cast) => cast.role == 'actor').toList();
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

  // Get movie cast
  Future<void> getMovieCast(int movieId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getMovieCast(movieId);

      if (response['success'] == true && response['data'] != null) {
        _movieCast = (response['data'] as List)
            .map((castJson) => Cast.fromJson(castJson))
            .toList();

        // Separate actors and directors
        _directors =
            _movieCast.where((cast) => cast.role == 'director').toList();
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải thông tin cast');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải thông tin cast');
      }
    }
  }

  // Update movie cast
  Future<bool> updateMovieCast({
    required int movieId,
    required List<String> cast,
    String? director,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.updateMovieCast(
        movieId: movieId,
        cast: cast,
        director: director,
      );

      if (response['success'] == true) {
        // Refresh cast data
        await getMovieCast(movieId);
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Không thể cập nhật cast');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi cập nhật cast');
      }
      return false;
    }
  }

  // Get cast by role
  List<Cast> getCastByRole(String role) {
    return _movieCast.where((cast) => cast.role == role).toList();
  }

  // Get main cast (first 5 actors)
  List<Cast> get mainCast {
    final actors = getCastByRole('actor');
    return actors.take(5).toList();
  }

  // Get supporting cast (remaining actors)
  List<Cast> get supportingCast {
    final actors = getCastByRole('actor');
    return actors.skip(5).toList();
  }

  // Clear cast data
  void clearCast() {
    _movieCast = [];
    _directors = [];
    notifyListeners();
  }
}

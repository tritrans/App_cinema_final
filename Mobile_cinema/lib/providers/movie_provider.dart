import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/genre.dart';
import '../services/api_service_enhanced.dart';

class MovieProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Movie> _movies = [];
  List<Genre> _genres = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Movie> get movies => _movies;
  List<Genre> get genres => _genres;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get all movies
  Future<void> getMovies() async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getMovies();
      print('MovieProvider.getMovies() response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data != null) {
          if (data is Map && data['data'] != null) {
            _movies = (data['data'] as List)
                .map((movieJson) => Movie.fromJson(movieJson))
                .toList();
            print('Loaded ${_movies.length} movies from API (pagination)');
          } else if (data is List) {
            _movies =
                data.map((movieJson) => Movie.fromJson(movieJson)).toList();
            print('Loaded ${_movies.length} movies from API (direct list)');
          } else {
            print('MovieProvider: Invalid data format from API');
            _setError('Dữ liệu phim không hợp lệ từ API');
          }
        } else {
          print('MovieProvider: Data field is null in API response');
          _setError('Không có dữ liệu phim từ API');
        }
      } else {
        print('MovieProvider: API returned error: ${response['message']}');
        _setError(response['message'] ?? 'Không thể tải danh sách phim');
      }
    } catch (e) {
      print('Exception in getMovies: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách phim: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get genres
  Future<void> getGenres() async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getGenres();
      print('MovieProvider.getGenres() response: $response');

      if (response['success'] == true && response['data'] != null) {
        _genres = (response['data'] as List)
            .map((genreJson) => Genre.fromJson(genreJson))
            .toList();
        print('Loaded ${_genres.length} genres from API');
      } else {
        print('MovieProvider: API returned error: ${response['message']}');
        _setError(response['message'] ?? 'Không thể tải danh sách thể loại');
      }
    } catch (e) {
      print('Exception in getGenres: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách thể loại: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get movie by ID
  Future<Movie?> getMovieById(int id) async {
    try {
      final response = await _apiService.getMovieById(id);
      print('MovieProvider.getMovieById() response: $response');

      if (response['success'] == true && response['data'] != null) {
        return Movie.fromJson(response['data']);
      } else {
        print('MovieProvider: API returned error: ${response['message']}');
        _setError(response['message'] ?? 'Không thể tải thông tin phim');
      }
      return null;
    } catch (e) {
      print('Exception in getMovieById: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải thông tin phim');
      }
      return null;
    }
  }

  // Filter movies by genre
  List<Movie> getMoviesByGenre(String genreName) {
    if (genreName == 'Tất cả') {
      return _movies;
    }
    return _movies.where((movie) {
      return movie.genres.any((genre) => genre.name == genreName);
    }).toList();
  }

  // Search movies
  List<Movie> searchMovies(String query) {
    if (query.isEmpty) {
      return _movies;
    }
    return _movies.where((movie) {
      return movie.title.toLowerCase().contains(query.toLowerCase()) ||
          (movie.titleVi?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // Get search results (for compatibility)
  List<Movie> get searchResults => _movies;

  // Get featured movies
  List<Movie> get featuredMovies =>
      _movies.where((movie) => movie.featured).toList();

  // Get featured movies method
  Future<void> getFeaturedMovies() async {
    // For now, just load all movies and filter featured ones
    await getMovies();
  }

  // Reset data method
  void resetData() {
    _movies.clear();
    _genres.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../models/theater.dart';
import '../models/schedule.dart';
import '../services/api_service_enhanced.dart';

class TheaterProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Theater> _theaters = [];
  Theater? _currentTheater;
  List<Schedule> _theaterSchedules = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Theater> get theaters => _theaters;
  Theater? get currentTheater => _currentTheater;
  List<Schedule> get theaterSchedules => _theaterSchedules;
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

  // Get all theaters
  Future<void> getTheaters({
    String? city,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getTheaters(
        city: city,
        page: page,
        perPage: perPage,
      );

      if (response['success'] == true && response['data'] != null) {
        if (response['data'] is List) {
          // Direct array of theaters
          _theaters = (response['data'] as List)
              .map((theaterJson) => Theater.fromJson(theaterJson))
              .toList();
        } else if (response['data']['data'] is List) {
          // Paginated response
          _theaters = (response['data']['data'] as List)
              .map((theaterJson) => Theater.fromJson(theaterJson))
              .toList();
        }
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải danh sách rạp');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách rạp');
      }
    }
  }

  // Get theater details
  Future<void> getTheaterDetails(int theaterId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getTheaterDetails(theaterId);

      if (response['success'] == true && response['data'] != null) {
        _currentTheater = Theater.fromJson(response['data']);
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải thông tin rạp');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải thông tin rạp');
      }
    }
  }

  // Get theater schedules
  Future<void> getTheaterSchedules(int theaterId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getTheaterSchedules(theaterId);

      if (response['success'] == true && response['data'] != null) {
        _theaterSchedules = (response['data'] as List)
            .map((scheduleJson) => Schedule.fromJson(scheduleJson))
            .toList();

        // Sort schedules by start time
        _theaterSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải lịch chiếu của rạp');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải lịch chiếu của rạp');
      }
    }
  }

  // Get theater movie schedules
  Future<void> getTheaterMovieSchedules(int theaterId, int movieId) async {
    try {
      _setLoading(true);
      clearError();

      final response =
          await _apiService.getTheaterMovieSchedules(theaterId, movieId);

      if (response['success'] == true && response['data'] != null) {
        _theaterSchedules = (response['data'] as List)
            .map((scheduleJson) => Schedule.fromJson(scheduleJson))
            .toList();

        // Sort schedules by start time
        _theaterSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

        _setLoading(false);
      } else {
        _setError(
            response['message'] ?? 'Không thể tải lịch chiếu phim tại rạp');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải lịch chiếu phim tại rạp');
      }
    }
  }

  // Get theaters by city
  List<Theater> getTheatersByCity(String city) {
    return _theaters
        .where((theater) => theater.city.toLowerCase() == city.toLowerCase())
        .toList();
  }

  // Get active theaters
  List<Theater> get activeTheaters {
    return _theaters.where((theater) => theater.active).toList();
  }

  // Get available cities
  List<String> get availableCities {
    final cities = _theaters.map((theater) => theater.city).toSet().toList();
    cities.sort();
    return cities;
  }

  // Get theaters with available schedules
  List<Theater> get theatersWithSchedules {
    return _theaters.where((theater) {
      // Check if theater has any schedules in the future
      return _theaterSchedules.any((schedule) =>
          schedule.theaterId == theater.id && schedule.isAvailable);
    }).toList();
  }

  // Get schedules for today at theater
  List<Schedule> getTodaySchedules(int theaterId) {
    final today = DateTime.now();
    return _theaterSchedules
        .where((schedule) =>
            schedule.theaterId == theaterId &&
            schedule.showDate.year == today.year &&
            schedule.showDate.month == today.month &&
            schedule.showDate.day == today.day &&
            schedule.isAvailable)
        .toList();
  }

  // Get schedules for tomorrow at theater
  List<Schedule> getTomorrowSchedules(int theaterId) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _theaterSchedules
        .where((schedule) =>
            schedule.theaterId == theaterId &&
            schedule.showDate.year == tomorrow.year &&
            schedule.showDate.month == tomorrow.month &&
            schedule.showDate.day == tomorrow.day &&
            schedule.isAvailable)
        .toList();
  }

  // Get schedules for specific date at theater
  List<Schedule> getSchedulesForDate(int theaterId, DateTime date) {
    return _theaterSchedules
        .where((schedule) =>
            schedule.theaterId == theaterId &&
            schedule.showDate.year == date.year &&
            schedule.showDate.month == date.month &&
            schedule.showDate.day == date.day &&
            schedule.isAvailable)
        .toList();
  }

  // Search theaters by name
  List<Theater> searchTheaters(String query) {
    if (query.isEmpty) return _theaters;

    final lowercaseQuery = query.toLowerCase();
    return _theaters
        .where((theater) =>
            theater.name.toLowerCase().contains(lowercaseQuery) ||
            theater.address.toLowerCase().contains(lowercaseQuery) ||
            theater.city.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Get theater by id
  Theater? getTheaterById(int theaterId) {
    try {
      return _theaters.firstWhere((theater) => theater.id == theaterId);
    } catch (e) {
      return null;
    }
  }

  // Check if theater has schedules for movie
  bool hasSchedulesForMovie(int theaterId, int movieId) {
    return _theaterSchedules.any((schedule) =>
        schedule.theaterId == theaterId &&
        schedule.movieId == movieId &&
        schedule.isAvailable);
  }

  // Get nearest theaters (mock implementation - would need location services)
  List<Theater> getNearestTheaters({int limit = 5}) {
    // For now, just return the first few active theaters
    // In a real app, you'd calculate distance based on user location
    return activeTheaters.take(limit).toList();
  }

  // Set current theater
  void setCurrentTheater(Theater theater) {
    _currentTheater = theater;
    notifyListeners();
  }

  // Clear current theater
  void clearCurrentTheater() {
    _currentTheater = null;
    notifyListeners();
  }

  // Clear theaters
  void clearTheaters() {
    _theaters = [];
    _currentTheater = null;
    _theaterSchedules = [];
    notifyListeners();
  }

  // Clear theater schedules
  void clearTheaterSchedules() {
    _theaterSchedules = [];
    notifyListeners();
  }

  // Refresh theaters
  Future<void> refreshTheaters({String? city}) async {
    await getTheaters(city: city);
  }

  // Refresh theater details
  Future<void> refreshTheaterDetails(int theaterId) async {
    await getTheaterDetails(theaterId);
  }

  // Refresh theater schedules
  Future<void> refreshTheaterSchedules(int theaterId) async {
    await getTheaterSchedules(theaterId);
  }
}

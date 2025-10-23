import 'package:flutter/foundation.dart';
import '../models/schedule.dart';
import '../models/theater.dart';
import '../services/api_service_enhanced.dart';

class ScheduleProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Schedule> _schedules = [];
  Map<String, List<Schedule>> _groupedSchedules = {};
  List<String> _availableDates = [];
  List<ScheduleSeat> _scheduleSeats = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Schedule> get schedules => _schedules;
  Map<String, List<Schedule>> get groupedSchedules => _groupedSchedules;
  List<String> get availableDates => _availableDates;
  List<ScheduleSeat> get scheduleSeats => _scheduleSeats;
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

  // Get movie schedules
  Future<void> getMovieSchedules(int movieId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getMovieSchedules(movieId);

      if (response['success'] == true) {
        final scheduleResponse = ScheduleResponse.fromJson(response);
        _schedules = scheduleResponse.schedules;
        _groupedSchedules = scheduleResponse.schedulesByDate;
        _availableDates = scheduleResponse.availableDates;
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải lịch chiếu');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải lịch chiếu');
      }
    }
  }

  // Get movie available dates
  Future<void> getMovieAvailableDates(int movieId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getMovieAvailableDates(movieId);

      if (response['success'] == true && response['data'] != null) {
        _availableDates = List<String>.from(response['data']['dates'] ?? []);
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải ngày chiếu');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải ngày chiếu');
      }
    }
  }

  // Get schedule seats
  Future<void> getScheduleSeats(int scheduleId) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getScheduleSeats(scheduleId);

      if (response['success'] == true && response['data'] != null) {
        _scheduleSeats = (response['data'] as List)
            .map((seatJson) => ScheduleSeat.fromJson(seatJson))
            .toList();
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải thông tin ghế');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải thông tin ghế');
      }
    }
  }

  // Get all schedules
  Future<void> getAllSchedules({int page = 1, int perPage = 20}) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getAllSchedules(
        page: page,
        perPage: perPage,
      );

      if (response['success'] == true) {
        final scheduleResponse = ScheduleResponse.fromJson(response);
        _schedules = scheduleResponse.schedules;
        _groupedSchedules = scheduleResponse.schedulesByDate;
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải lịch chiếu');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải lịch chiếu');
      }
    }
  }

  // Get schedules by date
  Future<void> getSchedulesByDate({
    required String date,
    int? theaterId,
    int? movieId,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.getSchedulesByDate(
        date: date,
        theaterId: theaterId,
        movieId: movieId,
      );

      if (response['success'] == true) {
        final scheduleResponse = ScheduleResponse.fromJson(response);
        _schedules = scheduleResponse.schedules;
        _groupedSchedules = scheduleResponse.schedulesByDate;
        _setLoading(false);
      } else {
        _setError(response['message'] ?? 'Không thể tải lịch chiếu');
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải lịch chiếu');
      }
    }
  }

  // Get schedules for specific date
  List<Schedule> getSchedulesForDate(String date) {
    return _groupedSchedules[date] ?? [];
  }

  // Get available schedules (not past and has available seats)
  List<Schedule> get availableSchedules {
    return _schedules.where((schedule) => schedule.isAvailable).toList();
  }

  // Get schedules for today
  List<Schedule> get todaySchedules {
    final today = DateTime.now();
    final todayKey = '${today.day} ${_getMonthName(today.month)} ${today.year}';
    return getSchedulesForDate(todayKey);
  }

  // Get schedules for tomorrow
  List<Schedule> get tomorrowSchedules {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowKey =
        '${tomorrow.day} ${_getMonthName(tomorrow.month)} ${tomorrow.year}';
    return getSchedulesForDate(tomorrowKey);
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // Get available seats for schedule
  List<ScheduleSeat> getAvailableSeats(int scheduleId) {
    return _scheduleSeats
        .where((seat) => seat.scheduleId == scheduleId && seat.isAvailable)
        .toList();
  }

  // Get sold seats for schedule
  List<ScheduleSeat> getSoldSeats(int scheduleId) {
    return _scheduleSeats
        .where((seat) => seat.scheduleId == scheduleId && seat.isSold)
        .toList();
  }

  // Get reserved seats for schedule
  List<ScheduleSeat> getReservedSeats(int scheduleId) {
    return _scheduleSeats
        .where((seat) => seat.scheduleId == scheduleId && seat.isReserved)
        .toList();
  }

  // Check if seat is available
  bool isSeatAvailable(int scheduleId, int seatId) {
    final scheduleSeat = _scheduleSeats.firstWhere(
      (seat) => seat.scheduleId == scheduleId && seat.seatId == seatId,
      orElse: () => ScheduleSeat(
        scheduleId: scheduleId,
        seatId: seatId,
        status: 'available',
      ),
    );
    return scheduleSeat.isAvailable;
  }

  // Get seat status
  String getSeatStatus(int scheduleId, int seatId) {
    final scheduleSeat = _scheduleSeats.firstWhere(
      (seat) => seat.scheduleId == scheduleId && seat.seatId == seatId,
      orElse: () => ScheduleSeat(
        scheduleId: scheduleId,
        seatId: seatId,
        status: 'available',
      ),
    );
    return scheduleSeat.status;
  }

  // Clear schedules
  void clearSchedules() {
    _schedules = [];
    _groupedSchedules = {};
    _availableDates = [];
    _scheduleSeats = [];
    notifyListeners();
  }

  // Clear seats
  void clearSeats() {
    _scheduleSeats = [];
    notifyListeners();
  }
}

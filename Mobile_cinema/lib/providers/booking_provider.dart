import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/theater.dart';
import '../models/schedule.dart';
import '../models/seat.dart' as seat_model;
import '../services/api_service_enhanced.dart';
import '../services/theater_api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final TheaterApiService _theaterApiService = TheaterApiService();

  List<Booking> _bookings = [];
  Booking? _currentBooking;
  List<Snack> _snacks = [];
  List<Theater> _theaters = [];
  List<Schedule> _schedules = [];
  List<String> _lockedSeats = [];
  List<int> _lockedSeatIds = [];
  List<seat_model.Seat> _scheduleSeats = []; // For seats in a schedule
  DateTime? _lockExpiry;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Booking> get bookings => _bookings;
  Booking? get currentBooking => _currentBooking;
  List<Snack> get snacks => _snacks;
  List<Theater> get theaters => _theaters;
  List<Schedule> get schedules => _schedules;

  // Get unique theater names
  List<String> get uniqueTheaterNames {
    return _theaters.map((theater) => theater.name).toSet().toList();
  }

  List<String> get lockedSeats => _lockedSeats;
  List<int> get lockedSeatIds => _lockedSeatIds;
  List<seat_model.Seat> get scheduleSeats => _scheduleSeats;
  DateTime? get lockExpiry => _lockExpiry;
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

  // Get all theaters
  Future<void> getTheaters() async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Calling TheaterApiService to get theaters...');
      _theaters = await _theaterApiService.getAllTheaters();
      print(
          'BookingProvider: Successfully loaded ${_theaters.length} theaters: ${_theaters.map((t) => t.name).toList()}');
    } catch (e) {
      print('BookingProvider: Error loading theaters from API: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách rạp: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get movie schedules
  Future<void> getMovieSchedules(int movieId) async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Calling API getMovieSchedules($movieId)...');
      final response = await _apiService.getMovieSchedules(movieId);
      print('BookingProvider: API response: $response');

      if (response['success'] == true && response['data'] != null) {
        try {
          _schedules = (response['data'] as List).map((scheduleJson) {
            print('BookingProvider: Parsing schedule: $scheduleJson');
            return Schedule.fromJson(scheduleJson);
          }).toList();
          print(
              'BookingProvider: Loaded ${_schedules.length} schedules from API');
        } catch (parseError) {
          print('BookingProvider: Error parsing schedules: $parseError');
          print('BookingProvider: Raw data: ${response['data']}');
          _setError('Lỗi phân tích dữ liệu lịch chiếu: $parseError');
        }
      } else {
        print('BookingProvider: API returned error: ${response['message']}');
        _setError(response['message'] ?? 'Không thể tải lịch chiếu');
      }
    } catch (e) {
      print('BookingProvider: Exception loading schedules: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải lịch chiếu: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get bookings by status
  List<Booking> getBookingsByStatus(String status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  // Get confirmed bookings
  List<Booking> get confirmedBookings => getBookingsByStatus('confirmed');

  // Get cancelled bookings
  List<Booking> get cancelledBookings => getBookingsByStatus('cancelled');

  // Get pending bookings
  List<Booking> get pendingBookings => getBookingsByStatus('pending');

  // Get upcoming bookings
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _bookings
        .where((booking) =>
            booking.showtime != null &&
            booking.showtime!.startTime.isAfter(now) &&
            booking.status != 'cancelled')
        .toList()
      ..sort((a, b) => a.showtime!.startTime.compareTo(b.showtime!.startTime));
  }

  // Get user bookings
  Future<void> getUserBookings(int userId) async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Calling API getUserBookings($userId)...');
      final response = await _apiService.getUserBookings(userId);
      print('BookingProvider: User bookings API response: $response');

      if (response['success'] == true && response['data'] != null) {
        _bookings = (response['data'] as List)
            .map((bookingJson) => Booking.fromJson(bookingJson))
            .toList();
        print('BookingProvider: Loaded ${_bookings.length} user bookings');
      } else {
        _setError(response['message'] ?? 'Không thể tải danh sách vé');
      }
    } catch (e) {
      print('BookingProvider: Exception loading user bookings: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách vé: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get booking details and set as current booking
  Future<void> getBookingDetails(String bookingId) async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Calling API getBookingDetails($bookingId)...');
      final response = await _apiService.getBookingDetails(bookingId);
      print('BookingProvider: Booking details API response: $response');

      if (response['success'] == true && response['data'] != null) {
        _currentBooking = Booking.fromJson(response['data']);
        print('BookingProvider: Loaded booking details for $bookingId');
      } else {
        _setError(response['message'] ?? 'Không thể tải chi tiết vé');
      }
    } catch (e) {
      print('BookingProvider: Exception loading booking details: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải chi tiết vé: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Create a new booking (local only, for now)
  Future<Booking?> createBooking({
    required int userId,
    required int showtimeId,
    required List<String> seatIds,
    required List<Snack> selectedSnacks,
    required double totalPrice,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch,
        bookingId: 'BK${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        showtimeId: showtimeId,
        totalPrice: totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        seats: [], // TODO: Convert seatIds to BookingSeat objects
        snacks: [], // TODO: Convert selectedSnacks to BookingSnack objects
      );

      _bookings.add(booking);
      _currentBooking = booking;
      _setLoading(false);
      notifyListeners();

      return booking;
    } catch (e) {
      _setError('Có lỗi xảy ra khi tạo booking: $e');
      return null;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex != -1) {
        // Create new booking with updated status
        final oldBooking = _bookings[bookingIndex];
        _bookings[bookingIndex] = Booking(
          id: oldBooking.id,
          bookingId: oldBooking.bookingId,
          userId: oldBooking.userId,
          showtimeId: oldBooking.showtimeId,
          totalPrice: oldBooking.totalPrice,
          status: status,
          createdAt: oldBooking.createdAt,
          updatedAt: DateTime.now(),
          user: oldBooking.user,
          showtime: oldBooking.showtime,
          seats: oldBooking.seats,
          snacks: oldBooking.snacks,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Có lỗi xảy ra khi cập nhật booking: $e');
      return false;
    }
  }

  // Lock seats
  void lockSeats(List<String> seatIds, {Duration? duration}) {
    _lockedSeats = seatIds;
    _lockExpiry = DateTime.now().add(duration ?? const Duration(minutes: 10));
    notifyListeners();
  }

  // Lock seats by ID
  void lockSeatsById(List<int> seatIds, {Duration? duration}) {
    _lockedSeatIds = seatIds;
    _lockExpiry = DateTime.now().add(duration ?? const Duration(minutes: 10));
    notifyListeners();
  }

  // Unlock seats
  void unlockSeats() {
    _lockedSeats.clear();
    _lockedSeatIds.clear();
    _lockExpiry = null;
    notifyListeners();
  }

  // Check if seats are locked
  bool areSeatsLocked(List<String> seatIds) {
    if (_lockExpiry == null || DateTime.now().isAfter(_lockExpiry!)) {
      unlockSeats();
      return false;
    }
    return seatIds.any((seatId) => _lockedSeats.contains(seatId));
  }

  // Check if seats are locked by ID
  bool areSeatsLockedById(List<int> seatIds) {
    if (_lockExpiry == null || DateTime.now().isAfter(_lockExpiry!)) {
      unlockSeats();
      return false;
    }
    return seatIds.any((seatId) => _lockedSeatIds.contains(seatId));
  }

  // Clear schedule seats
  void clearScheduleSeats() {
    _scheduleSeats.clear();
    notifyListeners();
  }

  // Get seats for a schedule
  Future<void> getScheduleSeats(int scheduleId) async {
    _setLoading(true);
    clearError();

    try {
      // Clear previous seats before loading new ones
      _scheduleSeats.clear();
      notifyListeners();

      print('BookingProvider: Loading seats for schedule $scheduleId...');
      final response = await _apiService.getScheduleSeats(scheduleId);
      print('BookingProvider: Seats API response: $response');

      if (response['success'] == true && response['data'] != null) {
        try {
          _scheduleSeats = (response['data'] as List).map((seatJson) {
            print('BookingProvider: Parsing seat: $seatJson');
            return seat_model.Seat.fromJson(seatJson);
          }).toList();
          _setLoading(false);
          print(
              'BookingProvider: Loaded ${_scheduleSeats.length} seats for schedule $scheduleId');

          // Print first few seats for debugging
          for (int i = 0; i < 5 && i < _scheduleSeats.length; i++) {
            final seat = _scheduleSeats[i];
            print(
                'Seat ${i + 1}: ${seat.rowLabel}${seat.seatNumber} - Status: ${seat.status}');
          }
        } catch (parseError) {
          print('BookingProvider: Error parsing seats: $parseError');
          print('BookingProvider: Raw seats data: ${response['data']}');
          _setError('Lỗi phân tích dữ liệu ghế: $parseError');
        }
      } else {
        print('BookingProvider: Seats API failed: ${response['message']}');
        _setError(response['message'] ?? 'Không thể tải thông tin ghế');
      }
    } catch (e) {
      print('BookingProvider: Exception loading seats: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải thông tin ghế');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get snacks
  Future<void> getSnacks() async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Calling API getSnacks()...');
      final response = await _apiService.getSnacks();
      print('BookingProvider: Snacks API response: $response');

      if (response['success'] == true && response['data'] != null) {
        try {
          _snacks = (response['data'] as List).map((snackJson) {
            print('BookingProvider: Parsing snack: $snackJson');
            return Snack.fromJson(snackJson);
          }).toList();
          print('BookingProvider: Loaded ${_snacks.length} snacks from API');
        } catch (parseError) {
          print('BookingProvider: Error parsing snacks: $parseError');
          print('BookingProvider: Raw data: ${response['data']}');
          _setError('Lỗi phân tích dữ liệu snacks: $parseError');
        }
      } else {
        print(
            'BookingProvider: Snacks API returned error: ${response['message']}');
        _setError(response['message'] ?? 'Không thể tải danh sách snacks');
      }
    } catch (e) {
      print('BookingProvider: Exception loading snacks: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi tải danh sách snacks: $e');
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============ Server-backed booking helpers ============

  /// Call API to lock seats on server. Returns the raw API response map.
  /// On success this will also set local locked seats/ids and expiry.
  Future<Map<String, dynamic>> lockSeatsOnServer({
    required int scheduleId,
    required List<String> seatNumbers,
    int lockDurationMinutes = 10,
  }) async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Calling API lockSeats for schedule $scheduleId');
      final response = await _apiService.lockSeats(
        scheduleId: scheduleId,
        seatNumbers: seatNumbers,
        lockDurationMinutes: lockDurationMinutes,
      );

      print('BookingProvider: lockSeats response: $response');

      if (response['success'] == true) {
        // Try to extract locked seat identifiers from response
        try {
          // Common shapes: response['data']['seat_ids'] or response['data']['locked_seat_ids']
          final data = response['data'];
          List<int> seatIds = [];
          if (data is Map) {
            if (data['seat_ids'] is List) {
              seatIds =
                  (data['seat_ids'] as List).map((e) => e as int).toList();
            } else if (data['locked_seat_ids'] is List) {
              seatIds = (data['locked_seat_ids'] as List)
                  .map((e) => e as int)
                  .toList();
            }
          }

          // Save locked seats locally (store both numbers and ids when available)
          _lockedSeats = seatNumbers;
          _lockedSeatIds = seatIds;
          _lockExpiry =
              DateTime.now().add(Duration(minutes: lockDurationMinutes));
          notifyListeners();
        } catch (e) {
          print('BookingProvider: Unable to parse locked seat ids: $e');
        }

        return response;
      } else {
        _setError(response['message'] ?? 'Không thể khóa ghế');
        return response;
      }
    } catch (e) {
      print('BookingProvider: Exception locking seats on server: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
        rethrow;
      } else {
        _setError('Lỗi kết nối khi khóa ghế: $e');
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Create booking on server (calls saveBookingToDatabase / createBooking).
  /// Returns Booking object parsed from server response on success.
  Future<Booking?> createBookingOnServer({
    required int userId,
    required int showtimeId,
    required List<String> selectedSeats,
    required Map<int, int> selectedSnacks,
    required List<dynamic> snacks,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      _setLoading(true);
      clearError();

      print('BookingProvider: Creating booking on server...');
      final response = await _apiService.saveBookingToDatabase(
        userId: userId,
        showtimeId: showtimeId,
        selectedSeats: selectedSeats,
        selectedSnacks: selectedSnacks,
        snacks: snacks,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
      );

      print('BookingProvider: createBooking response: $response');

      if (response['success'] == true && response['data'] != null) {
        try {
          // If API returns booking object in data
          final bookingJson = response['data'];
          // Some APIs may return nested booking object
          final bookingData =
              bookingJson is Map && bookingJson['booking'] != null
                  ? bookingJson['booking']
                  : bookingJson;

          final booking = Booking.fromJson(bookingData as Map<String, dynamic>);

          // Add to local list
          _bookings.add(booking);
          _currentBooking = booking;
          notifyListeners();

          return booking;
        } catch (parseError) {
          print('BookingProvider: Error parsing booking response: $parseError');
          _setError('Lỗi phân tích dữ liệu booking: $parseError');
          return null;
        }
      } else {
        _setError(response['message'] ?? 'Không thể tạo booking');
        return null;
      }
    } catch (e) {
      print('BookingProvider: Exception creating booking on server: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Lỗi khi tạo booking: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Release seats previously locked on server. Accepts seatIds (int).
  Future<Map<String, dynamic>> releaseSeatsOnServer({
    required int scheduleId,
    required List<int> seatIds,
  }) async {
    try {
      _setLoading(true);
      clearError();

      print(
          'BookingProvider: Releasing seats on server for schedule $scheduleId');
      final response = await _apiService.releaseSeats(
        scheduleId: scheduleId,
        seatIds: seatIds,
      );

      print('BookingProvider: releaseSeats response: $response');

      // Always clear local locks when releasing
      unlockSeats();

      return response;
    } catch (e) {
      print('BookingProvider: Exception releasing seats: $e');
      if (e is ApiException) {
        _setError(e.detailedMessage);
        rethrow;
      } else {
        _setError('Lỗi khi mở khóa ghế: $e');
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  // Clear all data
  void clearAllData() {
    _bookings.clear();
    _currentBooking = null;
    _snacks.clear();
    _theaters.clear();
    _schedules.clear();
    _lockedSeats.clear();
    _lockedSeatIds.clear();
    _scheduleSeats.clear();
    _lockExpiry = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

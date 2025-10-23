import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL của Laravel API (10.0.2.2 là địa chỉ để truy cập localhost từ Android emulator)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers mặc định
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Lưu token vào SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Xóa token khỏi SharedPreferences
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers với authentication
  Future<Map<String, String>> get _authHeaders async {
    final token = await _getToken();
    final headers = Map<String, String>.from(_defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Xử lý response chung
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        message: data['message'] ?? 'Có lỗi xảy ra',
        statusCode: response.statusCode,
        errors: data['errors'],
      );
    }
  }

  // ============ AUTH ENDPOINTS ============

  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _defaultHeaders,
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    return _handleResponse(response);
  }

  // Gửi OTP
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    String type = 'verification',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: _defaultHeaders,
      body: json.encode({
        'email': email,
        'type': type,
      }),
    );

    return _handleResponse(response);
  }

  // Xác thực OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _defaultHeaders,
      body: json.encode({
        'email': email,
        'otp': otp,
        'name': name,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final data = _handleResponse(response);

    // Lưu token nếu đăng ký thành công
    if (data['success'] == true && data['data']['access_token'] != null) {
      await _saveToken(data['data']['access_token']);
    }

    return data;
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _defaultHeaders,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final data = _handleResponse(response);

    // Lưu token nếu đăng nhập thành công
    if (data['success'] == true && data['data']['access_token'] != null) {
      await _saveToken(data['data']['access_token']);
    }

    return data;
  }

  // Quên mật khẩu
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _defaultHeaders,
      body: json.encode({
        'email': email,
      }),
    );

    return _handleResponse(response);
  }

  // Đặt lại mật khẩu
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _defaultHeaders,
      body: json.encode({
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    return _handleResponse(response);
  }

  // Thay đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: await _authHeaders,
      body: json.encode({
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    return _handleResponse(response);
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders,
    );

    return _handleResponse(response);
  }

  // Đăng xuất
  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: await _authHeaders,
    );

    final data = _handleResponse(response);

    // Xóa token khi đăng xuất
    await _removeToken();

    return data;
  }

  // ============ MOVIE ENDPOINTS ============

  // Lấy danh sách phim
  Future<Map<String, dynamic>> getMovies({
    String? genre,
    bool? featured,
    String? search,
    int page = 1,
    int perPage = 12,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (genre != null) queryParams['genre'] = genre;
    if (featured != null) queryParams['featured'] = featured.toString();
    if (search != null) queryParams['search'] = search;

    final uri =
        Uri.parse('$baseUrl/movies').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _defaultHeaders);

    return _handleResponse(response);
  }

  // Lấy phim nổi bật
  Future<Map<String, dynamic>> getFeaturedMovies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/movies/featured'),
      headers: _defaultHeaders,
    );

    return _handleResponse(response);
  }

  // Tìm kiếm phim
  Future<Map<String, dynamic>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    final queryParams = {
      'q': query,
      'page': page.toString(),
    };

    final uri = Uri.parse('$baseUrl/movies/search')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _defaultHeaders);

    return _handleResponse(response);
  }

  // Lấy chi tiết phim
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movies/$movieId'),
      headers: _defaultHeaders,
    );

    return _handleResponse(response);
  }

  // ============ SCHEDULE ENDPOINTS ============

  // Lấy lịch chiếu của phim
  Future<Map<String, dynamic>> getMovieSchedules(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schedules/movie/$movieId/flutter'),
      headers: _defaultHeaders,
    );

    return _handleResponse(response);
  }

  // Lấy ngày có lịch chiếu của phim
  Future<Map<String, dynamic>> getMovieAvailableDates(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schedules/movie/$movieId/dates/flutter'),
      headers: _defaultHeaders,
    );

    return _handleResponse(response);
  }

  // Lấy ghế của lịch chiếu
  Future<Map<String, dynamic>> getScheduleSeats(int scheduleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/schedules/$scheduleId/seats'),
      headers: _defaultHeaders,
    );

    return _handleResponse(response);
  }

  // ============ BOOKING ENDPOINTS ============

  // Khóa ghế
  Future<Map<String, dynamic>> lockSeats({
    required int scheduleId,
    required List<String> seatNumbers,
    int lockDurationMinutes = 10,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/lock-seats'),
      headers: await _authHeaders,
      body: json.encode({
        'schedule_id': scheduleId,
        'seat_numbers': seatNumbers,
        'lock_duration_minutes': lockDurationMinutes,
      }),
    );

    return _handleResponse(response);
  }

  // Hủy khóa ghế
  Future<Map<String, dynamic>> releaseSeats({
    required int scheduleId,
    required List<int> seatIds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/release-seats'),
      headers: await _authHeaders,
      body: json.encode({
        'schedule_id': scheduleId,
        'seat_ids': seatIds,
      }),
    );

    return _handleResponse(response);
  }

  // Tạo booking
  Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required List<String> seatIds,
    List<Map<String, dynamic>>? snacks,
    required double totalPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: await _authHeaders,
      body: json.encode({
        'showtime_id': showtimeId,
        'seat_ids': seatIds,
        'snacks': snacks ?? [],
        'total_price': totalPrice,
      }),
    );

    return _handleResponse(response);
  }

  // Lấy chi tiết booking
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId'),
      headers: await _authHeaders,
    );

    return _handleResponse(response);
  }

  // Lấy danh sách booking của user
  Future<Map<String, dynamic>> getUserBookings(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/bookings'),
      headers: await _authHeaders,
    );

    return _handleResponse(response);
  }

  // Hủy booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: await _authHeaders,
    );

    return _handleResponse(response);
  }

  // Lấy danh sách snacks
  Future<Map<String, dynamic>> getSnacks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/snacks'),
      headers: _defaultHeaders,
    );

    return _handleResponse(response);
  }

  // ============ FAVORITE ENDPOINTS ============

  // Lấy danh sách yêu thích
  Future<Map<String, dynamic>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites'),
      headers: await _authHeaders,
    );

    return _handleResponse(response);
  }

  // Thêm vào yêu thích
  Future<Map<String, dynamic>> addToFavorites({
    required String movieId,
    required String title,
    required String posterUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: await _authHeaders,
      body: json.encode({
        'movie_id': movieId,
        'title': title,
        'poster_url': posterUrl,
      }),
    );

    return _handleResponse(response);
  }

  // Xóa khỏi yêu thích
  Future<Map<String, dynamic>> removeFromFavorites(String movieId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/$movieId'),
      headers: await _authHeaders,
    );

    return _handleResponse(response);
  }

  // ============ USER ENDPOINTS ============

  // Cập nhật thông tin user
  Future<Map<String, dynamic>> updateUser({
    String? name,
    String? email,
    String? avatar,
    bool? receiveNotifications,
  }) async {
    final user = await getCurrentUser();
    final userId = user['data']['id'];

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (avatar != null) body['avatar'] = avatar;
    if (receiveNotifications != null)
      body['receive_notifications'] = receiveNotifications;

    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await _authHeaders,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  // Cập nhật avatar
  Future<Map<String, dynamic>> updateAvatar({
    required String avatar,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/avatar'),
      headers: await _authHeaders,
      body: json.encode({
        'avatar': avatar,
      }),
    );

    return _handleResponse(response);
  }

  // ============ UTILITY METHODS ============

  // Kiểm tra kết nối mạng
  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: await _authHeaders,
    );

    final data = _handleResponse(response);

    // Lưu token mới
    if (data['success'] == true && data['data']['access_token'] != null) {
      await _saveToken(data['data']['access_token']);
    }

    return data;
  }
}

// Exception class cho API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}

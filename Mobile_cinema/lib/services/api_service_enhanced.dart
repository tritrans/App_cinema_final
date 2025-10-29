import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL của Laravel API
  // 10.0.2.2:8000 - Android emulator
  // 127.0.0.1:8000 - iOS simulator
  // localhost:8000 - Web/Desktop
  // your-ip:8000 - Real device
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // Alternative URLs to try:
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // Web/Desktop
  // static const String baseUrl = 'http://192.168.1.XXX:8000/api'; // Real device (replace XXX with your IP)

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

  /// Xử lý response từ API với error handling cải thiện
  ///
  /// [response] - HTTP response từ server
  ///
  /// Trả về Map chứa dữ liệu đã parse hoặc throw ApiException nếu có lỗi
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      // Use utf8.decode to handle encoding issues
      final decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = json.decode(decodedBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ApiException(
          message: data['message'] ?? 'Có lỗi xảy ra',
          statusCode: response.statusCode,
          errors: data['errors'],
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;

      // Better error handling for different types of errors
      String errorMessage;
      if (e is FormatException) {
        errorMessage = 'Dữ liệu từ server không hợp lệ';
      } else if (response.statusCode == 0) {
        errorMessage = 'Không thể kết nối đến server';
      } else if (response.statusCode >= 500) {
        errorMessage = 'Lỗi server, vui lòng thử lại sau';
      } else {
        errorMessage = 'Có lỗi xảy ra: ${e.toString()}';
      }

      throw ApiException(
        message: errorMessage,
        statusCode: response.statusCode,
        errors: null,
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
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Gửi OTP
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    String type = 'verification',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: _defaultHeaders,
        body: json.encode({
          'email': email,
          'type': type,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Xác thực OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Quên mật khẩu
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _defaultHeaders,
        body: json.encode({
          'email': email,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Đặt lại mật khẩu
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Thay đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Đăng xuất
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _authHeaders,
      );

      final data = _handleResponse(response);

      // Xóa token khi đăng xuất
      await _removeToken();

      return data;
    } catch (e) {
      // Xóa token ngay cả khi có lỗi
      await _removeToken();
      rethrow;
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
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
    } catch (e) {
      rethrow;
    }
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
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Lấy phim nổi bật
  Future<Map<String, dynamic>> getFeaturedMovies() async {
    try {
      final uri = Uri.parse('$baseUrl/movies/featured');
      final response = await http.get(uri, headers: _defaultHeaders);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách thể loại
  Future<Map<String, dynamic>> getGenres() async {
    try {
      final uri = Uri.parse('$baseUrl/genres');
      final response = await http.get(uri, headers: _defaultHeaders);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách yêu thích
  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final uri = Uri.parse('$baseUrl/favorites');
      final response = await http.get(uri, headers: _defaultHeaders);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Thêm vào yêu thích
  Future<Map<String, dynamic>> addToFavorites({required int movieId}) async {
    try {
      final uri = Uri.parse('$baseUrl/favorites');
      final response = await http.post(
        uri,
        headers: _defaultHeaders,
        body: json.encode({'movie_id': movieId}),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Xóa khỏi yêu thích
  Future<Map<String, dynamic>> removeFromFavorites(
      {required int movieId}) async {
    try {
      final uri = Uri.parse('$baseUrl/favorites/$movieId');
      final response = await http.delete(uri, headers: _defaultHeaders);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy phim theo ID
  Future<Map<String, dynamic>> getMovieById(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/movies/$id');
      final response = await http.get(uri, headers: _defaultHeaders);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Tìm kiếm phim
  Future<Map<String, dynamic>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page.toString(),
      };

      final uri = Uri.parse('$baseUrl/movies/search')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy chi tiết phim
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$movieId'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ SCHEDULE ENDPOINTS ============

  // Lấy lịch chiếu của phim
  Future<Map<String, dynamic>> getMovieSchedules(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/movie/$movieId/flutter'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy ngày có lịch chiếu của phim
  Future<Map<String, dynamic>> getMovieAvailableDates(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/movie/$movieId/dates/flutter'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy ghế của lịch chiếu
  Future<Map<String, dynamic>> getScheduleSeats(int scheduleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/$scheduleId/seats'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy thông tin chi tiết của một lịch chiếu
  Future<Map<String, dynamic>> getScheduleDetails(int scheduleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/$scheduleId'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy tất cả lịch chiếu
  Future<Map<String, dynamic>> getAllSchedules({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final uri =
          Uri.parse('$baseUrl/schedules').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy lịch chiếu theo ngày
  Future<Map<String, dynamic>> getSchedulesByDate({
    required String date,
    int? theaterId,
    int? movieId,
  }) async {
    try {
      final queryParams = <String, String>{
        'date': date,
      };

      if (theaterId != null) queryParams['theater_id'] = theaterId.toString();
      if (movieId != null) queryParams['movie_id'] = movieId.toString();

      final uri = Uri.parse('$baseUrl/schedules/date')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ THEATER ENDPOINTS ============

  // Lấy danh sách rạp
  Future<Map<String, dynamic>> getTheaters({
    String? city,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (city != null) queryParams['city'] = city;

      final uri =
          Uri.parse('$baseUrl/theaters').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy chi tiết rạp
  Future<Map<String, dynamic>> getTheaterDetails(int theaterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/theaters/$theaterId'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy lịch chiếu của rạp
  Future<Map<String, dynamic>> getTheaterSchedules(int theaterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/theaters/$theaterId/schedules'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy lịch chiếu phim tại rạp
  Future<Map<String, dynamic>> getTheaterMovieSchedules(
      int theaterId, int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/theaters/$theaterId/movies/$movieId/schedules'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ BOOKING ENDPOINTS ============

  // Khóa ghế
  Future<Map<String, dynamic>> lockSeats({
    required int scheduleId,
    required List<String> seatNumbers,
    int lockDurationMinutes = 10,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Hủy khóa ghế
  Future<Map<String, dynamic>> releaseSeats({
    required int scheduleId,
    required List<int> seatIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/release-seats'),
        headers: await _authHeaders,
        body: json.encode({
          'schedule_id': scheduleId,
          'seat_ids': seatIds,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Tạo booking
  Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required List<String> seatIds,
    List<Map<String, dynamic>>? snacks,
    required double totalPrice,
    int? userId,
  }) async {
    try {
      // Get current user ID if not provided
      int actualUserId = userId ?? 6; // Default fallback
      if (userId == null) {
        try {
          final currentUser = await getCurrentUser();
          actualUserId = currentUser['data']['id'] ?? 6;
        } catch (e) {
          print('ApiService: Could not get current user, using fallback: $e');
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: await _authHeaders,
        body: json.encode({
          'user_id': actualUserId,
          'showtime_id': showtimeId,
          'seat_ids': seatIds,
          'snacks': snacks ?? [],
          'total_price': totalPrice,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy chi tiết booking
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách booking của user
  Future<Map<String, dynamic>> getUserBookings(int userId) async {
    try {
      // Kiểm tra user hiện tại trước
      print('ApiService: Checking current user...');
      final currentUserResponse = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _authHeaders,
      );
      print(
          'ApiService: Current user response status: ${currentUserResponse.statusCode}');
      print(
          'ApiService: Current user response body: ${currentUserResponse.body}');

      if (currentUserResponse.statusCode == 200) {
        final currentUserData = json.decode(currentUserResponse.body);
        final currentUserId = currentUserData['data']?['id'];
        print(
            'ApiService: Current user ID: $currentUserId, Requested user ID: $userId');

        // Sử dụng user ID thực tế thay vì userId được truyền vào
        final actualUserId = currentUserId ?? userId;

        print('ApiService: Trying /users/$actualUserId/bookings...');
        final response = await http.get(
          Uri.parse('$baseUrl/users/$actualUserId/bookings'),
          headers: await _authHeaders,
        );
        print(
            'ApiService: /users/$actualUserId/bookings response status: ${response.statusCode}');
        print(
            'ApiService: /users/$actualUserId/bookings response body: ${response.body}');
        return _handleResponse(response);
      } else {
        throw Exception('Cannot get current user info');
      }
    } catch (e) {
      print('ApiService: Error getting user bookings: $e');
      rethrow;
    }
  }

  // Hủy booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách snacks
  Future<Map<String, dynamic>> getSnacks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/snacks'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ REVIEW ENDPOINTS ============

  // Lấy reviews của phim
  Future<Map<String, dynamic>> getMovieReviews(int movieId,
      {int page = 1}) async {
    try {
      final queryParams = {
        'page': page.toString(),
      };

      final uri = Uri.parse('$baseUrl/movies/$movieId/reviews/public')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo đánh giá mới cho phim
  ///
  /// [movieId] - ID của phim
  /// [rating] - Điểm đánh giá (1-5)
  /// [comment] - Nội dung đánh giá (tùy chọn)
  ///
  /// Trả về Map chứa dữ liệu review đã tạo
  Future<Map<String, dynamic>> createReview({
    required int movieId,
    required double rating,
    String? comment,
  }) async {
    try {
      // Get current user ID
      int userId = 6; // Default fallback
      try {
        final currentUser = await getCurrentUser();
        userId = currentUser['data']['id'] ?? 6;
      } catch (e) {
        print(
            'ApiService: Could not get current user for review, using fallback: $e');
      }

      final requestBody = {
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      };

      print('ApiService: Creating review with body: $requestBody');
      print('ApiService: URL: $baseUrl/movies/$movieId/reviews');

      final response = await http.post(
        Uri.parse('$baseUrl/movies/$movieId/reviews'),
        headers: await _authHeaders,
        body: json.encode(requestBody),
      );

      print('ApiService: Review response status: ${response.statusCode}');
      print('ApiService: Review response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy review của user cho phim
  Future<Map<String, dynamic>> getUserMovieReview(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$movieId/user-review'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật review
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: await _authHeaders,
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Xóa review
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ COMMENT ENDPOINTS ============

  // Lấy comments của phim
  Future<Map<String, dynamic>> getMovieComments(int movieId,
      {int page = 1}) async {
    try {
      final queryParams = {
        'page': page.toString(),
      };

      final uri = Uri.parse('$baseUrl/movies/$movieId/comments/public')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _defaultHeaders);

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo comment mới cho phim
  ///
  /// [movieId] - ID của phim
  /// [content] - Nội dung bình luận
  /// [parentId] - ID của comment gốc (nếu là reply)
  ///
  /// Trả về Map chứa dữ liệu comment đã tạo
  Future<Map<String, dynamic>> createComment({
    required int movieId,
    required String content,
    int? parentId,
  }) async {
    try {
      // Get current user ID
      int userId = 6; // Default fallback
      try {
        final currentUser = await getCurrentUser();
        userId = currentUser['data']['id'] ?? 6;
      } catch (e) {
        print(
            'ApiService: Could not get current user for comment, using fallback: $e');
      }

      final requestBody = {
        'user_id': userId,
        'content': content,
        'parent_id': parentId,
      };

      print('ApiService: Creating comment with body: $requestBody');
      print('ApiService: URL: $baseUrl/movies/$movieId/comments');

      final response = await http.post(
        Uri.parse('$baseUrl/movies/$movieId/comments'),
        headers: await _authHeaders,
        body: json.encode(requestBody),
      );

      print('ApiService: Comment response status: ${response.statusCode}');
      print('ApiService: Comment response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo reply cho comment
  ///
  /// [commentId] - ID của comment gốc
  /// [content] - Nội dung reply
  ///
  /// Trả về Map chứa dữ liệu reply đã tạo
  Future<Map<String, dynamic>> createCommentReply({
    required int commentId,
    required String content,
  }) async {
    try {
      // Get current user ID
      int userId = 6; // Default fallback
      try {
        final currentUser = await getCurrentUser();
        userId = currentUser['data']['id'] ?? 6;
      } catch (e) {
        print(
            'ApiService: Could not get current user for comment reply, using fallback: $e');
      }

      final requestBody = {
        'user_id': userId,
        'content': content,
      };

      print('ApiService: Creating comment reply with body: $requestBody');
      print('ApiService: URL: $baseUrl/comments/$commentId/reply');

      final response = await http.post(
        Uri.parse('$baseUrl/comments/$commentId/reply'),
        headers: await _authHeaders,
        body: json.encode(requestBody),
      );

      print(
          'ApiService: Comment reply response status: ${response.statusCode}');
      print('ApiService: Comment reply response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo reply cho đánh giá (thực chất là tạo comment)
  ///
  /// [reviewId] - ID của đánh giá gốc
  /// [content] - Nội dung reply
  ///
  /// Trả về Map chứa dữ liệu reply đã tạo
  Future<Map<String, dynamic>> createReviewReply({
    required int reviewId,
    required String content,
  }) async {
    try {
      // Get current user ID
      int userId = 6; // Default fallback
      try {
        final currentUser = await getCurrentUser();
        userId = currentUser['data']['id'] ?? 6;
      } catch (e) {
        print(
            'ApiService: Could not get current user for review reply, using fallback: $e');
      }

      final requestBody = {
        'user_id': userId,
        'content': content,
      };

      print('ApiService: Creating review reply with body: $requestBody');
      print('ApiService: URL: $baseUrl/reviews/$reviewId/reply');

      final response = await http.post(
        Uri.parse('$baseUrl/reviews/$reviewId/reply'),
        headers: await _authHeaders,
        body: json.encode(requestBody),
      );

      print('ApiService: Review reply response status: ${response.statusCode}');
      print('ApiService: Review reply response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật comment
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: await _authHeaders,
        body: json.encode({
          'content': content,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Xóa comment
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: await _authHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ USER ENDPOINTS ============

  // Cập nhật thông tin user
  Future<Map<String, dynamic>> updateUser({
    String? name,
    String? email,
    String? avatar,
    bool? receiveNotifications,
  }) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật avatar
  Future<Map<String, dynamic>> updateAvatar({
    required String avatar,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/avatar'),
        headers: await _authHeaders,
        body: json.encode({
          'avatar': avatar,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
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

  // Test API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test-auth'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy thông tin database test
  Future<Map<String, dynamic>> testDatabase() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test-db'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách đạo diễn
  Future<Map<String, dynamic>> getDirectors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/directors'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách diễn viên
  Future<Map<String, dynamic>> getActors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/actors'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ MOVIE CAST ENDPOINTS ============

  // Lấy danh sách cast của phim
  Future<Map<String, dynamic>> getMovieCast(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$movieId/cast'),
        headers: _defaultHeaders,
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật cast của phim
  Future<Map<String, dynamic>> updateMovieCast({
    required int movieId,
    required List<String> cast,
    String? director,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/movies/$movieId/cast'),
        headers: await _authHeaders,
        body: json.encode({
          'cast': cast,
          'director': director,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ USER FILE UPLOAD ENDPOINTS ============

  // Upload avatar (user only)
  Future<Map<String, dynamic>> uploadAvatar({
    required File file,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/users/avatar');
      var request = http.MultipartRequest('POST', uri)
        ..headers.addAll(await _authHeaders)
        ..files.add(await http.MultipartFile.fromPath(
          'avatar',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ USER PROFILE ENDPOINTS ============

  // Cập nhật thông tin profile user
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      final user = await getCurrentUser();
      final userId = user['data']['id'];

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (dateOfBirth != null)
        body['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) body['gender'] = gender;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _authHeaders,
        body: json.encode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  // ============ IMAGE PROXY ============

  // Lấy URL hình ảnh qua proxy để tránh CORS
  String getImageProxyUrl(String originalUrl) {
    if (originalUrl.contains('drive.google.com')) {
      return '$baseUrl/image-proxy?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

  // Lưu booking vào database
  Future<Map<String, dynamic>> saveBookingToDatabase({
    required int userId,
    required int showtimeId,
    required List<String> selectedSeats,
    required Map<int, int> selectedSnacks,
    required List<dynamic> snacks,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      // Chuyển đổi selectedSeats thành seatIds (giả sử seat ID = seat number)
      final seatIds = selectedSeats;

      // Chuyển đổi selectedSnacks thành format phù hợp
      final snacksList = selectedSnacks.entries.map((entry) {
        // Tìm snack trong danh sách (snacks có thể là List<dynamic> hoặc List<Snack>)
        dynamic snack;
        try {
          snack = snacks.firstWhere(
            (s) {
              // Xử lý cả trường hợp s là Map hoặc Snack object
              if (s is Map<String, dynamic>) {
                return s['id'] == entry.key;
              } else {
                return s.id == entry.key;
              }
            },
          );
        } catch (e) {
          // Nếu không tìm thấy, tạo snack mặc định
          snack = null;
        }

        // Lấy price từ snack
        double price = 0.0;
        if (snack != null) {
          if (snack is Map<String, dynamic>) {
            price = (snack['price'] ?? 0.0).toDouble();
          } else {
            price = snack.price ?? 0.0;
          }
        }

        return {
          'snack_id': entry.key,
          'quantity': entry.value,
          'unit_price': price,
        };
      }).toList();

      // Sử dụng method createBooking có sẵn
      return await createBooking(
        showtimeId: showtimeId,
        seatIds: seatIds,
        snacks: snacksList,
        totalPrice: totalPrice,
      );
    } catch (e) {
      throw ApiException(
        message: 'Lỗi lưu booking: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Cập nhật trạng thái ghế đã đặt
  Future<Map<String, dynamic>> updateSeatStatus({
    required int showtimeId,
    required List<String> selectedSeats,
    required String status, // 'booked' hoặc 'available'
  }) async {
    try {
      // Chuyển đổi selectedSeats thành seatIds
      final seatIds = selectedSeats.map((seat) => seat.hashCode).toList();

      // Sử dụng method lockSeats có sẵn để khóa ghế
      if (status == 'booked') {
        return await lockSeats(
          scheduleId: showtimeId,
          seatNumbers: selectedSeats,
          lockDurationMinutes: 999999, // Khóa vĩnh viễn
        );
      } else {
        // Nếu muốn mở khóa ghế, có thể sử dụng releaseSeats
        return await releaseSeats(
          scheduleId: showtimeId,
          seatIds: seatIds,
        );
      }
    } catch (e) {
      throw ApiException(
        message: 'Lỗi cập nhật trạng thái ghế: ${e.toString()}',
        statusCode: 500,
      );
    }
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

  // Getter để lấy thông báo lỗi chi tiết
  String get detailedMessage {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = <String>[];
      errors!.forEach((field, messages) {
        if (messages is List) {
          errorMessages.addAll(messages.cast<String>());
        } else {
          errorMessages.add(messages.toString());
        }
      });
      return errorMessages.join('\n');
    }
    return message;
  }

  // Getter để kiểm tra loại lỗi
  bool get isNetworkError => statusCode == 0 || statusCode >= 500;
  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isValidationError => statusCode == 422;
  bool get isNotFoundError => statusCode == 404;
}

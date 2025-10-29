import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator

  // Helper to get headers
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Helper for handling response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'An error occurred');
    }
  }

  // --- Movie Methods ---
  Future<Map<String, dynamic>> getMovies({
    String? genre,
    bool? featured,
    int page = 1,
    int perPage = 12,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (genre != null) {
      queryParams['genre'] = genre;
    }
    if (featured != null) {
      queryParams['featured'] = featured.toString();
    }

    final uri =
        Uri.parse('$baseUrl/movies').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getFeaturedMovies() async {
    final uri = Uri.parse('$baseUrl/movies/featured');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    final Map<String, String> queryParams = {
      'q': query,
      'page': page.toString(),
    };
    final uri = Uri.parse('$baseUrl/movies/search')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMovieCast(int movieId) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId/cast');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  // --- Auth Methods ---
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(uri,
        headers: _getHeaders(),
        body:
            json.encode({'name': name, 'email': email, 'password': password}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final body = {'email': email, 'password': password};
    print('ApiService: Login request to $uri');
    print('ApiService: Login body: $body');
    final response =
        await http.post(uri, headers: _getHeaders(), body: json.encode(body));
    print('ApiService: Login response status: ${response.statusCode}');
    print('ApiService: Login response body: ${response.body}');
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    final uri = Uri.parse('$baseUrl/auth/send-otp');
    final response = await http.post(uri,
        headers: _getHeaders(), body: json.encode({'email': email}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final uri = Uri.parse('$baseUrl/auth/verify-otp');
    final response = await http.post(uri,
        headers: _getHeaders(),
        body: json.encode({'email': email, 'otp': otp}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$baseUrl/auth/forgot-password');
    final response = await http.post(uri,
        headers: _getHeaders(), body: json.encode({'email': email}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String token) async {
    final uri = Uri.parse('$baseUrl/auth/reset-password');
    final response = await http.post(uri,
        headers: _getHeaders(),
        body: json
            .encode({'email': email, 'password': password, 'token': token}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword, String token) async {
    final uri = Uri.parse('$baseUrl/auth/change-password');
    final response = await http.post(uri,
        headers: _getHeaders(token: token),
        body: json.encode(
            {'old_password': oldPassword, 'new_password': newPassword}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final uri = Uri.parse('$baseUrl/auth/me');
    final response = await http.get(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> data, String token) async {
    final uri = Uri.parse('$baseUrl/users/$userId');
    final response = await http.put(uri,
        headers: _getHeaders(token: token), body: json.encode(data));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateAvatar(File image, String token) async {
    final uri = Uri.parse('$baseUrl/users/avatar');
    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_getHeaders(token: token))
      ..files.add(await http.MultipartFile.fromPath(
        'avatar',
        image.path,
        contentType:
            MediaType('image', 'jpeg'), // Adjust content type if needed
      ));
    final response = await http.Response.fromStream(await request.send());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout(String token) async {
    final uri = Uri.parse('$baseUrl/auth/logout');
    final response = await http.post(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  // --- Favorite Methods ---
  Future<Map<String, dynamic>> getFavorites(String token) async {
    final uri = Uri.parse('$baseUrl/favorites');
    final response = await http.get(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addToFavorites(int movieId, String token) async {
    final uri = Uri.parse('$baseUrl/favorites');
    final response = await http.post(uri,
        headers: _getHeaders(token: token),
        body: json.encode({'movie_id': movieId}));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeFromFavorites(
      int movieId, String token) async {
    final uri = Uri.parse('$baseUrl/favorites/$movieId');
    final response = await http.delete(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  // --- Review & Comment Methods ---
  Future<Map<String, dynamic>> getMovieReviews(int movieId) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId/reviews');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addMovieReview(
      int movieId, double rating, String content, String token) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId/reviews');
    final body = json.encode({'rating': rating, 'comment': content});
    final response =
        await http.post(uri, headers: _getHeaders(token: token), body: body);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMovieComments(int movieId) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId/comments');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> addMovieComment(int movieId, String content,
      {int? parentId, String? token}) async {
    final uri = Uri.parse('$baseUrl/movies/$movieId/comments');
    final body = json.encode({'content': content, 'parent_id': parentId});
    final response =
        await http.post(uri, headers: _getHeaders(token: token), body: body);
    return _handleResponse(response);
  }

  // Reply to review
  Future<Map<String, dynamic>> replyToReview(int reviewId, String content,
      {String? token}) async {
    final uri = Uri.parse('$baseUrl/reviews/$reviewId/reply');
    final body = json.encode({'content': content});
    final response =
        await http.post(uri, headers: _getHeaders(token: token), body: body);
    return _handleResponse(response);
  }

  // Reply to comment
  Future<Map<String, dynamic>> replyToComment(int commentId, String content,
      {String? token}) async {
    final uri = Uri.parse('$baseUrl/comments/$commentId/reply');
    final body = json.encode({'content': content});
    final response =
        await http.post(uri, headers: _getHeaders(token: token), body: body);
    return _handleResponse(response);
  }

  // --- Booking/Ticket Methods ---
  Future<Map<String, dynamic>> getUserBookings(int userId, String token) async {
    final uri = Uri.parse('$baseUrl/users/$userId/bookings');
    final response = await http.get(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData, String token) async {
    final uri = Uri.parse('$baseUrl/bookings');
    final response = await http.post(uri,
        headers: _getHeaders(token: token), body: json.encode(bookingData));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelBooking(
      int bookingId, String token) async {
    final uri = Uri.parse('$baseUrl/bookings/$bookingId/cancel');
    final response = await http.post(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getBookingDetails(
      int bookingId, String token) async {
    final uri = Uri.parse('$baseUrl/bookings/$bookingId');
    final response = await http.get(uri, headers: _getHeaders(token: token));
    return _handleResponse(response);
  }

  // --- Schedule, Theater, and Seat Methods ---
  Future<Map<String, dynamic>> getMovieScheduleDates(int movieId) async {
    final uri = Uri.parse('$baseUrl/schedules/movie/$movieId/dates/flutter');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getMovieSchedules(
      int movieId, String date) async {
    final queryParams = {'date': date};
    final uri = Uri.parse('$baseUrl/schedules/movie/$movieId/flutter')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getScheduleSeats(int scheduleId) async {
    final uri = Uri.parse('$baseUrl/schedules/$scheduleId/seats');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> lockSeats(
      int scheduleId, List<int> seatIds, String token) async {
    final uri = Uri.parse('$baseUrl/bookings/lock-seats');
    final body = json.encode({'schedule_id': scheduleId, 'seat_ids': seatIds});
    final response =
        await http.post(uri, headers: _getHeaders(token: token), body: body);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> releaseSeats(String lockId, String token) async {
    final uri = Uri.parse('$baseUrl/bookings/release-seats');
    final body = json.encode({'lock_id': lockId});
    final response =
        await http.post(uri, headers: _getHeaders(token: token), body: body);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getSnacks() async {
    final uri = Uri.parse('$baseUrl/snacks');
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }
}

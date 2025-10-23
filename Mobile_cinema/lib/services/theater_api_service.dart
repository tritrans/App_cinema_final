import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/theater.dart';

class TheaterApiService {
  static const String baseUrl =
      'http://10.0.2.2:8000/api'; // Thay đổi IP nếu cần

  // Helper to get headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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

  /// Lấy danh sách tất cả rạp chiếu
  Future<List<Theater>> getAllTheaters() async {
    try {
      print('TheaterApiService: Calling API to get all theaters...');

      final response = await http.get(
        Uri.parse('$baseUrl/theaters/basic'),
        headers: _getHeaders(),
      );

      print('TheaterApiService: API response status: ${response.statusCode}');
      print(
          'TheaterApiService: API response body length: ${response.body.length}');

      // Log first 500 characters to debug JSON format
      final preview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      print('TheaterApiService: Response preview: $preview');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          // Handle different response formats
          List<dynamic> theatersJson;
          if (data is List) {
            // Direct array response
            theatersJson = data;
            print(
                'TheaterApiService: Direct array response with ${theatersJson.length} theaters');
          } else if (data is Map && data['data'] != null) {
            // Wrapped response
            theatersJson = data['data'];
            print(
                'TheaterApiService: Wrapped response with ${theatersJson.length} theaters');
          } else {
            print('TheaterApiService: Unexpected response format: $data');
            throw Exception('Unexpected API response format');
          }

          final theaters = theatersJson.map((theaterJson) {
            try {
              return Theater.fromJson(theaterJson);
            } catch (e) {
              print('TheaterApiService: Error parsing theater: $e');
              print('TheaterApiService: Theater data: $theaterJson');
              rethrow;
            }
          }).toList();

          print(
              'TheaterApiService: Successfully loaded ${theaters.length} theaters');
          return theaters;
        } catch (e) {
          print('TheaterApiService: JSON parsing error: $e');
          throw Exception('Failed to parse API response: $e');
        }
      } else {
        print('TheaterApiService: API error: ${response.statusCode}');
        print('TheaterApiService: Error response: ${response.body}');
        throw Exception(
            'API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      print('TheaterApiService: Error loading theaters: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết một rạp chiếu
  Future<Theater> getTheaterById(int theaterId) async {
    try {
      print('TheaterApiService: Calling API to get theater $theaterId...');

      final response = await http.get(
        Uri.parse('$baseUrl/theaters/$theaterId'),
        headers: _getHeaders(),
      );

      print('TheaterApiService: API response status: ${response.statusCode}');
      print('TheaterApiService: API response body: ${response.body}');

      final data = _handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        final theater = Theater.fromJson(data['data']);
        print(
            'TheaterApiService: Successfully loaded theater: ${theater.name}');
        return theater;
      } else {
        throw Exception(data['message'] ?? 'Failed to load theater');
      }
    } catch (e) {
      print('TheaterApiService: Error loading theater: $e');
      rethrow;
    }
  }

  /// Lấy lịch chiếu của một rạp
  Future<List<Map<String, dynamic>>> getTheaterSchedules(int theaterId) async {
    try {
      print(
          'TheaterApiService: Calling API to get schedules for theater $theaterId...');

      final response = await http.get(
        Uri.parse('$baseUrl/theaters/$theaterId/schedules'),
        headers: _getHeaders(),
      );

      print('TheaterApiService: API response status: ${response.statusCode}');
      print('TheaterApiService: API response body: ${response.body}');

      final data = _handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> schedulesJson = data['data'];
        print(
            'TheaterApiService: Successfully loaded ${schedulesJson.length} schedules');
        return schedulesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception(data['message'] ?? 'Failed to load theater schedules');
      }
    } catch (e) {
      print('TheaterApiService: Error loading theater schedules: $e');
      rethrow;
    }
  }

  /// Lấy lịch chiếu phim tại một rạp cụ thể
  Future<List<Map<String, dynamic>>> getTheaterMovieSchedules(
      int theaterId, int movieId) async {
    try {
      print(
          'TheaterApiService: Calling API to get movie $movieId schedules at theater $theaterId...');

      final response = await http.get(
        Uri.parse('$baseUrl/theaters/$theaterId/movies/$movieId/schedules'),
        headers: _getHeaders(),
      );

      print('TheaterApiService: API response status: ${response.statusCode}');
      print('TheaterApiService: API response body: ${response.body}');

      final data = _handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> schedulesJson = data['data'];
        print(
            'TheaterApiService: Successfully loaded ${schedulesJson.length} movie schedules');
        return schedulesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            data['message'] ?? 'Failed to load theater movie schedules');
      }
    } catch (e) {
      print('TheaterApiService: Error loading theater movie schedules: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tên rạp duy nhất (không trùng lặp)
  Future<List<String>> getUniqueTheaterNames() async {
    try {
      final theaters = await getAllTheaters();
      final uniqueNames =
          theaters.map((theater) => theater.name).toSet().toList();
      print(
          'TheaterApiService: Found ${uniqueNames.length} unique theater names: $uniqueNames');
      return uniqueNames;
    } catch (e) {
      print('TheaterApiService: Error getting unique theater names: $e');
      rethrow;
    }
  }

  /// Lấy tất cả chi nhánh của một rạp theo tên
  Future<List<Theater>> getTheatersByName(String theaterName) async {
    try {
      final theaters = await getAllTheaters();
      final theatersWithSameName =
          theaters.where((theater) => theater.name == theaterName).toList();
      print(
          'TheaterApiService: Found ${theatersWithSameName.length} branches for $theaterName');
      return theatersWithSameName;
    } catch (e) {
      print('TheaterApiService: Error getting theaters by name: $e');
      rethrow;
    }
  }
}

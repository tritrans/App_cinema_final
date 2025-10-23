import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/seat.dart';
import 'api_service_enhanced.dart';

class SeatApiService {
  final String baseUrl = ApiService.baseUrl;

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    try {
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
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi kết nối: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Lấy danh sách ghế cho một suất chiếu cụ thể
  Future<List<Seat>> getSeatsForSchedule(int scheduleId) async {
    try {
      final uri = Uri.parse('$baseUrl/schedules/$scheduleId/seats');
      final response = await http.get(uri, headers: _defaultHeaders);
      final decodedResponse = await _handleResponse(response);

      if (decodedResponse['success'] == true &&
          decodedResponse['data'] != null) {
        return (decodedResponse['data'] as List)
            .map((json) => Seat.fromJson(json))
            .toList();
      } else {
        throw ApiException(
          message: decodedResponse['message'] ?? 'Failed to load seats',
          statusCode: 400,
        );
      }
    } catch (e) {
      print('SeatApiService: Error in getSeatsForSchedule: $e');
      rethrow;
    }
  }

  /// Khóa ghế (reserve seats)
  Future<Map<String, dynamic>> lockSeats({
    required int scheduleId,
    required List<String> seatIds,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/bookings/lock-seats');
      final response = await http.post(
        uri,
        headers: _defaultHeaders,
        body: jsonEncode({
          'schedule_id': scheduleId,
          'seat_ids': seatIds,
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      print('SeatApiService: Error in lockSeats: $e');
      rethrow;
    }
  }

  /// Giải phóng ghế (release seats)
  Future<Map<String, dynamic>> releaseSeats({
    required int scheduleId,
    required List<String> seatIds,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/bookings/release-seats');
      final response = await http.post(
        uri,
        headers: _defaultHeaders,
        body: jsonEncode({
          'schedule_id': scheduleId,
          'seat_ids': seatIds,
        }),
      );

      return await _handleResponse(response);
    } catch (e) {
      print('SeatApiService: Error in releaseSeats: $e');
      rethrow;
    }
  }
}

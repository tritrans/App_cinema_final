import 'movie.dart';
import 'theater.dart';

class Schedule {
  final int id;
  final int movieId;
  final int theaterId;
  final DateTime startTime;
  final DateTime endTime;
  final String format; // 2D, 3D, IMAX, etc.
  final String roomName;
  final double price;
  final int availableSeats;
  final int totalSeats;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final Movie? movie;
  final Theater? theater;

  Schedule({
    required this.id,
    required this.movieId,
    required this.theaterId,
    required this.startTime,
    required this.endTime,
    required this.format,
    required this.roomName,
    required this.price,
    required this.availableSeats,
    required this.totalSeats,
    required this.createdAt,
    required this.updatedAt,
    this.movie,
    this.theater,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    try {
      return Schedule(
        id: json['id'] ?? 0,
        movieId: json['movie_id'] ?? 0,
        theaterId: json['theater_id'] ?? 0,
        startTime: DateTime.parse(
            json['start_time'] ?? DateTime.now().toIso8601String()),
        endTime: DateTime.parse(
            json['end_time'] ?? DateTime.now().toIso8601String()),
        format:
            json['format']?.toString() ?? '2D', // API không trả về field này
        roomName: json['room_name']?.toString() ?? 'Room 1',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        availableSeats: json['available_seats'] ?? 0,
        totalSeats: json['total_seats'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(), // API không trả về field này
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(), // API không trả về field này
        movie: json['movie'] != null ? Movie.fromJson(json['movie']) : null,
        theater:
            json['theater'] != null ? Theater.fromJson(json['theater']) : null,
      );
    } catch (e) {
      print('Schedule.fromJson error: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'theater_id': theaterId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'format': format,
      'room_name': roomName,
      'price': price,
      'available_seats': availableSeats,
      'total_seats': totalSeats,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'movie': movie?.toJson(),
      'theater': theater?.toJson(),
    };
  }

  // Getter để lấy ngày chiếu
  DateTime get showDate =>
      DateTime(startTime.year, startTime.month, startTime.day);

  // Getter để lấy giờ chiếu dạng string
  String get showTimeString {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  // Getter để lấy giờ kết thúc dạng string
  String get endTimeString {
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  // Getter để lấy thời gian chiếu đầy đủ
  String get fullShowTime => '$showTimeString - $endTimeString';

  // Getter để lấy ngày chiếu dạng string
  String get showDateString {
    final months = [
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
    return '${showDate.day} ${months[showDate.month - 1]} ${showDate.year}';
  }

  // Getter để kiểm tra lịch chiếu có khả dụng không
  bool get isAvailable =>
      availableSeats > 0 && startTime.isAfter(DateTime.now());

  // Getter để kiểm tra lịch chiếu đã qua chưa
  bool get isPast => startTime.isBefore(DateTime.now());

  // Getter để lấy phần trăm ghế đã bán
  double get occupancyRate =>
      totalSeats > 0 ? (totalSeats - availableSeats) / totalSeats : 0.0;

  // Getter để lấy giá tiền dạng string
  String get priceString => '${price.toStringAsFixed(0)} VND';

  // Getter để lấy thông tin phòng chiếu đầy đủ
  String get roomInfo => '$roomName ($format)';
}

class ScheduleResponse {
  final bool success;
  final String message;
  final List<Schedule> schedules;
  final Map<String, List<Schedule>>? groupedSchedules; // Grouped by date

  ScheduleResponse({
    required this.success,
    required this.message,
    required this.schedules,
    this.groupedSchedules,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) {
    List<Schedule> schedulesList = [];
    Map<String, List<Schedule>>? grouped;

    try {
      if (json['data'] is List) {
        // Direct array of schedules
        schedulesList = (json['data'] as List)
            .map((scheduleJson) => Schedule.fromJson(scheduleJson))
            .toList();
      } else if (json['data'] is Map) {
        // Check if it's grouped by date (Flutter format)
        final data = json['data'] as Map<String, dynamic>;
        if (data.containsKey('grouped_schedules')) {
          grouped = {};
          final groupedData = data['grouped_schedules'] as Map<String, dynamic>;
          groupedData.forEach((date, schedules) {
            grouped![date] =
                (schedules as List).map((s) => Schedule.fromJson(s)).toList();
            schedulesList.addAll(grouped[date]!);
          });
        } else if (data.containsKey('schedules')) {
          // Regular schedules array
          schedulesList = (data['schedules'] as List)
              .map((scheduleJson) => Schedule.fromJson(scheduleJson))
              .toList();
        }
      }
    } catch (e) {
      print('ScheduleResponse: Error parsing schedules: $e');
    }

    return ScheduleResponse(
      success: json['success'],
      message: json['message'] ?? '',
      schedules: schedulesList,
      groupedSchedules: grouped,
    );
  }

  // Group schedules by date if not already grouped
  Map<String, List<Schedule>> get schedulesByDate {
    if (groupedSchedules != null) return groupedSchedules!;

    final Map<String, List<Schedule>> grouped = {};
    for (final schedule in schedules) {
      final dateKey = schedule.showDateString;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(schedule);
    }

    // Sort schedules within each date by start time
    grouped.forEach((date, scheduleList) {
      scheduleList.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return grouped;
  }

  // Get available dates
  List<String> get availableDates {
    return schedulesByDate.keys.toList()..sort();
  }
}

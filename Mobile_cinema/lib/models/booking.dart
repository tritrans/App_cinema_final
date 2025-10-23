import 'user.dart';
import 'schedule.dart';

class Booking {
  final int? id; // Made nullable
  final String bookingId;
  final int? userId; // Made nullable
  final int? showtimeId; // Made nullable
  final double totalPrice;
  final String status; // confirmed, cancelled, pending
  final DateTime? createdAt; // Made nullable
  final DateTime? updatedAt; // Made nullable

  // Relationships
  final User? user;
  final Schedule? showtime;
  final List<BookingSeat> seats;
  final List<BookingSnack> snacks;

  Booking({
    this.id, // Made nullable
    required this.bookingId,
    this.userId, // No longer required
    this.showtimeId, // No longer required
    required this.totalPrice,
    required this.status,
    this.createdAt, // No longer required
    this.updatedAt, // No longer required
    this.user,
    this.showtime,
    required this.seats,
    required this.snacks,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: (json['id'] as int?) ??
          0, // Cast to nullable int and provide fallback
      bookingId: json['booking_id'],
      userId: json['user_id'] as int?, // Cast to nullable int
      showtimeId: json['showtime_id'] as int?, // Cast to nullable int
      totalPrice: double.parse(json['total_price']?.toString() ?? '0'),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(), // Provide fallback
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(), // Provide fallback
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      showtime:
          json['showtime'] != null ? Schedule.fromJson(json['showtime']) : null,
      seats: json['seats'] != null
          ? (json['seats'] as List).map((s) => BookingSeat.fromJson(s)).toList()
          : [],
      snacks: json['snacks'] != null
          ? (json['snacks'] as List)
              .map((s) => BookingSnack.fromJson(s))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'showtime_id': showtimeId,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
      'showtime': showtime?.toJson(),
      'seats': seats.map((s) => s.toJson()).toList(),
      'snacks': snacks.map((s) => s.toJson()).toList(),
    };
  }

  // Getter để lấy tên phim
  String get movieTitle => showtime?.movie?.title ?? 'Unknown Movie';

  // Getter để lấy poster phim
  String get moviePoster => showtime?.movie?.poster ?? '';

  // Getter để lấy tên rạp
  String get theaterName => showtime?.theater?.name ?? 'Unknown Theater';

  // Getter để lấy địa chỉ rạp
  String get theaterAddress => showtime?.theater?.address ?? '';

  // Getter để lấy thời gian chiếu
  String get showTimeString => showtime?.fullShowTime ?? '';

  // Getter để lấy ngày chiếu
  String get showDateString => showtime?.showDateString ?? '';

  // Getter để lấy danh sách ghế
  String get seatNumbers => seats.map((s) => s.seatNumber).join(', ');

  // Getter để lấy số lượng ghế
  int get seatCount => seats.length;

  // Getter để lấy tổng giá vé
  double get ticketPrice => seats.fold(0.0, (sum, seat) => sum + seat.price);

  // Getter để lấy tổng giá đồ ăn
  double get snackPrice =>
      snacks.fold(0.0, (sum, snack) => sum + snack.totalPrice);

  // Getter để kiểm tra booking có thể hủy không
  bool get canCancel {
    if (status == 'cancelled') return false;
    if (showtime == null) return false;
    return showtime!.startTime.isAfter(DateTime.now());
  }

  // Getter để kiểm tra booking đã qua chưa
  bool get isPast {
    if (showtime == null) return true;
    return showtime!.startTime.isBefore(DateTime.now());
  }

  // Getter để lấy màu status
  String get statusColor {
    switch (status) {
      case 'confirmed':
        return '#4CAF50'; // Green
      case 'cancelled':
        return '#F44336'; // Red
      case 'pending':
        return '#FF9800'; // Orange
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Getter để lấy text status tiếng Việt
  String get statusText {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'pending':
        return 'Đang chờ';
      default:
        return 'Không xác định';
    }
  }
}

class BookingSeat {
  final int id;
  final int bookingId;
  final String seatNumber;
  final String seatType;
  final double price;

  BookingSeat({
    required this.id,
    required this.bookingId,
    required this.seatNumber,
    required this.seatType,
    required this.price,
  });

  factory BookingSeat.fromJson(Map<String, dynamic> json) {
    return BookingSeat(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'],
      seatNumber: json['seat_number'],
      seatType: json['seat_type'] ?? 'standard',
      price: double.parse(json['price']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'seat_number': seatNumber,
      'seat_type': seatType,
      'price': price,
    };
  }
}

class BookingSnack {
  final int id;
  final int bookingId;
  final int snackId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? snackName;
  final Snack? snack;

  BookingSnack({
    required this.id,
    required this.bookingId,
    required this.snackId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.snackName,
    this.snack,
  });

  factory BookingSnack.fromJson(Map<String, dynamic> json) {
    return BookingSnack(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'],
      snackId: json['snack_id'],
      quantity: json['quantity'],
      unitPrice: double.parse(json['unit_price']?.toString() ?? '0'),
      totalPrice: double.parse(json['total_price']?.toString() ?? '0'),
      snackName: json['snack_name'],
      snack: json['snack'] != null ? Snack.fromJson(json['snack']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'snack_id': snackId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'snack_name': snackName,
      'snack': snack?.toJson(),
    };
  }

  // Getter để lấy tên snack tiếng Việt
  String get snackNameVi => snack?.nameVi ?? snackName ?? 'Unknown Snack';
}

class Snack {
  final int id;
  final String name;
  final String nameVi;
  final String? description;
  final String? descriptionVi;
  final double price;
  final String? image;
  final String category;
  final bool available;
  final DateTime createdAt;
  final DateTime updatedAt;

  Snack({
    required this.id,
    required this.name,
    required this.nameVi,
    this.description,
    this.descriptionVi,
    required this.price,
    this.image,
    required this.category,
    required this.available,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Snack.fromJson(Map<String, dynamic> json) {
    return Snack(
      id: json['id'],
      name: json['name'],
      nameVi: json['name_vi'] ?? json['name'],
      description: json['description'],
      descriptionVi: json['description_vi'],
      price: double.parse(json['price']?.toString() ?? '0'),
      image: json['image'],
      category: json['category'] ?? 'food',
      available: json['available'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_vi': nameVi,
      'description': description,
      'description_vi': descriptionVi,
      'price': price,
      'image': image,
      'category': category,
      'available': available,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getter để lấy giá dạng string
  String get priceString => '${price.toStringAsFixed(0)}₫';

  // Getter để lấy hình ảnh hoặc placeholder
  String get imageUrl => image ?? 'https://via.placeholder.com/150';
}

class BookingResponse {
  final bool success;
  final String message;
  final List<Booking> bookings;
  final Booking? booking;

  BookingResponse({
    required this.success,
    required this.message,
    required this.bookings,
    this.booking,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    List<Booking> bookingsList = [];
    Booking? singleBooking;

    try {
      if (json['data'] is List) {
        // Array of bookings
        bookingsList = (json['data'] as List)
            .map((bookingJson) => Booking.fromJson(bookingJson))
            .toList();
      } else if (json['data'] is Map) {
        // Single booking
        singleBooking = Booking.fromJson(json['data']);
        bookingsList = [singleBooking];
      }
    } catch (e) {
      print('BookingResponse: Error parsing bookings: $e');
    }

    return BookingResponse(
      success: json['success'],
      message: json['message'] ?? '',
      bookings: bookingsList,
      booking: singleBooking,
    );
  }
}

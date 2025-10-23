class Theater {
  final int id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String city;
  final String? description;
  final bool active;
  final int totalSeats;
  final DateTime createdAt;
  final DateTime updatedAt;

  Theater({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    required this.city,
    this.description,
    required this.active,
    required this.totalSeats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Theater.fromJson(Map<String, dynamic> json) {
    try {
      return Theater(
        id: json['id'] ?? 0,
        name: json['name']?.toString() ?? 'Unknown Theater',
        address: json['address']?.toString() ?? 'Unknown Address',
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        city: json['city']?.toString() ?? 'TP.HCM', // Default city
        description: json['description']?.toString(),
        active: json['is_active'] ?? true,
        totalSeats: json['total_seats'] ?? 100, // Default to 100 seats
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Theater.fromJson error: $e');
      print('Theater JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'city': city,
      'description': description,
      'active': active,
      'total_seats': totalSeats,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getter để lấy thông tin liên hệ đầy đủ
  String get contactInfo {
    List<String> contacts = [];
    if (phone != null) contacts.add(phone!);
    if (email != null) contacts.add(email!);
    return contacts.join(' • ');
  }

  // Getter để lấy địa chỉ đầy đủ
  String get fullAddress => '$address, $city';
}

class Seat {
  final int id;
  final int theaterId;
  final String rowLabel;
  final int seatNumber;
  final String seatType;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Seat({
    required this.id,
    required this.theaterId,
    required this.rowLabel,
    required this.seatNumber,
    required this.seatType,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      theaterId: json['theater_id'],
      rowLabel: json['row_label'],
      seatNumber: json['seat_number'],
      seatType: json['seat_type'] ?? 'standard',
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theater_id': theaterId,
      'row_label': rowLabel,
      'seat_number': seatNumber,
      'seat_type': seatType,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getter để lấy tên ghế đầy đủ (ví dụ: A1, B5)
  String get seatName => '$rowLabel$seatNumber';

  // Getter để lấy ID dạng string cho Flutter UI (row_seat format)
  String get seatId => '${rowLabel}_$seatNumber';
}

class ScheduleSeat {
  final int scheduleId;
  final int seatId;
  final String status; // available, reserved, sold
  final DateTime? lockedUntil;
  final Seat? seat;

  ScheduleSeat({
    required this.scheduleId,
    required this.seatId,
    required this.status,
    this.lockedUntil,
    this.seat,
  });

  factory ScheduleSeat.fromJson(Map<String, dynamic> json) {
    return ScheduleSeat(
      scheduleId: json['schedule_id'],
      seatId: json['seat_id'],
      status: json['status'] ?? 'available',
      lockedUntil: json['locked_until'] != null
          ? DateTime.parse(json['locked_until'])
          : null,
      seat: json['seat'] != null ? Seat.fromJson(json['seat']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'seat_id': seatId,
      'status': status,
      'locked_until': lockedUntil?.toIso8601String(),
      'seat': seat?.toJson(),
    };
  }

  // Getter để kiểm tra ghế có khả dụng không
  bool get isAvailable => status == 'available';

  // Getter để kiểm tra ghế đã được đặt chưa
  bool get isSold => status == 'sold';

  // Getter để kiểm tra ghế đang được giữ chỗ
  bool get isReserved => status == 'reserved';

  // Getter để kiểm tra ghế có bị khóa không
  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());
}

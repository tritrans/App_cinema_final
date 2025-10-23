class Seat {
  final int id;
  final int theaterId;
  final String rowLabel;
  final int seatNumber;
  final String status; // available, selected, booked, sold, vip

  Seat({
    required this.id,
    required this.theaterId,
    required this.rowLabel,
    required this.seatNumber,
    required this.status,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['seat_id'] ?? json['id'] ?? 0,
      theaterId: json['theater_id'] ?? 0,
      rowLabel: json['row_label'] ?? '',
      seatNumber: json['seat_number'] ?? 0,
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theater_id': theaterId,
      'row_label': rowLabel,
      'seat_number': seatNumber,
      'status': status,
    };
  }

  Seat copyWith({
    int? id,
    int? theaterId,
    String? rowLabel,
    int? seatNumber,
    String? status,
  }) {
    return Seat(
      id: id ?? this.id,
      theaterId: theaterId ?? this.theaterId,
      rowLabel: rowLabel ?? this.rowLabel,
      seatNumber: seatNumber ?? this.seatNumber,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'Seat(id: $id, theaterId: $theaterId, rowLabel: $rowLabel, seatNumber: $seatNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Seat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

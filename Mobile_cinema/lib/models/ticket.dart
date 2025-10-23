class Ticket {
  final int? id;
  final String movieId;
  final String movieTitle;
  final String posterUrl;
  final List<String> seats;
  final double totalAmount;
  final DateTime dateTime;
  final String userEmail;
  final String theater;
  final String status;

  Ticket({
    this.id,
    required this.movieId,
    required this.movieTitle,
    required this.posterUrl,
    required this.seats,
    required this.totalAmount,
    required this.dateTime,
    required this.userEmail,
    required this.theater,
    this.status = 'active',
  });
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as int?,
      movieId: map['movieId'] ?? '',
      movieTitle: map['movieTitle'] ?? '',
      posterUrl: map['posterUrl'] ?? '',
      seats: (map['seats'] as String).split(','),
      totalAmount: map['totalAmount'] is int
          ? (map['totalAmount'] as int).toDouble()
          : map['totalAmount'] as double,
      dateTime: DateTime.parse(map['dateTime']),
      userEmail: map['userEmail'] ?? '',
      theater: map['theater'] ?? '',
      status: map['status'] ?? 'active',
    );
  }
  Map<String, dynamic> toMap() => {
        'id': id,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'posterUrl': posterUrl,
        'seats': seats.join(','),
        'totalAmount': totalAmount,
        'dateTime': dateTime.toIso8601String(),
        'userEmail': userEmail,
        'theater': theater,
        'status': status,
      };
  Map<String, dynamic> toMapNoId() => {
        'movieId': movieId,
        'movieTitle': movieTitle,
        'posterUrl': posterUrl,
        'seats': seats.join(','),
        'totalAmount': totalAmount,
        'dateTime': dateTime.toIso8601String(),
        'userEmail': userEmail,
        'theater': theater,
        'status': status,
      };
}

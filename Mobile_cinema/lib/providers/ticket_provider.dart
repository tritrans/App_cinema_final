import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/api_service_enhanced.dart';

class TicketProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Booking> _myTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Booking> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get tickets by status
  List<Booking> getTicketsByStatus(String status) {
    return _myTickets.where((ticket) => ticket.status == status).toList();
  }

  // Get upcoming tickets
  List<Booking> get upcomingTickets {
    return _myTickets
        .where((ticket) => ticket.status == 'confirmed' && !ticket.isPast)
        .toList();
  }

  // Get past tickets
  List<Booking> get pastTickets {
    return _myTickets.where((ticket) => ticket.isPast).toList();
  }

  // Add a new ticket
  void addTicket(Booking ticket) {
    _myTickets.insert(0, ticket); // Add to beginning of list
    notifyListeners();
  }

  // Add ticket from booking data
  void addTicketFromBookingData(Map<String, dynamic> bookingData) {
    try {
      // Create booking seats
      final seats = <BookingSeat>[];
      final selectedSeats = bookingData['selectedSeats'] as List<String>? ?? [];
      for (int i = 0; i < selectedSeats.length; i++) {
        seats.add(BookingSeat(
          id: i + 1,
          bookingId: DateTime.now().millisecondsSinceEpoch,
          seatNumber: selectedSeats[i],
          seatType: 'standard',
          price: (bookingData['seatPrice'] ?? 0.0) / selectedSeats.length,
        ));
      }

      // Create booking snacks
      final snacks = <BookingSnack>[];
      final selectedSnacks =
          bookingData['selectedSnacks'] as Map<int, int>? ?? {};
      final snackList = bookingData['snacks'] as List<dynamic>? ?? [];

      for (var entry in selectedSnacks.entries) {
        final snack = snackList.firstWhere(
          (s) => s['id'] == entry.key,
          orElse: () => {'name': 'Unknown Snack', 'price': 0},
        );
        final unitPrice = snack['price'] ?? 0.0;
        final snackName = snack['name'] ?? snack['nameVi'] ?? 'Unknown Snack';
        snacks.add(BookingSnack(
          id: entry.key,
          bookingId: DateTime.now().millisecondsSinceEpoch,
          snackId: entry.key,
          quantity: entry.value,
          unitPrice: unitPrice,
          totalPrice: unitPrice * entry.value,
          snackName: snackName,
        ));
      }

      final ticket = Booking(
        id: DateTime.now().millisecondsSinceEpoch,
        bookingId: bookingData['bookingId'] ?? 'BKQ9SFCXNP',
        userId: 1, // Mock user ID
        showtimeId: bookingData['schedule']['id'] ?? 1,
        totalPrice: bookingData['totalPrice'] ?? 0.0,
        status: bookingData['status'] ?? 'confirmed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        showtime: null, // Will be set from schedule data
        seats: seats,
        snacks: snacks,
      );

      addTicket(ticket);
    } catch (e) {
      _errorMessage = 'Lỗi khi tạo vé: $e';
      notifyListeners();
    }
  }

  // Cancel a ticket
  void cancelTicket(String bookingId) {
    final index =
        _myTickets.indexWhere((ticket) => ticket.bookingId == bookingId);
    if (index != -1) {
      // Create a new booking with cancelled status
      final oldTicket = _myTickets[index];
      final newTicket = Booking(
        id: oldTicket.id,
        bookingId: oldTicket.bookingId,
        userId: oldTicket.userId,
        showtimeId: oldTicket.showtimeId,
        totalPrice: oldTicket.totalPrice,
        status: 'cancelled',
        createdAt: oldTicket.createdAt,
        updatedAt: DateTime.now(),
        user: oldTicket.user,
        showtime: oldTicket.showtime,
        seats: oldTicket.seats,
        snacks: oldTicket.snacks,
      );
      _myTickets[index] = newTicket;
      notifyListeners();
    }
  }

  // Get ticket by booking ID
  Booking? getTicketByBookingId(String bookingId) {
    try {
      return _myTickets.firstWhere((ticket) => ticket.bookingId == bookingId);
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Load tickets from API
  Future<void> loadTicketsFromAPI(int userId) async {
    try {
      print('TicketProvider: Starting to load tickets for user $userId');
      setLoading(true);
      clearError();

      print('TicketProvider: Calling getUserBookings API...');
      final response = await _apiService.getUserBookings(userId);
      print('TicketProvider: API response: $response');

      if (response['success'] == true && response['data'] != null) {
        // API trả về dữ liệu trong format {data: {current_page: 1, data: [...]}}
        final data = response['data'] as Map<String, dynamic>;
        final bookingsData = data['data'] as List<dynamic>;
        print('TicketProvider: Found ${bookingsData.length} bookings');
        _myTickets =
            bookingsData.map((json) => Booking.fromJson(json)).toList();
        notifyListeners();
        print(
            'TicketProvider: Successfully loaded ${_myTickets.length} tickets');
      } else {
        print('TicketProvider: API returned error: ${response['message']}');
        throw Exception(response['message'] ?? 'Không thể tải danh sách vé');
      }
    } catch (e) {
      print('TicketProvider: Error loading tickets: $e');
      setError('Lỗi tải danh sách vé: $e');
      // Removed fallback to mock data to force API data or error
      _myTickets = []; // Clear tickets instead of loading mock data
    } finally {
      setLoading(false);
    }
  }
}

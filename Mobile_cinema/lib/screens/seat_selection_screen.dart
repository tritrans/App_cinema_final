import 'package:flutter/material.dart';
import '../models/seat.dart';
import '../models/schedule.dart';
import '../models/movie.dart';
import '../services/seat_api_service.dart';
import '../services/api_service_enhanced.dart';
import 'snack_selection_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int scheduleId;
  final String movieTitle;
  final String theaterName;
  final String showtime;
  final Movie? movie; // Thêm movie để truyền cho SnackSelectionScreen

  const SeatSelectionScreen({
    Key? key,
    required this.scheduleId,
    required this.movieTitle,
    required this.theaterName,
    required this.showtime,
    this.movie,
  }) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final SeatApiService _seatApiService = SeatApiService();
  final ApiService _apiService = ApiService();
  List<Seat> _seats = [];
  List<String> _selectedSeats = [];
  bool _isLoading = true;
  String? _error;
  Schedule? _schedule;

  @override
  void initState() {
    super.initState();
    _loadScheduleAndSeats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadScheduleAndSeats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load schedule details first
      final scheduleResponse =
          await _apiService.getScheduleDetails(widget.scheduleId);
      if (scheduleResponse['success'] == true &&
          scheduleResponse['data'] != null) {
        _schedule = Schedule.fromJson(scheduleResponse['data']);
      }

      // Load seats
      final seats =
          await _seatApiService.getSeatsForSchedule(widget.scheduleId);

      // Tạo layout ghế như mẫu: 6 hàng (A-F), 8 cột (1-8)
      // Hàng A, B: VIP (màu vàng)
      // Hàng C, D, E, F: Ghế thường (màu xanh lá)
      final List<Seat> formattedSeats = [];

      for (int row = 0; row < 6; row++) {
        final rowLabel = String.fromCharCode(65 + row); // A, B, C, D, E, F
        for (int col = 1; col <= 8; col++) {
          // Tìm ghế trong API response hoặc tạo mới
          final existingSeat = seats.firstWhere(
            (seat) => seat.rowLabel == rowLabel && seat.seatNumber == col,
            orElse: () => Seat(
              id: row * 8 + col,
              theaterId: 1,
              rowLabel: rowLabel,
              seatNumber: col,
              status: 'available',
            ),
          );

          // Sử dụng trạng thái thực từ API, chỉ set VIP type cho hàng A, B
          String seatType = existingSeat.status;
          if (rowLabel == 'A' || rowLabel == 'B') {
            // Nếu ghế available, set thành vip, nếu đã sold/booked thì giữ nguyên
            if (seatType == 'available') {
              seatType = 'vip';
            }
          }

          formattedSeats.add(existingSeat.copyWith(status: seatType));
        }
      }

      setState(() {
        _seats = formattedSeats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSeatSelection(Seat seat) {
    if (seat.status == 'sold' || seat.status == 'booked') {
      return; // Không thể chọn ghế đã bán hoặc đã đặt
    }

    setState(() {
      // Sử dụng format "A_1", "B_2" để tương thích với createBooking API
      final seatKey = '${seat.rowLabel}_${seat.seatNumber}';
      if (_selectedSeats.contains(seatKey)) {
        _selectedSeats.remove(seatKey);
      } else {
        _selectedSeats.add(seatKey);
      }
    });
  }

  double get _totalPrice {
    if (_schedule == null) return 0;

    double total = 0;
    const double vipMultiplier = 1.5; // Ghế VIP đắt hơn 50%

    for (String seatId in _selectedSeats) {
      // Format: "A_1", "B_2" - lấy ký tự đầu làm rowLabel
      if (seatId.isNotEmpty) {
        final rowLabel = seatId[0];
        // Hàng A và B là VIP
        if (rowLabel == 'A' || rowLabel == 'B') {
          total += _schedule!.price * vipMultiplier;
        } else {
          total += _schedule!.price;
        }
      }
    }
    return total;
  }

  Color _getSeatColor(Seat seat) {
    if (_selectedSeats.contains('${seat.rowLabel}_${seat.seatNumber}')) {
      return Colors.blue; // Đã chọn
    }

    switch (seat.status) {
      case 'available':
        return Colors.green; // Có sẵn
      case 'vip':
        return Colors.yellow; // VIP
      case 'booked':
        return Colors.orange; // Đã đặt
      case 'sold':
        return Colors.red; // Đã bán
      default:
        return Colors.grey;
    }
  }

  Widget _buildSeatLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Colors.green, 'Có sẵn'),
          _buildLegendItem(Colors.blue, 'Đã chọn'),
          _buildLegendItem(Colors.orange, 'Đã đặt'),
          _buildLegendItem(Colors.red, 'Đã bán'),
          _buildLegendItem(Colors.yellow, 'VIP'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSeatGrid() {
    // Nhóm ghế theo hàng
    final Map<String, List<Seat>> seatsByRow = {};
    for (final seat in _seats) {
      if (!seatsByRow.containsKey(seat.rowLabel)) {
        seatsByRow[seat.rowLabel] = [];
      }
      seatsByRow[seat.rowLabel]!.add(seat);
    }

    final sortedRowLabels = seatsByRow.keys.toList()..sort();

    return Column(
      children: sortedRowLabels.map((rowLabel) {
        final rowSeats = seatsByRow[rowLabel]!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Label hàng
              Container(
                width: 30,
                child: Text(
                  rowLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Ghế trong hàng
              ...rowSeats.map((seat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => _toggleSeatSelection(seat),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getSeatColor(seat),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          seat.seatNumber.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chọn ghế'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadScheduleAndSeats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật trạng thái ghế',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadScheduleAndSeats,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Thông tin phim và suất chiếu
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            widget.movieTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.theaterName} - ${widget.showtime}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Màn hình
                    Container(
                      width: double.infinity,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'MÀN HÌNH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Chú thích
                    _buildSeatLegend(),

                    const SizedBox(height: 16),

                    // Lưới ghế
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildSeatGrid(),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedSeats.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Đã chọn ${_selectedSeats.length} ghế: ${_selectedSeats.join(', ')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedSeats.isNotEmpty && _schedule != null
                      ? () {
                          if (widget.movie != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SnackSelectionScreen(
                                  movie: widget.movie!,
                                  schedule: _schedule!,
                                  selectedSeats: _selectedSeats,
                                  seatPrice: _totalPrice /
                                      _selectedSeats
                                          .length, // Giá trung bình mỗi ghế
                                ),
                              ),
                            );
                          } else {
                            // Fallback nếu không có movie
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Không thể chuyển đến màn hình chọn đồ ăn'),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSeats.isNotEmpty
                        ? Colors.pink
                        : Colors.grey[300],
                    foregroundColor: _selectedSeats.isNotEmpty
                        ? Colors.white
                        : Colors.grey[600],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _selectedSeats.isNotEmpty
                        ? 'Tiếp tục chọn bắp nước'
                        : 'Chọn ghế để tiếp tục',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

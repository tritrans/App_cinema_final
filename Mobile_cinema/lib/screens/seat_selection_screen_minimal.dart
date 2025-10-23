import 'package:flutter/material.dart';
import '../models/seat.dart';
import '../services/seat_api_service.dart';

class SeatSelectionScreenMinimal extends StatefulWidget {
  final int scheduleId;
  final String movieTitle;
  final String theaterName;
  final String showtime;

  const SeatSelectionScreenMinimal({
    Key? key,
    required this.scheduleId,
    required this.movieTitle,
    required this.theaterName,
    required this.showtime,
  }) : super(key: key);

  @override
  State<SeatSelectionScreenMinimal> createState() =>
      _SeatSelectionScreenMinimalState();
}

class _SeatSelectionScreenMinimalState
    extends State<SeatSelectionScreenMinimal> {
  final SeatApiService _seatApiService = SeatApiService();
  List<Seat> _seats = [];
  List<String> _selectedSeats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading seats for schedule ID: ${widget.scheduleId}');
      final seats =
          await _seatApiService.getSeatsForSchedule(widget.scheduleId);
      print('Loaded ${seats.length} seats from API');

      // Tạo layout ghế đơn giản: 6 hàng (A-F), 8 cột (1-8)
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

          // Sử dụng trạng thái thực từ API, chỉ set VIP type cho hàng A, B nếu available
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
      print('Error loading seats: $e');
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
      if (_selectedSeats.contains('${seat.rowLabel}_${seat.seatNumber}')) {
        _selectedSeats.remove('${seat.rowLabel}_${seat.seatNumber}');
      } else {
        _selectedSeats.add('${seat.rowLabel}_${seat.seatNumber}');
      }
    });
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
                        onPressed: _loadSeats,
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
                          const SizedBox(height: 8),
                          Text(
                            'Schedule ID: ${widget.scheduleId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
                Text(
                  'Đã chọn ${_selectedSeats.length} ghế: ${_selectedSeats.join(', ')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedSeats.isNotEmpty
                      ? () {
                          // TODO: Chuyển đến trang thanh toán
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSeats.isNotEmpty
                        ? Colors.blue
                        : Colors.grey[300],
                    foregroundColor: _selectedSeats.isNotEmpty
                        ? Colors.white
                        : Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedSeats.isNotEmpty
                        ? 'Tiếp tục thanh toán'
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

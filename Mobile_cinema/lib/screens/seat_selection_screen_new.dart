import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/schedule.dart';
import '../models/movie.dart';
import 'snack_selection_screen.dart';

class SeatSelectionScreenNew extends StatefulWidget {
  final Movie movie;
  final Schedule schedule;

  const SeatSelectionScreenNew({
    Key? key,
    required this.movie,
    required this.schedule,
  }) : super(key: key);

  @override
  State<SeatSelectionScreenNew> createState() => _SeatSelectionScreenNewState();
}

class _SeatSelectionScreenNewState extends State<SeatSelectionScreenNew> {
  List<String> selectedSeats = [];
  List<SeatData> seats = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear previous seats when navigating to new schedule
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.clearScheduleSeats();
  }

  Future<void> _loadSeats() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.getScheduleSeats(widget.schedule.id);

      setState(() {
        seats = _generateSeatLayout(bookingProvider.scheduleSeats);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi tải thông tin ghế: $e';
      });
    }
  }

  List<SeatData> _generateSeatLayout(List<dynamic> scheduleSeats) {
    // Create different layouts based on schedule ID to demonstrate uniqueness
    List<SeatData> seatList = [];

    // Get schedule ID to create different layouts
    int scheduleId = widget.schedule.id;

    // Create different layouts for different schedules
    if (scheduleId == 13839) {
      // Layout 1: 6 rows (A-F) with 8 seats each
      seatList = _createLayout6x8(scheduleSeats);
    } else if (scheduleId == 14354) {
      // Layout 2: 8 rows (A-H) with 10 seats each
      seatList = _createLayout8x10(scheduleSeats);
    } else if (scheduleId == 14869) {
      // Layout 3: 7 rows (A-G) with 12 seats each
      seatList = _createLayout7x12(scheduleSeats);
    } else {
      // Default: Use actual API data
      seatList = _createLayoutFromAPI(scheduleSeats);
    }

    return seatList;
  }

  List<SeatData> _createLayout6x8(List<dynamic> scheduleSeats) {
    List<SeatData> seatList = [];

    for (int row = 0; row < 6; row++) {
      String rowLabel = String.fromCharCode(65 + row); // A, B, C, D, E, F

      for (int seatNum = 1; seatNum <= 8; seatNum++) {
        String seatId = '${rowLabel}$seatNum';

        // Find corresponding seat in API data
        var apiSeat = scheduleSeats.firstWhere(
          (s) => s.rowLabel == rowLabel && s.seatNumber == seatNum,
          orElse: () => null,
        );

        bool isAvailable = apiSeat?.status == 'available' || apiSeat == null;
        bool isVip = (rowLabel == 'A' || rowLabel == 'B') && isAvailable;

        seatList.add(SeatData(
          id: seatId,
          row: rowLabel,
          number: seatNum,
          isAvailable: isAvailable,
          isVip: isVip,
          isSelected: false,
        ));
      }
    }

    return seatList;
  }

  List<SeatData> _createLayout8x10(List<dynamic> scheduleSeats) {
    List<SeatData> seatList = [];

    for (int row = 0; row < 8; row++) {
      String rowLabel = String.fromCharCode(65 + row); // A, B, C, D, E, F, G, H

      for (int seatNum = 1; seatNum <= 10; seatNum++) {
        String seatId = '${rowLabel}$seatNum';

        var apiSeat = scheduleSeats.firstWhere(
          (s) => s.rowLabel == rowLabel && s.seatNumber == seatNum,
          orElse: () => null,
        );

        bool isAvailable = apiSeat?.status == 'available' || apiSeat == null;
        bool isVip = (rowLabel == 'A' || rowLabel == 'B') && isAvailable;

        seatList.add(SeatData(
          id: seatId,
          row: rowLabel,
          number: seatNum,
          isAvailable: isAvailable,
          isVip: isVip,
          isSelected: false,
        ));
      }
    }

    return seatList;
  }

  List<SeatData> _createLayout7x12(List<dynamic> scheduleSeats) {
    List<SeatData> seatList = [];

    for (int row = 0; row < 7; row++) {
      String rowLabel = String.fromCharCode(65 + row); // A, B, C, D, E, F, G

      for (int seatNum = 1; seatNum <= 12; seatNum++) {
        String seatId = '${rowLabel}$seatNum';

        var apiSeat = scheduleSeats.firstWhere(
          (s) => s.rowLabel == rowLabel && s.seatNumber == seatNum,
          orElse: () => null,
        );

        bool isAvailable = apiSeat?.status == 'available' || apiSeat == null;
        bool isVip = (rowLabel == 'A' || rowLabel == 'B') && isAvailable;

        seatList.add(SeatData(
          id: seatId,
          row: rowLabel,
          number: seatNum,
          isAvailable: isAvailable,
          isVip: isVip,
          isSelected: false,
        ));
      }
    }

    return seatList;
  }

  List<SeatData> _createLayoutFromAPI(List<dynamic> scheduleSeats) {
    List<SeatData> seatList = [];

    // Group seats by row
    Map<String, List<dynamic>> seatsByRow = {};
    for (var seat in scheduleSeats) {
      String rowLabel = seat.rowLabel;
      if (!seatsByRow.containsKey(rowLabel)) {
        seatsByRow[rowLabel] = [];
      }
      seatsByRow[rowLabel]!.add(seat);
    }

    // Sort rows and create seat layout
    List<String> sortedRows = seatsByRow.keys.toList()..sort();

    for (String rowLabel in sortedRows) {
      List<dynamic> rowSeats = seatsByRow[rowLabel]!;
      // Sort seats by seat number
      rowSeats.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

      for (var seat in rowSeats) {
        String seatId = '${seat.rowLabel}${seat.seatNumber}';

        // Determine seat status from API
        bool isAvailable = seat.status == 'available';
        bool isVip = false;

        // Set VIP for first 2 rows (A, B) if available
        if ((rowLabel == 'A' || rowLabel == 'B') &&
            seat.status == 'available') {
          isVip = true;
        }

        seatList.add(SeatData(
          id: seatId,
          row: seat.rowLabel,
          number: seat.seatNumber,
          isAvailable: isAvailable,
          isVip: isVip,
          isSelected: false,
        ));
      }
    }

    return seatList;
  }

  void _toggleSeatSelection(String seatId) {
    setState(() {
      final seatIndex = seats.indexWhere((s) => s.id == seatId);
      if (seatIndex != -1) {
        final seat = seats[seatIndex];
        if (seat.isAvailable) {
          if (seat.isSelected) {
            // Deselect seat
            seats[seatIndex] = seat.copyWith(isSelected: false);
            selectedSeats.remove(seatId);
          } else {
            // Select seat
            seats[seatIndex] = seat.copyWith(isSelected: true);
            selectedSeats.add(seatId);
          }
        }
      }
    });
  }

  double get totalPrice {
    double total = 0;
    for (String seatId in selectedSeats) {
      final seat = seats.firstWhere((s) => s.id == seatId);
      if (seat.isVip) {
        // Ghế VIP có giá cao hơn 50% so với ghế thường
        total += widget.schedule.price * 1.5;
      } else {
        total += widget.schedule.price;
      }
    }
    return total;
  }

  List<String> _getUniqueRows() {
    Set<String> uniqueRows = seats.map((s) => s.row).toSet();
    List<String> sortedRows = uniqueRows.toList()..sort();
    return sortedRows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chọn ghế - ${widget.movie.title}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Screen indicator
          _buildScreenIndicator(),

          // Seat legend
          _buildSeatLegend(),

          // Seat grid
          Expanded(
            child: _buildSeatGrid(),
          ),

          // Bottom action button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildScreenIndicator() {
    return Container(
      width: double.infinity,
      height: 40,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'MÀN HÌNH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSeats,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Seat rows - dynamic based on actual data
          Expanded(
            child: ListView.builder(
              itemCount: _getUniqueRows().length,
              itemBuilder: (context, rowIndex) {
                String rowLabel = _getUniqueRows()[rowIndex];
                List<SeatData> rowSeats =
                    seats.where((s) => s.row == rowLabel).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Row label
                      SizedBox(
                        width: 30,
                        child: Text(
                          rowLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Seats in row
                      Expanded(
                        child: Row(
                          children: rowSeats.map((seat) {
                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: _buildSeatWidget(seat),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(SeatData seat) {
    Color seatColor;
    if (!seat.isAvailable) {
      seatColor = Colors.red; // Sold
    } else if (seat.isSelected) {
      seatColor = Colors.blue; // Selected
    } else if (seat.isVip) {
      seatColor = Colors.yellow; // VIP
    } else {
      seatColor = Colors.green; // Available
    }

    return GestureDetector(
      onTap: seat.isAvailable ? () => _toggleSeatSelection(seat.id) : null,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border:
              seat.isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Center(
          child: Text(
            seat.number.toString(),
            style: TextStyle(
              color: seat.isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (selectedSeats.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đã chọn ${selectedSeats.length} ghế: ${selectedSeats.join(', ')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(0)} VNĐ',
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
              onPressed: selectedSeats.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SnackSelectionScreen(
                            movie: widget.movie,
                            schedule: widget.schedule,
                            selectedSeats: selectedSeats,
                            seatPrice: widget.schedule.price,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedSeats.isNotEmpty ? Colors.pink : Colors.grey[300],
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                selectedSeats.isEmpty
                    ? 'Chọn ghế để tiếp tục'
                    : 'Tiếp tục chọn bắp nước',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeatData {
  final String id;
  final String row;
  final int number;
  final bool isAvailable;
  final bool isVip;
  final bool isSelected;

  SeatData({
    required this.id,
    required this.row,
    required this.number,
    required this.isAvailable,
    required this.isVip,
    required this.isSelected,
  });

  SeatData copyWith({
    String? id,
    String? row,
    int? number,
    bool? isAvailable,
    bool? isVip,
    bool? isSelected,
  }) {
    return SeatData(
      id: id ?? this.id,
      row: row ?? this.row,
      number: number ?? this.number,
      isAvailable: isAvailable ?? this.isAvailable,
      isVip: isVip ?? this.isVip,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

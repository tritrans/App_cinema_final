import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/booking_provider.dart';
import '../models/theater.dart';
import '../models/schedule.dart';
import '../models/movie.dart';
import 'seat_selection_screen_new.dart';

class TheaterSelectionScreen extends StatefulWidget {
  final Movie movie;
  final DateTime selectedDate;

  const TheaterSelectionScreen({
    Key? key,
    required this.movie,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<TheaterSelectionScreen> createState() => _TheaterSelectionScreenState();
}

class _TheaterSelectionScreenState extends State<TheaterSelectionScreen> {
  String selectedTimeSlot = 'Tất cả';
  Theater? selectedTheater;
  List<Schedule> availableSchedules = [];
  bool isLoading = false;

  final List<String> timeSlots = [
    'Tất cả',
    'Chiều (12h-17h)',
    'Tối (17h-21h)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      isLoading = true;
    });

    try {
      final scheduleProvider =
          Provider.of<ScheduleProvider>(context, listen: false);
      await scheduleProvider.getMovieSchedules(widget.movie.id);

      setState(() {
        availableSchedules = scheduleProvider.schedules;
        isLoading = false;
      });
    } catch (e) {
      print('Exception in _loadSchedules: $e');
      setState(() {
        isLoading = false;
      });
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải lịch chiếu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Schedule> getFilteredSchedules() {
    List<Schedule> filtered = availableSchedules.where((schedule) {
      // Filter by date
      final scheduleDate = schedule.startTime;
      final selectedDate = widget.selectedDate;
      if (scheduleDate.year != selectedDate.year ||
          scheduleDate.month != selectedDate.month ||
          scheduleDate.day != selectedDate.day) {
        return false;
      }

      // Filter by time slot
      if (selectedTimeSlot != 'Tất cả') {
        final hour = scheduleDate.hour;
        if (selectedTimeSlot == 'Chiều (12h-17h)' &&
            (hour < 12 || hour >= 17)) {
          return false;
        }
        if (selectedTimeSlot == 'Tối (17h-21h)' && (hour < 17 || hour >= 21)) {
          return false;
        }
      }

      // Filter by theater
      if (selectedTheater != null &&
          schedule.theaterId != selectedTheater!.id) {
        return false;
      }

      return true;
    }).toList();

    return filtered;
  }

  List<Theater> getUniqueTheaters() {
    return availableSchedules
        .map((schedule) => schedule.theater)
        .where((theater) => theater != null)
        .cast<Theater>()
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Chọn rạp chiếu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Time slot filter
                Row(
                  children: [
                    Text(
                      'Khung giờ:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: timeSlots.map((slot) {
                            final isSelected = selectedTimeSlot == slot;
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(slot),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedTimeSlot = slot;
                                  });
                                },
                                selectedColor: Colors.red[100],
                                checkmarkColor: Colors.red,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Theater filter
                Row(
                  children: [
                    Text(
                      'Rạp:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All theaters option
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text('Tất cả'),
                                selected: selectedTheater == null,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedTheater = null;
                                  });
                                },
                                selectedColor: Colors.red[100],
                                checkmarkColor: Colors.red,
                              ),
                            ),
                            // Individual theaters
                            ...getUniqueTheaters().map((theater) {
                              final isSelected =
                                  selectedTheater?.id == theater.id;
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(theater.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedTheater =
                                          selected ? theater : null;
                                    });
                                  },
                                  selectedColor: Colors.red[100],
                                  checkmarkColor: Colors.red,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Schedules list
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : getFilteredSchedules().isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_creation_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không có lịch chiếu',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vui lòng chọn ngày khác',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: getFilteredSchedules().length,
                        itemBuilder: (context, index) {
                          final schedule = getFilteredSchedules()[index];
                          final startTime = schedule.startTime;
                          final endTime = schedule.endTime;

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                    Text(
                                      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                schedule.theater?.name ?? 'Unknown Theater',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hiển thị địa chỉ từ Theater data
                                  Text(
                                    _getTheaterAddress(schedule.theater?.id),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(
                                        Icons.room,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        schedule.roomName,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SeatSelectionScreenNew(
                                        movie: widget.movie,
                                        schedule: schedule,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('Chọn ghế'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Lấy địa chỉ từ Theater data đã có sẵn
  String _getTheaterAddress(int? theaterId) {
    if (theaterId == null) {
      print('TheaterSelectionScreen: theaterId is null');
      return 'Unknown Address';
    }

    // Lấy BookingProvider từ context
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    print('TheaterSelectionScreen: Looking for theater ID $theaterId');
    print(
        'TheaterSelectionScreen: Available theaters: ${bookingProvider.theaters.map((t) => '${t.id}:${t.name}').join(', ')}');

    // Tìm theater từ danh sách đã load
    final theater = bookingProvider.theaters.firstWhere(
      (t) => t.id == theaterId,
      orElse: () {
        print(
            'TheaterSelectionScreen: Theater ID $theaterId not found in ${bookingProvider.theaters.length} theaters');
        return Theater(
          id: 0,
          name: 'Unknown Theater',
          address: 'Unknown Address',
          city: 'TP.HCM',
          active: true,
          totalSeats: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      },
    );

    print(
        'TheaterSelectionScreen: Found theater: ${theater.name} - ${theater.address}');
    return theater.address;
  }
}

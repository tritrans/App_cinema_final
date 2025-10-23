import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../models/schedule.dart';
import '../models/theater.dart';
import '../providers/schedule_provider.dart';
import '../providers/booking_provider.dart';
import 'seat_selection_screen.dart';

class BookingScreen extends StatefulWidget {
  final Movie movie;

  const BookingScreen({super.key, required this.movie});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  Theater? _selectedTheater;
  List<DateTime> _availableDates = [];
  List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];
  List<Theater> _theaters = [];
  bool _isLoadingDates = false;
  bool _isLoadingSchedules = false;
  bool _isLoadingTheaters = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadAvailableDates(),
      _loadAllSchedules(),
      _loadTheaters(),
    ]);
  }

  Future<void> _loadAvailableDates() async {
    setState(() {
      _isLoadingDates = true;
    });

    try {
      final scheduleProvider =
          Provider.of<ScheduleProvider>(context, listen: false);
      await scheduleProvider.getMovieAvailableDates(widget.movie.id);

      setState(() {
        _availableDates = scheduleProvider.availableDates
            .map((dateStr) => DateTime.parse(dateStr))
            .toList();
        _isLoadingDates = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDates = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ngày chiếu: $e')),
        );
      }
    }
  }

  Future<void> _loadAllSchedules() async {
    setState(() {
      _isLoadingSchedules = true;
    });

    try {
      final scheduleProvider =
          Provider.of<ScheduleProvider>(context, listen: false);
      await scheduleProvider.getMovieSchedules(widget.movie.id);

      setState(() {
        _allSchedules = scheduleProvider.schedules;
        _isLoadingSchedules = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSchedules = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch chiếu: $e')),
        );
      }
    }
  }

  Future<void> _loadTheaters() async {
    setState(() {
      _isLoadingTheaters = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.getTheaters();

      setState(() {
        _theaters = bookingProvider.theaters;
        _isLoadingTheaters = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTheaters = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách rạp: $e')),
        );
      }
    }
  }

  void _filterSchedules() {
    if (_selectedTheater == null || _selectedDate == null) {
      setState(() {
        _filteredSchedules = [];
      });
      return;
    }

    final filtered = _allSchedules.where((schedule) {
      final selectedDateStr = _selectedDate!.toIso8601String().split('T')[0];
      final scheduleDateStr =
          schedule.startTime.toIso8601String().split('T')[0];

      return schedule.theater?.id == _selectedTheater?.id &&
          scheduleDateStr == selectedDateStr;
    }).toList();

    setState(() {
      _filteredSchedules = filtered;
    });
  }

  void _onTheaterSelected(Theater? theater) {
    setState(() {
      _selectedTheater = theater;
    });
    _filterSchedules();
  }

  void _onDateSelected(DateTime? date) {
    setState(() {
      _selectedDate = date;
    });
    _filterSchedules();
  }

  void _onScheduleSelected(Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          scheduleId: schedule.id,
          movieTitle: widget.movie.title,
          theaterName: schedule.theater?.name ?? 'Unknown Theater',
          showtime:
              '${schedule.startTime.hour.toString().padLeft(2, '0')}:${schedule.startTime.minute.toString().padLeft(2, '0')} - ${schedule.endTime.hour.toString().padLeft(2, '0')}:${schedule.endTime.minute.toString().padLeft(2, '0')}',
          movie: widget.movie, // Thêm movie object
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double? price) {
    if (price == null) return '0 VNĐ';
    return '${price.toStringAsFixed(0)} VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt vé - ${widget.movie.title}'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.movie.poster,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thời lượng: ${widget.movie.duration} phút',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Đạo diễn: ${widget.movie.director ?? "N/A"}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (widget.movie.rating != null)
                            Text(
                              'Đánh giá: ${widget.movie.rating}/5',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Theater selection
            Text(
              'Chọn rạp chiếu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingTheaters)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Theater?>(
                    value: _selectedTheater,
                    hint: const Text('Chọn rạp chiếu'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<Theater?>(
                        value: null,
                        child: Text('Chọn rạp chiếu'),
                      ),
                      ..._theaters.map((theater) => DropdownMenuItem<Theater?>(
                            value: theater,
                            child: Text(theater.name),
                          )),
                    ],
                    onChanged: _onTheaterSelected,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Date selection
            Text(
              'Chọn ngày chiếu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingDates)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableDates.length,
                  itemBuilder: (context, index) {
                    final date = _availableDates[index];
                    final isSelected = _selectedDate?.day == date.day &&
                        _selectedDate?.month == date.month &&
                        _selectedDate?.year == date.year;
                    final isToday = DateTime.now().day == date.day &&
                        DateTime.now().month == date.month &&
                        DateTime.now().year == date.year;

                    return GestureDetector(
                      onTap: () => _onDateSelected(date),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.red
                              : isToday
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.red
                                : isToday
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected || isToday
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              _getMonthName(date.month),
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected || isToday
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // Schedule selection
            if (_selectedTheater != null && _selectedDate != null) ...[
              Text(
                'Chọn suất chiếu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingSchedules)
                const Center(child: CircularProgressIndicator())
              else if (_filteredSchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Không có suất chiếu nào cho ngày đã chọn'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = _filteredSchedules[index];
                    return GestureDetector(
                      onTap: () => _onScheduleSelected(schedule),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(schedule.startTime),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatPrice(schedule.price),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Phòng: ${schedule.roomName}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12'
    ];
    return months[month - 1];
  }
}

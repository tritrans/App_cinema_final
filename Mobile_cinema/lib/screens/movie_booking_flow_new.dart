import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../models/schedule.dart';
import '../providers/booking_provider.dart';
import 'seat_selection_screen.dart';

class MovieBookingFlowNew extends StatefulWidget {
  final Movie movie;

  const MovieBookingFlowNew({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  State<MovieBookingFlowNew> createState() => _MovieBookingFlowNewState();
}

class _MovieBookingFlowNewState extends State<MovieBookingFlowNew> {
  DateTime? selectedDate;
  String selectedTimeSlot = 'Tất cả';
  String? selectedTheaterName; // Changed from Theater? to String?
  List<Schedule> schedules = [];
  bool isLoading = false;

  final List<String> timeSlots = [
    'Tất cả',
    'Chiều (12h-17h)',
    'Tối (17h-21h)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);

      print('DEBUG: Starting to load data for movie ${widget.movie.id}');

      // Load theaters
      print('DEBUG: Loading theaters...');
      await bookingProvider.getTheaters();
      print(
          'DEBUG: Loaded ${bookingProvider.theaters.length} theaters: ${bookingProvider.theaters.map((t) => t.name).toList()}');

      // Load schedules for this movie
      print('DEBUG: Loading schedules for movie ${widget.movie.id}...');
      await bookingProvider.getMovieSchedules(widget.movie.id);
      print('DEBUG: Loaded ${bookingProvider.schedules.length} schedules');

      setState(() {
        schedules = bookingProvider.schedules;
        isLoading = false;
      });

      print(
          'DEBUG: Final state - ${bookingProvider.theaters.length} theaters and ${schedules.length} schedules');
    } catch (e) {
      print('ERROR: Error loading data: $e');

      // Add fallback data if API fails
      print('DEBUG: Adding fallback data...');
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);

      // Add fallback theaters if none loaded
      if (bookingProvider.theaters.isEmpty) {
        print('DEBUG: Adding fallback theaters...');
        // This will be handled by the provider's fallback mechanism
      }

      setState(() {
        schedules = bookingProvider.schedules;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.movie.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Movie details card
                  _buildMovieDetailsCard(),

                  // Date selection
                  _buildDateSelection(),

                  // Time slot selection
                  _buildTimeSlotSelection(),

                  // Cinema selection
                  _buildCinemaSelection(),

                  // Showtimes list
                  _buildShowtimesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildMovieDetailsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.movie.poster,
              width: 80,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.movie, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movie.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.movie.rating}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.movie.duration} phút',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Thể loại: ${widget.movie.genres.map((g) => g.name).join(', ')}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày khởi chiếu: ${_formatDate(widget.movie.releaseDate)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    final today = DateTime.now();
    final dates = List.generate(7, (index) => today.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = selectedDate?.day == date.day;
                final isToday = date.day == today.day;

                return Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.pink : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.pink : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isToday ? 'H.nay' : _getDayName(date.weekday),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTimeSlotSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Chọn khung giờ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = timeSlots[index];
                final isSelected = selectedTimeSlot == timeSlot;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTimeSlot = timeSlot;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTimeSlotIcon(timeSlot),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeSlot,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCinemaSelection() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final uniqueTheaterNames = bookingProvider.uniqueTheaterNames;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Chọn rạp chiếu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      uniqueTheaterNames.length + 1, // +1 for "Tất cả" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Tất cả" option
                      final isSelected = selectedTheaterName == null;
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTheaterName = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.pink : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.pink
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.movie,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tất cả',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final theaterName = uniqueTheaterNames[index - 1];
                    final isSelected = selectedTheaterName == theaterName;

                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTheaterName = theaterName;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.pink : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.pink : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.movie,
                                color: isSelected ? Colors.white : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                theaterName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShowtimesList() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        final filteredSchedules = _getFilteredSchedules();

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Suất chiếu (${filteredSchedules.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              if (filteredSchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Không có suất chiếu nào',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = filteredSchedules[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.movie,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.theater?.name ?? 'Unknown Theater',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  schedule.theater?.address ??
                                      'Unknown Address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '2D Phụ đề • ${_formatPrice(schedule.price)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _selectShowtime(schedule);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Chọn'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<Schedule> _getFilteredSchedules() {
    return schedules.where((schedule) {
      // Filter by theater name
      if (selectedTheaterName != null &&
          schedule.theater?.name != selectedTheaterName) {
        return false;
      }

      // Filter by date
      if (selectedDate != null) {
        final scheduleDate = schedule.startTime;
        if (scheduleDate.day != selectedDate!.day ||
            scheduleDate.month != selectedDate!.month ||
            scheduleDate.year != selectedDate!.year) {
          return false;
        }
      }

      // Filter by time slot
      if (selectedTimeSlot != 'Tất cả') {
        final scheduleTime = schedule.startTime;
        final hour = scheduleTime.hour;

        if (selectedTimeSlot == 'Chiều (12h-17h)' &&
            (hour < 12 || hour >= 17)) {
          return false;
        }
        if (selectedTimeSlot == 'Tối (17h-21h)' && (hour < 17 || hour >= 21)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _selectShowtime(Schedule schedule) {
    // Navigate to seat selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          scheduleId: schedule.id,
          movieTitle: widget.movie.title,
          theaterName: schedule.theater?.name ?? 'Unknown Theater',
          showtime: '${schedule.startTime} - ${schedule.endTime}',
          movie: widget.movie, // Thêm movie object
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}₫';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  IconData _getTimeSlotIcon(String timeSlot) {
    switch (timeSlot) {
      case 'Tất cả':
        return Icons.access_time;
      case 'Chiều (12h-17h)':
        return Icons.wb_sunny;
      case 'Tối (17h-21h)':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
}

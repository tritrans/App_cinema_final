import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../models/theater.dart';
import '../providers/booking_provider.dart';
import 'theater_selection_screen.dart';

class MovieBookingFlow extends StatefulWidget {
  final Movie movie;

  const MovieBookingFlow({
    Key? key,
    required this.movie,
  }) : super(key: key);

  @override
  State<MovieBookingFlow> createState() => _MovieBookingFlowState();
}

class _MovieBookingFlowState extends State<MovieBookingFlow> {
  Theater? selectedTheater;
  DateTime selectedDate = DateTime.now();
  List<Theater> theaters = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTheaters();
  }

  Future<void> _loadTheaters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.getTheaters();

      if (bookingProvider.theaters.isNotEmpty) {
        setState(() {
          theaters = bookingProvider.theaters;
          isLoading = false;
        });
        print('Loaded ${theaters.length} theaters from API');
      } else {
        print('No theaters from API');
        setState(() {
          theaters = [];
        });
      }
    } catch (e) {
      print('Error loading theaters from API: $e');
      setState(() {
        theaters = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: Text('Đặt vé - ${widget.movie.title}'),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : theaters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.theater_comedy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có rạp chiếu',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vui lòng thử lại sau',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Theater selection
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn rạp chiếu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: theaters.length,
                              itemBuilder: (context, index) {
                                final theater = theaters[index];
                                final isSelected =
                                    selectedTheater?.id == theater.id;
                                return Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedTheater = theater;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.red
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          theater.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Date selection
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn ngày',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 7,
                              itemBuilder: (context, index) {
                                final date =
                                    DateTime.now().add(Duration(days: index));
                                final isSelected =
                                    selectedDate.day == date.day &&
                                        selectedDate.month == date.month &&
                                        selectedDate.year == date.year;
                                return Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedDate = date;
                                      });
                                    },
                                    child: Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.red
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${date.day}',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            _getDayName(date.weekday),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 12,
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
                    ),
                    SizedBox(height: 16),
                    // Continue button
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: selectedTheater != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TheaterSelectionScreen(
                                        movie: widget.movie,
                                        selectedDate: selectedDate,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tiếp tục',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
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
}

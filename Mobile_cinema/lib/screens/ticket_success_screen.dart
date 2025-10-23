import 'package:flutter/material.dart';
import '../models/movie.dart';
import 'ticket_screen.dart';

class TicketSuccessScreen extends StatelessWidget {
  final Movie movie;
  final List<String> selectedSeats;
  final double totalAmount;

  const TicketSuccessScreen({
    super.key,
    required this.movie,
    required this.selectedSeats,
    required this.totalAmount,
  });

  // Format price with thousand separator dots
  String _formatPrice(double price) {
    String priceString = price.toStringAsFixed(0);
    final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return priceString.replaceAllMapped(pattern, (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        children: [
          // Top padding for status bar
          SizedBox(height: statusBarHeight),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Success animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đặt vé thành công!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bạn đã đặt ${selectedSeats.length} vé xem phim "${movie.title}" thành công.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Ticket details card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Movie info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Movie poster
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    movie.poster,
                                    width: 80,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Movie details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.event_seat_outlined,
                                        'Ghế: ${selectedSeats.join(", ")}',
                                        isDark,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.confirmation_number_outlined,
                                        '${selectedSeats.length} vé',
                                        isDark,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.location_on_outlined,
                                        'HNP Cinema',
                                        isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Dashed divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: List.generate(
                                40,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1,
                                    color: index % 2 == 0
                                        ? Colors.transparent
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Price
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng thanh toán',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_formatPrice(totalAmount)} VND',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Điều hướng đến TicketScreen và yêu cầu hiển thị nút back
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TicketScreen(showBackButton: true),
                            ),
                          );
                        },
                        child: const Text(
                          'XEM VÉ CỦA TÔI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: Text(
                        'Về trang chủ',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

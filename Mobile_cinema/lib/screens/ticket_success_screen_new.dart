import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';

class TicketSuccessScreenNew extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const TicketSuccessScreenNew({
    Key? key,
    required this.bookingData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Save ticket to provider when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      ticketProvider.addTicketFromBookingData(bookingData);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết vé',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Code section
            _buildQRCodeSection(),

            // Ticket details
            _buildTicketDetails(),

            // Copy booking code button
            _buildCopyButton(context),

            // Success message
            _buildSuccessMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // QR Code
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: QrImageView(
              data: bookingData['bookingId'] ?? 'BKQ9SFCXNP',
              version: QrVersions.auto,
              size: 168.0,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Booking ID
          Text(
            bookingData['bookingId'] ?? 'BKQ9SFCXNP',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 12),

          // QR instruction
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Xuất trình mã QR này tại quầy để nhận vé',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails() {
    final movie = bookingData['movie'];
    final schedule = bookingData['schedule'];
    final selectedSeats = bookingData['selectedSeats'] as List<String>;
    final totalPrice = bookingData['totalPrice'] as double;

    return Container(
      margin: const EdgeInsets.only(top: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết vé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Phim', movie.titleVi ?? movie.title ?? 'Unknown Movie'),
          _buildDetailRow('Rạp', schedule.theater?.name ?? 'CGV Aeon Mall'),
          _buildDetailRow('Phòng', '${schedule.format} Phụ đề'),
          _buildDetailRow('Ngày', _formatDate(schedule.startTime.toString())),
          _buildDetailRow(
              'Giờ',
              _formatTime(
                  schedule.startTime.toString(), schedule.endTime.toString())),
          _buildDetailRow('Ghế', selectedSeats.join(', ')),
          _buildDetailRow('Tổng tiền', '${totalPrice.toStringAsFixed(0)}₫'),
          _buildDetailRow('Trạng thái', 'Đã thanh toán', isStatus: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isStatus ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          _copyBookingCode(context);
        },
        icon: const Icon(Icons.copy),
        label: const Text(
          'Sao chép mã đặt vé',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đặt vé thành công! Thông tin vé đã được gửi đến email của bạn.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '18/9/2025';
    }
  }

  String _formatTime(String startTimeString, String endTimeString) {
    try {
      final startTime = DateTime.parse(startTimeString);
      final endTime = DateTime.parse(endTimeString);

      final startHour = startTime.hour.toString().padLeft(2, '0');
      final startMinute = startTime.minute.toString().padLeft(2, '0');
      final endHour = endTime.hour.toString().padLeft(2, '0');
      final endMinute = endTime.minute.toString().padLeft(2, '0');

      return '$startHour:$startMinute~$endHour:$endMinute';
    } catch (e) {
      return '14:00~16:32';
    }
  }

  void _copyBookingCode(BuildContext context) {
    final bookingId = bookingData['bookingId'] ?? 'BKQ9SFCXNP';
    Clipboard.setData(ClipboardData(text: bookingId));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã đặt vé'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

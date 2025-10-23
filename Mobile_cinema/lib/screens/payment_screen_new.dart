import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/movie.dart';
import '../models/booking.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import 'ticket_success_screen_new.dart';

class PaymentScreenNew extends StatefulWidget {
  final Movie movie;
  final Schedule schedule;
  final List<String> selectedSeats;
  final Map<int, int> selectedSnacks;
  final List<Snack> snacks;
  final double totalAmount;

  const PaymentScreenNew({
    Key? key,
    required this.movie,
    required this.schedule,
    required this.selectedSeats,
    required this.selectedSnacks,
    required this.snacks,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PaymentScreenNew> createState() => _PaymentScreenNewState();
}

class _PaymentScreenNewState extends State<PaymentScreenNew> {
  String selectedPaymentMethod = 'momo';
  bool isProcessing = false;
  // Use BookingProvider for booking flow

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'momo',
      name: 'Ví MoMo',
      description: 'Thanh toán qua ví MoMo',
      icon: Icons.favorite,
      color: Colors.purple,
    ),
    PaymentMethod(
      id: 'zalopay',
      name: 'ZaloPay',
      description: 'Thanh toán qua ZaloPay',
      icon: Icons.favorite,
      color: Colors.blue,
    ),
    PaymentMethod(
      id: 'vnpay',
      name: 'VNPay',
      description: 'Thanh toán qua VNPay',
      icon: Icons.favorite,
      color: Colors.green,
    ),
    PaymentMethod(
      id: 'bank',
      name: 'Chuyển khoản',
      description: 'Chuyển khoản ngân hàng',
      icon: Icons.account_balance,
      color: Colors.blue,
    ),
  ];

  double get snackTotal {
    double total = 0;
    widget.selectedSnacks.forEach((snackId, quantity) {
      // We need to get snack price from the provider
      // For now, using a placeholder price
      total += 50000 * quantity; // Placeholder price
    });
    return total;
  }

  double get seatTotal {
    return widget.totalAmount - snackTotal;
  }

  double get grandTotal {
    return widget.totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0), // Add some padding
                child: Column(
                  children: [
                    // Order summary
                    _buildOrderSummary(),
                    const SizedBox(height: 16), // Space between sections

                    // Payment methods
                    _buildPaymentMethods(),
                  ],
                ),
              ),
            ),
            // Bottom payment section
            _buildBottomPayment(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vé xem phim:'),
              Text('${seatTotal.toStringAsFixed(0)} VNĐ'),
            ],
          ),
          const SizedBox(height: 4),
          Text('Ghế: ${widget.selectedSeats.join(', ')}'),
          const SizedBox(height: 8),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${grandTotal.toStringAsFixed(0)} VNĐ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.map((method) => _buildPaymentMethodItem(method)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(PaymentMethod method) {
    final isSelected = selectedPaymentMethod == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method.id;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.pink[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.pink, width: 2)
                : Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: method.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method.icon,
                  color: method.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Method info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPayment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${grandTotal.toStringAsFixed(0)} VNĐ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Thanh toán',
                      style: TextStyle(
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

  Future<void> _processPayment() async {
    setState(() {
      isProcessing = true;
    });

    // Chuyển đổi format từ "A_1" sang "A1" cho lockSeats API
    final lockSeatNumbers = widget.selectedSeats.map((seat) {
      return seat.replaceAll('_', '');
    }).toList();

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 1));

      // Bước 1: Khóa ghế trên server
      setState(() {
        isProcessing = true;
      });

      final lockResponse = await bookingProvider.lockSeatsOnServer(
        scheduleId: widget.schedule.id,
        seatNumbers: lockSeatNumbers,
        lockDurationMinutes: 15,
      );

      if (lockResponse['success'] != true) {
        final errorMessage = lockResponse['message'] ?? 'Lỗi khóa ghế';
        throw Exception(errorMessage);
      }

      // Bước 2: Tạo booking trên server
      final booking = await bookingProvider.createBookingOnServer(
        userId: 1, // TODO: use real user id from AuthProvider
        showtimeId: widget.schedule.id,
        selectedSeats: widget.selectedSeats,
        selectedSnacks: widget.selectedSnacks,
        snacks: widget.snacks,
        totalPrice: grandTotal,
        paymentMethod: selectedPaymentMethod,
      );

      if (booking == null) {
        throw Exception('Không thể tạo booking');
      }

      // Navigate to success screen
      if (mounted) {
        final bookingData = {
          'movie': widget.movie,
          'schedule': widget.schedule,
          'selectedSeats': widget.selectedSeats,
          'selectedSnacks': widget.selectedSnacks,
          'snacks': widget.snacks,
          'seatPrice': seatTotal,
          'snackPrice': snackTotal,
          'totalPrice': grandTotal,
          'paymentMethod': selectedPaymentMethod,
          'bookingId': booking.bookingId,
          'status': booking.status,
        };

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TicketSuccessScreenNew(
              bookingData: bookingData,
            ),
          ),
        );
      }
    } catch (e) {
      // If locking succeeded but booking failed, try to release seats
      try {
        if (bookingProvider.lockedSeatIds.isNotEmpty) {
          await bookingProvider.releaseSeatsOnServer(
            scheduleId: widget.schedule.id,
            seatIds: bookingProvider.lockedSeatIds,
          );
        } else {
          // Fallback: attempt to release by hashing seat strings (best-effort)
          await bookingProvider.releaseSeatsOnServer(
            scheduleId: widget.schedule.id,
            seatIds: lockSeatNumbers.map((s) => s.hashCode).toList(),
          );
        }
      } catch (releaseErr) {
        print('Lỗi khi release ghế: $releaseErr');
      }

      if (mounted) {
        setState(() {
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt vé: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

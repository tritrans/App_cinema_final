import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie.dart';
import '../models/schedule.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';

class PaymentScreen extends StatefulWidget {
  final Movie movie;
  final Schedule schedule;
  final List<String> selectedSeats;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.movie,
    required this.schedule,
    required this.selectedSeats,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'cash';
  List<Map<String, dynamic>> _snacks = [];
  List<Map<String, dynamic>> _selectedSnacks = [];
  bool _isLoadingSnacks = false;
  bool _isCreatingBooking = false;

  @override
  void initState() {
    super.initState();
    _loadSnacks();
  }

  Future<void> _loadSnacks() async {
    setState(() {
      _isLoadingSnacks = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.getSnacks();

      setState(() {
        _snacks = bookingProvider.snacks
            .map((snack) => {
                  'id': snack.id,
                  'name': snack.name,
                  'price': snack.price,
                })
            .toList();
        _isLoadingSnacks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSnacks = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải đồ ăn: $e')),
        );
      }
    }
  }

  void _toggleSnack(Map<String, dynamic> snack) {
    setState(() {
      final existingIndex =
          _selectedSnacks.indexWhere((s) => s['id'] == snack['id']);
      if (existingIndex != -1) {
        _selectedSnacks.removeAt(existingIndex);
      } else {
        _selectedSnacks.add({
          'id': snack['id'],
          'name': snack['name'],
          'price': snack['price'],
          'quantity': 1,
        });
      }
    });
  }

  void _updateSnackQuantity(Map<String, dynamic> snack, int quantity) {
    setState(() {
      final index = _selectedSnacks.indexWhere((s) => s['id'] == snack['id']);
      if (index != -1) {
        if (quantity <= 0) {
          _selectedSnacks.removeAt(index);
        } else {
          _selectedSnacks[index]['quantity'] = quantity;
        }
      }
    });
  }

  int _getSnackQuantity(Map<String, dynamic> snack) {
    final selectedSnack = _selectedSnacks.firstWhere(
      (s) => s['id'] == snack['id'],
      orElse: () => {'quantity': 0},
    );
    return selectedSnack['quantity'] ?? 0;
  }

  double _getSnacksTotal() {
    return _selectedSnacks.fold(0.0, (sum, snack) {
      return sum + (snack['price'] * snack['quantity']);
    });
  }

  double _getGrandTotal() {
    return widget.totalPrice + _getSnacksTotal();
  }

  Future<void> _createBooking() async {
    setState(() {
      _isCreatingBooking = true;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);

      // Convert selectedSnacks to Snack objects
      final snacks = _selectedSnacks.map((snackData) {
        return Snack(
          id: snackData['id'],
          name: snackData['name'] ?? '',
          nameVi: snackData['name'] ?? '',
          description: '',
          descriptionVi: '',
          price: snackData['price']?.toDouble() ?? 0.0,
          image: null,
          category: 'food',
          available: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      final success = await bookingProvider.createBooking(
        showtimeId: widget.schedule.id,
        seatIds: widget.selectedSeats,
        selectedSnacks: snacks,
        totalPrice: _getGrandTotal(),
        userId: 6, // TODO: Get from auth provider
      );

      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đặt vé thành công!')),
          );
          Navigator.pop(context); // Quay lại màn hình trước
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi tạo đặt vé')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo đặt vé: $e')),
        );
      }
    } finally {
      setState(() {
        _isCreatingBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Movie and schedule info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
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
                            const SizedBox(height: 6),
                            Text(
                                '${widget.schedule.startTime} - ${widget.schedule.endTime}'),
                            Text(
                                'Rạp: ${widget.schedule.theater?.name ?? "N/A"}'),
                            Text('Ghế: ${widget.selectedSeats.join(", ")}'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Snacks section
                    Text(
                      'Đồ ăn & Nước uống',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingSnacks)
                      const Center(child: CircularProgressIndicator())
                    else if (_snacks.isEmpty)
                      const Text('Không có đồ ăn nào')
                    else
                      ..._snacks.map((snack) {
                        final quantity = _getSnackQuantity(snack);
                        final isSelected = quantity > 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            title: Text(snack['name'] ?? ''),
                            subtitle: Text(
                                '${snack['price']?.toStringAsFixed(0) ?? "0"} VNĐ'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  IconButton(
                                    onPressed: () => _updateSnackQuantity(
                                        snack, quantity - 1),
                                    icon: const Icon(Icons.remove),
                                    iconSize: 20,
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    onPressed: () => _updateSnackQuantity(
                                        snack, quantity + 1),
                                    icon: const Icon(Icons.add),
                                    iconSize: 20,
                                  ),
                                ] else
                                  IconButton(
                                    onPressed: () => _toggleSnack(snack),
                                    icon: const Icon(Icons.add),
                                    iconSize: 20,
                                  ),
                              ],
                            ),
                            selected: isSelected,
                            onTap: () => _toggleSnack(snack),
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 16),

                    // Payment method
                    Text(
                      'Phương thức thanh toán',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text('Thanh toán tại rạp'),
                            subtitle: const Text('Tiền mặt hoặc thẻ'),
                            value: 'cash',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Chuyển khoản'),
                            subtitle: const Text('Chuyển khoản ngân hàng'),
                            value: 'bank_transfer',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Total
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vé phim:'),
                                Text(
                                    '${widget.totalPrice.toStringAsFixed(0)} VNĐ'),
                              ],
                            ),
                            if (_selectedSnacks.isNotEmpty) ...[
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Đồ ăn:'),
                                  Text(
                                      '${_getSnacksTotal().toStringAsFixed(0)} VNĐ'),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tổng cộng:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${_getGrandTotal().toStringAsFixed(0)} VNĐ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Fixed bottom button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreatingBooking ? null : _createBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCreatingBooking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Xác nhận đặt vé',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

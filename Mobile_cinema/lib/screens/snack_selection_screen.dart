import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../models/schedule.dart';
import '../models/movie.dart';
import '../models/booking.dart';
import 'order_summary_screen.dart';

class SnackSelectionScreen extends StatefulWidget {
  final Movie movie;
  final Schedule schedule;
  final List<String> selectedSeats;
  final double seatPrice;

  const SnackSelectionScreen({
    Key? key,
    required this.movie,
    required this.schedule,
    required this.selectedSeats,
    required this.seatPrice,
  }) : super(key: key);

  @override
  State<SnackSelectionScreen> createState() => _SnackSelectionScreenState();
}

class _SnackSelectionScreenState extends State<SnackSelectionScreen> {
  Map<int, int> selectedSnacks = {}; // snackId -> quantity
  List<Snack> snacks = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('SnackSelectionScreen: initState called');
    // Defer loading snacks until after first frame to avoid calling setState
    // during the widget build (which can cause "setState() called during build" errors)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSnacks();
    });
  }

  Future<void> _loadSnacks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.getSnacks();

      setState(() {
        snacks = bookingProvider.snacks;
        isLoading = false;
      });

      print('Loaded ${snacks.length} snacks from API');

      // Nếu API trả về danh sách rỗng, sử dụng mock data
      if (snacks.isEmpty) {
        print('API returned empty snacks, using mock data');
        setState(() {
          snacks = _getMockSnacks();
        });
      }
    } catch (e) {
      print('Error loading snacks from API: $e');
      // Fallback to mock data if API fails
      setState(() {
        snacks = _getMockSnacks();
        isLoading = false;
        errorMessage = null; // Don't show error, use mock data
      });
    }
  }

  List<Snack> _getMockSnacks() {
    return [
      Snack(
        id: 1,
        name: 'Medium popcorn + Medium drink',
        nameVi: 'Bắp rang bơ vừa + Nước vừa',
        description: 'Medium popcorn with medium drink',
        descriptionVi: 'Bắp rang bơ vừa kèm nước vừa',
        price: 55000,
        image: null,
        category: 'combo',
        available: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Snack(
        id: 2,
        name: 'Combo 2 - Hot Dog + Drink',
        nameVi: 'Combo 2 - Hot Dog + Nước',
        description: 'Hot dog + Large drink',
        descriptionVi: 'Hot dog kèm nước lớn',
        price: 80000,
        image: null,
        category: 'combo',
        available: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Snack(
        id: 3,
        name: 'Combo 3 - Family Pack',
        nameVi: 'Combo 3 - Gói gia đình',
        description: '2 Large popcorn + 2 Large drinks + Nachos',
        descriptionVi: '2 bắp rang bơ lớn + 2 nước lớn + Nachos',
        price: 180000,
        image: null,
        category: 'combo',
        available: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Snack(
        id: 4,
        name: 'Coca Cola Large',
        nameVi: 'Coca Cola Lớn',
        description: 'Large Coca Cola',
        descriptionVi: 'Coca Cola size lớn',
        price: 35000,
        image: null,
        category: 'drink',
        available: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Snack(
        id: 5,
        name: 'Pepsi Large',
        nameVi: 'Pepsi Lớn',
        description: 'Large Pepsi',
        descriptionVi: 'Pepsi size lớn',
        price: 35000,
        image: null,
        category: 'drink',
        available: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Snack(
        id: 6,
        name: 'Popcorn Large',
        nameVi: 'Bắp rang bơ lớn',
        description: 'Large popcorn',
        descriptionVi: 'Bắp rang bơ size lớn',
        price: 45000,
        image: null,
        category: 'food',
        available: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  void _updateSnackQuantity(int snackId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        selectedSnacks.remove(snackId);
      } else {
        selectedSnacks[snackId] = quantity;
      }
    });
  }

  double get snackTotal {
    double total = 0;
    selectedSnacks.forEach((snackId, quantity) {
      final snack = snacks.firstWhere((s) => s.id == snackId);
      total += snack.price * quantity;
    });
    return total;
  }

  double get grandTotal {
    return (widget.seatPrice * widget.selectedSeats.length) + snackTotal;
  }

  List<Snack> get combos {
    final displaySnacks = snacks.isEmpty ? _getMockSnacks() : snacks;
    final combosList =
        displaySnacks.where((snack) => snack.category == 'combo').toList();
    print('SnackSelectionScreen: combos count = ${combosList.length}');
    return combosList;
  }

  List<Snack> get drinks {
    final displaySnacks = snacks.isEmpty ? _getMockSnacks() : snacks;
    final drinksList =
        displaySnacks.where((snack) => snack.category == 'drink').toList();
    print('SnackSelectionScreen: drinks count = ${drinksList.length}');
    return drinksList;
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
          'Chọn bắp nước',
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
            // Order summary
            _buildOrderSummary(),

            // Snacks list
            Expanded(
              child: _buildSnacksList(),
            ),

            // Bottom total and buttons
            _buildBottomSection(),
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
              Text(
                  '${(widget.seatPrice * widget.selectedSeats.length).toStringAsFixed(0)} VNĐ'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ghế: ${widget.selectedSeats.join(', ')}'),
              const SizedBox(),
            ],
          ),
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
                '${(widget.seatPrice * widget.selectedSeats.length).toStringAsFixed(0)} VNĐ',
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

  Widget _buildSnacksList() {
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
              onPressed: _loadSnacks,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Sử dụng mock data nếu không có snacks
    final displaySnacks = snacks.isEmpty ? _getMockSnacks() : snacks;
    print(
        'SnackSelectionScreen: Building list with ${displaySnacks.length} snacks');

    // Add bottom padding so the final total/buttons area doesn't overlap the
    // scrollable snacks list and avoids overflow on small screens.
    // Calculate bottom padding dynamically using safe area insets so the
    // scrollable area doesn't get hidden behind the bottom controls.
    // Add bottom padding so the final total/buttons area doesn't overlap the
    // scrollable snacks list and avoids overflow on small screens.
    // The bottom section has a dynamic height, but we can estimate a safe minimum.
    // The SafeArea around the main Column should handle system insets.
    const double estimatedBottomSectionHeight =
        120.0; // Estimate height of _buildBottomSection
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, estimatedBottomSectionHeight + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combos section
          if (combos.isNotEmpty) ...[
            const Text(
              'Combo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...combos.map((snack) => _buildSnackItem(snack)),
            const SizedBox(height: 16),
          ],

          // Drinks section
          if (drinks.isNotEmpty) ...[
            const Text(
              'Nước uống',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...drinks.map((snack) => _buildSnackItem(snack)),
            const SizedBox(height: 16),
          ],

          // Food section
          ...() {
            final foodSnacks = displaySnacks
                .where((snack) => snack.category == 'food')
                .toList();
            if (foodSnacks.isNotEmpty) {
              return [
                const Text(
                  'Đồ ăn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...foodSnacks.map((snack) => _buildSnackItem(snack)),
                const SizedBox(height: 16),
              ];
            }
            return <Widget>[];
          }(),
        ],
      ),
    );
  }

  Widget _buildSnackItem(Snack snack) {
    final quantity = selectedSnacks[snack.id] ?? 0;
    final isCombo = snack.category == 'combo';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCombo ? Colors.green[100] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCombo ? Icons.restaurant : Icons.local_drink,
              color: isCombo ? Colors.green : Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Snack info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snack.nameVi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snack.descriptionVi ?? snack.nameVi,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snack.priceString,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Quantity selector
          Row(
            children: [
              // Minus button
              GestureDetector(
                onTap: quantity > 0
                    ? () => _updateSnackQuantity(snack.id, quantity - 1)
                    : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: quantity > 0 ? Colors.red : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

              // Quantity
              Container(
                width: 40,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Plus button
              GestureDetector(
                onTap: () => _updateSnackQuantity(snack.id, quantity + 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total
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
                  '${grandTotal.toStringAsFixed(0)}₫',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                // Skip button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderSummaryScreen(
                            movie: widget.movie,
                            schedule: widget.schedule,
                            selectedSeats: widget.selectedSeats,
                            selectedSnacks: selectedSnacks,
                            snacks: snacks,
                            seatPrice: widget.seatPrice,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Continue button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderSummaryScreen(
                            movie: widget.movie,
                            schedule: widget.schedule,
                            selectedSeats: widget.selectedSeats,
                            selectedSnacks: selectedSnacks,
                            snacks: snacks,
                            seatPrice: widget.seatPrice,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Tiếp tục',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

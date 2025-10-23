import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../services/api_service_enhanced.dart';
import 'main_screen.dart';
import 'ticket_detail_screen.dart';

class TicketScreen extends StatefulWidget {
  final bool showBackButton;

  const TicketScreen({super.key, this.showBackButton = false});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _isLoading = true;
  String _filterStatus = 'Tất cả';

  // Format price with thousand separator dots
  String _formatPrice(double price) {
    String priceString = price.toStringAsFixed(0);
    final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return priceString.replaceAllMapped(pattern, (Match m) => '${m[1]}.');
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    print('TicketScreen: Loading tickets from API...');
    // Load tickets from API with user ID 1 (mock user ID)
    await context.read<TicketProvider>().loadTicketsFromAPI(1);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final allTickets = ticketProvider.myTickets;

    // Sắp xếp danh sách vé theo `createdAt` giảm dần (mới nhất trước)
    allTickets.sort((a, b) {
      final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    final tickets = _filterStatus == 'Tất cả'
        ? allTickets
        : allTickets.where((t) => getTicketStatus(t) == _filterStatus).toList();

    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Đang tải vé của bạn...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Custom App Bar with status bar padding
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                  elevation: 0,
                  leading: widget.showBackButton
                      ? IconButton(
                          icon: Icon(Icons.arrow_back, color: primaryColor),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : null,
                  automaticallyImplyLeading: widget.showBackButton,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vé của tôi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        '${allTickets.length} vé đã đặt',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  centerTitle: false,
                  expandedHeight: 120,
                  // Add top padding to account for status bar
                  toolbarHeight:
                      kToolbarHeight + MediaQuery.of(context).padding.top,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      // Adjust padding to account for status bar
                      padding: EdgeInsets.fromLTRB(
                          16, 80 + MediaQuery.of(context).padding.top, 16, 0),
                      child: _buildFilterSection(primaryColor, isDark),
                    ),
                  ),
                ),

                // Ticket List
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: tickets.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(primaryColor),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ticket = tickets[index];
                              return _buildTicketCard(
                                context,
                                ticket,
                                getTicketStatus(ticket),
                                primaryColor,
                                isDark,
                              );
                            },
                            childCount: tickets.length,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterSection(Color primaryColor, bool isDark) {
    final statusList = ['Tất cả', 'Sắp chiếu', 'Đã xem', 'Đã huỷ'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statusList.length,
        itemBuilder: (context, index) {
          final status = statusList[index];
          final isSelected = _filterStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                checkmarkColor: Colors.white,
                selectedColor: primaryColor,
                backgroundColor:
                    isDark ? Colors.grey[800] : Colors.grey.withOpacity(0.1),
                elevation: isSelected ? 3 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) {
                  setState(() => _filterStatus = status);
                },
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey[800]),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    final message = _filterStatus == 'Tất cả'
        ? 'Bạn chưa đặt vé nào'
        : 'Không có vé $_filterStatus';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: isDark ? Colors.grey[400] : Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi bạn đặt vé, chúng sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 0),
                ),
              );
            },
            icon: Icon(Icons.movie_outlined, color: primaryColor),
            label: Text(
              'Khám phá phim',
              style: TextStyle(color: primaryColor),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    dynamic ticket,
    String status,
    Color primaryColor,
    bool isDark,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Đã huỷ':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'Đã xem':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = Colors.amber;
        statusIcon = Icons.access_time;
    }

    // Format date and time từ showtime
    DateTime displayDateTime = ticket.createdAt; // Default fallback
    if (ticket.showtime != null) {
      displayDateTime = ticket.showtime!.startTime;
    }

    final day = displayDateTime.day.toString().padLeft(2, '0');
    final month = displayDateTime.month.toString().padLeft(2, '0');
    final year = displayDateTime.year;
    final hour = displayDateTime.hour.toString().padLeft(2, '0');
    final minute = displayDateTime.minute.toString().padLeft(2, '0');
    final formattedDate = '$day/$month/$year';
    final formattedTime = '$hour:$minute';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: ticket),
          ),
        ).then((cancelled) {
          // Refresh the list if ticket was cancelled in the detail screen
          if (cancelled == true) {
            _loadTickets();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with movie info
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ticket.showtime?.movie?.poster ?? '',
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Movie info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.showtime?.movie?.title ?? 'Unknown Movie',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          Icons.calendar_today_outlined,
                          formattedDate,
                          isDark,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          Icons.access_time_outlined,
                          formattedTime,
                          isDark,
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          Icons.event_seat_outlined,
                          'Ghế: ${ticket.seats.map((s) => s.seatNumber).join(', ')}',
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

            // Footer with status and price
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_formatPrice(ticket.totalPrice)} VND',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cancel button
            if (status == 'Sắp chiếu')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancelTicket(context, ticket),
                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                  label: Text(
                    'Hủy vé',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 4),
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

  Future<void> _confirmCancelTicket(
      BuildContext context, dynamic ticket) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận huỷ vé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc muốn huỷ vé này không?'),
            const SizedBox(height: 12),
            Text(
              'Phim: ${ticket.showtime?.movie?.title ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                'Ngày chiếu: ${ticket.showtime?.startTime != null ? '${ticket.showtime!.startTime.day}/${ticket.showtime!.startTime.month}/${ticket.showtime!.startTime.year}' : 'N/A'}'),
            Text(
                'Giờ chiếu: ${ticket.showtime?.startTime != null ? '${ticket.showtime!.startTime.hour.toString().padLeft(2, '0')}:${ticket.showtime!.startTime.minute.toString().padLeft(2, '0')}' : 'N/A'}'),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        actions: [
          TextButton(
            child: const Text('HUỶ BỎ'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Call API to cancel ticket
        final apiService = ApiService();
        final response = await apiService.cancelBooking(ticket.bookingId);

        if (response['success'] == true) {
          // Update local state
          context.read<TicketProvider>().cancelTicket(ticket.bookingId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đã huỷ vé thành công'),
                backgroundColor: Theme.of(context).primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        } else {
          throw Exception(response['message'] ?? 'Lỗi huỷ vé');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi huỷ vé: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  String getTicketStatus(dynamic booking) {
    if (booking.status == 'cancelled') return 'Đã huỷ';

    // Tính toán thời gian chiếu từ showtime
    if (booking.showtime != null) {
      try {
        final showtimeDateTime = booking.showtime!.startTime;
        return DateTime.now().isAfter(showtimeDateTime)
            ? 'Đã xem'
            : 'Sắp chiếu';
      } catch (e) {
        return 'Sắp chiếu';
      }
    }

    return 'Sắp chiếu';
  }
}

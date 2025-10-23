import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/booking.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TicketDetailScreen extends StatefulWidget {
  final Booking ticket;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnimating = false;
  final List<String> _tabs = ['Vé', 'Chi tiết'];
  final GlobalKey _qrKey = GlobalKey();

  // Format price with thousand separator dots
  String _formatPrice(double price) {
    String priceString = price.toStringAsFixed(0);
    final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return priceString.replaceAllMapped(pattern, (Match m) => '${m[1]}.');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isAnimating = true;
        });
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareTicket() async {
    try {
      // 1. Chụp ảnh Widget QR Code
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Lưu ảnh vào tệp tạm thời
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_ticket.png').create();
      await file.writeAsBytes(pngBytes);

      // 3. Chuẩn bị nội dung văn bản
      final date = widget.ticket.showtime?.startTime ?? widget.ticket.createdAt;
      final day = date!.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final formattedDate = '$day/$month/$year';
      final formattedTime = '$hour:$minute';

      final String ticketInfo = '''
🎉 Bạn có vé xem phim! 🎉

🎬 Phim: ${widget.ticket.showtime?.movie?.title ?? 'Unknown Movie'}
📅 Ngày: $formattedDate
🕒 Giờ: $formattedTime
📍 Rạp: ${widget.ticket.showtime?.theater?.name ?? 'Unknown Theater'}
💺 Ghế: ${widget.ticket.seats.map((s) => s.seatNumber).join(', ')}

Mã vé của bạn là: ${_getTicketCode()}
Hãy đến rạp và tận hưởng bộ phim nhé!
''';

      // 4. Chia sẻ cả văn bản và tệp ảnh
      await Share.shareXFiles(
        [XFile(file.path)],
        text: ticketInfo,
        subject:
            'Vé xem phim: ${widget.ticket.showtime?.movie?.title ?? 'Unknown Movie'}',
      );
    } catch (e) {
      print('Lỗi khi chia sẻ vé: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không thể chia sẻ vé. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _confirmCancelTicket() async {
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
              'Phim: ${widget.ticket.showtime?.movie?.title ?? 'Unknown Movie'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                'Ngày chiếu: ${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.day}/${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.month}/${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.year}'),
            Text(
                'Giờ chiếu: ${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.hour}:${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.minute.toString().padLeft(2, '0')}'),
          ],
        ),
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
      final email = context.read<AuthProvider>().currentUser?.email ?? '';
      // TODO: Implement cancel booking functionality
      // await context
      //     .read<BookingProvider>()
      //     .cancelBooking(widget.ticket.bookingId);

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
        Navigator.pop(context, true); // Return true to indicate cancellation
      }
    }
  }

  String _getTicketStatus() {
    if (widget.ticket.status == 'cancelled') return 'Đã huỷ';
    return DateTime.now().isAfter(
            (widget.ticket.showtime?.startTime ?? widget.ticket.createdAt)!)
        ? 'Đã xem'
        : 'Sắp chiếu';
  }

  // Generate ticket code for display
  String _getTicketCode() {
    return widget.ticket.id != null
        ? '#${widget.ticket.id.toString().padLeft(8, '0')}'
        : '#00000000';
  }

  // Generate transaction code
  String _getTransactionCode() {
    return widget.ticket.id != null
        ? 'TXN${widget.ticket.id.toString().padLeft(10, '0')}'
        : 'TXN0000000000';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Calculate status color and icon
    final status = _getTicketStatus();
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

    // Format date and time
    final date = widget.ticket.showtime?.startTime ?? widget.ticket.createdAt;
    final day = date!.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final formattedDate = '$day/$month/$year';
    final formattedTime = '$hour:$minute';
    final dayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final dayOfWeek = dayNames[date!.weekday - 1];

    // Generate unique ticket ID for QR code
    final qrData =
        'TICKET:${widget.ticket.id != null ? widget.ticket.id.toString() : ""}:${widget.ticket.showtime?.movie?.title ?? 'Unknown Movie'}:${widget.ticket.seats.map((s) => s.seatNumber).join(",")}:$formattedDate:$formattedTime';

    return Scaffold(
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Status bar padding
              SizedBox(height: statusBarHeight),

              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Chi tiết vé',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _shareTicket,
                    ),
                  ],
                ),
              ),

              // Tab Bar - Custom implementation
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _tabController.animateTo(0);
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tabController.index == 0
                                        ? primaryColor
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Vé',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _tabController.index == 0
                                            ? primaryColor
                                            : isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _tabController.animateTo(1);
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _tabController.index == 1
                                        ? primaryColor
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Chi tiết',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _tabController.index == 1
                                            ? primaryColor
                                            : isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // Ticket tab with QR code
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedOpacity(
                        opacity: _tabController.index == 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            // Ticket card with QR code
                            Container(
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
                                  // Header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.confirmation_number_outlined,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'MÃ VÉ: ${_getTicketCode().toUpperCase()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Movie info
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Movie poster
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            widget.ticket.showtime?.movie
                                                    ?.poster ??
                                                '',
                                            width: 70,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 70,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.broken_image,
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
                                                widget.ticket.showtime?.movie
                                                        ?.title ??
                                                    'Unknown Movie',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildInfoItem(
                                                Icons.calendar_today_outlined,
                                                "$dayOfWeek, $formattedDate",
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
                                                Icons.location_on_outlined,
                                                widget.ticket.showtime?.theater
                                                        ?.name ??
                                                    'Unknown Theater',
                                                isDark,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status badge
                                  Center(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                  ),

                                  // Dashed line
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
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

                                  // QR Code
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        RepaintBoundary(
                                          key: _qrKey,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: QrImageView(
                                              data: qrData,
                                              version: QrVersions.auto,
                                              size: 200,
                                              eyeStyle: const QrEyeStyle(
                                                eyeShape: QrEyeShape.square,
                                                color: Colors.black,
                                              ),
                                              dataModuleStyle:
                                                  const QrDataModuleStyle(
                                                dataModuleShape:
                                                    QrDataModuleShape.square,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Quét mã QR này tại quầy vé hoặc cổng vào',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Bottom actions
                            if (status == 'Sắp chiếu')
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: _confirmCancelTicket,
                                    icon: Icon(Icons.cancel_outlined,
                                        color: Colors.red[700]),
                                    label: Text(
                                      'Huỷ vé',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red[700]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Details tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedOpacity(
                        opacity: _tabController.index == 1 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Movie details
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thông tin phim',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow(
                                    'Bộ phim',
                                    widget.ticket.showtime?.movie?.title ??
                                        'Unknown Movie',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Rạp chiếu',
                                    widget.ticket.showtime?.theater?.name ??
                                        'Unknown Theater',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Phòng chiếu',
                                    'Phòng 3',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Ngày chiếu',
                                    "$dayOfWeek, $formattedDate",
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Giờ chiếu',
                                    formattedTime,
                                    isDark,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Ticket details
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thông tin vé',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow(
                                    'Mã vé',
                                    _getTicketCode().toUpperCase(),
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Số ghế',
                                    widget.ticket.seats
                                        .map((s) => s.seatNumber)
                                        .join(', '),
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Loại ghế',
                                    'Standard',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Số lượng',
                                    '${widget.ticket.seats.length} vé',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Đơn giá',
                                    '${_formatPrice(90000)} VND/vé',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Tổng tiền',
                                    '${_formatPrice(widget.ticket.totalPrice)} VND',
                                    isDark,
                                    highlightValue: true,
                                    primaryColor: primaryColor,
                                  ),
                                  _buildDetailRow(
                                    'Trạng thái',
                                    status,
                                    isDark,
                                    valueColor: statusColor,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Snacks info
                            if (widget.ticket.snacks.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      isDark ? Colors.grey[850] : Colors.white,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bắp nước đã đặt',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...widget.ticket.snacks
                                        .map(
                                          (snack) => Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.grey[800]
                                                  : Colors.grey[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[200]!,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.local_dining,
                                                  color: primaryColor,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        snack.snackName ??
                                                            'Unknown Snack',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Số lượng: ${snack.quantity}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: isDark
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '${_formatPrice(snack.totalPrice)} VND',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Payment info
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thông tin thanh toán',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow(
                                    'Phương thức',
                                    'Thẻ tín dụng/Ghi nợ',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Thời gian',
                                    'Ngày ${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.day}/${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.month}/${(widget.ticket.showtime?.startTime ?? widget.ticket.createdAt!)!.year}',
                                    isDark,
                                  ),
                                  _buildDetailRow(
                                    'Mã giao dịch',
                                    _getTransactionCode().toUpperCase(),
                                    isDark,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Note
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: statusColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Lưu ý',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '• Vui lòng đến trước giờ chiếu 15-30 phút để nhận vé.\n'
                                    '• Xuất trình mã QR ở tab VÉ để được kiểm tra.\n'
                                    '• Mỗi mã QR chỉ được sử dụng một lần.\n'
                                    '• Đến muộn quá 15 phút sau khi phim bắt đầu, bạn có thể không được vào rạp.\n'
                                    '• Vé đã mua không được đổi hoặc hoàn tiền.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
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

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool highlightValue = false,
    Color? primaryColor,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    highlightValue ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? (highlightValue ? primaryColor : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

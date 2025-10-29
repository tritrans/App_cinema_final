import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/theme_provider.dart';
import '../providers/auth_provider.dart';
// Removed Supabase import - using Laravel API instead
import '../models/user.dart' as app_user;
import '../main.dart'; // Import for the navigator key
import 'login_screen.dart';
import '../utils/url_helper.dart';
import 'favorite_screen.dart';
import 'change_password_screen.dart';
import 'ticket_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _cachedAvatarUrl;
  bool _isLoadingAvatar = true;

  @override
  void initState() {
    super.initState();
    // Tải profile ngay khi màn hình được tạo
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Luôn tải lại profile khi screen được hiển thị, nhưng không làm mới state liên tục
    if (_cachedAvatarUrl == null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAvatar = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      try {
        debugPrint('Loading user profile data...');
        // Lấy avatar từ user profile hiện tại
        final avatarUrl = authProvider.currentUser?.avatar;

        if (!mounted) return;

        setState(() {
          _cachedAvatarUrl = avatarUrl;
          _isLoadingAvatar = false;
        });

        if (avatarUrl != null) {
          debugPrint('Avatar URL from profile: $avatarUrl');
          // Avatar đã được load từ user profile
        } else {
          debugPrint('No avatar URL found in profile data');
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
        setState(() {
          _isLoadingAvatar = false;
        });
      }
    } else {
      setState(() {
        _isLoadingAvatar = false;
      });
    }
  }

  // Profile avatar with edit button
  Widget _buildAvatar(
      app_user.User? user, bool isDark, Color primaryColor, Color textColor) {
    // Sử dụng cached avatar url thay vì FutureBuilder để tránh loading lại liên tục
    if (_isLoadingAvatar) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: textColor, width: 3),
        ),
        child: const CircleAvatar(
          radius: 50,
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Debug: In URL ra console
    debugPrint('AVATAR URL DEBUG: ${_cachedAvatarUrl ?? "NULL"}');

    // Hiển thị avatar từ URL hoặc mặc định
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: textColor, width: 3),
          ),
          child: _cachedAvatarUrl != null
              ? _buildNetworkAvatar(_cachedAvatarUrl!, textColor)
              : _buildDefaultAvatar(textColor),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: InkWell(
              onTap: _isLoading ? null : _pickAndUploadImage,
              child: Icon(
                Icons.camera_alt_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Hiển thị avatar từ network với error handling
  Widget _buildNetworkAvatar(String url, Color borderColor) {
    // Xóa tham số timestamp để tránh load lại liên tục
    String cleanUrl = url;
    if (url.contains('?t=')) {
      cleanUrl = url.substring(0, url.indexOf('?t='));
    }

    // Chuyển đổi URL cho Android emulator
    cleanUrl = UrlHelper.convertUrlForEmulator(cleanUrl);

    return CircleAvatar(
      radius: 50,
      backgroundColor: borderColor,
      backgroundImage: NetworkImage(cleanUrl),
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Error loading avatar: $exception');
      },
      child: null, // Will show default avatar if image fails
    );
  }

  // Avatar mặc định
  Widget _buildDefaultAvatar(Color borderColor) {
    return const CircleAvatar(
      radius: 50,
      backgroundImage:
          NetworkImage('https://randomuser.me/api/portraits/men/31.jpg'),
    );
  }

  // Hiển thị dialog debug thông tin avatar
  void _showAvatarDebugDialog(String avatarUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin avatar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL Avatar:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(avatarUrl, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              const Text('Hình ảnh:'),
              const SizedBox(height: 8),
              Image.network(
                avatarUrl,
                height: 150,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Không thể tải ảnh',
                      style: TextStyle(color: Colors.red));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, app_user.User? user,
      Color primaryColor, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.white;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile avatar with edit button
          _buildAvatar(user as app_user.User?, isDark, primaryColor, textColor),
          const SizedBox(height: 20),

          // User name
          Text(
            user?.email?.split('@')[0] ?? 'Tài khoản',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // User email
          Text(
            user?.email ?? '',
            style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),

          // Membership tag
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Thành viên',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, Color primaryColor, bool isDark) {
    final menuItems = [
      {
        'icon': Icons.confirmation_number_outlined,
        'title': 'Vé của tôi',
        'subtitle': 'Xem vé đã đặt và lịch sử',
        'route': const TicketScreen(showBackButton: true),
      },
      {
        'icon': Icons.favorite_border,
        'title': 'Phim yêu thích',
        'subtitle': 'Danh sách phim đã lưu',
        'route': const FavoriteScreen(),
      },
      {
        'icon': Icons.notifications_none,
        'title': 'Thông báo',
        'subtitle': 'Cập nhật phim mới & khuyến mãi',
        'route': null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Text(
              'Tiện ích',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 70,
                endIndent: 20,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onTap: () {
                    final route = item['route'];
                    if (route != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => route as Widget),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    ThemeProvider themeProvider,
    AuthProvider authProvider,
    Color primaryColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Text(
              'Cài đặt tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Chế độ tối',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    themeProvider.isDarkMode ? 'Đang bật' : 'Đang tắt',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  value: themeProvider.isDarkMode,
                  activeColor: primaryColor,
                  onChanged: (_) {
                    themeProvider.toggleTheme();
                  },
                ),
                Divider(
                  height: 1,
                  indent: 70,
                  endIndent: 20,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: primaryColor,
                    ),
                  ),
                  title: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Cập nhật mật khẩu mới',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc muốn đăng xuất?'),
                    backgroundColor:
                        isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(
                              context); // Close the confirmation dialog

                          try {
                            // Sign out using Laravel API

                            // Then update local auth state
                            authProvider.logout();

                            // Use the global navigator key for more reliable navigation
                            navigatorKey.currentState?.pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          } catch (e) {
                            // Show error snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi đăng xuất: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();

    try {
      // Hiển thị hộp thoại chọn nguồn ảnh
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Chọn ảnh từ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Thư viện ảnh'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Máy ảnh'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Pick an image
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        // Hiển thị hộp thoại tiến trình
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải ảnh lên...'),
              ],
            ),
          ),
        );

        // Upload avatar thông qua AuthProvider
        final File imageFile = File(image.path);
        final bool success =
            await authProvider.updateAvatar(avatar: imageFile.path);

        String? avatarUrl;
        if (success) {
          avatarUrl = authProvider.currentUser?.avatar;
        }

        // Đóng hộp thoại tiến trình
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        if (avatarUrl != null) {
          // Update cached avatar URL và state
          setState(() {
            _cachedAvatarUrl = avatarUrl;
            _isLoading = false;
          });

          // Avatar đã được cập nhật thông qua updateAvatar method

          // Hiển thị thông báo thành công
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ảnh đại diện thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Không thể tải ảnh lên. Vui lòng thử lại sau.';
            _isLoading = false;
          });

          // Hiển thị hộp thoại lỗi chi tiết
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Lỗi tải ảnh'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Không thể tải ảnh lên. Vui lòng kiểm tra:'),
                    const SizedBox(height: 8),
                    const Text('• Kết nối mạng'),
                    const Text('• Quyền truy cập'),
                    const Text('• Kích thước ảnh (tối đa 5MB)'),
                    const SizedBox(height: 16),
                    FutureBuilder<int>(
                      future: imageFile.length(),
                      builder: (context, snapshot) {
                        final size = snapshot.data ?? 0;
                        return Text('Kích thước ảnh: ${size ~/ 1024} KB');
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
        _isLoading = false;
      });

      // Hiển thị lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final app_user.User? user = authProvider.currentUser;
    final isDark = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Trang cá nhân'),
        // backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with gradient background
            _buildProfileHeader(context, user, primaryColor, isDark),
            const SizedBox(height: 24),
            _buildMenuSection(context, primaryColor, isDark),
            const SizedBox(height: 24),
            _buildAccountSection(
                context, themeProvider, authProvider, primaryColor, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

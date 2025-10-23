import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();

    _redirect();
  }

  Future<void> _redirect() async {
    try {
      // Đợi một chút để animation chạy
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();

      print(
          'SplashScreen: AuthProvider isAuthenticated: ${authProvider.isAuthenticated}');
      print('SplashScreen: AuthProvider isLoading: ${authProvider.isLoading}');
      print('SplashScreen: AuthProvider error: ${authProvider.errorMessage}');

      // Đợi AuthProvider khởi tạo xong nếu đang loading
      if (authProvider.isLoading) {
        print('SplashScreen: Waiting for auth initialization...');
        // Đợi tối đa 5 giây
        int waitTime = 0;
        while (authProvider.isLoading && waitTime < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          waitTime++;
        }
      }

      if (!mounted) return;

      // Kiểm tra trạng thái đăng nhập từ AuthProvider
      if (authProvider.isAuthenticated) {
        print('SplashScreen: User is authenticated, navigating to /main');
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        print('SplashScreen: User not authenticated, navigating to /login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('SplashScreen: Error in _redirect: $e');
      // Fallback: chuyển đến login nếu có lỗi
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.movie_outlined,
                        size: 80,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HNP CINEMA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đặt Vé Xem Phim Ngay',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

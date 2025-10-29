import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service_enhanced.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Load token from SharedPreferences
  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Clear token from SharedPreferences
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  // Initialize authentication state
  Future<void> initializeAuth() async {
    try {
      _setLoading(true);
      print('AuthProvider: Starting initialization...');

      // First, try to load token from SharedPreferences
      final savedToken = await _loadToken();
      if (savedToken != null) {
        _token = savedToken;
        print('AuthProvider: Loaded token from storage');

        // Try to get user info with saved token
        try {
          final response = await _apiService.getCurrentUser().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('AuthProvider: getCurrentUser timeout');
              throw Exception('Authentication check timeout');
            },
          );

          print('AuthProvider: Got response: ${response['success']}');

          if (response['success'] == true && response['data'] != null) {
            _currentUser = User.fromJson(response['data']);
            // Fix avatar URL to use correct port for Flutter app (like web app)
            if (_currentUser?.avatar != null) {
              final oldAvatar = _currentUser!.avatar!;
              String newAvatar = oldAvatar;

              // If avatar URL contains 8001 (web app port), replace with 8000 (API port)
              if (oldAvatar.contains('8001')) {
                newAvatar = oldAvatar.replaceAll('8001', '8000');
                print('AuthProvider: Avatar URL fix - Old: $oldAvatar');
                print('AuthProvider: Avatar URL fix - New: $newAvatar');
              }

              // If avatar URL doesn't start with http, prepend API base URL (like web app does)
              if (!newAvatar.startsWith('http')) {
                // Extract base URL without /api suffix
                final apiBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
                newAvatar = '$apiBaseUrl/storage/$newAvatar';
                print(
                    'AuthProvider: Avatar URL prepend API base - New: $newAvatar');
              } else {
                // Ensure the base URL matches the configured API base URL
                final configuredBaseUrl =
                    ApiService.baseUrl.replaceAll('/api', '');
                if (!newAvatar.startsWith(configuredBaseUrl)) {
                  // Replace the domain part with the configured base URL
                  final uri = Uri.parse(newAvatar);
                  newAvatar = '$configuredBaseUrl${uri.path}';
                  print('AuthProvider: Avatar URL rebase - Old: $oldAvatar');
                  print('AuthProvider: Avatar URL rebase - New: $newAvatar');
                }
              }

              _currentUser = _currentUser!.copyWith(avatar: newAvatar);
              print('AuthProvider: Final avatar URL: ${_currentUser!.avatar}');
            }
            _isAuthenticated = true;
            print('AuthProvider: User authenticated: ${_currentUser!.name}');
          } else {
            print('AuthProvider: Token invalid, clearing stored token');
            await _clearToken();
            _token = null;
            _isAuthenticated = false;
            _currentUser = null;
          }
        } catch (e) {
          print('AuthProvider: Error validating token: $e');
          await _clearToken();
          _token = null;
          _isAuthenticated = false;
          _currentUser = null;
        }
      } else {
        print('AuthProvider: No saved token found');
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      print('AuthProvider: Error in initialization: $e');
      _isAuthenticated = false;
      _currentUser = null;
      // Don't show error for initialization failure
    } finally {
      _setLoading(false);
      print(
          'AuthProvider: Initialization completed. Authenticated: $_isAuthenticated');
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      clearError();

      print('AuthProvider: Attempting login for email: $email');
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      print('AuthProvider: Login response: $response');

      if (response['success'] == true && response['data'] != null) {
        _currentUser = User.fromJson(response['data']['user']);
        // Fix avatar URL to use correct port for Flutter app (like web app)
        if (_currentUser?.avatar != null) {
          final oldAvatar = _currentUser!.avatar!;
          String newAvatar = oldAvatar;

          // If avatar URL contains 8001 (web app port), replace with 8000 (API port)
          if (oldAvatar.contains('8001')) {
            newAvatar = oldAvatar.replaceAll('8001', '8000');
          }

          // If avatar URL doesn't start with http, prepend API base URL (like web app does)
          if (!newAvatar.startsWith('http')) {
            final apiBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            newAvatar = '$apiBaseUrl/storage/$newAvatar';
          } else {
            final configuredBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            if (!newAvatar.startsWith(configuredBaseUrl)) {
              final uri = Uri.parse(newAvatar);
              newAvatar = '$configuredBaseUrl${uri.path}';
            }
          }

          _currentUser = _currentUser!.copyWith(avatar: newAvatar);
        }
        _token = response['data'][
            'access_token']; // Save token (API returns 'access_token', not 'token')
        await _saveToken(_token!); // Save token to SharedPreferences
        _isAuthenticated = true;
        _setLoading(false);
        print('AuthProvider: Login successful for user: ${_currentUser?.name}');
        return true;
      } else {
        _setError(response['message'] ?? 'Đăng nhập thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi đăng nhập');
      }
      return false;
    }
  }

  // Register (step 1: send registration info)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Đăng ký thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi đăng ký');
      }
      return false;
    }
  }

  // Send OTP
  Future<bool> sendOtp({
    required String email,
    String type = 'verification',
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.sendOtp(
        email: email,
        type: type,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Gửi OTP thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi gửi OTP');
      }
      return false;
    }
  }

  // Verify OTP and complete registration
  Future<bool> verifyOtp({
    required String email,
    required String otp,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.verifyOtp(
        email: email,
        otp: otp,
        name: name,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response['success'] == true && response['data'] != null) {
        _currentUser = User.fromJson(response['data']['user']);
        // Fix avatar URL to use correct port for Flutter app (like web app)
        if (_currentUser?.avatar != null) {
          final oldAvatar = _currentUser!.avatar!;
          String newAvatar = oldAvatar;

          // If avatar URL contains 8001 (web app port), replace with 8000 (API port)
          if (oldAvatar.contains('8001')) {
            newAvatar = oldAvatar.replaceAll('8001', '8000');
          }

          // If avatar URL doesn't start with http, prepend API base URL (like web app does)
          if (!newAvatar.startsWith('http')) {
            final apiBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            newAvatar = '$apiBaseUrl/storage/$newAvatar';
          } else {
            final configuredBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            if (!newAvatar.startsWith(configuredBaseUrl)) {
              final uri = Uri.parse(newAvatar);
              newAvatar = '$configuredBaseUrl${uri.path}';
            }
          }

          _currentUser = _currentUser!.copyWith(avatar: newAvatar);
        }
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Xác thực OTP thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi xác thực OTP');
      }
      return false;
    }
  }

  // Forgot password
  Future<bool> forgotPassword({
    required String email,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.forgotPassword(email: email);

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(
            response['message'] ?? 'Gửi yêu cầu đặt lại mật khẩu thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi gửi yêu cầu đặt lại mật khẩu');
      }
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.resetPassword(
        email: email,
        otp: otp,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Đặt lại mật khẩu thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi đặt lại mật khẩu');
      }
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Thay đổi mật khẩu thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi thay đổi mật khẩu');
      }
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? avatar,
    bool? receiveNotifications,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.updateUser(
        name: name,
        email: email,
        avatar: avatar,
        receiveNotifications: receiveNotifications,
      );

      if (response['success'] == true && response['data'] != null) {
        _currentUser = User.fromJson(response['data']);
        // Fix avatar URL to use correct port for Flutter app (like web app)
        if (_currentUser?.avatar != null) {
          final oldAvatar = _currentUser!.avatar!;
          String newAvatar = oldAvatar;

          // If avatar URL contains 8001 (web app port), replace with 8000 (API port)
          if (oldAvatar.contains('8001')) {
            newAvatar = oldAvatar.replaceAll('8001', '8000');
          }

          // If avatar URL doesn't start with http, prepend API base URL (like web app does)
          if (!newAvatar.startsWith('http')) {
            final apiBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            newAvatar = '$apiBaseUrl/storage/$newAvatar';
          }

          _currentUser = _currentUser!.copyWith(avatar: newAvatar);
        }
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Cập nhật thông tin thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi cập nhật thông tin');
      }
      return false;
    }
  }

  // Update avatar
  Future<bool> updateAvatar({
    required String avatar,
  }) async {
    try {
      _setLoading(true);
      clearError();

      final response = await _apiService.updateAvatar(avatar: avatar);

      if (response['success'] == true) {
        // Refresh user data
        await getCurrentUserInfo();
        return true;
      } else {
        _setError(response['message'] ?? 'Cập nhật avatar thất bại');
        return false;
      }
    } catch (e) {
      if (e is ApiException) {
        _setError(e.detailedMessage);
      } else {
        _setError('Có lỗi xảy ra khi cập nhật avatar');
      }
      return false;
    }
  }

  // Get current user info
  Future<void> getCurrentUserInfo() async {
    try {
      final response = await _apiService.getCurrentUser();

      if (response['success'] == true && response['data'] != null) {
        _currentUser = User.fromJson(response['data']);
        // Fix avatar URL to use correct port for Flutter app (like web app)
        if (_currentUser?.avatar != null) {
          final oldAvatar = _currentUser!.avatar!;
          String newAvatar = oldAvatar;

          // If avatar URL contains 8001 (web app port), replace with 8000 (API port)
          if (oldAvatar.contains('8001')) {
            newAvatar = oldAvatar.replaceAll('8001', '8000');
          }

          // If avatar URL doesn't start with http, prepend API base URL (like web app does)
          if (!newAvatar.startsWith('http')) {
            final apiBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            newAvatar = '$apiBaseUrl/storage/$newAvatar';
          } else {
            final configuredBaseUrl = ApiService.baseUrl.replaceAll('/api', '');
            if (!newAvatar.startsWith(configuredBaseUrl)) {
              final uri = Uri.parse(newAvatar);
              newAvatar = '$configuredBaseUrl${uri.path}';
            }
          }

          _currentUser = _currentUser!.copyWith(avatar: newAvatar);
        }
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      // Handle silently for refresh operations
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _token = null; // Clear token
      await _clearToken(); // Clear token from SharedPreferences
      notifyListeners();
    }
  }

  // Method to clear all auth data for testing
  Future<void> clearAuth() async {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _token = null;
    _isLoading = false;
    await _clearToken();
    notifyListeners();
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final response = await _apiService.refreshToken();

      if (response['success'] == true) {
        return true;
      } else {
        // Token refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      // Token refresh failed, logout user
      await logout();
      return false;
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.roles.contains(role) ?? false;
  }

  // Check if user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Check if user is manager
  bool get isManager => _currentUser?.isManager ?? false;
}

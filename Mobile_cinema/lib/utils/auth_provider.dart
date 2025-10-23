import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service_enhanced.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Đăng ký
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // API register endpoint only needs name, email, password
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Đăng ký thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Gửi OTP
  Future<bool> sendOtp({
    required String email,
    String type = 'verification',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // API sendOtp endpoint only needs email
      final response = await _apiService.sendOtp(email: email);

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Gửi OTP thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Xác thực OTP và hoàn tất đăng ký
  Future<bool> verifyOtp({
    required String email,
    required String otp,
    required String name,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // API verifyOtp endpoint only needs email and otp
      final response = await _apiService.verifyOtp(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
        otp: otp,
      );

      if (response['success'] == true) {
        // After OTP verification, typically you would log the user in
        // or consider them registered. Here we just return true.
        // The login flow should handle fetching user data.
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Xác thực OTP thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Đăng nhập
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true && response['data']['user'] != null) {
        // Combine user data and token
        final userData = response['data']['user'];
        userData['access_token'] = response['data']['access_token'];
        _user = User.fromJson(userData);
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Đăng nhập thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Thay đổi mật khẩu
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user?.token == null) {
        throw Exception("User not logged in");
      }
      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: password,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Thay đổi mật khẩu thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Lấy thông tin user hiện tại
  Future<void> loadUserProfile() async {
    try {
      if (_user?.token == null) {
        // Try to load token from storage if available, otherwise return
        return;
      }
      final response = await _apiService.getCurrentUser();

      if (response['success'] == true && response['data'] != null) {
        _user = User.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      // Không set error ở đây vì đây là background task
      print('Error loading user profile: $e');
    }
  }

  // Cập nhật thông tin user
  Future<bool> updateUser({
    String? name,
    String? email,
    String? avatar,
    bool? receiveNotifications,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user?.id == null || _user?.token == null) {
        throw Exception("User not logged in");
      }
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      // avatar and receiveNotifications are not in the API updateUser method

      final response = await _apiService.updateUser(
        name: data['name'],
        email: data['email'],
      );

      if (response['success'] == true) {
        await loadUserProfile(); // Reload user data
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Cập nhật thông tin thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Cập nhật avatar
  Future<bool> updateAvatar({
    required String avatarPath,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (_user?.token == null) {
        throw Exception("User not logged in");
      }
      final response = await _apiService.updateAvatar(avatar: avatarPath);

      if (response['success'] == true) {
        await loadUserProfile(); // Reload user data
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'Cập nhật avatar thất bại');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    try {
      if (_user?.token != null) {
        await _apiService.logout();
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      _user = null;
      _error = null;
      notifyListeners();
    }
  }

  // Kiểm tra trạng thái đăng nhập khi khởi động app
  Future<void> checkAuthStatus() async {
    try {
      await loadUserProfile();
    } catch (e) {
      // User not logged in or token expired
      _user = null;
      notifyListeners();
    }
  }
}

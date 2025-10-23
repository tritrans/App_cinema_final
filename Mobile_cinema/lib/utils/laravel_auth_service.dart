// DEPRECATED: This file is no longer used. Use ApiService instead.
// All content has been commented out to avoid conflicts.

/*
import 'api_client.dart';

class LaravelAuthService {
  // ... all content commented out
}
*/

// Placeholder class to avoid import errors
class LaravelAuthService {
  Future<(bool, Map<String, dynamic>?, String?)> login(
      {required String email, required String password}) async {
    return (false, null, 'Deprecated service');
  }

  Future<(bool, Map<String, dynamic>?, String?)> me() async {
    return (false, null, 'Deprecated service');
  }

  Future<void> logout() async {
    // Do nothing - deprecated
  }
}

// Global instance for backward compatibility
final laravelAuth = LaravelAuthService();

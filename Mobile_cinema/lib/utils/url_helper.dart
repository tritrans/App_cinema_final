class UrlHelper {
  /// Chuyển đổi URL cho Android emulator
  /// Android emulator cần sử dụng 10.0.2.2 thay vì 127.0.0.1 để truy cập localhost
  static String convertUrlForEmulator(String url) {
    print('UrlHelper: Original URL: $url');

    // Chuyển đổi avatar URL từ API server sang web server
    if (url.contains('/storage/uploads/avatars/')) {
      // Chuyển từ API server (port 8000) sang web server (port 8001)
      String converted = url;

      // Nếu URL chứa 127.0.0.1:8000, chuyển thành 127.0.0.1:8001
      if (converted.contains('127.0.0.1:8000')) {
        converted = converted.replaceAll('127.0.0.1:8000', '127.0.0.1:8001');
      }

      // Nếu URL chứa 10.0.2.2:8000, chuyển thành 10.0.2.2:8001
      if (converted.contains('10.0.2.2:8000')) {
        converted = converted.replaceAll('10.0.2.2:8000', '10.0.2.2:8001');
      }

      // Chuyển đổi đường dẫn từ /storage/uploads/avatars/ thành /uploads/avatars/
      converted = converted.replaceAll(
          '/storage/uploads/avatars/', '/uploads/avatars/');

      print('UrlHelper: Converted avatar URL: $url -> $converted');
      return converted;
    }

    // Chuyển đổi 127.0.0.1:8001 thành 10.0.2.2:8000 cho Android emulator
    if (url.contains('127.0.0.1:8001')) {
      final converted = url.replaceAll('127.0.0.1:8001', '10.0.2.2:8001');
      print('UrlHelper: Converted 127.0.0.1:8001 -> $converted');
      return converted;
    }
    // Chuyển đổi 127.0.0.1:8000 thành 10.0.2.2:8000 cho Android emulator
    if (url.contains('127.0.0.1:8000')) {
      final converted = url.replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
      print('UrlHelper: Converted 127.0.0.1:8000 -> $converted');
      return converted;
    }
    // Chuyển đổi localhost:8001 thành 10.0.2.2:8001 cho Android emulator
    if (url.contains('localhost:8001')) {
      final converted = url.replaceAll('localhost:8001', '10.0.2.2:8001');
      print('UrlHelper: Converted localhost:8001 -> $converted');
      return converted;
    }
    // Chuyển đổi localhost:8000 thành 10.0.2.2:8000 cho Android emulator
    if (url.contains('localhost:8000')) {
      final converted = url.replaceAll('localhost:8000', '10.0.2.2:8000');
      print('UrlHelper: Converted localhost:8000 -> $converted');
      return converted;
    }

    print('UrlHelper: No conversion needed: $url');
    return url;
  }
}

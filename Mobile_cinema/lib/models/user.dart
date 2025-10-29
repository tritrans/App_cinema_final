class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final List<String> roles;
  final bool receiveNotifications;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? token; // Add token field

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    required this.roles,
    required this.receiveNotifications,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.token, // Add to constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: _processAvatarUrl(json['avatar']),
      role: json['role'] ?? 'user',
      roles: List<String>.from(json['roles'] ?? ['user']),
      receiveNotifications: json['receive_notifications'] == true ||
          json['receive_notifications'] == 1,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      token: json['access_token'], // Get token from login response
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'roles': roles,
      'receive_notifications': receiveNotifications,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    List<String>? roles,
    bool? receiveNotifications,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      token: token ?? this.token,
    );
  }

  // Getter để kiểm tra quyền admin
  bool get isAdmin => role == 'admin' || roles.contains('admin');

  // Getter để kiểm tra quyền manager
  bool get isManager => role == 'manager' || roles.contains('manager');

  // Getter để kiểm tra user thường
  bool get isUser => role == 'user' || roles.contains('user');

  // Getter để lấy avatar URL hoặc placeholder
  String get avatarUrl => avatar ?? 'https://via.placeholder.com/150';

  static String? _processAvatarUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) {
      return null;
    }

    // Import ApiService here to use its baseUrl
    // This is a workaround as ApiService is not directly available in models
    // A better solution would be to pass the base URL or use a global config.
    // For now, we'll hardcode the Android emulator IP for consistency.
    const String androidEmulatorIp = '10.0.2.2';
    const String apiPort = '8000';
    const String webAppPort = '8001';

    String processedUrl = originalUrl;

    // Replace 8001 with 8000 if present
    if (processedUrl.contains(':$webAppPort')) {
      processedUrl = processedUrl.replaceAll(':$webAppPort', ':$apiPort');
    }

    // Replace 127.0.0.1 with Android emulator IP if present
    if (processedUrl.contains('127.0.0.1')) {
      processedUrl = processedUrl.replaceAll('127.0.0.1', androidEmulatorIp);
    }

    // Ensure it starts with http
    if (!processedUrl.startsWith('http')) {
      processedUrl = 'http://$androidEmulatorIp:$apiPort/storage/$processedUrl';
    }

    return processedUrl;
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? accessToken;
  final String? tokenType;
  final int? expiresIn;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.tokenType,
    this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'],
      message: json['message'],
      user: json['data']?['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
      accessToken: json['data']?['access_token'],
      tokenType: json['data']?['token_type'],
      expiresIn: json['data']?['expires_in'],
    );
  }
}

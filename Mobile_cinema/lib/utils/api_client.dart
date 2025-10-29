import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String _computeDefaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://10.0.2.2:8000/api';
  }

  static const String _tokenKey = 'jwt_token';

  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _computeDefaultBaseUrl();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Map<String, String>> _buildHeaders(
      {Map<String, String>? headers}) async {
    final token = await _getToken();
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      defaultHeaders['Authorization'] = 'Bearer ' + token;
    }
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    return defaultHeaders;
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? query]) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }
    final uri = Uri.parse(baseUrl + endpoint);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    });
  }

  Future<(bool, dynamic, int)> _handleResponse(http.Response response) async {
    final status = response.statusCode;
    dynamic body;
    try {
      body = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = response.body;
    }
    if (status >= 200 && status < 300) {
      final data = body is Map<String, dynamic> && body.containsKey('data')
          ? body['data']
          : body;
      return (true, data, status);
    }
    return (false, body, status);
  }

  Future<(bool, dynamic, int)> get(String endpoint,
      {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint, query);
    final mergedHeaders = await _buildHeaders(headers: headers);
    final resp = await http.get(uri, headers: mergedHeaders);
    return _handleResponse(resp);
  }

  Future<(bool, dynamic, int)> post(String endpoint,
      {Object? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(headers: headers);
    final resp = await http.post(uri,
        headers: mergedHeaders,
        body: body is String ? body : json.encode(body));
    return _handleResponse(resp);
  }

  Future<(bool, dynamic, int)> put(String endpoint,
      {Object? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(headers: headers);
    final resp = await http.put(uri,
        headers: mergedHeaders,
        body: body is String ? body : json.encode(body));
    return _handleResponse(resp);
  }

  Future<(bool, dynamic, int)> delete(String endpoint,
      {Object? body, Map<String, String>? headers}) async {
    final uri = _buildUri(endpoint);
    final mergedHeaders = await _buildHeaders(headers: headers);
    final resp = await http.delete(uri,
        headers: mergedHeaders,
        body: body is String ? body : json.encode(body));
    return _handleResponse(resp);
  }
}

final apiClient = ApiClient();

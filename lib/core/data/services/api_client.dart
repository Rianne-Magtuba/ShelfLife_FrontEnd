import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';


class ApiClient {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static const _storage = FlutterSecureStorage();

  // ── Token management ──────────────────────────────────────────────────────



  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ── Headers ───────────────────────────────────────────────────────────────

  /// requiresAuth: false → used only for login and register.
  /// Every other endpoint needs the Bearer token or the backend returns 401.
  static Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      debugPrint(
          '[API] Token exists: ${token != null}'
      );

      if (token != null) {
        // This single line is what "Bearer token" means in practice.
        // The backend's [Authorize] attribute reads this header,
        // verifies the JWT signature with its secret key,
        // and extracts the userId from the token's claims.
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ── HTTP verbs ────────────────────────────────────────────────────────────

  static Future<http.Response> get(
      String path, {
        bool requiresAuth = true,
      }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[API] GET $uri');
    final response = await http.get(uri, headers: headers);
    _log(response, 'GET $path');
    return response;
  }

  static Future<http.Response> post(
      String path,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[API] POST $uri');
    debugPrint('[API] Body: ${jsonEncode(body)}');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _log(response, 'POST $path');
    return response;
  }

  static Future<http.Response> put(
      String path,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    _log(response, 'PUT $path');
    return response;
  }

  static Future<http.Response> delete(
      String path, {
        bool requiresAuth = true,
      }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.delete(uri, headers: headers);
    _log(response, 'DELETE $path');
    return response;
  }

  static Future<http.Response> patch(
      String path, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
      }) async {
    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final uri = Uri.parse('$_baseUrl$path');
    debugPrint('[API] PATCH $uri');
    final response = await http.patch(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _log(response, 'PATCH $path');
    return response;
  }

  // ── Error parsing ─────────────────────────────────────────────────────────

  /// Reads the error message the backend sends.
  /// ASP.NET typically returns { "message": "..." } or { "title": "..." }
  static String parseError(http.Response response, String fallback) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['message'] as String?
          ?? json['Message'] as String?
          ?? json['error']   as String?
          ?? json['title']   as String?
          ?? fallback;
    } catch (_) {
      if (response.body.isNotEmpty && response.body.length < 300) {
        return response.body;
      }
      return fallback;
    }
  }

  // Add at the top of the class
  static VoidCallback? onUnauthorized;

// Update _log to call it
  static void _log(http.Response r, String label) {
    debugPrint('[API] ${r.statusCode} ← $label');
    if (r.statusCode >= 400) {
      debugPrint('[API] Error body: ${r.body}');
    }
    if (r.statusCode == 401) {
      debugPrint('[API] 401 detected — token likely expired');
      onUnauthorized?.call();
    }
  }
}
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import 'api_client.dart';


abstract class IAuthService {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> logout();
  Future<bool> isLoggedIn();
}

// ── MOCK (use this now — no network needed) ───────────────────────────────────

class MockAuthService implements IAuthService {
  static const _storage = FlutterSecureStorage();

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    // Simulates the 2-second network round trip to Cloud Run
    await Future.delayed(const Duration(seconds: 2));

    // Simulates the backend returning 401 for wrong credentials
    if (request.email    != 'test@test.com' ||
        request.password != 'password123') {
      throw Exception('Invalid email or password.');
    }

    // Simulates a 200 OK response with a fake JWT
    final response = LoginResponse(
      token:    'mock.jwt.token',
      userId:   'mock-user-001',
      username: 'testuser',
      email:    request.email,
    );

    // Store exactly the same way the real service will
    await ApiClient.saveToken(response.token);
    await _storage.write(key: 'user_id',  value: response.userId);
    await _storage.write(key: 'username', value: response.username);

    return response;
  }

  @override
  Future<void> register(RegisterRequest request) async {
    await Future.delayed(const Duration(seconds: 2));

    // Simulate 409 Conflict — email already taken
    if (request.email == 'taken@test.com') {
      throw Exception('An account with this email already exists.');
    }

    // Simulate 201 Created — success, no body returned
  }

  @override
  Future<void> logout() async {
    await ApiClient.clearAll();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}

// ── REAL (swap in when backend URL is confirmed) ──────────────────────────────

class AuthService implements IAuthService {
  static const _storage = FlutterSecureStorage();

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await ApiClient.post(
      '/api/auth/login',
      request.toJson(),
      requiresAuth: false, // no token yet — we're getting one
    );

    if (response.statusCode == 200) {
      final json     = jsonDecode(response.body) as Map<String, dynamic>;
      final result   = LoginResponse.fromJson(json);

      await ApiClient.saveToken(result.token);
      await _storage.write(key: 'user_id',  value: result.userId);
      await _storage.write(key: 'username', value: result.username);
      await _storage.write(key: 'email',    value: result.email);

      return result;

    } else if (response.statusCode == 401) {
      throw Exception(ApiClient.parseError(response, 'Invalid email or password.'));
    } else {
      throw Exception(ApiClient.parseError(response, 'Login failed. Please try again.'));
    }
  }

  @override
  Future<void> register(RegisterRequest request) async {
    final response = await ApiClient.post(
      '/api/auth/register',
      request.toJson(),
      requiresAuth: false,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return; // success
    } else if (response.statusCode == 409) {
      throw Exception(ApiClient.parseError(
          response, 'An account with this email already exists.'));
    } else if (response.statusCode == 400) {
      throw Exception(ApiClient.parseError(
          response, 'Please check your details and try again.'));
    } else {
      throw Exception(ApiClient.parseError(
          response, 'Registration failed. Please try again.'));
    }
  }

  @override
  Future<void> logout() async {
    await ApiClient.clearAll();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}
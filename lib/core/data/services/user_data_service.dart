import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common/interfaces/i_user_data_service.dart';
import '../../business/dtos/user_dto.dart';
import 'api_client.dart';

class UserDataService implements IUserDataService {
  static const _storage = FlutterSecureStorage();

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await ApiClient.post(
      '/api/auth/login',
      request.toJson(),
      requiresAuth: false,
    );

    if (response.statusCode == 200) {
      final json   = jsonDecode(response.body) as Map<String, dynamic>;
      final result = LoginResponse.fromJson(json);

      await ApiClient.saveToken(result.token);
      await _storage.write(key: 'user_id',  value: result.userId);
      await _storage.write(key: 'username', value: result.username);
      await _storage.write(key: 'email',    value: result.email);

      return result;
    } else if (response.statusCode == 401) {
      throw Exception(ApiClient.parseError(response, 'Invalid email or password.'));
    }

    throw Exception(ApiClient.parseError(response, 'Login failed. Please try again.'));
  }

  @override
  Future<void> register(RegisterRequest request) async {
    final response = await ApiClient.post(
      '/api/auth/register',
      request.toJson(),
      requiresAuth: false,
    );

    debugPrint('[UserDataService] Register ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 409) {
      throw Exception(ApiClient.parseError(response, 'An account with this email already exists.'));
    } else if (response.statusCode == 400) {
      throw Exception(ApiClient.parseError(response, 'Please check your details and try again.'));
    }

    throw Exception(ApiClient.parseError(response, 'Registration failed. Please try again.'));
  }

  @override
  Future<void> logout() async => ApiClient.clearAll();

  @override
  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> sendPasswordReset(ResetPasswordRequest request) async {
    final response = await ApiClient.post(
      '/api/auth/reset-password',
      request.toJson(),
      requiresAuth: false, // no token — user is logged out
    );

    if (response.statusCode == 200) return;

    if (response.statusCode == 400) {
      throw Exception(
        ApiClient.parseError(response, 'Invalid email format.'),
      );
    }

    throw Exception(
      ApiClient.parseError(response, 'Could not send reset email. Please try again.'),
    );
  }

}
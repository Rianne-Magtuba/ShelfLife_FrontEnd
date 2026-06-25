import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common/entities/notification.dart';
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

    switch (response.statusCode) {
      case 200:
      case 201:
        return;

      case 409:
        final error = ApiClient.parseError(
          response,
          'Email or username already exists.',
        );

        if (error.toLowerCase().contains('email')) {
          throw Exception('An account with this email already exists.');
        }

        if (error.toLowerCase().contains('username')) {
          throw Exception('This username is already taken.');
        }

        throw Exception(error);

      case 400:
        throw Exception(
          ApiClient.parseError(
            response,
            'Please check your details and try again.',
          ),
        );

      default:
        throw Exception(
          ApiClient.parseError(
            response,
            'Registration failed. Please try again.',
          ),
        );
    }
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

  @override
  Future<void> updateProfile(
      UpdateProfileRequest request,
      ) async {

    final response = await ApiClient.put(
      '/api/auth/profile',
      request.toJson(),
    );

    if (response.statusCode == 200) {

      await _storage.write(
        key: 'username',
        value: request.username,
      );

      await _storage.write(
        key: 'email',
        value: request.email,
      );

      return;
    }

    throw Exception(
      ApiClient.parseError(
        response,
        'Unable to update profile.',
      ),
    );
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {
    final response = await ApiClient.post(
      '/api/auth/change-password',
      request.toJson(),
    );

    if (response.statusCode == 200) return;

    if (response.statusCode == 401) {
      throw Exception('Current password is incorrect.');
    }

    throw Exception(
      ApiClient.parseError(response, 'Unable to change password.'),
    );
  }

  // ── Notification settings ───────────────────────────────────────────────

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    final response = await ApiClient.get('/api/auth/notification-settings');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = NotificationSettingsResponse.fromJson(json);
      return NotificationSettings(
        enabled:           data.enabled,
        frequency:         data.frequency == 'realtime' ? 'daily' : data.frequency,
        alertLeadDays:     data.alertLeadDays,
        dailyReminderTime: TimeOfDay(
          hour:   data.reminderHour,
          minute: data.reminderMinute,
        ),
      );
    }

    throw Exception(
      ApiClient.parseError(response, 'Failed to load notification settings.'),
    );
  }

  @override
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    final response = await ApiClient.put(
      '/api/auth/notification-settings',
      NotificationSettingsRequest(
        enabled:        settings.enabled,
        frequency:      settings.frequency,
        alertLeadDays:  settings.alertLeadDays,
        reminderHour:   settings.dailyReminderTime.hour,
        reminderMinute: settings.dailyReminderTime.minute,
      ).toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        ApiClient.parseError(response, 'Failed to save notification settings.'),
      );
    }
  }
}
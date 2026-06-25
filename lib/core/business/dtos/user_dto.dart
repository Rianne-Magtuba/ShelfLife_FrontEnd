import 'dart:convert';
import 'package:flutter/foundation.dart';

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'Email': email, 'Password': password};
}

class LoginResponse {
  final String token;
  final String userId;
  final String username;
  final String email;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> decodeJwt(String token) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return {};
        String payload = parts[1];
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded = utf8.decode(base64Url.decode(payload));
        return jsonDecode(decoded) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }

    final token = _str(json, ['token', 'Token']);
    final claims = decodeJwt(token);
    debugPrint('[JWT Claims] $claims');

    return LoginResponse(
      token:    token,
      userId:   claims['sub']      as String? ?? '',
      username: claims['username'] as String? ?? (json['username'] as String? ?? ''),
      email:    claims['email']    as String? ?? (json['email']    as String? ?? ''),
    );
  }

  static String _str(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] != null) return json[k] as String;
    }
    throw FormatException('None of $keys found in response: $json');
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  RegisterRequest({required this.username, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'Username': username,
    'Email':    email,
    'Password': password,
  };

}

class ResetPasswordRequest {
  final String email;
  const ResetPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'Email': email};
}

class UpdateProfileRequest {
  final String username;
  final String email;

  UpdateProfileRequest({
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'Username': username,
    'Email': email,
  };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'CurrentPassword': currentPassword,
    'NewPassword': newPassword,
  };
}

class NotificationSettingsRequest {
  final bool enabled;
  final String frequency;
  final int alertLeadDays;
  final int reminderHour;
  final int reminderMinute;

  NotificationSettingsRequest({
    required this.enabled,
    required this.frequency,
    required this.alertLeadDays,
    required this.reminderHour,
    required this.reminderMinute,
  });

  Map<String, dynamic> toJson() => {
    'enabled':       enabled,
    'frequency':     frequency,
    'alertLeadDays': alertLeadDays,
    'reminderHour':  reminderHour,
    'reminderMinute': reminderMinute,
  };
}

class NotificationSettingsResponse {
  final bool enabled;
  final String frequency;
  final int alertLeadDays;
  final int reminderHour;
  final int reminderMinute;

  NotificationSettingsResponse.fromJson(Map<String, dynamic> json)
      : enabled        = json['enabled']        as bool,
        frequency      = json['frequency']      as String,
        alertLeadDays  = json['alertLeadDays']  as int,
        reminderHour   = json['reminderHour']   as int,
        reminderMinute = json['reminderMinute'] as int;
}
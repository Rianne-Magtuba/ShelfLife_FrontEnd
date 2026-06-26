import 'package:flutter/cupertino.dart';

import '../../common/entities/notification.dart';
import '../../common/interfaces/i_user_data_service.dart';
import '../../data/services/cache_service.dart';
import '../../data/services/user_data_service.dart';
import '../dtos/user_dto.dart';

class AuthService implements IUserDataService {
  final _data = UserDataService();

  @override
  Future<LoginResponse> login(LoginRequest request) =>
      _data.login(request);

  @override
  Future<void> register(RegisterRequest request) =>
      _data.register(request);

  @override
  Future<void> logout() => _data.logout();

  @override
  Future<bool> isLoggedIn() => _data.isLoggedIn();
  
  @override
  Future<void> sendPasswordReset(ResetPasswordRequest request) {
    // TODO: implement sendPasswordReset
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile(
      UpdateProfileRequest request,
      ) =>
      _data.updateProfile(request);

  @override
  Future<void> changePassword(
      ChangePasswordRequest request,
      ) =>
      _data.changePassword(request);

  Future<NotificationSettings> getNotificationSettings() async {
    try {
      return await _data.getNotificationSettings();
    } catch (e) {
      debugPrint('[Settings] API failed, using cache: $e');
      return CacheService.loadNotificationSettings();
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    await Future.wait([
      _data.saveNotificationSettings(settings),
      CacheService.saveNotificationSettings(settings),
    ]);
  }
}
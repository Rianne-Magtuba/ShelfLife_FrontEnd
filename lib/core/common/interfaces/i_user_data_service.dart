import '../../business/dtos/user_dto.dart';
import '../entities/notification.dart';

abstract class IUserDataService {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<void> sendPasswordReset(ResetPasswordRequest request);
  Future<void> updateProfile(
      UpdateProfileRequest request,
      );

  Future<void> changePassword(
      ChangePasswordRequest request,
      );

  // ── Notification settings ───────────────────────────────────────────────
  Future<NotificationSettings> getNotificationSettings(); // ← now async
  Future<void> saveNotificationSettings(NotificationSettings settings);

}
import '../../business/dtos/user_dto.dart';

abstract class IUserDataService {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<void> sendPasswordReset(ResetPasswordRequest request);
}
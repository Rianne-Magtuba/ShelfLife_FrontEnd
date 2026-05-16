import '../../business/dtos/user_dto.dart';

abstract class IAuthService {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> register(RegisterRequest request);
  Future<void> logout();
  Future<bool> isLoggedIn();
}
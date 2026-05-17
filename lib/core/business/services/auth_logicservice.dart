import '../../common/interfaces/i_user_data_service.dart';
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
}
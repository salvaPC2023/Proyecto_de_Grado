import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/token_storage.dart';
import 'api_client.dart';
import 'dtos/auth_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.apiClient, required this.tokenStorage});
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Future<AuthSession> login(String username, String password) async {
    final response = await apiClient.dio.post(
      '/auth/login',
      data: LoginRequest(username: username, password: password).toJson(),
    );
    final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);
    await tokenStorage.write(loginResponse.accessToken);
    return AuthSession(token: loginResponse.accessToken, user: loginResponse.user);
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } finally {
      await tokenStorage.delete();
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await tokenStorage.read();
    if (token == null) return null;
    try {
      final response = await apiClient.dio.get('/users/me');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      return AuthSession(token: token, user: user);
    } catch (_) {
      await tokenStorage.delete();
      return null;
    }
  }
}

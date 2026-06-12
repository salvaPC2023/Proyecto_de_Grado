import '../models/user.dart';

abstract class AuthRepository {
  Future<AuthSession> login(String username, String password);
  Future<void> logout();
  Future<AuthSession?> restoreSession();
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'auth_token';
  final _storage = const FlutterSecureStorage();

  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<String?> read() => _storage.read(key: _key);
  Future<void> delete() => _storage.delete(key: _key);
}

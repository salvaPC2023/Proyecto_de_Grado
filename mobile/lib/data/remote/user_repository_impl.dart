import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import 'api_client.dart';
import 'dtos/user_dto.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<User> getMe() async {
    final res = await apiClient.dio.get('/users/me');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<User> updateProfile({String? displayName}) async {
    final res = await apiClient.dio.patch('/users/me', data: {
      if (displayName != null) 'display_name': displayName,
    });
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await apiClient.dio.patch('/users/me/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  @override
  Future<List<User>> listTechnicians() async {
    final res = await apiClient.dio.get('/technicians');
    final list = res.data as List<dynamic>;
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<User> createTechnician({required String username, required String displayName}) async {
    final res = await apiClient.dio.post(
      '/technicians',
      data: CreateTechnicianRequest(username: username, displayName: displayName).toJson(),
    );
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<User> getTechnician(String id) async {
    final res = await apiClient.dio.get('/technicians/$id');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<User> updateTechnician(String id, {String? username, String? displayName}) async {
    final res = await apiClient.dio.patch(
      '/technicians/$id',
      data: UpdateTechnicianRequest(username: username, displayName: displayName).toJson(),
    );
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<User> setTechnicianStatus(String id, {required bool active}) async {
    final res = await apiClient.dio.patch('/technicians/$id/status', data: {'status': active ? 'active' : 'disabled'});
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTechnician(String id) async {
    await apiClient.dio.delete('/technicians/$id');
  }
}

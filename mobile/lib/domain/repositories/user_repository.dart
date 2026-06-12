import '../models/user.dart';

abstract class UserRepository {
  Future<User> getMe();
  Future<User> updateProfile({String? displayName});
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<List<User>> listTechnicians();
  Future<User> createTechnician({required String username, required String displayName});
  Future<User> getTechnician(String id);
  Future<User> updateTechnician(String id, {String? displayName, String? username});
  Future<User> setTechnicianStatus(String id, {required bool active});
  Future<void> deleteTechnician(String id);
}

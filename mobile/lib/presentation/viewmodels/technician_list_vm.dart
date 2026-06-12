import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/user.dart';

class TechnicianListNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() => ref.read(userRepositoryProvider).listTechnicians();

  Future<void> loadList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).listTechnicians(),
    );
  }

  Future<void> createTechnician(String username, String displayName) async {
    await ref.read(userRepositoryProvider).createTechnician(
          username: username,
          displayName: displayName,
        );
    await loadList();
  }

  Future<void> editTechnician(String id, {String? displayName, String? username}) async {
    await ref.read(userRepositoryProvider).updateTechnician(id,
        displayName: displayName, username: username);
    await loadList();
  }

  Future<void> disableTechnician(String id) async {
    await ref.read(userRepositoryProvider).setTechnicianStatus(id, active: false);
    await loadList();
  }

  Future<void> enableTechnician(String id) async {
    await ref.read(userRepositoryProvider).setTechnicianStatus(id, active: true);
    await loadList();
  }

  Future<void> deleteTechnician(String id) async {
    await ref.read(userRepositoryProvider).deleteTechnician(id);
    await loadList();
  }
}

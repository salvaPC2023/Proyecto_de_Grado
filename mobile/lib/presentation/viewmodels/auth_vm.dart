import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/user.dart';

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.restoreSession();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(username, password),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AsyncData(null);
    }
  }
}

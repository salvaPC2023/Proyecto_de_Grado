import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/user.dart';

class ProfileNotifier extends AutoDisposeAsyncNotifier<User> {
  @override
  Future<User> build() => ref.read(userRepositoryProvider).getMe();

  Future<void> updateDisplayName(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).updateProfile(displayName: name),
    );
  }

  Future<void> changePassword(String current, String next) async {
    final snapshot = state.valueOrNull;
    await ref.read(userRepositoryProvider).changePassword(
          currentPassword: current,
          newPassword: next,
        );
    if (snapshot != null) state = AsyncData(snapshot);
  }
}

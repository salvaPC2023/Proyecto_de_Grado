import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/repositories/standardization_repository.dart';

// State is String? — null = idle, non-null = standardized text in review.
// AsyncValue wrapping: loading while request in-flight, error on failure.
class StandardizationNotifier extends AutoDisposeAsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> standardize(String text) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(standardizationRepositoryProvider).standardize(text),
    );
  }

  Future<void> retry(String text) => standardize(text);

  void reset() {
    state = const AsyncValue.data(null);
  }
}

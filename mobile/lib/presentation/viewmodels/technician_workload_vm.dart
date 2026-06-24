import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/work_order.dart';

class TechnicianWorkloadNotifier
    extends AsyncNotifier<List<TechnicianWorkload>> {
  @override
  Future<List<TechnicianWorkload>> build() async {
    return ref.read(workOrderRepositoryProvider).getWorkload();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(workOrderRepositoryProvider).getWorkload(),
    );
  }
}

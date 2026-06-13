import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/work_order.dart';

class WorkOrderDetailNotifier extends AutoDisposeFamilyAsyncNotifier<WorkOrder, String> {
  @override
  Future<WorkOrder> build(String id) =>
      ref.read(workOrderRepositoryProvider).getById(id);

  Future<void> loadDetail(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(workOrderRepositoryProvider).getById(id),
    );
  }
}

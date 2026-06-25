import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/remote/dtos/work_order_dto.dart';
import '../../domain/models/work_order.dart';

class SupervisorDashboardNotifier extends AutoDisposeAsyncNotifier<List<WorkOrder>> {
  @override
  Future<List<WorkOrder>> build() async => [];

  Future<void> loadShiftList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(workOrderRepositoryProvider).listForShift(),
    );
  }

  Future<void> createWorkOrder(CreateWorkOrderRequest request) async {
    await ref.read(workOrderRepositoryProvider).createWorkOrder(request);
    await loadShiftList();
  }
}

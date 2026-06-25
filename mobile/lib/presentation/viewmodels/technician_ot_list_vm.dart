import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/work_order.dart';

class OtListResult {
  const OtListResult({required this.list, required this.isStale});
  final List<WorkOrder> list;
  final bool isStale;
}

class TechnicianOtListNotifier extends AutoDisposeAsyncNotifier<OtListResult> {
  @override
  Future<OtListResult> build() => _fetch();

  Future<OtListResult> _fetch() async {
    final list = await ref.read(workOrderRepositoryProvider).listForShift();
    return OtListResult(list: list, isStale: false);
  }

  Future<void> loadList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

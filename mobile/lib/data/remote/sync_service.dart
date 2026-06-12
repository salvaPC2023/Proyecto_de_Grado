import '../../domain/repositories/sync_repository.dart';
import '../local/daos/pending_closure_dao.dart';
import '../local/database.dart';
import 'api_client.dart';
import 'dtos/closure_dto.dart';

class SyncService implements SyncRepository {
  SyncService({required this.apiClient, required this.dao});
  final ApiClient apiClient;
  final PendingClosureDao dao;

  @override
  Future<int> pendingCount() => dao.countPending();

  @override
  Future<SyncResult> syncPending() async {
    final items = await dao.listPending();
    int succeeded = 0;
    int failed = 0;

    for (final item in items) {
      try {
        await apiClient.dio.post(
          '/work-orders/${item.otId}/steps/${item.stepId}/closures',
          data: RegisterClosureRequest(
            actualDuration: item.actualDuration,
            deviationKey: item.deviationKey,
            workDescription: item.workDescription,
            safetyQuestionResponse: item.safetyQuestionResponse == 1,
          ).toJson(),
        );
        await dao.markSynced(item.id);
        succeeded++;
      } catch (e) {
        await dao.markFailed(item.id, e.toString());
        failed++;
      }
    }

    await dao.deleteSynced();
    return SyncResult(succeeded: succeeded, failed: failed);
  }

  Future<void> retryFailed(int pendingId) async {
    await dao.resetFailed(pendingId);
  }

  Future<List<PendingClosure>> listFailed() => dao.listFailed();

  Future<int> insertPending(PendingClosuresCompanion entry) => dao.insertPending(entry);
}

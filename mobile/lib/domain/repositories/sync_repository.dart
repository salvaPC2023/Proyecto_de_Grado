class SyncResult {
  const SyncResult({required this.succeeded, required this.failed});
  final int succeeded;
  final int failed;
  bool get hasFailures => failed > 0;
}

abstract class SyncRepository {
  Future<SyncResult> syncPending();
  Future<int> pendingCount();
}

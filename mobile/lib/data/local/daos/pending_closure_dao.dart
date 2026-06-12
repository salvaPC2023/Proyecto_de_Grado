import 'package:drift/drift.dart';
import '../database.dart';

part 'pending_closure_dao.g.dart';

@DriftAccessor(tables: [PendingClosures])
class PendingClosureDao extends DatabaseAccessor<AppDatabase> with _$PendingClosureDaoMixin {
  PendingClosureDao(super.db);

  Future<int> insertPending(PendingClosuresCompanion entry) =>
      into(pendingClosures).insert(entry);

  Future<List<PendingClosure>> listPending() =>
      (select(pendingClosures)..where((t) => t.syncStatus.equals('pending'))
        ..orderBy([(t) => OrderingTerm.asc(t.submittedAt)])).get();

  Future<void> markSynced(int id) =>
      (update(pendingClosures)..where((t) => t.id.equals(id)))
          .write(const PendingClosuresCompanion(syncStatus: Value('synced')));

  Future<void> markFailed(int id, String errorMessage) =>
      (update(pendingClosures)..where((t) => t.id.equals(id))).write(
        PendingClosuresCompanion(
          syncStatus: const Value('failed'),
          errorMessage: Value(errorMessage),
        ),
      );

  Future<void> deleteSynced() =>
      (delete(pendingClosures)..where((t) => t.syncStatus.equals('synced'))).go();

  Future<int> countPending() async {
    final count = pendingClosures.id.count();
    final query = selectOnly(pendingClosures)
      ..addColumns([count])
      ..where(pendingClosures.syncStatus.equals('pending'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<PendingClosure>> listFailed() =>
      (select(pendingClosures)..where((t) => t.syncStatus.equals('failed'))).get();

  Future<void> resetFailed(int id) =>
      (update(pendingClosures)..where((t) => t.id.equals(id)))
          .write(const PendingClosuresCompanion(syncStatus: Value('pending'), errorMessage: Value(null)));
}

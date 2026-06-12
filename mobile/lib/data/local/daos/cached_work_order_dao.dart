import 'package:drift/drift.dart';
import '../database.dart';

part 'cached_work_order_dao.g.dart';

@DriftAccessor(tables: [CachedWorkOrders, CachedOtSteps])
class CachedWorkOrderDao extends DatabaseAccessor<AppDatabase> with _$CachedWorkOrderDaoMixin {
  CachedWorkOrderDao(super.db);

  Future<void> upsertAll(List<CachedWorkOrdersCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(cachedWorkOrders, rows);
    });
  }

  Future<List<CachedWorkOrder>> listCached() =>
      (select(cachedWorkOrders)..orderBy([(t) => OrderingTerm.desc(t.cachedAt)])).get();

  Future<void> upsertSteps(List<CachedOtStepsCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(cachedOtSteps, rows);
    });
  }

  Future<List<CachedOtStep>> listStepsFor(String workOrderId) =>
      (select(cachedOtSteps)
            ..where((t) => t.workOrderId.equals(workOrderId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
}

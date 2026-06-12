import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'daos/pending_closure_dao.dart';
import 'daos/cached_work_order_dao.dart';

part 'database.g.dart';

class PendingClosures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get stepId => text()();
  TextColumn get otId => text()();
  RealColumn get actualDuration => real()();
  TextColumn get deviationKey => text()();
  TextColumn get workDescription => text()();
  IntColumn get safetyQuestionResponse => integer()();
  IntColumn get submittedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();
}

class CachedWorkOrders extends Table {
  TextColumn get id => text()();
  TextColumn get orderType => text()();
  TextColumn get technicalLocationId => text()();
  TextColumn get technicalLocationLabel => text()();
  TextColumn get assignedTechnicianId => text()();
  IntColumn get priority => integer()();
  TextColumn get plannedStart => text()();
  TextColumn get plannedEnd => text()();
  TextColumn get status => text()();
  IntColumn get shiftNumber => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedOtSteps extends Table {
  TextColumn get id => text()();
  TextColumn get workOrderId => text()();
  IntColumn get position => integer()();
  TextColumn get description => text()();
  TextColumn get controlKey => text()();
  RealColumn get plannedInterventionTime => real().nullable()();
  IntColumn get isFixed => integer()();
  IntColumn get hasClosure => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [PendingClosures, CachedWorkOrders, CachedOtSteps],
  daos: [PendingClosureDao, CachedWorkOrderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'maintenance_app');
  }
}

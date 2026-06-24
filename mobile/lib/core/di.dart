import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/local/daos/cached_work_order_dao.dart';
import '../data/local/daos/pending_closure_dao.dart';
import '../data/local/token_storage.dart';
import '../data/remote/api_client.dart';
import '../data/remote/auth_repository_impl.dart';
import '../data/remote/sync_service.dart';
import '../data/remote/technical_location_repository_impl.dart';
import '../data/remote/user_repository_impl.dart';
import '../data/remote/work_order_repository_impl.dart';
import '../domain/models/technical_location.dart';
import '../domain/models/user.dart';
import '../domain/models/work_order.dart';
import '../presentation/viewmodels/auth_vm.dart';
import '../presentation/viewmodels/closure_form_vm.dart';
import '../presentation/viewmodels/location_report_vm.dart';
import '../presentation/viewmodels/profile_vm.dart';
import '../presentation/viewmodels/supervisor_dashboard_vm.dart';
import '../presentation/viewmodels/technician_list_vm.dart';
import '../presentation/viewmodels/technician_ot_list_vm.dart';
import '../presentation/viewmodels/technician_workload_vm.dart';
import '../presentation/viewmodels/work_order_detail_vm.dart';
import 'providers.dart';
import 'router.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(tokenStorageProvider));
});

// ─── DAOs ─────────────────────────────────────────────────────────────────────

final pendingClosureDaoProvider = Provider<PendingClosureDao>(
  (ref) => ref.read(appDatabaseProvider).pendingClosureDao,
);

final cachedWorkOrderDaoProvider = Provider<CachedWorkOrderDao>(
  (ref) => ref.read(appDatabaseProvider).cachedWorkOrderDao,
);

// ─── Repository overrides ─────────────────────────────────────────────────────
// Override the placeholder providers from providers.dart with concrete impls.

List<Override> get appProviderOverrides => [
      authRepositoryProvider.overrideWith(
        (ref) => AuthRepositoryImpl(
          apiClient: ref.read(apiClientProvider),
          tokenStorage: ref.read(tokenStorageProvider),
        ),
      ),
      userRepositoryProvider.overrideWith(
        (ref) => UserRepositoryImpl(apiClient: ref.read(apiClientProvider)),
      ),
      workOrderRepositoryProvider.overrideWith(
        (ref) => WorkOrderRepositoryImpl(
          apiClient: ref.read(apiClientProvider),
          dao: ref.read(cachedWorkOrderDaoProvider),
        ),
      ),
      techLocRepositoryProvider.overrideWith(
        (ref) => TechnicalLocationRepositoryImpl(apiClient: ref.read(apiClientProvider)),
      ),
      syncServiceProvider.overrideWith(
        (ref) => SyncService(
          apiClient: ref.read(apiClientProvider),
          dao: ref.read(pendingClosureDaoProvider),
        ),
      ),
    ];

// ─── ViewModels ───────────────────────────────────────────────────────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);

final profileNotifierProvider =
    AsyncNotifierProvider.autoDispose<ProfileNotifier, User>(ProfileNotifier.new);

final technicianListNotifierProvider =
    AsyncNotifierProvider<TechnicianListNotifier, List<User>>(TechnicianListNotifier.new);

final supervisorDashboardProvider =
    AsyncNotifierProvider<SupervisorDashboardNotifier, List<WorkOrder>>(
        SupervisorDashboardNotifier.new);

final technicianOtListProvider =
    AsyncNotifierProvider<TechnicianOtListNotifier, OtListResult>(
        TechnicianOtListNotifier.new);

final workOrderDetailProvider =
    AsyncNotifierProviderFamily<WorkOrderDetailNotifier, WorkOrder, String>(
        WorkOrderDetailNotifier.new);

final locationReportProvider =
    AsyncNotifierProvider<LocationReportNotifier, List<TechnicalLocationReportEntry>>(
        LocationReportNotifier.new);

final closureFormProvider =
    NotifierProvider<ClosureFormNotifier, ClosureFormState>(ClosureFormNotifier.new);

final technicianWorkloadProvider =
    AsyncNotifierProvider<TechnicianWorkloadNotifier, List<TechnicianWorkload>>(
        TechnicianWorkloadNotifier.new);

final workloadDrilldownProvider =
    FutureProvider.family<List<WorkOrder>, String>((ref, technicianId) async {
  return ref.read(workOrderRepositoryProvider).listForTechnicianInShift(technicianId);
});

// ─── Sync helpers ─────────────────────────────────────────────────────────────

final pendingCountProvider = FutureProvider<int>(
  (ref) => ref.read(syncServiceProvider).pendingCount(),
);

final failedClosuresForOtProvider =
    FutureProvider.family<List<dynamic>, String>((ref, otId) async {
  final failed = await ref.read(syncServiceProvider).listFailed();
  return failed.where((c) => c.otId == otId).toList();
});

// ─── Router ───────────────────────────────────────────────────────────────────

final routerProvider = Provider((ref) => AppRouter.router(ref));

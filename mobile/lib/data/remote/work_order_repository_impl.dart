import '../../domain/models/technical_location.dart';
import '../../domain/models/work_order.dart';
import '../../domain/repositories/work_order_repository.dart';
import '../local/daos/cached_work_order_dao.dart';
import '../local/database.dart';
import 'api_client.dart';
import 'dtos/closure_dto.dart';
import 'dtos/work_order_dto.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  WorkOrderRepositoryImpl({required this.apiClient, required this.dao});
  final ApiClient apiClient;
  final CachedWorkOrderDao dao;

  @override
  Future<List<WorkOrder>> listForShift() async {
    try {
      final res = await apiClient.dio.get('/work-orders');
      final list = res.data as List<dynamic>;
      final orders = list.map((e) => WorkOrder.fromJson(e as Map<String, dynamic>)).toList();
      await _cacheOrders(orders);
      return orders;
    } catch (_) {
      return _loadFromCache();
    }
  }

  @override
  Future<WorkOrder> getById(String id) async {
    final res = await apiClient.dio.get('/work-orders/$id');
    return WorkOrder.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<WorkOrder> createWorkOrder(CreateWorkOrderRequest request) async {
    final res = await apiClient.dio.post('/work-orders', data: request.toJson());
    return WorkOrder.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<WorkOrder> registerClosure({
    required String otId,
    required String stepId,
    required RegisterClosureRequest request,
  }) async {
    final res = await apiClient.dio.post(
      '/work-orders/$otId/steps/$stepId/closures',
      data: request.toJson(),
    );
    return WorkOrder.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> _cacheOrders(List<WorkOrder> orders) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = orders
        .map(
          (o) => CachedWorkOrdersCompanion.insert(
            id: o.id,
            orderType: o.orderType,
            technicalLocationId: o.technicalLocation.id,
            technicalLocationLabel: o.technicalLocation.fullLabel,
            assignedTechnicianId: o.assignedTechnicianId,
            priority: o.priority,
            plannedStart: o.plannedStart.toIso8601String(),
            plannedEnd: o.plannedEnd.toIso8601String(),
            status: o.status.name,
            shiftNumber: o.shiftNumber,
            cachedAt: now,
          ),
        )
        .toList();
    await dao.upsertAll(rows);
  }

  Future<List<WorkOrder>> _loadFromCache() async {
    final cached = await dao.listCached();
    return cached.map(_fromCachedRow).toList();
  }

  WorkOrder _fromCachedRow(CachedWorkOrder row) {
    // fullLabel format: 'sector / subsector / system / subsystem'
    final parts = row.technicalLocationLabel.split(' / ');
    final location = TechnicalLocation(
      id: row.technicalLocationId,
      sector: parts.length > 0 ? parts[0] : row.technicalLocationLabel,
      subsector: parts.length > 1 ? parts[1] : '',
      system: parts.length > 2 ? parts[2] : '',
      subsystem: parts.length > 3 ? parts[3] : '',
    );
    return WorkOrder(
      id: row.id,
      orderType: row.orderType,
      technicalLocation: location,
      assignedTechnicianId: row.assignedTechnicianId,
      priority: row.priority,
      plannedStart: DateTime.parse(row.plannedStart),
      plannedEnd: DateTime.parse(row.plannedEnd),
      status: WorkOrderStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => WorkOrderStatus.released,
      ),
      shiftNumber: row.shiftNumber,
      steps: const [],
    );
  }
}

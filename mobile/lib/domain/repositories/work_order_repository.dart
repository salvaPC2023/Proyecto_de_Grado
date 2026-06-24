import '../models/work_order.dart';
import '../../data/remote/dtos/closure_dto.dart';
import '../../data/remote/dtos/work_order_dto.dart';

abstract class WorkOrderRepository {
  Future<List<WorkOrder>> listForShift();
  Future<List<WorkOrder>> listForTechnicianInShift(String technicianId);
  Future<WorkOrder> getById(String id);
  Future<WorkOrder> createWorkOrder(CreateWorkOrderRequest request);
  Future<WorkOrder> registerClosure({
    required String otId,
    required String stepId,
    required RegisterClosureRequest request,
  });
  Future<List<TechnicianWorkload>> getWorkload();
}

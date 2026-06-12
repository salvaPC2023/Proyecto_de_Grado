import '../../../domain/models/work_order.dart';
import '../../../domain/models/ot_step.dart';
import '../../../domain/models/technical_location.dart';

class WorkOrderSummaryDto {
  static WorkOrder fromJson(Map<String, dynamic> json) => WorkOrder.fromJson(json);
}

class WorkOrderDetailDto {
  static WorkOrder fromJson(Map<String, dynamic> json) => WorkOrder.fromJson(json);
}

class CreateWorkOrderRequest {
  const CreateWorkOrderRequest({
    required this.orderType,
    required this.technicalLocationId,
    required this.assignedTechnicianId,
    required this.plannerGroup,
    required this.installationState,
    required this.plannedStart,
    required this.plannedEnd,
    required this.priority,
    required this.steps,
  });

  final String orderType;
  final String technicalLocationId;
  final String assignedTechnicianId;
  final String plannerGroup;
  final String installationState;
  final DateTime plannedStart;
  final DateTime plannedEnd;
  final int priority;
  final List<CreateStepRequest> steps;

  Map<String, dynamic> toJson() => {
        'order_type': orderType,
        'technical_location_id': technicalLocationId,
        'assigned_technician_id': assignedTechnicianId,
        'planner_group': plannerGroup,
        'installation_state': installationState,
        'planned_start': '${plannedStart.year.toString().padLeft(4, '0')}-${plannedStart.month.toString().padLeft(2, '0')}-${plannedStart.day.toString().padLeft(2, '0')}',
        'planned_end': '${plannedEnd.year.toString().padLeft(4, '0')}-${plannedEnd.month.toString().padLeft(2, '0')}-${plannedEnd.day.toString().padLeft(2, '0')}',
        'priority': priority,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

class CreateStepRequest {
  const CreateStepRequest({
    required this.description,
    required this.controlKey,
    this.plannedInterventionTime,
  });
  final String description;
  final String controlKey;
  final double? plannedInterventionTime;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'description': description,
      'control_key': controlKey,
    };
    if (plannedInterventionTime != null) m['planned_intervention_time'] = plannedInterventionTime;
    return m;
  }
}

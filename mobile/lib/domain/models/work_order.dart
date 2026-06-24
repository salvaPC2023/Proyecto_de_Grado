import 'ot_step.dart';
import 'technical_location.dart';

enum WorkOrderStatus { released, notified }

class WorkOrder {
  const WorkOrder({
    required this.id,
    required this.orderType,
    required this.technicalLocation,
    required this.assignedTechnicianId,
    required this.priority,
    required this.plannedStart,
    required this.plannedEnd,
    required this.status,
    required this.shiftNumber,
    this.steps = const [],
    this.createdById,
    this.plannerGroup,
    this.activityClass,
    this.installationState,
    this.notifFinal = false,
    this.sinTtbjoReal = false,
    this.createdAt,
  });

  final String id;
  final String orderType;
  final TechnicalLocation technicalLocation;
  final String assignedTechnicianId;
  final int priority;
  final DateTime plannedStart;
  final DateTime plannedEnd;
  final WorkOrderStatus status;
  final int shiftNumber;
  final List<OTStep> steps;
  final String? createdById;
  final String? plannerGroup;
  final String? activityClass;
  final String? installationState;
  final bool notifFinal;
  final bool sinTtbjoReal;
  final DateTime? createdAt;

  factory WorkOrder.fromJson(Map<String, dynamic> json) => WorkOrder(
        id: json['id'] as String,
        orderType: json['order_type'] as String,
        technicalLocation: TechnicalLocation.fromJson(json['technical_location'] as Map<String, dynamic>),
        assignedTechnicianId: json['assigned_technician_id'] as String,
        priority: json['priority'] as int,
        plannedStart: DateTime.parse(json['planned_start'] as String),
        plannedEnd: DateTime.parse(json['planned_end'] as String),
        status: WorkOrderStatus.values.byName(json['status'] as String),
        shiftNumber: json['shift_number'] as int,
        steps: (json['steps'] as List<dynamic>?)
                ?.map((e) => OTStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdById: json['created_by_id'] as String?,
        plannerGroup: json['planner_group'] as String?,
        activityClass: json['activity_class'] as String?,
        installationState: json['installation_state'] as String?,
        notifFinal: json['notif_final'] as bool? ?? false,
        sinTtbjoReal: json['sin_ttbjo_real'] as bool? ?? false,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );
}

class TechnicianWorkload {
  const TechnicianWorkload({
    required this.technicianId,
    required this.technicianName,
    required this.otCount,
    required this.shiftNumber,
  });

  final String technicianId;
  final String technicianName;
  final int otCount;
  final int shiftNumber;

  factory TechnicianWorkload.fromJson(Map<String, dynamic> json) =>
      TechnicianWorkload(
        technicianId: json['technician_id'] as String,
        technicianName: json['technician_name'] as String,
        otCount: json['ot_count'] as int,
        shiftNumber: json['shift_number'] as int,
      );
}

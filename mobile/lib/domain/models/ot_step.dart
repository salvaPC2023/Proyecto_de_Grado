import 'step_closure.dart';

enum ControlKey { PMNN, PM01 }

class OTStep {
  const OTStep({
    required this.id,
    required this.workOrderId,
    required this.position,
    required this.description,
    required this.controlKey,
    required this.isFixed,
    this.plannedInterventionTime,
    this.closure,
  });

  final String id;
  final String workOrderId;
  final int position;
  final String description;
  final ControlKey controlKey;
  final bool isFixed;
  final double? plannedInterventionTime;
  final StepClosure? closure;

  bool get hasClosuse => closure != null;

  factory OTStep.fromJson(Map<String, dynamic> json) => OTStep(
        id: json['id'] as String,
        workOrderId: json['work_order_id'] as String? ?? '',
        position: json['position'] as int,
        description: json['description'] as String,
        controlKey: json['control_key'] == 'PM01' ? ControlKey.PM01 : ControlKey.PMNN,
        isFixed: json['is_fixed'] as bool? ?? false,
        plannedInterventionTime: (json['planned_intervention_time'] as num?)?.toDouble(),
        closure: json['closure'] != null
            ? StepClosure.fromJson(json['closure'] as Map<String, dynamic>)
            : null,
      );
}

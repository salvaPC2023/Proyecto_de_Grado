enum DeviationKey { pm01Executed, pm01NotExecuted }

enum SyncStatus { pending, synced, failed }

class StepClosure {
  const StepClosure({
    required this.id,
    required this.actualDuration,
    required this.deviationKey,
    required this.workDescription,
    required this.safetyQuestionResponse,
    required this.submittedAt,
  });

  final String id;
  final double actualDuration;
  final DeviationKey deviationKey;
  final String workDescription;
  final bool safetyQuestionResponse;
  final DateTime submittedAt;

  factory StepClosure.fromJson(Map<String, dynamic> json) => StepClosure(
        id: json['id'] as String,
        actualDuration: (json['actual_duration'] as num).toDouble(),
        deviationKey: json['deviation_key'] == 'PM01 Executed'
            ? DeviationKey.pm01Executed
            : DeviationKey.pm01NotExecuted,
        workDescription: json['work_description'] as String,
        safetyQuestionResponse: json['safety_question_response'] as bool,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
      );
}

class PendingClosure {
  const PendingClosure({
    required this.id,
    required this.stepId,
    required this.otId,
    required this.actualDuration,
    required this.deviationKey,
    required this.workDescription,
    required this.safetyQuestionResponse,
    required this.submittedAt,
    required this.syncStatus,
    this.errorMessage,
  });

  final int id;
  final String stepId;
  final String otId;
  final double actualDuration;
  final String deviationKey;
  final String workDescription;
  final bool safetyQuestionResponse;
  final DateTime submittedAt;
  final SyncStatus syncStatus;
  final String? errorMessage;
}

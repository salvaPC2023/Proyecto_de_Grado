class RegisterClosureRequest {
  const RegisterClosureRequest({
    required this.actualDuration,
    required this.deviationKey,
    required this.workDescription,
    required this.safetyQuestionResponse,
  });

  final double actualDuration;
  final String deviationKey;
  final String workDescription;
  final bool safetyQuestionResponse;

  Map<String, dynamic> toJson() => {
        'actual_duration': actualDuration,
        'deviation_key': deviationKey,
        'work_description': workDescription,
        'safety_question_response': safetyQuestionResponse,
      };
}

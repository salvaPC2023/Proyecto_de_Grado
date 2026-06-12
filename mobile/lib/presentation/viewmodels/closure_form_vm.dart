import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/local/database.dart';
import '../../data/remote/dtos/closure_dto.dart';

class ClosureFormState {
  const ClosureFormState({
    this.actualDuration = '',
    this.deviationKey = '',
    this.workDescription = '',
    this.safetyQuestionResponse,
    this.isSubmitting = false,
    this.result,
    this.validationErrors = const {},
  });

  final String actualDuration;
  final String deviationKey;
  final String workDescription;
  final bool? safetyQuestionResponse;
  final bool isSubmitting;
  final ClosureResult? result;
  final Map<String, String> validationErrors;

  ClosureFormState copyWith({
    String? actualDuration,
    String? deviationKey,
    String? workDescription,
    bool? safetyQuestionResponse,
    bool? isSubmitting,
    ClosureResult? result,
    Map<String, String>? validationErrors,
  }) =>
      ClosureFormState(
        actualDuration: actualDuration ?? this.actualDuration,
        deviationKey: deviationKey ?? this.deviationKey,
        workDescription: workDescription ?? this.workDescription,
        safetyQuestionResponse: safetyQuestionResponse ?? this.safetyQuestionResponse,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        result: result ?? this.result,
        validationErrors: validationErrors ?? this.validationErrors,
      );
}

class ClosureResult {
  const ClosureResult({required this.isQueued});
  final bool isQueued;
}

class ClosureFormNotifier extends Notifier<ClosureFormState> {
  @override
  ClosureFormState build() => const ClosureFormState();

  void updateActualDuration(String v) =>
      state = state.copyWith(actualDuration: v, validationErrors: {});

  void updateDeviationKey(String v) =>
      state = state.copyWith(deviationKey: v, validationErrors: {});

  void updateWorkDescription(String v) =>
      state = state.copyWith(workDescription: v, validationErrors: {});

  void updateSafetyResponse(bool v) =>
      state = state.copyWith(safetyQuestionResponse: v, validationErrors: {});

  Future<void> submit(String otId, String stepId) async {
    final errors = <String, String>{};
    final duration = double.tryParse(state.actualDuration);
    if (duration == null || duration <= 0) errors['actualDuration'] = 'Ingrese un tiempo válido';
    if (state.deviationKey.isEmpty) errors['deviationKey'] = 'Seleccione una desviación';
    if (state.workDescription.trim().isEmpty) errors['workDescription'] = 'Describa el trabajo';
    if (state.safetyQuestionResponse == null) {
      errors['safetyQuestionResponse'] = 'Responda la pregunta de seguridad';
    }
    if (errors.isNotEmpty) {
      state = state.copyWith(validationErrors: errors);
      return;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final request = RegisterClosureRequest(
        actualDuration: duration!,
        deviationKey: state.deviationKey,
        workDescription: state.workDescription.trim(),
        safetyQuestionResponse: state.safetyQuestionResponse!,
      );
      await ref.read(workOrderRepositoryProvider).registerClosure(
            otId: otId,
            stepId: stepId,
            request: request,
          );
      state = state.copyWith(isSubmitting: false, result: const ClosureResult(isQueued: false));
    } catch (_) {
      try {
        await ref.read(syncServiceProvider).insertPending(
          PendingClosuresCompanion.insert(
            stepId: stepId,
            otId: otId,
            actualDuration: double.parse(state.actualDuration),
            deviationKey: state.deviationKey,
            workDescription: state.workDescription.trim(),
            safetyQuestionResponse: state.safetyQuestionResponse! ? 1 : 0,
            submittedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        state = state.copyWith(isSubmitting: false, result: const ClosureResult(isQueued: true));
      } catch (e2) {
        state = state.copyWith(
          isSubmitting: false,
          validationErrors: {'submit': e2.toString()},
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../core/providers.dart';
import '../../../domain/models/ot_step.dart';
import '../../../domain/models/step_closure.dart';
import '../../../domain/models/user.dart';
import '../../../domain/models/work_order.dart';

class OtDetailScreen extends ConsumerWidget {
  const OtDetailScreen({super.key, required this.otId});
  final String otId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workOrderDetailProvider(otId));
    final authSession = ref.watch(authNotifierProvider).valueOrNull;
    final isTechnician = authSession?.user.role == Role.technician;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle OT')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ot) => _OtDetailBody(ot: ot, isTechnician: isTechnician, otId: otId),
      ),
    );
  }
}

class _OtDetailBody extends ConsumerWidget {
  const _OtDetailBody({
    required this.ot,
    required this.isTechnician,
    required this.otId,
  });
  final WorkOrder ot;
  final bool isTechnician;
  final String otId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedState = ref.watch(failedClosuresForOtProvider(otId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Failed sync recovery section
        if (isTechnician)
          failedState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (failed) => failed.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...failed.map(
                        (c) => Card(
                          color: Colors.red[50],
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Error al sincronizar cierre',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.errorMessage ?? 'Error desconocido',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(syncServiceProvider)
                                          .retryFailed(c.id);
                                      ref.invalidate(
                                          failedClosuresForOtProvider(otId));
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reintentar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        // OT header info
        _InfoCard(ot: ot),
        const SizedBox(height: 16),
        Text('Pasos de mantenimiento',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...ot.steps.map(
          (step) => _StepCard(
            step: step,
            isTechnician: isTechnician,
            onRegisterClosure: () => context.push(
                '/technician/ots/$otId/steps/${step.id}/closure'),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.ot});
  final WorkOrder ot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ot.orderType,
                    style: Theme.of(context).textTheme.titleMedium),
                Chip(
                  label: Text(
                      ot.status == WorkOrderStatus.notified
                          ? 'Notificada'
                          : 'Liberada',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: ot.status == WorkOrderStatus.notified
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _LabelValue(label: 'Ubicación', value: ot.technicalLocation.fullLabel),
            _LabelValue(label: 'Prioridad', value: 'P${ot.priority}'),
            _LabelValue(
              label: 'Inicio planificado',
              value: ot.plannedStart.toLocal().toString().substring(0, 16),
            ),
            _LabelValue(
              label: 'Fin planificado',
              value: ot.plannedEnd.toLocal().toString().substring(0, 16),
            ),
            _LabelValue(label: 'Turno', value: 'Turno ${ot.shiftNumber}'),
          ],
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.isTechnician,
    required this.onRegisterClosure,
  });
  final OTStep step;
  final bool isTechnician;
  final VoidCallback onRegisterClosure;

  @override
  Widget build(BuildContext context) {
    final isPm01 = step.controlKey == ControlKey.PM01;
    final hasClosure = step.closure != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: step.isFixed ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(step.controlKey.name.toUpperCase(),
                      style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text('Paso ${step.position}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(step.description),
            if (step.plannedInterventionTime != null)
              Text('Tiempo planificado: ${step.plannedInterventionTime}h',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (hasClosure) ...[
              const Divider(),
              const Text('Cierre registrado',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
              if (!step.isFixed) ...[
                const SizedBox(height: 4),
                Text('Duración real: ${step.closure!.actualDuration}h'),
                Text('Desviación: ${step.closure!.deviationKey == DeviationKey.pm01Executed ? "PM01 Ejecutado" : "PM01 No ejecutado"}'),
                const SizedBox(height: 4),
                const Text('Descripción del trabajo:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(step.closure!.workDescription),
                const SizedBox(height: 4),
                Text(
                  '¿Equipo con riesgo? ${step.closure!.safetyQuestionResponse ? "Sí" : "No"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ] else if (isPm01 && isTechnician) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRegisterClosure,
                  child: const Text('Registrar cierre'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

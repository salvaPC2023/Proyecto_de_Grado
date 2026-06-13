import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../widgets/standardization_panel.dart';

class ClosureFormScreen extends ConsumerStatefulWidget {
  const ClosureFormScreen({super.key, required this.otId, required this.stepId});
  final String otId;
  final String stepId;

  @override
  ConsumerState<ClosureFormScreen> createState() => _ClosureFormScreenState();
}

class _ClosureFormScreenState extends ConsumerState<ClosureFormScreen> {
  final _workDescController = TextEditingController();

  @override
  void dispose() {
    _workDescController.dispose();
    super.dispose();
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((c) => c != ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(closureFormProvider);
    final stdState = ref.watch(standardizationNotifierProvider);

    ref.listen(closureFormProvider, (_, next) {
      if (next.result != null) {
        final msg = next.result!.isQueued
            ? 'En cola — se enviará al reconectar'
            : 'Registrado exitosamente';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        if (!next.result!.isQueued) {
          ref.invalidate(workOrderDetailProvider(widget.otId));
        }
        context.pop();
      }
    });

    ref.listen(standardizationNotifierProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => ref
                  .read(standardizationNotifierProvider.notifier)
                  .retry(_workDescController.text),
            ),
          ),
        );
      }
    });

    final workDescText = _workDescController.text;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar cierre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Actual duration
          TextField(
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            decoration: InputDecoration(
              labelText: 'Duración real (horas)',
              border: const OutlineInputBorder(),
              errorText: state.validationErrors['actualDuration'],
            ),
            onChanged: (v) => ref
                .read(closureFormProvider.notifier)
                .updateActualDuration(v),
            enabled: !state.isSubmitting,
          ),
          const SizedBox(height: 16),

          // Deviation key dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Desviación',
              border: const OutlineInputBorder(),
              errorText: state.validationErrors['deviationKey'],
            ),
            value: state.deviationKey.isEmpty ? null : state.deviationKey,
            items: AppConstants.deviationKeys
                .map(
                  (kv) => DropdownMenuItem(
                    value: kv.$1,
                    child: Text(kv.$2),
                  ),
                )
                .toList(),
            onChanged: state.isSubmitting
                ? null
                : (v) => ref
                    .read(closureFormProvider.notifier)
                    .updateDeviationKey(v ?? ''),
          ),
          const SizedBox(height: 16),

          // Work description
          TextField(
            controller: _workDescController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: 'Descripción del trabajo',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              errorText: state.validationErrors['workDescription'],
            ),
            onChanged: (v) {
              ref.read(closureFormProvider.notifier).updateWorkDescription(v);
              setState(() {});
            },
            enabled: !state.isSubmitting,
          ),
          const SizedBox(height: 8),

          // Standardize button — only shown when online and field is non-empty
          FutureBuilder<bool>(
            future: _isOnline(),
            builder: (context, snapshot) {
              final online = snapshot.data ?? false;
              final canStandardize = online && workDescText.trim().isNotEmpty;
              if (!online) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: canStandardize && !stdState.isLoading
                      ? () => ref
                          .read(standardizationNotifierProvider.notifier)
                          .standardize(_workDescController.text)
                      : null,
                  icon: stdState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Estandarizar descripción'),
                ),
              );
            },
          ),

          // Standardization panel — shown when result is available
          if (stdState is AsyncData<String?> && stdState.value != null)
            StandardizationPanel(
              initialText: stdState.value!,
              onConfirm: (confirmed) {
                _workDescController.text = confirmed;
                ref
                    .read(closureFormProvider.notifier)
                    .updateWorkDescription(confirmed);
                ref.read(standardizationNotifierProvider.notifier).reset();
                setState(() {});
              },
              onKeepOriginal: () {
                ref.read(standardizationNotifierProvider.notifier).reset();
              },
            ),

          const SizedBox(height: 16),

          // Safety question
          Text('¿El equipo presenta riesgo?',
              style: Theme.of(context).textTheme.bodyLarge),
          if (state.validationErrors['safetyQuestionResponse'] != null)
            Text(state.validationErrors['safetyQuestionResponse']!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Sí')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: state.safetyQuestionResponse != null
                ? {state.safetyQuestionResponse!}
                : {},
            emptySelectionAllowed: true,
            onSelectionChanged: state.isSubmitting
                ? null
                : (s) {
                    if (s.isNotEmpty) {
                      ref
                          .read(closureFormProvider.notifier)
                          .updateSafetyResponse(s.first);
                    }
                  },
          ),
          const SizedBox(height: 24),

          if (state.validationErrors['submit'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(state.validationErrors['submit']!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => ref
                      .read(closureFormProvider.notifier)
                      .submit(widget.otId, widget.stepId),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar cierre'),
            ),
          ),
        ],
      ),
    );
  }
}

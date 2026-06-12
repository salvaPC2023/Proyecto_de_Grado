import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../core/providers.dart';
import '../../../data/remote/dtos/work_order_dto.dart';
import '../../../domain/models/technical_location.dart';
import '../../../domain/models/user.dart';

// ─── Local Providers ─────────────────────────────────────────────────────────

final _techLocationsProvider = FutureProvider<List<TechnicalLocation>>((ref) =>
    ref.read(techLocRepositoryProvider).listLocations());

final _technicianListForFormProvider = FutureProvider<List<User>>(
  (ref) => ref.read(userRepositoryProvider).listTechnicians(),
);

// ─── Screen ──────────────────────────────────────────────────────────────────

class CreateWorkOrderScreen extends ConsumerStatefulWidget {
  const CreateWorkOrderScreen({super.key});

  @override
  ConsumerState<CreateWorkOrderScreen> createState() =>
      _CreateWorkOrderScreenState();
}

class _CreateWorkOrderScreenState extends ConsumerState<CreateWorkOrderScreen> {
  // Form state
  String? _orderType;
  String? _plannerGroup;
  String? _installationState;
  String? _assignedTechnicianId;
  TechnicalLocation? _technicalLocation;
  int _priority = 3;
  DateTime? _plannedStart;
  DateTime? _plannedEnd;
  final List<_StepEntry> _customSteps = [];
  bool _loading = false;
  String? _error;

  static const _orderTypes = ['OE01', 'OE02', 'OE03', 'OE04'];
  static const _plannerGroups = [
    ('mechanical', 'Mecánico'),
    ('electrical', 'Eléctrico'),
    ('electronic', 'Electrónico'),
  ];
  static const _installationStates = [
    ('running', 'En operación'),
    ('stopped', 'Detenido'),
  ];
  static const _fixedStepDescriptions = [
    'PM01 - Inspección inicial y verificación de seguridad',
    'PM02 - Ejecución de mantenimiento preventivo',
    'PM03 - Pruebas de funcionamiento y cierre',
  ];

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_plannedStart ?? now) : (_plannedEnd ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _plannedStart = picked;
        } else {
          _plannedEnd = picked;
        }
      });
    }
  }

  bool _hasPm01Step() =>
      _customSteps.any((s) => s.controlKey == 'PM01');

  Future<void> _submit() async {
    if (_orderType == null ||
        _technicalLocation == null ||
        _assignedTechnicianId == null ||
        _plannerGroup == null ||
        _installationState == null ||
        _plannedStart == null ||
        _plannedEnd == null) {
      setState(() => _error = 'Complete todos los campos requeridos');
      return;
    }
    if (!_hasPm01Step()) {
      setState(() =>
          _error = 'Agregue al menos un paso PM01 con tiempo planificado');
      return;
    }
    final invalidPm01 = _customSteps.any((s) =>
        s.controlKey == 'PM01' &&
        (s.plannedTime == null ||
            double.tryParse(s.plannedTime ?? '') == null));
    if (invalidPm01) {
      setState(() => _error = 'Los pasos PM01 requieren tiempo planificado válido');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final request = CreateWorkOrderRequest(
        orderType: _orderType!,
        technicalLocationId: _technicalLocation!.id,
        assignedTechnicianId: _assignedTechnicianId!,
        plannerGroup: _plannerGroup!,
        installationState: _installationState!,
        plannedStart: _plannedStart!,
        plannedEnd: _plannedEnd!,
        priority: _priority,
        steps: _customSteps.map((s) => CreateStepRequest(
              description: s.description,
              controlKey: s.controlKey,
              plannedInterventionTime: double.tryParse(s.plannedTime ?? ''),
            )).toList(),
      );
      await ref.read(supervisorDashboardProvider.notifier).createWorkOrder(request);
      if (context.mounted) context.pop();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().contains('400')
            ? 'Se requiere al menos un paso PM01'
            : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final techLocsState = ref.watch(_techLocationsProvider);
    final techsState = ref.watch(_technicianListForFormProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Orden de Trabajo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order type
          Text('Tipo de orden', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _orderTypes.map((type) => ChoiceChip(
              label: Text(type),
              selected: _orderType == type,
              onSelected: (_) => setState(() => _orderType = type),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // Technical location picker
          Text('Ubicación técnica', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          techLocsState.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error cargando ubicaciones: $e',
                style: const TextStyle(color: Colors.red)),
            data: (locs) => _TechLocationPicker(
              locations: locs,
              selected: _technicalLocation,
              onSelected: (loc) => setState(() => _technicalLocation = loc),
            ),
          ),
          const SizedBox(height: 16),

          // Assigned technician
          Text('Técnico asignado', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          techsState.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error cargando técnicos: $e',
                style: const TextStyle(color: Colors.red)),
            data: (techs) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: _assignedTechnicianId,
              hint: const Text('Seleccionar técnico'),
              items: techs.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.displayName),
                  )).toList(),
              onChanged: (v) => setState(() => _assignedTechnicianId = v),
            ),
          ),
          const SizedBox(height: 16),

          // Planner group
          Text('Grupo planificador', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            value: _plannerGroup,
            hint: const Text('Seleccionar grupo'),
            items: _plannerGroups.map((g) => DropdownMenuItem(
                  value: g.$1,
                  child: Text(g.$2),
                )).toList(),
            onChanged: (v) => setState(() => _plannerGroup = v),
          ),
          const SizedBox(height: 16),

          // Installation state
          Text('Estado de instalación', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            value: _installationState,
            hint: const Text('Seleccionar estado'),
            items: _installationStates.map((s) => DropdownMenuItem(
                  value: s.$1,
                  child: Text(s.$2),
                )).toList(),
            onChanged: (v) => setState(() => _installationState = v),
          ),
          const SizedBox(height: 16),

          // Dates
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inicio planificado',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_plannedStart != null
                        ? _plannedStart!.toLocal().toString().substring(0, 10)
                        : 'Seleccionar'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fin planificado',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_plannedEnd != null
                        ? _plannedEnd!.toLocal().toString().substring(0, 10)
                        : 'Seleccionar'),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Priority
          Text('Prioridad', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Urgente')),
              ButtonSegment(value: 2, label: Text('Alta')),
              ButtonSegment(value: 3, label: Text('Normal')),
              ButtonSegment(value: 4, label: Text('Baja')),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 24),

          // Steps
          Text('Pasos de mantenimiento',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Fixed PMNN steps (read-only)
          ..._fixedStepDescriptions.asMap().entries.map((e) => Card(
                color: Colors.blue[50],
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Chip(label: Text('PMNN')),
                  title: Text('Paso ${e.key + 1}'),
                  subtitle: Text(e.value),
                ),
              )),
          // Custom steps
          ..._customSteps.asMap().entries.map((e) => _StepEntryCard(
                entry: e.value,
                position: e.key + 4,
                onRemove: () =>
                    setState(() => _customSteps.removeAt(e.key)),
              )),
          // Add step button
          TextButton.icon(
            onPressed: () => setState(() => _customSteps.add(_StepEntry())),
            icon: const Icon(Icons.add),
            label: const Text('Agregar paso'),
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear OT'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Technical Location Picker ───────────────────────────────────────────────

class _TechLocationPicker extends StatefulWidget {
  const _TechLocationPicker({
    required this.locations,
    required this.selected,
    required this.onSelected,
  });
  final List<TechnicalLocation> locations;
  final TechnicalLocation? selected;
  final void Function(TechnicalLocation) onSelected;

  @override
  State<_TechLocationPicker> createState() => _TechLocationPickerState();
}

class _TechLocationPickerState extends State<_TechLocationPicker> {
  String? _sector;
  String? _subsector;
  String? _system;

  List<String> get _sectors =>
      widget.locations.map((l) => l.sector).toSet().toList()..sort();

  List<String> get _subsectors => widget.locations
      .where((l) => l.sector == _sector)
      .map((l) => l.subsector)
      .toSet()
      .toList()
        ..sort();

  List<String> get _systems => widget.locations
      .where((l) => l.sector == _sector && l.subsector == _subsector)
      .map((l) => l.system)
      .toSet()
      .toList()
        ..sort();

  List<TechnicalLocation> get _subsystems => widget.locations
      .where((l) =>
          l.sector == _sector &&
          l.subsector == _subsector &&
          l.system == _system)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected != null)
          Chip(
            label: Text(widget.selected!.fullLabel,
                style: const TextStyle(fontSize: 12)),
            onDeleted: () {
              setState(() {
                _sector = null;
                _subsector = null;
                _system = null;
              });
              widget.onSelected(widget.selected!);
            },
          ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
              labelText: 'Sector', border: OutlineInputBorder()),
          value: _sector,
          items: _sectors
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() {
            _sector = v;
            _subsector = null;
            _system = null;
          }),
        ),
        if (_sector != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
                labelText: 'Subsector', border: OutlineInputBorder()),
            value: _subsector,
            items: _subsectors
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() {
              _subsector = v;
              _system = null;
            }),
          ),
        ],
        if (_subsector != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
                labelText: 'Sistema', border: OutlineInputBorder()),
            value: _system,
            items: _systems
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _system = v),
          ),
        ],
        if (_system != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<TechnicalLocation>(
            decoration: const InputDecoration(
                labelText: 'Subsistema', border: OutlineInputBorder()),
            value: _subsystems.contains(widget.selected) ? widget.selected : null,
            items: _subsystems
                .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(l.subsystem),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) widget.onSelected(v);
            },
          ),
        ],
      ],
    );
  }
}

// ─── Step Entry ───────────────────────────────────────────────────────────────

class _StepEntry {
  String description = '';
  String controlKey = 'PMNN';
  String? plannedTime;
}

class _StepEntryCard extends StatefulWidget {
  const _StepEntryCard({
    required this.entry,
    required this.position,
    required this.onRemove,
  });
  final _StepEntry entry;
  final int position;
  final VoidCallback onRemove;

  @override
  State<_StepEntryCard> createState() => _StepEntryCardState();
}

class _StepEntryCardState extends State<_StepEntryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Paso ${widget.position}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, color: Colors.red)),
              ],
            ),
            // Control key
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'Control Key', border: OutlineInputBorder()),
              value: widget.entry.controlKey,
              items: const [
                DropdownMenuItem(value: 'PMNN', child: Text('PMNN')),
                DropdownMenuItem(value: 'PM01', child: Text('PM01')),
              ],
              onChanged: (v) => setState(() {
                widget.entry.controlKey = v ?? 'PMNN';
                if (v != 'PM01') widget.entry.plannedTime = null;
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Descripción', border: OutlineInputBorder()),
              onChanged: (v) => widget.entry.description = v,
            ),
            if (widget.entry.controlKey == 'PM01') ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Tiempo planificado (horas)',
                    border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => widget.entry.plannedTime = v,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../domain/models/work_order.dart';

class TechnicianWorkloadScreen extends ConsumerWidget {
  const TechnicianWorkloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(technicianWorkloadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Carga de Trabajo')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error al cargar: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(technicianWorkloadProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No tienes técnicos registrados.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(technicianWorkloadProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return _WorkloadTile(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _WorkloadTile extends StatelessWidget {
  const _WorkloadTile({required this.item});
  final TechnicianWorkload item;

  @override
  Widget build(BuildContext context) {
    final hasOts = item.otCount > 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasOts ? Colors.blue : Colors.grey.shade300,
        child: Text(
          '${item.otCount}',
          style: TextStyle(
            color: hasOts ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(item.technicianName),
      subtitle: Text(hasOts ? '${item.otCount} OT(s) este turno' : 'Sin OTs este turno'),
      trailing: hasOts ? const Icon(Icons.chevron_right) : null,
      onTap: hasOts
          ? () => context.push(
                '/supervisor/workload/${item.technicianId}/ots',
                extra: item.technicianName,
              )
          : null,
    );
  }
}

// ── Drill-down: OTs for a specific technician ─────────────────────────────────

class WorkloadOtListScreen extends ConsumerWidget {
  const WorkloadOtListScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  final String technicianId;
  final String technicianName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otsFuture = ref.watch(workloadDrilldownProvider(technicianId));

    return Scaffold(
      appBar: AppBar(title: Text(technicianName)),
      body: otsFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ots) {
          if (ots.isEmpty) {
            return const Center(child: Text('Sin OTs para este turno.'));
          }
          return ListView.builder(
            itemCount: ots.length,
            itemBuilder: (context, index) {
              final ot = ots[index];
              return ListTile(
                leading: Chip(label: Text(ot.orderType)),
                title: Text(ot.technicalLocation.fullLabel),
                subtitle: Text(ot.status.name.toUpperCase()),
                trailing: _statusBadge(ot.status),
                onTap: () =>
                    context.push('/supervisor/ots/${ot.id}'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusBadge(WorkOrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == WorkOrderStatus.notified ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == WorkOrderStatus.notified ? 'Notified' : 'Released',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

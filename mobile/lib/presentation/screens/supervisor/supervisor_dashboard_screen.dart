import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../domain/models/work_order.dart';

class SupervisorDashboardScreen extends ConsumerStatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  ConsumerState<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState
    extends ConsumerState<SupervisorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(supervisorDashboardProvider.notifier).loadShiftList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supervisorDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turno actual'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/supervisor/location-report'),
            tooltip: 'Reporte de ubicaciones',
          ),
          IconButton(
            icon: const Icon(Icons.group_work),
            onPressed: () => context.push('/supervisor/workload'),
            tooltip: 'Carga de trabajo',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.push('/supervisor/technicians'),
            tooltip: 'Técnicos',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Perfil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            tooltip: 'Salir',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/supervisor/create-work-order'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva OT'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              TextButton(
                  onPressed: () =>
                      ref.read(supervisorDashboardProvider.notifier).loadShiftList(),
                  child: const Text('Reintentar')),
            ],
          ),
        ),
        data: (orders) => orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('No hay OTs en este turno'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => context.push('/supervisor/create-work-order'),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear OT'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(supervisorDashboardProvider.notifier).loadShiftList(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _OtCard(
                    ot: orders[i],
                    onTap: () => context.push('/supervisor/ots/${orders[i].id}'),
                  ),
                ),
              ),
      ),
    );
  }
}

class _OtCard extends StatelessWidget {
  const _OtCard({required this.ot, required this.onTap});
  final WorkOrder ot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNotified = ot.status == WorkOrderStatus.notified;
    return Card(
      child: ListTile(
        leading: _PriorityBadge(priority: ot.priority),
        title: Text(ot.technicalLocation.shortLabel),
        subtitle: Text(ot.orderType),
        trailing: Chip(
          label: Text(isNotified ? 'Notificada' : 'Liberada',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: isNotified ? Colors.green : Colors.orange,
          padding: EdgeInsets.zero,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final int priority;

  @override
  Widget build(BuildContext context) {
    final colors = {1: Colors.red, 2: Colors.orange, 3: Colors.blue, 4: Colors.grey};
    return CircleAvatar(
      backgroundColor: colors[priority] ?? Colors.grey,
      radius: 18,
      child: Text('P$priority',
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

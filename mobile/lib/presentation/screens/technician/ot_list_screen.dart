import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../domain/models/work_order.dart';

class _PendingBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingCountProvider).valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Stack(
      alignment: Alignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.cloud_upload),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                color: Colors.red, shape: BoxShape.circle),
            child: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 9)),
          ),
        ),
      ],
    );
  }
}

class OtListScreen extends ConsumerStatefulWidget {
  const OtListScreen({super.key});

  @override
  ConsumerState<OtListScreen> createState() => _OtListScreenState();
}

class _OtListScreenState extends ConsumerState<OtListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(technicianOtListProvider.notifier).loadList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianOtListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis OTs'),
        actions: [
          _PendingBadge(),
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
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              TextButton(
                  onPressed: () =>
                      ref.read(technicianOtListProvider.notifier).loadList(),
                  child: const Text('Reintentar')),
            ],
          ),
        ),
        data: (result) => Column(
          children: [
            if (result.isStale)
              MaterialBanner(
                content: const Text('Datos del caché — sin conexión'),
                leading: const Icon(Icons.wifi_off),
                backgroundColor: Colors.amber[100],
                actions: [
                  TextButton(
                      onPressed: () =>
                          ref.read(technicianOtListProvider.notifier).loadList(),
                      child: const Text('Reintentar'))
                ],
              ),
            Expanded(
              child: result.list.isEmpty
                  ? const Center(child: Text('No tienes OTs asignadas en este turno'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(technicianOtListProvider.notifier).loadList(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: result.list.length,
                        itemBuilder: (_, i) {
                          final ot = result.list[i];
                          return _OtCard(
                            ot: ot,
                            onTap: () => context.push('/technician/ots/${ot.id}'),
                          );
                        },
                      ),
                    ),
            ),
          ],
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
        leading: CircleAvatar(
          backgroundColor: isNotified ? Colors.green : Colors.orange,
          child: Text('P${ot.priority}',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
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

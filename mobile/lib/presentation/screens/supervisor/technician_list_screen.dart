import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di.dart';
import '../../../domain/models/user.dart';

class TechnicianListScreen extends ConsumerWidget {
  const TechnicianListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(technicianListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Técnicos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Mi perfil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            tooltip: 'Salir',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/supervisor/create-technician'),
        child: const Icon(Icons.person_add),
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
                      ref.read(technicianListNotifierProvider.notifier).loadList(),
                  child: const Text('Reintentar')),
            ],
          ),
        ),
        data: (technicians) => technicians.isEmpty
            ? const Center(child: Text('No hay técnicos registrados'))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(technicianListNotifierProvider.notifier).loadList(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: technicians.length,
                  itemBuilder: (ctx, i) {
                    final t = technicians[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(t.displayName),
                        subtitle: Text('@${t.username}'),
                        trailing: _StatusChip(status: t.status),
                        onTap: () =>
                            context.push('/supervisor/technicians/${t.id}'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == UserStatus.active;
    return Chip(
      label: Text(isActive ? 'Activo' : 'Desactivado',
          style: TextStyle(color: isActive ? Colors.white : null, fontSize: 12)),
      backgroundColor: isActive ? Colors.green : Colors.grey[300],
      padding: EdgeInsets.zero,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di.dart';

class LocationReportScreen extends ConsumerWidget {
  const LocationReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte por ubicación')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              TextButton(
                  onPressed: () =>
                      ref.read(locationReportProvider.notifier).loadReport(),
                  child: const Text('Reintentar')),
            ],
          ),
        ),
        data: (entries) => entries.isEmpty
            ? const Center(child: Text('Sin datos'))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(locationReportProvider.notifier).loadReport(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${e.otCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(e.technicalLocation.subsystem),
                        subtitle: Text(e.technicalLocation.fullLabel,
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${e.otCount} OT${e.otCount != 1 ? 's' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

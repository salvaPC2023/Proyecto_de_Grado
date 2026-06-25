import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../domain/models/technical_location.dart';

class LocationReportNotifier extends AutoDisposeAsyncNotifier<List<TechnicalLocationReportEntry>> {
  @override
  Future<List<TechnicalLocationReportEntry>> build() =>
      ref.read(techLocRepositoryProvider).getLocationReport();

  Future<void> loadReport() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(techLocRepositoryProvider).getLocationReport(),
    );
  }
}

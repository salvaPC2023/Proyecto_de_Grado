import '../../domain/models/technical_location.dart';
import '../../domain/repositories/technical_location_repository.dart';
import 'api_client.dart';

class TechnicalLocationRepositoryImpl implements TechnicalLocationRepository {
  TechnicalLocationRepositoryImpl({required this.apiClient});
  final ApiClient apiClient;

  @override
  Future<List<TechnicalLocation>> listLocations() async {
    final res = await apiClient.dio.get('/technical-locations');
    final list = res.data as List<dynamic>;
    return list.map((e) => TechnicalLocation.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TechnicalLocationReportEntry>> getLocationReport() async {
    final res = await apiClient.dio.get('/technical-locations/report');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => TechnicalLocationReportEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

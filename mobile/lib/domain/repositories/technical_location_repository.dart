import '../models/technical_location.dart';

abstract class TechnicalLocationRepository {
  Future<List<TechnicalLocation>> listLocations();
  Future<List<TechnicalLocationReportEntry>> getLocationReport();
}

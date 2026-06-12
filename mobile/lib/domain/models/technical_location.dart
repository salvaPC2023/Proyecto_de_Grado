class TechnicalLocation {
  const TechnicalLocation({
    required this.id,
    required this.sector,
    required this.subsector,
    required this.system,
    required this.subsystem,
  });

  final String id;
  final String sector;
  final String subsector;
  final String system;
  final String subsystem;

  String get fullLabel => '$sector / $subsector / $system / $subsystem';
  String get shortLabel => '$sector / $subsystem';

  factory TechnicalLocation.fromJson(Map<String, dynamic> json) => TechnicalLocation(
        id: json['id'] as String,
        sector: json['sector'] as String,
        subsector: json['subsector'] as String,
        system: json['system'] as String,
        subsystem: json['subsystem'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicalLocation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TechnicalLocationReportEntry {
  const TechnicalLocationReportEntry({
    required this.technicalLocation,
    required this.otCount,
  });

  final TechnicalLocation technicalLocation;
  final int otCount;

  factory TechnicalLocationReportEntry.fromJson(Map<String, dynamic> json) =>
      TechnicalLocationReportEntry(
        technicalLocation: TechnicalLocation.fromJson(json['technical_location'] as Map<String, dynamic>),
        otCount: json['ot_count'] as int,
      );
}

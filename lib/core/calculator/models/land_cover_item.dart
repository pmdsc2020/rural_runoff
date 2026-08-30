// lib/core/calculator/models/land_cover_item.dart

class LandCoverItem {
  final String id;
  final String label;
  final double areaHectares;
  final double runoffCoefficient;

  const LandCoverItem({
    required this.id,
    required this.label,
    required this.areaHectares,
    required this.runoffCoefficient,
  });

  double get areaKm2 => areaHectares / 100.0;

  LandCoverItem copyWith({
    String? id,
    String? label,
    double? areaHectares,
    double? runoffCoefficient,
  }) {
    return LandCoverItem(
      id: id ?? this.id,
      label: label ?? this.label,
      areaHectares: areaHectares ?? this.areaHectares,
      runoffCoefficient: runoffCoefficient ?? this.runoffCoefficient,
    );
  }
}
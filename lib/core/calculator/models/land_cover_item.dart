// lib/core/calculator/models/land_cover_item.dart

/// Recommended rural runoff coefficient (see README "Runoff Coefficients").
class LandCoverPreset {
  final String name;
  final double c;
  final double cMin;
  final double cMax;

  const LandCoverPreset(this.name, this.c, this.cMin, this.cMax);
}

const landCoverPresets = [
  LandCoverPreset('Cultivated Flat Land', 0.35, 0.30, 0.40),
  LandCoverPreset('Cultivated Rolling Land', 0.45, 0.40, 0.50),
  LandCoverPreset('Pasture / Grassland', 0.25, 0.20, 0.35),
  LandCoverPreset('Forest Cover', 0.15, 0.10, 0.25),
  LandCoverPreset('Barren / Rocky', 0.70, 0.60, 0.80),
  LandCoverPreset('Settlement / Village', 0.60, 0.50, 0.70),
];

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
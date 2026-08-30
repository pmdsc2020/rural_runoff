// lib/core/calculator/models/calculation_result.dart

class CalculationResult {
  final double areaKm2;
  final double areaHectares;
  final double flowLengthM;
  final double elevationDropM;
  final double slope;
  final double tcMinutes;
  final double runoffCoefficient;
  final double rainfallIntensityMmHr;
  final double peakDischargeM3s;
  final double peakDischargeLps;
  final bool areaExceedsLimit;
  final List<String> substitutionSteps;

  const CalculationResult({
    required this.areaKm2,
    required this.areaHectares,
    required this.flowLengthM,
    required this.elevationDropM,
    required this.slope,
    required this.tcMinutes,
    required this.runoffCoefficient,
    required this.rainfallIntensityMmHr,
    required this.peakDischargeM3s,
    required this.peakDischargeLps,
    required this.areaExceedsLimit,
    required this.substitutionSteps,
  });
}
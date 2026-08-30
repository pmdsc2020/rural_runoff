// lib/core/calculator/rational_calculator.dart

import 'dart:math' as math;
import 'models/calculation_result.dart';
import 'models/land_cover_item.dart';
import 'models/idf_parameters.dart';

class RationalCalculator {
  static const double maxReliableAreaKm2 = 25.0;

  double computeSlope(double elevationDropM, double flowLengthM) {
    if (flowLengthM <= 0) {
      throw ArgumentError('Flow length must exceed zero');
    }
    if (elevationDropM < 0) {
      throw ArgumentError('Elevation drop cannot be negative');
    }
    return elevationDropM / flowLengthM;
  }

  double computeTimeOfConcentration(double flowLengthM, double slope) {
    if (flowLengthM <= 0) {
      throw ArgumentError('Flow length must exceed zero');
    }
    if (slope <= 0) {
      throw ArgumentError('Slope must exceed zero');
    }
    return 0.01947 * math.pow(flowLengthM, 0.77) * math.pow(slope, -0.385);
  }

  double computeCompositeC(List<LandCoverItem> items) {
    if (items.isEmpty) {
      throw ArgumentError('Provide at least one land cover item');
    }
    double totalWeightedC = 0.0;
    double totalArea = 0.0;

    for (final item in items) {
      if (item.areaHectares < 0) {
        throw ArgumentError('Area cannot be negative');
      }
      if (item.runoffCoefficient < 0 || item.runoffCoefficient > 1.0) {
        throw ArgumentError('Runoff coefficient must fall between 0.0 and 1.0');
      }
      totalWeightedC += item.runoffCoefficient * item.areaHectares;
      totalArea += item.areaHectares;
    }

    if (totalArea <= 0) {
      throw ArgumentError('Total catchment area must exceed zero');
    }

    return totalWeightedC / totalArea;
  }

  CalculationResult calculate({
    required double areaKm2,
    required double flowLengthM,
    required double elevationDropM,
    required double runoffCoefficient,
    IdfParameters? idfParams,
    double? directIntensityMmHr,
  }) {
    if (areaKm2 <= 0) {
      throw ArgumentError('Catchment area must exceed zero');
    }
    if (runoffCoefficient <= 0 || runoffCoefficient > 1.0) {
      throw ArgumentError('Runoff coefficient must fall between 0.0 and 1.0');
    }

    final slope = computeSlope(elevationDropM, flowLengthM);
    final tc = computeTimeOfConcentration(flowLengthM, slope);

    double intensity;
    String intensityStep;

    if (directIntensityMmHr != null) {
      if (directIntensityMmHr <= 0) {
        throw ArgumentError('Rainfall intensity must exceed zero');
      }
      intensity = directIntensityMmHr;
      intensityStep = 'I = $intensity mm/hr (user direct entry)';
    } else if (idfParams != null) {
      intensity = idfParams.calculateIntensity(tc);
      intensityStep =
          'I = (${idfParams.a} * ${idfParams.returnPeriodYears}^${idfParams.m}) / ($tc + ${idfParams.b})^${idfParams.n} = ${intensity.toStringAsFixed(2)} mm/hr';
    } else {
      throw ArgumentError('Supply IDF parameters or direct rainfall intensity');
    }

    final peakDischargeM3s = (runoffCoefficient * intensity * areaKm2) / 3.6;
    final peakDischargeLps = peakDischargeM3s * 1000.0;
    final areaExceedsLimit = areaKm2 > maxReliableAreaKm2;

    final steps = [
      '1. Slope (S) = Drop / Length = $elevationDropM m / $flowLengthM m = ${slope.toStringAsFixed(5)} m/m',
      '2. Time of Concentration (tc) = 0.01947 * ($flowLengthM)^0.77 * (${slope.toStringAsFixed(5)})^-0.385 = ${tc.toStringAsFixed(2)} minutes',
      '3. Rainfall Intensity (I): $intensityStep',
      '4. Peak Runoff (Q) = (C * I * A) / 3.6',
      '   Q = (${runoffCoefficient.toStringAsFixed(3)} * ${intensity.toStringAsFixed(2)} * ${areaKm2.toStringAsFixed(3)}) / 3.6',
      '   Q = ${peakDischargeM3s.toStringAsFixed(3)} m3/s',
      '5. In litres per second: Q = ${peakDischargeM3s.toStringAsFixed(3)} * 1000 = ${peakDischargeLps.toStringAsFixed(1)} L/s',
    ];

    return CalculationResult(
      areaKm2: areaKm2,
      areaHectares: areaKm2 * 100.0,
      flowLengthM: flowLengthM,
      elevationDropM: elevationDropM,
      slope: slope,
      tcMinutes: tc,
      runoffCoefficient: runoffCoefficient,
      rainfallIntensityMmHr: intensity,
      peakDischargeM3s: peakDischargeM3s,
      peakDischargeLps: peakDischargeLps,
      areaExceedsLimit: areaExceedsLimit,
      substitutionSteps: steps,
    );
  }
}
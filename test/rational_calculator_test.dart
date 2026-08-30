// test/rational_calculator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:rural_runoff/core/calculator/rational_calculator.dart';
import 'package:rural_runoff/core/calculator/models/idf_parameters.dart';
import 'package:rural_runoff/core/calculator/models/land_cover_item.dart';

void main() {
  late RationalCalculator calculator;

  setUp(() {
    calculator = RationalCalculator();
  });

  group('Kirpich Time of Concentration Tests', () {
    test('Calculates tc for standard rural stream slope', () {
      // L = 1200 m, drop = 15 m -> slope = 0.0125 m/m
      final slope = calculator.computeSlope(15.0, 1200.0);
      final tc = calculator.computeTimeOfConcentration(1200.0, slope);

      // Expected tc approx 24.96 minutes
      expect(slope, closeTo(0.0125, 0.0001));
      expect(tc, closeTo(24.96, 0.5));
    });

    test('Throws exception on zero slope or drop', () {
      expect(
        () => calculator.computeTimeOfConcentration(1000.0, 0.0),
        throwsArgumentError,
      );
    });

    test('Throws exception on zero flow length', () {
      expect(
        () => calculator.computeSlope(10.0, 0.0),
        throwsArgumentError,
      );
    });
  });

  group('Composite Runoff Coefficient C Tests', () {
    test('Calculates area-weighted C correctly', () {
      final items = [
        const LandCoverItem(
          id: '1',
          label: 'Cultivated Flat',
          areaHectares: 40.0,
          runoffCoefficient: 0.35,
        ),
        const LandCoverItem(
          id: '2',
          label: 'Forest',
          areaHectares: 60.0,
          runoffCoefficient: 0.15,
        ),
      ];

      // Weighted C = (40*0.35 + 60*0.15) / 100 = (14 + 9) / 100 = 0.23
      final compositeC = calculator.computeCompositeC(items);
      expect(compositeC, closeTo(0.23, 0.001));
    });

    test('Throws exception for empty list', () {
      expect(
        () => calculator.computeCompositeC([]),
        throwsArgumentError,
      );
    });
  });

  group('Rational Method Peak Discharge Tests', () {
    test('Calculates standard textbook runoff scenario with direct intensity', () {
      // Area = 2.0 km2, C = 0.40, I = 50 mm/hr
      // Q = 0.40 * 50 * 2.0 / 3.6 = 11.111 m3/s
      final result = calculator.calculate(
        areaKm2: 2.0,
        flowLengthM: 1500.0,
        elevationDropM: 20.0,
        runoffCoefficient: 0.40,
        directIntensityMmHr: 50.0,
      );

      expect(result.peakDischargeM3s, closeTo(11.111, 0.01));
      expect(result.peakDischargeLps, closeTo(11111.11, 10.0));
      expect(result.areaExceedsLimit, isFalse);
    });

    test('Calculates runoff with IDF equation parameters', () {
      const idf = IdfParameters(
        a: 1000.0,
        b: 10.0,
        m: 0.2,
        n: 0.7,
        returnPeriodYears: 25.0,
      );

      final result = calculator.calculate(
        areaKm2: 1.5,
        flowLengthM: 800.0,
        elevationDropM: 10.0,
        runoffCoefficient: 0.30,
        idfParams: idf,
      );

      expect(result.peakDischargeM3s, greaterThan(0.0));
      expect(result.tcMinutes, greaterThan(0.0));
      expect(result.substitutionSteps.length, 7);
    });

    test('Flags warning when area exceeds 25 km2', () {
      final result = calculator.calculate(
        areaKm2: 30.0,
        flowLengthM: 5000.0,
        elevationDropM: 50.0,
        runoffCoefficient: 0.45,
        directIntensityMmHr: 40.0,
      );

      expect(result.areaExceedsLimit, isTrue);
    });
  });
}
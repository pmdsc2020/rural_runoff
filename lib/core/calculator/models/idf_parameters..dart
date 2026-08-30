import 'dart:math' as math;

class IdfParameters {
  final double a;
  final double b;
  final double m;
  final double n;
  final double returnPeriodYears;

  const IdfParameters({
    required this.a,
    required this.b,
    required this.m,
    required this.n,
    required this.returnPeriodYears,
  });

  double calculateIntensity(double tcMinutes) {
    if (tcMinutes <= 0) {
      throw ArgumentError('Time of concentration must exceed zero');
    }
    final numerator = a * math.pow(returnPeriodYears, m).toDouble();
    final denominator = math.pow(tcMinutes + b, n).toDouble();
    return numerator / denominator;
  }
}
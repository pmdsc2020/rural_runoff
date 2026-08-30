// lib/features/catchment/models/catchment_project.dart

class CatchmentProject {
  final int? id;
  final String name;
  final double areaKm2;
  final double flowLengthM;
  final double elevationDropM;
  final double runoffCoefficient;
  final double? directIntensityMmHr;
  final double? idfA;
  final double? idfB;
  final double? idfM;
  final double? idfN;
  final double? returnPeriodYears;
  final double? latitude;
  final double? longitude;
  final double peakDischargeM3s;
  final double tcMinutes;
  final String createdAt;

  CatchmentProject({
    this.id,
    required this.name,
    required this.areaKm2,
    required this.flowLengthM,
    required this.elevationDropM,
    required this.runoffCoefficient,
    this.directIntensityMmHr,
    this.idfA,
    this.idfB,
    this.idfM,
    this.idfN,
    this.returnPeriodYears,
    this.latitude,
    this.longitude,
    required this.peakDischargeM3s,
    required this.tcMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area_km2': areaKm2,
      'flow_length_m': flowLengthM,
      'elevation_drop_m': elevationDropM,
      'runoff_c': runoffCoefficient,
      'direct_intensity': directIntensityMmHr,
      'idf_a': idfA,
      'idf_b': idfB,
      'idf_m': idfM,
      'idf_n': idfN,
      'return_period': returnPeriodYears,
      'latitude': latitude,
      'longitude': longitude,
      'peak_q_m3s': peakDischargeM3s,
      'tc_min': tcMinutes,
      'created_at': createdAt,
    };
  }

  factory CatchmentProject.fromMap(Map<String, dynamic> map) {
    return CatchmentProject(
      id: map['id'] as int?,
      name: map['name'] as String,
      areaKm2: map['area_km2'] as double,
      flowLengthM: map['flow_length_m'] as double,
      elevationDropM: map['elevation_drop_m'] as double,
      runoffCoefficient: map['runoff_c'] as double,
      directIntensityMmHr: map['direct_intensity'] as double?,
      idfA: map['idf_a'] as double?,
      idfB: map['idf_b'] as double?,
      idfM: map['idf_m'] as double?,
      idfN: map['idf_n'] as double?,
      returnPeriodYears: map['return_period'] as double?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      peakDischargeM3s: map['peak_q_m3s'] as double,
      tcMinutes: map['tc_min'] as double,
      createdAt: map['created_at'] as String,
    );
  }
}
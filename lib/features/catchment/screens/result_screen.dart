// lib/features/catchment/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/calculator/models/calculation_result.dart';
import '../../../core/calculator/models/idf_parameters.dart';
import '../../../core/pdf/report_generator.dart';
import '../models/catchment_project.dart';
import '../providers/catchment_providers.dart';

class ResultScreen extends ConsumerWidget {
  final String projectName;
  final CalculationResult result;
  final double? directIntensity;
  final IdfParameters? idfParams;
  final double? latitude;
  final double? longitude;

  const ResultScreen({
    super.key,
    required this.projectName,
    required this.result,
    this.directIntensity,
    this.idfParams,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runoff Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final project = CatchmentProject(
                name: projectName,
                areaKm2: result.areaKm2,
                flowLengthM: result.flowLengthM,
                elevationDropM: result.elevationDropM,
                runoffCoefficient: result.runoffCoefficient,
                directIntensityMmHr: directIntensity,
                idfA: idfParams?.a,
                idfB: idfParams?.b,
                idfM: idfParams?.m,
                idfN: idfParams?.n,
                returnPeriodYears: idfParams?.returnPeriodYears,
                latitude: latitude,
                longitude: longitude,
                peakDischargeM3s: result.peakDischargeM3s,
                tcMinutes: result.tcMinutes,
                createdAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              );
              await ref.read(projectsListProvider.notifier).save(project);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project saved locally')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ReportGenerator.generateAndPrint(
                projectName: projectName,
                result: result,
                latitude: latitude,
                longitude: longitude,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (result.areaExceedsLimit)
            Card(
              color: Colors.red.shade100,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Catchment area exceeds 25 km2. The Rational Method is outside its reliable range for large catchments. Switch to SCS-CN or Dickens method.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Peak Discharge (Q)', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${result.peakDischargeM3s.toStringAsFixed(3)} m3/s',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${result.peakDischargeLps.toStringAsFixed(1)} L/s',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time of Concentration (tc): ${result.tcMinutes.toStringAsFixed(2)} min'),
                  const SizedBox(height: 6),
                  Text('Runoff Coefficient (C): ${result.runoffCoefficient.toStringAsFixed(3)}'),
                  const SizedBox(height: 6),
                  Text('Rainfall Intensity (I): ${result.rainfallIntensityMmHr.toStringAsFixed(2)} mm/hr'),
                  const SizedBox(height: 6),
                  Text('Catchment Area (A): ${result.areaKm2.toStringAsFixed(3)} km2 (${result.areaHectares.toStringAsFixed(1)} ha)'),
                  if (latitude != null) ...[
                    const SizedBox(height: 6),
                    Text('Outlet GPS: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Worked Step-by-Step Substitution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.substitutionSteps
                    .map((step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            step,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
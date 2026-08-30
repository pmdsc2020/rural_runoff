// lib/core/pdf/report_generator.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../calculator/models/calculation_result.dart';

class ReportGenerator {
  static Future<void> generateAndPrint({
    required String projectName,
    required CalculationResult result,
    double? latitude,
    double? longitude,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RURAL RUNOFF REPORT',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Method: Rational Formula (Q = C * I * A / 3.6)'),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text('Project Name: $projectName'),
                pw.Text('Generated: ${DateTime.now().toIso8601String().substring(0, 16)}'),
                if (latitude != null)
                  pw.Text('Outlet Coordinates: $latitude, $longitude'),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Key Summary',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Peak Discharge: ${result.peakDischargeM3s.toStringAsFixed(3)} m3/s (${result.peakDischargeLps.toStringAsFixed(1)} L/s)'),
                pw.Text('Time of Concentration: ${result.tcMinutes.toStringAsFixed(2)} min'),
                pw.Text('Runoff Coefficient C: ${result.runoffCoefficient.toStringAsFixed(3)}'),
                pw.Text('Rainfall Intensity I: ${result.rainfallIntensityMmHr.toStringAsFixed(2)} mm/hr'),
                pw.Text('Catchment Area: ${result.areaKm2.toStringAsFixed(3)} km2 (${result.areaHectares.toStringAsFixed(1)} ha)'),
                if (result.areaExceedsLimit) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'WARNING: Catchment exceeds 25 km2 reliability threshold for Rational Method.',
                    style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold),
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Text(
                  'Step-by-Step Substitution Trace',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                ...result.substitutionSteps.map(
                  (step) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(step, style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
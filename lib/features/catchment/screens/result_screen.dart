// lib/features/catchment/screens/result_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/calculator/models/calculation_result.dart';
import '../../../core/calculator/models/idf_parameters.dart';
import '../../../core/pdf/report_generator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/section_card.dart';
import '../models/catchment_project.dart';
import '../providers/catchment_providers.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String projectName;
  final CalculationResult result;
  final double? directIntensity;
  final IdfParameters? idfParams;
  final double? latitude;
  final double? longitude;

  /// True when opened from the saved project list, so saving again is disabled.
  final bool alreadySaved;

  const ResultScreen({
    super.key,
    required this.projectName,
    required this.result,
    this.directIntensity,
    this.idfParams,
    this.latitude,
    this.longitude,
    this.alreadySaved = false,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late bool _saved = widget.alreadySaved;
  bool _busy = false;

  CalculationResult get r => widget.result;

  Future<void> _save() async {
    setState(() => _busy = true);
    final project = CatchmentProject(
      name: widget.projectName,
      areaKm2: r.areaKm2,
      flowLengthM: r.flowLengthM,
      elevationDropM: r.elevationDropM,
      runoffCoefficient: r.runoffCoefficient,
      directIntensityMmHr: widget.directIntensity,
      idfA: widget.idfParams?.a,
      idfB: widget.idfParams?.b,
      idfM: widget.idfParams?.m,
      idfN: widget.idfParams?.n,
      returnPeriodYears: widget.idfParams?.returnPeriodYears,
      latitude: widget.latitude,
      longitude: widget.longitude,
      peakDischargeM3s: r.peakDischargeM3s,
      tcMinutes: r.tcMinutes,
      createdAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );
    try {
      await ref.read(projectsListProvider.notifier).save(project);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project saved on this device')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pdf() {
    ReportGenerator.generateAndPrint(
      projectName: widget.projectName,
      result: r,
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
  }

  void _copySteps() {
    Clipboard.setData(ClipboardData(text: r.substitutionSteps.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calculation steps copied')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final idf = widget.idfParams;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 270,
            foregroundColor: scheme.onPrimary,
            backgroundColor: scheme.primary,
            title: Text(widget.projectName.isEmpty ? 'Results' : widget.projectName),
            actions: [
              IconButton(tooltip: 'Copy steps', icon: const Icon(Icons.copy_all), onPressed: _copySteps),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _Hero(result: r),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                if (r.areaExceedsLimit)
                  Card(
                    elevation: 0,
                    color: scheme.errorContainer,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Catchment area exceeds 25 km². The Rational Method is outside its reliable range for large catchments. Switch to SCS-CN or Dickens method.',
                              style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.75,
                  children: [
                    MetricTile(icon: Icons.timer_outlined, label: 'Time of conc. tc', value: r.tcMinutes.toStringAsFixed(1), unit: 'min'),
                    MetricTile(icon: Icons.thunderstorm_outlined, label: 'Intensity I', value: r.rainfallIntensityMmHr.toStringAsFixed(1), unit: 'mm/hr'),
                    MetricTile(icon: Icons.grass, label: 'Runoff coeff. C', value: r.runoffCoefficient.toStringAsFixed(3), unit: ''),
                    MetricTile(icon: Icons.crop_square, label: 'Area A', value: r.areaKm2.toStringAsFixed(3), unit: 'km²'),
                    MetricTile(icon: Icons.terrain, label: 'Slope S', value: (r.slope * 100).toStringAsFixed(2), unit: '%'),
                    MetricTile(icon: Icons.waves, label: 'Runoff volume', value: _compact(r.runoffVolumeM3), unit: 'm³'),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.show_chart,
                  title: 'Design hydrograph',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LineChart(
                        points: [Offset.zero, Offset(r.tcMinutes, r.peakDischargeM3s), Offset(r.tcMinutes * 2, 0)],
                        marker: Offset(r.tcMinutes, r.peakDischargeM3s),
                        markerLabel: 'Qp ${r.peakDischargeM3s.toStringAsFixed(2)}',
                        xUnit: 'min',
                        yUnit: 'm³/s',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Triangular Rational hydrograph: rises to Qp at tc, recedes over another tc.',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (idf != null)
                  SectionCard(
                    icon: Icons.stacked_line_chart,
                    title: 'IDF curve · T = ${idf.returnPeriodYears.toStringAsFixed(0)} yr',
                    child: LineChart(
                      points: [
                        for (var d = 5.0; d <= math.max(120.0, r.tcMinutes * 2); d += 2.5)
                          Offset(d, idf.calculateIntensity(d)),
                      ],
                      marker: Offset(r.tcMinutes, r.rainfallIntensityMmHr),
                      markerLabel: 'I(tc) ${r.rainfallIntensityMmHr.toStringAsFixed(1)}',
                      xUnit: 'duration min',
                      yUnit: 'mm/hr',
                    ),
                  ),
                if (widget.latitude != null)
                  SectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Outlet location',
                    child: SelectableText(
                      '${widget.latitude!.toStringAsFixed(6)}, ${widget.longitude!.toStringAsFixed(6)}',
                      style: text.titleMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                SectionCard(
                  icon: Icons.calculate_outlined,
                  title: 'Worked substitution',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      r.substitutionSteps.join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _saved || _busy ? null : _save,
                  icon: Icon(_saved ? Icons.check_circle : Icons.save_outlined),
                  label: Text(_saved ? 'Saved' : 'Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _compact(double v) => NumberFormat.compact().format(v);
}

class _Hero extends StatelessWidget {
  final CalculationResult result;
  const _Hero({required this.result});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onHero = scheme.onPrimary;
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.heroGradient(scheme)),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -30,
            child: Icon(Icons.water_drop, size: 220, color: onHero.withValues(alpha: 0.08)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Peak discharge Q', style: TextStyle(color: onHero.withValues(alpha: 0.85), fontSize: 14)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: result.peakDischargeM3s),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutExpo,
                    builder: (_, v, __) => Text.rich(
                      TextSpan(children: [
                        TextSpan(text: v.toStringAsFixed(3), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const TextSpan(text: '  m³/s', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ]),
                      style: TextStyle(color: onHero),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _HeroChip(text: '${result.peakDischargeLps.toStringAsFixed(1)} L/s'),
                      _HeroChip(text: 'Q = C·I·A / 3.6'),
                      _HeroChip(text: result.areaExceedsLimit ? 'Outside method range' : 'Within 25 km² limit'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  const _HeroChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: on.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(color: on, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

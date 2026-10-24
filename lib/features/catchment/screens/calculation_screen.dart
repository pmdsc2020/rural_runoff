// lib/features/catchment/screens/calculation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/calculator/models/calculation_result.dart';
import '../../../core/calculator/models/idf_parameters.dart';
import '../../../core/calculator/models/land_cover_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';
import '../providers/catchment_providers.dart';
import 'composite_c_screen.dart';
import 'result_screen.dart';

class CalculationScreen extends ConsumerStatefulWidget {
  const CalculationScreen({super.key});

  @override
  ConsumerState<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends ConsumerState<CalculationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Catchment 1');
  final _areaController = TextEditingController();
  final _lengthController = TextEditingController();
  final _dropController = TextEditingController();
  final _cController = TextEditingController();
  final _directIntensityController = TextEditingController();

  final _idfAController = TextEditingController(text: '1200');
  final _idfBController = TextEditingController(text: '15');
  final _idfMController = TextEditingController(text: '0.20');
  final _idfNController = TextEditingController(text: '0.75');

  late final List<TextEditingController> _numericControllers = [
    _areaController,
    _lengthController,
    _dropController,
    _cController,
    _directIntensityController,
    _idfAController,
    _idfBController,
    _idfMController,
    _idfNController,
  ];

  static const _returnPeriods = [2.0, 5.0, 10.0, 25.0, 50.0, 100.0];

  bool _isHectares = false;
  bool _useDirectIntensity = true;
  double _selectedReturnPeriod = 10.0;
  double? _latitude;
  double? _longitude;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so the live preview tracks the inputs.
    for (final c in _numericControllers) {
      c.addListener(_onInputChanged);
    }
  }

  void _onInputChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _numericControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Location services are off');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _toast('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      _toast('Could not get location: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim());

  /// Builds the inputs from the form; null when any field is missing or invalid.
  ({CalculationResult result, double? direct, IdfParameters? idf})? _tryCompute() {
    final rawArea = _num(_areaController);
    final length = _num(_lengthController);
    final drop = _num(_dropController);
    final c = _num(_cController);
    if (rawArea == null || length == null || drop == null || c == null) return null;

    double? direct;
    IdfParameters? idf;
    if (_useDirectIntensity) {
      direct = _num(_directIntensityController);
      if (direct == null) return null;
    } else {
      final a = _num(_idfAController), b = _num(_idfBController);
      final m = _num(_idfMController), n = _num(_idfNController);
      if (a == null || b == null || m == null || n == null) return null;
      idf = IdfParameters(a: a, b: b, m: m, n: n, returnPeriodYears: _selectedReturnPeriod);
    }

    try {
      final result = ref.read(rationalCalculatorProvider).calculate(
            areaKm2: _isHectares ? rawArea / 100.0 : rawArea,
            flowLengthM: length,
            elevationDropM: drop,
            runoffCoefficient: c,
            directIntensityMmHr: direct,
            idfParams: idf,
          );
      if (!result.peakDischargeM3s.isFinite || !result.rainfallIntensityMmHr.isFinite) return null;
      return (result: result, direct: direct, idf: idf);
    } on ArgumentError {
      return null;
    }
  }

  void _runCalculation() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final computed = _tryCompute();
    if (computed == null) {
      _toast('Inputs produce no valid result – check IDF coefficients');
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          projectName: _nameController.text.trim(),
          result: computed.result,
          directIntensity: computed.direct,
          idfParams: computed.idf,
          latitude: _latitude,
          longitude: _longitude,
        ),
      ),
    );
  }

  void _reset() {
    _formKey.currentState?.reset();
    for (final c in [_areaController, _lengthController, _dropController, _cController, _directIntensityController]) {
      c.clear();
    }
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

  String? _positive(String? v, String missing) {
    if (v == null || v.trim().isEmpty) return missing;
    final parsed = double.tryParse(v.trim());
    if (parsed == null || parsed <= 0) return 'Must exceed 0';
    return null;
  }

  Widget _numField(
    TextEditingController controller,
    String label, {
    String? suffix,
    IconData? icon,
    String? Function(String?)? validator,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final preview = _tryCompute()?.result;
    final length = _num(_lengthController);
    final drop = _num(_dropController);
    final slope = (length != null && length > 0 && drop != null && drop > 0) ? drop / length : null;
    final cValue = _num(_cController);

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('RuralRunoff'),
              actions: [
                IconButton(
                  tooltip: 'Reset inputs',
                  icon: const Icon(Icons.restart_alt),
                  onPressed: _reset,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Rational Method peak discharge for small rural catchments',
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.landscape_outlined,
                    title: 'Catchment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Catchment name',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter project name' : null,
                        ),
                        const SizedBox(height: 12),
                        _numField(
                          _areaController,
                          'Area (A)',
                          suffix: _isHectares ? 'ha' : 'km²',
                          icon: Icons.crop_square,
                          validator: (v) => _positive(v, 'Enter area'),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('km²')),
                            ButtonSegment(value: true, label: Text('hectares')),
                          ],
                          selected: {_isHectares},
                          onSelectionChanged: (v) => setState(() => _isHectares = v.first),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _locating ? null : _captureGps,
                          icon: _locating
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(_latitude == null ? Icons.my_location : Icons.location_on),
                          label: Text(
                            _latitude == null
                                ? 'Capture outlet GPS'
                                : '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    icon: Icons.timeline,
                    title: 'Flow path',
                    trailing: slope == null
                        ? null
                        : _Pill(text: 'S = ${slope.toStringAsFixed(4)}'),
                    child: Column(
                      children: [
                        _numField(
                          _lengthController,
                          'Longest flow length (L)',
                          suffix: 'm',
                          icon: Icons.straighten,
                          validator: (v) => _positive(v, 'Enter flow length'),
                        ),
                        const SizedBox(height: 12),
                        _numField(
                          _dropController,
                          'Elevation drop (ΔH)',
                          suffix: 'm',
                          icon: Icons.terrain,
                          validator: (v) => _positive(v, 'Enter elevation drop'),
                        ),
                        if (preview != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.timer_outlined,
                            text: 'Kirpich tc ≈ ${preview.tcMinutes.toStringAsFixed(1)} min',
                          ),
                        ],
                      ],
                    ),
                  ),
                  SectionCard(
                    icon: Icons.grass,
                    title: 'Runoff coefficient',
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.donut_large, size: 18),
                      label: const Text('Composite'),
                      onPressed: () async {
                        final compositeC = await Navigator.push<double>(
                          context,
                          MaterialPageRoute(builder: (_) => const CompositeCScreen()),
                        );
                        if (compositeC != null) _cController.text = compositeC.toStringAsFixed(3);
                      },
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _numField(
                          _cController,
                          'C (0.01 – 1.00)',
                          icon: Icons.opacity,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter C value';
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null || parsed <= 0 || parsed > 1.0) return 'Range: 0.01 - 1.0';
                            return null;
                          },
                        ),
                        Slider(
                          value: (cValue ?? 0.35).clamp(0.01, 1.0),
                          min: 0.01,
                          max: 1.0,
                          divisions: 99,
                          label: (cValue ?? 0.35).toStringAsFixed(2),
                          onChanged: (v) => _cController.text = v.toStringAsFixed(2),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final p in landCoverPresets)
                              ChoiceChip(
                                label: Text('${p.name.split(' ').first} ${p.c.toStringAsFixed(2)}'),
                                tooltip: '${p.name}: ${p.cMin}–${p.cMax}',
                                selected: cValue == p.c,
                                onSelected: (_) => _cController.text = p.c.toStringAsFixed(2),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    icon: Icons.thunderstorm_outlined,
                    title: 'Rainfall intensity',
                    trailing: preview == null
                        ? null
                        : _Pill(text: 'I = ${preview.rainfallIntensityMmHr.toStringAsFixed(1)}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, icon: Icon(Icons.edit), label: Text('Direct')),
                            ButtonSegment(value: false, icon: Icon(Icons.functions), label: Text('IDF curve')),
                          ],
                          selected: {_useDirectIntensity},
                          onSelectionChanged: (v) => setState(() => _useDirectIntensity = v.first),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _useDirectIntensity
                              ? _numField(
                                  _directIntensityController,
                                  'Rainfall intensity (I)',
                                  suffix: 'mm/hr',
                                  icon: Icons.water,
                                  helper: 'For a storm duration equal to tc',
                                  validator: (v) => _positive(v, 'Enter intensity'),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text('Return period T', style: text.labelLarge),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final t in _returnPeriods)
                                          ChoiceChip(
                                            label: Text('${t.toStringAsFixed(0)} yr'),
                                            selected: _selectedReturnPeriod == t,
                                            onSelected: (_) => setState(() => _selectedReturnPeriod = t),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'I = a · Tᵐ / (tc + b)ⁿ',
                                        textAlign: TextAlign.center,
                                        style: text.titleMedium?.copyWith(fontFamily: 'monospace'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _numField(_idfAController, 'a', validator: (v) => _positive(v, 'a?'))),
                                        const SizedBox(width: 8),
                                        Expanded(child: _numField(_idfBController, 'b', validator: _nonNegative)),
                                        const SizedBox(width: 8),
                                        Expanded(child: _numField(_idfMController, 'm', validator: _nonNegative)),
                                        const SizedBox(width: 8),
                                        Expanded(child: _numField(_idfNController, 'n', validator: (v) => _positive(v, 'n?'))),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _PreviewBar(result: preview, onCalculate: _runCalculation),
    );
  }

  String? _nonNegative(String? v) {
    final parsed = double.tryParse(v?.trim() ?? '');
    return parsed == null || parsed < 0 ? '≥ 0' : null;
  }
}

class _PreviewBar extends StatelessWidget {
  final CalculationResult? result;
  final VoidCallback onCalculate;

  const _PreviewBar({required this.result, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = result;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient(scheme),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Live peak discharge',
                      style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8), fontSize: 12)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      r == null ? '— m³/s' : '${r.peakDischargeM3s.toStringAsFixed(3)} m³/s',
                      key: ValueKey(r?.peakDischargeM3s),
                      style: TextStyle(color: scheme.onPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.onPrimary,
                foregroundColor: scheme.primary,
              ),
              onPressed: onCalculate,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Results'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

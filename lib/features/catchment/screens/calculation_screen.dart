// lib/features/catchment/screens/calculation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/calculator/models/idf_parameters.dart';
import '../providers/catchment_providers.dart';
import 'composite_c_screen.dart';
import 'result_screen.dart';
import 'project_list_screen.dart';

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

  bool _isHectares = false;
  bool _useDirectIntensity = true;
  double _selectedReturnPeriod = 10.0;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _lengthController.dispose();
    _dropController.dispose();
    _cController.dispose();
    _directIntensityController.dispose();
    _idfAController.dispose();
    _idfBController.dispose();
    _idfMController.dispose();
    _idfNController.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    });
  }

  void _runCalculation() {
    if (!_formKey.currentState!.validate()) return;

    final rawArea = double.parse(_areaController.text);
    final areaKm2 = _isHectares ? rawArea / 100.0 : rawArea;
    final lengthM = double.parse(_lengthController.text);
    final dropM = double.parse(_dropController.text);
    final cVal = double.parse(_cController.text);

    final calculator = ref.read(rationalCalculatorProvider);

    IdfParameters? idfParams;
    double? directIntensity;

    if (_useDirectIntensity) {
      directIntensity = double.parse(_directIntensityController.text);
    } else {
      idfParams = IdfParameters(
        a: double.parse(_idfAController.text),
        b: double.parse(_idfBController.text),
        m: double.parse(_idfMController.text),
        n: double.parse(_idfNController.text),
        returnPeriodYears: _selectedReturnPeriod,
      );
    }

    final result = calculator.calculate(
      areaKm2: areaKm2,
      flowLengthM: lengthM,
      elevationDropM: dropM,
      runoffCoefficient: cVal,
      directIntensityMmHr: directIntensity,
      idfParams: idfParams,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          projectName: _nameController.text,
          result: result,
          directIntensity: directIntensity,
          idfParams: idfParams,
          latitude: _latitude,
          longitude: _longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RuralRunoff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectListScreen()),
              );
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Catchment Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter project name' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _isHectares ? 'Area (ha)' : 'Area (km2)',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter area';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Must exceed 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('km2'),
                  selected: !_isHectares,
                  onSelected: (val) => setState(() => _isHectares = !val),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('ha'),
                  selected: _isHectares,
                  onSelected: (val) => setState(() => _isHectares = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lengthController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Longest Flow Length L (m)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter flow length';
                final parsed = double.tryParse(v);
                if (parsed == null || parsed <= 0) return 'Must exceed 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dropController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Elevation Drop Delta H (m)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter elevation drop';
                final parsed = double.tryParse(v);
                if (parsed == null || parsed <= 0) return 'Must exceed 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Runoff Coefficient C (0.10 - 0.80)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter C value';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0 || parsed > 1.0) {
                        return 'Range: 0.01 - 1.0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final compositeC = await Navigator.push<double>(
                      context,
                      MaterialPageRoute(builder: (_) => const CompositeCScreen()),
                    );
                    if (compositeC != null) {
                      setState(() {
                        _cController.text = compositeC.toStringAsFixed(3);
                      });
                    }
                  },
                  child: const Text('Builder'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Direct I (mm/hr)')),
                ButtonSegment(value: false, label: Text('IDF Parameters')),
              ],
              selected: {_useDirectIntensity},
              onSelectionChanged: (val) => setState(() => _useDirectIntensity = val.first),
            ),
            const SizedBox(height: 16),
            if (_useDirectIntensity)
              TextFormField(
                controller: _directIntensityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Rainfall Intensity I (mm/hr)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (!_useDirectIntensity) return null;
                  if (v == null || v.isEmpty) return 'Enter intensity';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Must exceed 0';
                  return null;
                },
              )
            else ...[
              DropdownButtonFormField<double>(
                value: _selectedReturnPeriod,
                decoration: const InputDecoration(
                  labelText: 'Return Period T (Years)',
                  border: OutlineInputBorder(),
                ),
                items: const [2.0, 5.0, 10.0, 25.0, 50.0, 100.0]
                    .map((t) => DropdownMenuItem(value: t, child: Text('$t years')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedReturnPeriod = val!),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idfAController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'a', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _idfBController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'b', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _idfMController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'm', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _idfNController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'n', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _captureGps,
              icon: const Icon(Icons.location_on),
              label: Text(
                _latitude == null
                    ? 'Capture Outlet GPS'
                    : 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _runCalculation,
              child: const Text('Calculate Peak Discharge'),
            ),
          ],
        ),
      ),
    );
  }
}
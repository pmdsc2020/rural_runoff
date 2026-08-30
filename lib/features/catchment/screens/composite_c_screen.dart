// lib/features/catchment/screens/composite_c_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculator/models/land_cover_item.dart';
import '../providers/catchment_providers.dart';

class CompositeCScreen extends ConsumerStatefulWidget {
  const CompositeCScreen({super.key});

  @override
  ConsumerState<CompositeCScreen> createState() => _CompositeCScreenState();
}

class _CompositeCScreenState extends ConsumerState<CompositeCScreen> {
  final _presets = const [
    {'name': 'Cultivated Flat Land', 'c': 0.35},
    {'name': 'Cultivated Rolling Land', 'c': 0.45},
    {'name': 'Pasture / Grassland', 'c': 0.25},
    {'name': 'Forest Cover', 'c': 0.15},
    {'name': 'Barren / Rocky', 'c': 0.70},
    {'name': 'Settlement / Village', 'c': 0.60},
  ];

  void _showAddDialog() {
    String selectedName = _presets.first['name'] as String;
    double selectedC = _presets.first['c'] as double;
    final areaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Land Cover Sub-Area'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: selectedName,
                items: _presets.map((p) {
                  return DropdownMenuItem<String>(
                    value: p['name'] as String,
                    child: Text('${p['name']} (C=${p['c']})'),
                  );
                }).toList(),
                onChanged: (val) {
                  final match = _presets.firstWhere((p) => p['name'] == val);
                  setDialogState(() {
                    selectedName = match['name'] as String;
                    selectedC = match['c'] as double;
                  });
                },
              ),
              TextField(
                controller: areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Sub-Area (hectares)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final area = double.tryParse(areaController.text);
                if (area != null && area > 0) {
                  ref.read(landCoverItemsProvider.notifier).addItem(
                        LandCoverItem(
                          id: DateTime.now().toIso8601String(),
                          label: selectedName,
                          areaHectares: area,
                          runoffCoefficient: selectedC,
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(landCoverItemsProvider);
    final calculator = ref.read(rationalCalculatorProvider);

    double compositeC = 0.0;
    if (items.isNotEmpty) {
      compositeC = calculator.computeCompositeC(items);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Composite C Builder')),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No land cover sub-areas added'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item.label),
                        subtitle: Text('${item.areaHectares} ha @ C = ${item.runoffCoefficient}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref.read(landCoverItemsProvider.notifier).removeItem(item.id),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Text(
                  'Weighted Composite C: ${compositeC.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showAddDialog,
                        child: const Text('Add Sub-Area'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: items.isEmpty
                            ? null
                            : () => Navigator.pop(context, compositeC),
                        child: const Text('Apply C Value'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
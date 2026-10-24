// lib/features/catchment/screens/composite_c_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculator/models/land_cover_item.dart';
import '../../../core/widgets/charts.dart';
import '../../../core/widgets/section_card.dart';
import '../providers/catchment_providers.dart';

const _palette = [
  Color(0xFF2E7D32),
  Color(0xFF0277BD),
  Color(0xFFF9A825),
  Color(0xFF6A1B9A),
  Color(0xFFD84315),
  Color(0xFF00838F),
  Color(0xFF8D6E63),
];

class CompositeCScreen extends ConsumerStatefulWidget {
  const CompositeCScreen({super.key});

  @override
  ConsumerState<CompositeCScreen> createState() => _CompositeCScreenState();
}

class _CompositeCScreenState extends ConsumerState<CompositeCScreen> {
  void _showAddSheet() {
    var preset = landCoverPresets.first;
    var c = preset.c;
    final areaController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add land cover sub-area', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in landCoverPresets)
                    ChoiceChip(
                      label: Text(p.name),
                      selected: preset == p,
                      onSelected: (_) => setSheet(() {
                        preset = p;
                        c = p.c;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text('C = ${c.toStringAsFixed(2)}  (recommended ${preset.cMin}–${preset.cMax})'),
              Slider(
                value: c,
                min: preset.cMin,
                max: preset.cMax,
                divisions: ((preset.cMax - preset.cMin) * 100).round(),
                label: c.toStringAsFixed(2),
                onChanged: (v) => setSheet(() => c = v),
              ),
              TextField(
                controller: areaController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: const InputDecoration(labelText: 'Sub-area', suffixText: 'ha', prefixIcon: Icon(Icons.crop_square)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add sub-area'),
                onPressed: () {
                  final area = double.tryParse(areaController.text);
                  if (area == null || area <= 0) {
                    HapticFeedback.heavyImpact();
                    return;
                  }
                  ref.read(landCoverItemsProvider.notifier).addItem(
                        LandCoverItem(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          label: preset.name,
                          areaHectares: area,
                          runoffCoefficient: double.parse(c.toStringAsFixed(2)),
                        ),
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(areaController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(landCoverItemsProvider);
    final calculator = ref.read(rationalCalculatorProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final compositeC = items.isEmpty ? 0.0 : calculator.computeCompositeC(items);
    final totalHa = items.fold<double>(0, (s, i) => s + i.areaHectares);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Composite C builder'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ref.read(landCoverItemsProvider.notifier).clear(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Sub-area'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SectionCard(
            icon: Icons.donut_large,
            title: 'Weighted coefficient',
            child: Center(
              child: DonutChart(
                values: [for (final i in items) i.areaHectares],
                colors: _palette,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(compositeC.toStringAsFixed(3), style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    Text('C composite', style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    Text('${totalHa.toStringAsFixed(1)} ha', style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('C = Σ(Cᵢ · Aᵢ) / ΣAᵢ', style: text.titleSmall?.copyWith(fontFamily: 'monospace')),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Add each land cover type in the catchment with its area to get an area-weighted C.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          for (var i = 0; i < items.length; i++)
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: CircleAvatar(radius: 8, backgroundColor: _palette[i % _palette.length]),
                title: Text(items[i].label),
                subtitle: Text(
                  '${items[i].areaHectares} ha · ${(items[i].areaHectares / totalHa * 100).toStringAsFixed(1)}% · C ${items[i].runoffCoefficient}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(landCoverItemsProvider.notifier).removeItem(items[i].id),
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: items.isEmpty ? null : () => Navigator.pop(context, compositeC),
            icon: const Icon(Icons.check),
            label: Text('Apply C = ${compositeC.toStringAsFixed(3)}'),
          ),
        ],
      ),
    );
  }
}

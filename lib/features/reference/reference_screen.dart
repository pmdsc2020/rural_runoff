// lib/features/reference/reference_screen.dart

import 'package:flutter/material.dart';
import '../../core/calculator/models/land_cover_item.dart';
import '../../core/widgets/section_card.dart';

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Reference')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.list(
            children: [
              const _Formula(
                icon: Icons.water_drop_outlined,
                title: 'Rational formula',
                formula: 'Q = C · I · A / 3.6',
                terms: [
                  ('Q', 'Peak discharge (m³/s)'),
                  ('C', 'Dimensionless runoff coefficient'),
                  ('I', 'Rainfall intensity for duration = tc (mm/hr)'),
                  ('A', 'Catchment area (km²)'),
                  ('3.6', 'Metric unit conversion constant'),
                ],
              ),
              const _Formula(
                icon: Icons.timer_outlined,
                title: 'Kirpich time of concentration',
                formula: 'tc = 0.01947 · L^0.77 · S^-0.385',
                terms: [
                  ('tc', 'Time of concentration (min)'),
                  ('L', 'Longest hydraulic flow path (m)'),
                  ('S', 'Average slope ΔH / L (m/m)'),
                ],
              ),
              const _Formula(
                icon: Icons.thunderstorm_outlined,
                title: 'IDF relationship',
                formula: 'I = a · T^m / (tc + b)^n',
                terms: [
                  ('T', 'Design return period (years)'),
                  ('a, b, m, n', 'Empirical regional rainfall coefficients'),
                ],
              ),
              const _Formula(
                icon: Icons.donut_large,
                title: 'Composite coefficient',
                formula: 'C = Σ(Cᵢ · Aᵢ) / ΣAᵢ',
                terms: [('Cᵢ, Aᵢ', 'Coefficient and area of each land cover')],
              ),
              SectionCard(
                icon: Icons.grass,
                title: 'Rural runoff coefficients',
                child: Column(
                  children: [
                    for (final p in landCoverPresets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(p.name)),
                                Text('${p.cMin.toStringAsFixed(2)} – ${p.cMax.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LayoutBuilder(
                              builder: (_, box) => Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  Positioned(
                                    left: box.maxWidth * p.cMin,
                                    width: box.maxWidth * (p.cMax - p.cMin),
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
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
              Card(
                elevation: 0,
                color: scheme.tertiaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Application limit: the Rational Method is valid for small rural catchments under 25 km². '
                          'For larger areas use SCS-CN or Dickens. All calculations and projects stay offline on this device.',
                          style: TextStyle(color: scheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Formula extends StatelessWidget {
  final IconData icon;
  final String title;
  final String formula;
  final List<(String, String)> terms;

  const _Formula({required this.icon, required this.title, required this.formula, required this.terms});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SectionCard(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(formula, style: text.titleLarge?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          for (final (sym, desc) in terms)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 72, child: Text(sym, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(child: Text(desc, style: TextStyle(color: scheme.onSurfaceVariant))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// lib/features/catchment/screens/project_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculator/models/idf_parameters.dart';
import '../models/catchment_project.dart';
import '../providers/catchment_providers.dart';
import 'result_screen.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  String _query = '';

  void _open(CatchmentProject p) {
    final idf = p.idfA == null
        ? null
        : IdfParameters(a: p.idfA!, b: p.idfB!, m: p.idfM!, n: p.idfN!, returnPeriodYears: p.returnPeriodYears!);
    try {
      final result = ref.read(rationalCalculatorProvider).calculate(
            areaKm2: p.areaKm2,
            flowLengthM: p.flowLengthM,
            elevationDropM: p.elevationDropM,
            runoffCoefficient: p.runoffCoefficient,
            directIntensityMmHr: p.directIntensityMmHr,
            idfParams: idf,
          );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            projectName: p.name,
            result: result,
            directIntensity: p.directIntensityMmHr,
            idfParams: idf,
            latitude: p.latitude,
            longitude: p.longitude,
            alreadySaved: true,
          ),
        ),
      );
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot open project: ${e.message}')));
    }
  }

  Future<void> _delete(CatchmentProject p) async {
    final notifier = ref.read(projectsListProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    await notifier.delete(p.id!);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Deleted "${p.name}"'),
        action: SnackBarAction(label: 'Undo', onPressed: () => notifier.save(p)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(projectsListProvider.notifier).loadProjects(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar.large(title: Text('Projects')),
            ...state.when(
              loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
              error: (err, _) => [SliverFillRemaining(child: Center(child: Text('Error loading projects: $err')))],
              data: (projects) {
                if (projects.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(scheme: scheme),
                    ),
                  ];
                }
                final q = _query.toLowerCase();
                final filtered = projects.where((p) => p.name.toLowerCase().contains(q)).toList();
                final maxQ = projects.map((p) => p.peakDischargeM3s).reduce((a, b) => a > b ? a : b);
                final totalArea = projects.fold<double>(0, (s, p) => s + p.areaKm2);
                return [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.list(children: [
                      Row(
                        children: [
                          _Stat(label: 'Projects', value: '${projects.length}'),
                          const SizedBox(width: 10),
                          _Stat(label: 'Max Q m³/s', value: maxQ.toStringAsFixed(2)),
                          const SizedBox(width: 10),
                          _Stat(label: 'Total km²', value: totalArea.toStringAsFixed(1)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SearchBar(
                        hintText: 'Search catchments',
                        leading: const Icon(Icons.search),
                        elevation: const WidgetStatePropertyAll(0),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 12),
                    ]),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _ProjectCard(
                        project: filtered[i],
                        maxQ: maxQ,
                        onTap: () => _open(filtered[i]),
                        onDelete: () => _delete(filtered[i]),
                        onDuplicate: () => ref.read(projectsListProvider.notifier).duplicate(filtered[i]),
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final CatchmentProject project;
  final double maxQ;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _ProjectCard({
    required this.project,
    required this.maxQ,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = project;
    final share = maxQ > 0 ? (p.peakDischargeM3s / maxQ).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(p.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(22)),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        child: Material(
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.water_drop, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                            Text(p.createdAt, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) => v == 'duplicate' ? onDuplicate() : onDelete(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'duplicate', child: ListTile(leading: Icon(Icons.copy), title: Text('Duplicate'))),
                          PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Tag(text: 'Q ${p.peakDischargeM3s.toStringAsFixed(3)} m³/s', strong: true),
                            _Tag(text: 'A ${p.areaKm2.toStringAsFixed(2)} km²'),
                            _Tag(text: 'C ${p.runoffCoefficient.toStringAsFixed(2)}'),
                            _Tag(text: 'tc ${p.tcMinutes.toStringAsFixed(1)} min'),
                            if (p.latitude != null) const _Tag(text: 'GPS', icon: Icons.location_on),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: share, minHeight: 5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool strong;
  final IconData? icon;
  const _Tag({required this.text, this.strong = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = strong ? scheme.primary : scheme.secondaryContainer;
    final fg = strong ? scheme.onPrimary : scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
          Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  const _EmptyState({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.folder_open, size: 56, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text('No saved catchments yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Run a calculation and tap Save on the results screen. Projects stay on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

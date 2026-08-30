// lib/features/catchment/screens/project_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catchment_providers.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Catchment Projects')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading projects: $err')),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(child: Text('No saved projects found'));
          }
          return ListView.separated(
            itemCount: projects.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final item = projects[i];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(
                  'Q: ${item.peakDischargeM3s.toStringAsFixed(3)} m3/s | A: ${item.areaKm2} km2 | ${item.createdAt}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'duplicate') {
                      ref.read(projectsListProvider.notifier).duplicate(item);
                    } else if (val == 'delete' && item.id != null) {
                      ref.read(projectsListProvider.notifier).delete(item.id!);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// lib/features/home/home_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../catchment/providers/catchment_providers.dart';
import '../catchment/screens/calculation_screen.dart';
import '../catchment/screens/project_list_screen.dart';
import '../reference/reference_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final projectCount = ref.watch(projectsListProvider).valueOrNull?.length ?? 0;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          CalculationScreen(),
          ProjectListScreen(),
          ReferenceScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Calculate',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: projectCount > 0,
              label: Text('$projectCount'),
              child: const Icon(Icons.folder_outlined),
            ),
            selectedIcon: const Icon(Icons.folder),
            label: 'Projects',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Reference',
          ),
        ],
      ),
    );
  }
}

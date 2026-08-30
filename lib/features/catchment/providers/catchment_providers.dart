// lib/features/catchment/providers/catchment_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculator/rational_calculator.dart';
import '../../../core/calculator/models/land_cover_item.dart';
import '../../../core/database/app_database.dart';
import '../models/catchment_project.dart';

final rationalCalculatorProvider = Provider<RationalCalculator>((ref) {
  return RationalCalculator();
});

final landCoverItemsProvider =
    StateNotifierProvider<LandCoverNotifier, List<LandCoverItem>>((ref) {
  return LandCoverNotifier();
});

class LandCoverNotifier extends StateNotifier<List<LandCoverItem>> {
  LandCoverNotifier() : super([]);

  void addItem(LandCoverItem item) {
    state = [...state, item];
  }

  void removeItem(String id) {
    state = state.where((element) => element.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

final projectsListProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<CatchmentProject>>>(
        (ref) {
  return ProjectsNotifier();
});

class ProjectsNotifier extends StateNotifier<AsyncValue<List<CatchmentProject>>> {
  ProjectsNotifier() : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      final list = await AppDatabase.instance.getAllProjects();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(CatchmentProject project) async {
    await AppDatabase.instance.insertProject(project);
    await loadProjects();
  }

  Future<void> update(CatchmentProject project) async {
    await AppDatabase.instance.updateProject(project);
    await loadProjects();
  }

  Future<void> delete(int id) async {
    await AppDatabase.instance.deleteProject(id);
    await loadProjects();
  }

  Future<void> duplicate(CatchmentProject project) async {
    final copy = CatchmentProject(
      name: '${project.name} (Copy)',
      areaKm2: project.areaKm2,
      flowLengthM: project.flowLengthM,
      elevationDropM: project.elevationDropM,
      runoffCoefficient: project.runoffCoefficient,
      directIntensityMmHr: project.directIntensityMmHr,
      idfA: project.idfA,
      idfB: project.idfB,
      idfM: project.idfM,
      idfN: project.idfN,
      returnPeriodYears: project.returnPeriodYears,
      latitude: project.latitude,
      longitude: project.longitude,
      peakDischargeM3s: project.peakDischargeM3s,
      tcMinutes: project.tcMinutes,
      createdAt: DateTime.now().toIso8601String(),
    );
    await save(copy);
  }
}
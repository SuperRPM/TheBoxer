import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/local/hive_routine_repository.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/repositories/routine_repository.dart';

/// RoutineRepository Provider
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return HiveRoutineRepository();
});

/// 루틴 목록 실시간 스트림 Provider
final routinesProvider = StreamProvider<List<Routine>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.watchRoutines();
});

/// 루틴 CRUD Notifier
class RoutineNotifier extends StateNotifier<AsyncValue<List<Routine>>> {
  final RoutineRepository _repo;

  RoutineNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final routines = await _repo.getAllRoutines();
      state = AsyncValue.data(routines);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRoutine(Routine routine) async {
    await _repo.saveRoutine(routine);
    await _load();
  }

  Future<void> updateRoutine(Routine routine) async {
    await _repo.saveRoutine(routine);
    await _load();
  }

  Future<void> deleteRoutine(String id) async {
    await _repo.deleteRoutine(id);
    await _load();
  }

  Future<void> refresh() async {
    await _load();
  }
}

/// 루틴 Notifier Provider
final routineNotifierProvider =
    StateNotifierProvider<RoutineNotifier, AsyncValue<List<Routine>>>(
  (ref) {
    final repo = ref.watch(routineRepositoryProvider);
    return RoutineNotifier(repo);
  },
);

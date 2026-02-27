import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/local/hive_weekly_plan_repository.dart';
import 'package:timebox_planner/data/models/weekly_plan.dart';
import 'package:timebox_planner/data/repositories/weekly_plan_repository.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// WeeklyPlanRepository Provider
final weeklyPlanRepositoryProvider = Provider<WeeklyPlanRepository>((ref) {
  return HiveWeeklyPlanRepository();
});

/// 오늘 날짜 기준 현재 주 플랜 Provider
final currentWeeklyPlanProvider = FutureProvider<WeeklyPlan?>((ref) async {
  final repo = ref.watch(weeklyPlanRepositoryProvider);
  return repo.getPlanByDate(TimeUtils.dateOnly(DateTime.now()));
});

/// 주간 플랜 CRUD Notifier
class WeeklyPlanNotifier extends StateNotifier<AsyncValue<WeeklyPlan?>> {
  final WeeklyPlanRepository _repo;

  WeeklyPlanNotifier(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final plan = await _repo.getPlanByDate(TimeUtils.dateOnly(DateTime.now()));
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> savePlan(WeeklyPlan plan) async {
    await _repo.savePlan(plan);
    await _load();
  }

  Future<void> deletePlan(String id) async {
    await _repo.deletePlan(id);
    await _load();
  }

  Future<void> loadForDate(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      final plan = await _repo.getPlanByDate(date);
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> saveMemo(String content, dynamic currentPlan) async {
    final weekStart = TimeUtils.getWeekStartDate(DateTime.now());
    final plan = WeeklyPlan(
      id: currentPlan?.id ?? const Uuid().v4(),
      weekStartDate: weekStart,
      content: content,
      goals: currentPlan?.goals ?? [],
    );
    await savePlan(plan);
  }
}

/// 주간 플랜 Notifier Provider
final weeklyPlanNotifierProvider =
    StateNotifierProvider<WeeklyPlanNotifier, AsyncValue<WeeklyPlan?>>(
  (ref) {
    final repo = ref.watch(weeklyPlanRepositoryProvider);
    return WeeklyPlanNotifier(repo);
  },
);

/// 현재 주의 시작 날짜 반환 (월요일)
DateTime getCurrentWeekStart() {
  return TimeUtils.getWeekStartDate(DateTime.now());
}

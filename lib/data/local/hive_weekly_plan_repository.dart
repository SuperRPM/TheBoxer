import 'package:hive/hive.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/weekly_plan.dart';
import 'package:timebox_planner/data/repositories/weekly_plan_repository.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// Hive 기반 WeeklyPlanRepository 구현체
class HiveWeeklyPlanRepository implements WeeklyPlanRepository {
  Box<WeeklyPlan> get _box =>
      Hive.box<WeeklyPlan>(AppConstants.weeklyPlanBoxName);

  @override
  Future<WeeklyPlan?> getPlanByDate(DateTime date) async {
    final weekStart = TimeUtils.getWeekStartDate(date);
    try {
      return _box.values.firstWhere(
        (plan) => TimeUtils.isSameDay(plan.weekStartDate, weekStart),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlan(WeeklyPlan plan) async {
    await _box.put(plan.id, plan);
  }

  @override
  Future<void> deletePlan(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<WeeklyPlan>> getAllPlans() async {
    return _box.values.toList();
  }
}

import '../models/weekly_plan.dart';

/// 주간 플랜 저장소 인터페이스
abstract class WeeklyPlanRepository {
  /// 특정 날짜가 속한 주의 플랜 조회 (없으면 null)
  Future<WeeklyPlan?> getPlanByDate(DateTime date);

  /// 주간 플랜 저장 (신규 또는 수정)
  Future<void> savePlan(WeeklyPlan plan);

  /// 주간 플랜 삭제
  Future<void> deletePlan(String id);

  /// 전체 주간 플랜 조회
  Future<List<WeeklyPlan>> getAllPlans();
}

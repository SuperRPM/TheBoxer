import 'package:hive/hive.dart';

part 'weekly_plan.g.dart';

/// 주간 플랜 모델
///
/// weekStartDate: 해당 주의 월요일(시각 정보 제외).
/// 해당 주가 끝날 때(일요일 23:59)까지 플래너 화면에 표시된다.
///
/// typeId: 3
@HiveType(typeId: 3)
class WeeklyPlan extends HiveObject {
  @HiveField(0)
  final String id;

  /// 주의 시작일 (월요일 기준, 날짜만 사용)
  @HiveField(1)
  DateTime weekStartDate;

  /// 주간 목표/계획 내용
  @HiveField(2)
  String content;

  /// 주간 목표 리스트 (체크리스트 형태)
  @HiveField(3)
  List<String> goals;

  WeeklyPlan({
    required this.id,
    required this.weekStartDate,
    required this.content,
    List<String>? goals,
  }) : goals = goals ?? [];

  /// 해당 주의 종료일 (일요일)
  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  /// 오늘 날짜가 해당 주에 속하는지 확인
  bool isCurrentWeek(DateTime today) {
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime(weekStartDate.year, weekStartDate.month, weekStartDate.day);
    final end = DateTime(weekEndDate.year, weekEndDate.month, weekEndDate.day);
    return !todayDate.isBefore(start) && !todayDate.isAfter(end);
  }

  WeeklyPlan copyWith({
    String? id,
    DateTime? weekStartDate,
    String? content,
    List<String>? goals,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      content: content ?? this.content,
      goals: goals ?? List.from(this.goals),
    );
  }

  @override
  String toString() => 'WeeklyPlan(id: $id, week: $weekStartDate)';
}

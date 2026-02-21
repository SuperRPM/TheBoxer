import 'package:hive/hive.dart';

part 'timebox_block.g.dart';

/// 타임박스 블록 모델
///
/// 모든 시각은 자정(00:00)부터의 분(minute) 단위로 저장.
/// 예: 09:30 → 570, 24:00 → 1440
///
/// typeId: 0
@HiveType(typeId: 0)
class TimeboxBlock extends HiveObject {
  @HiveField(0)
  final String id;

  /// 해당 타임박스가 속하는 날짜 (시각 정보 제외, 날짜만 사용)
  @HiveField(1)
  DateTime date;

  /// 시작 시각 (자정부터 분 단위)
  @HiveField(2)
  int startMinute;

  /// 종료 시각 (자정부터 분 단위)
  @HiveField(3)
  int endMinute;

  @HiveField(4)
  String title;

  @HiveField(5)
  String? description;

  /// 연결된 카테고리 ID (null이면 미지정)
  @HiveField(6)
  String? categoryId;

  /// 루틴에서 추가된 경우 해당 루틴 ID
  @HiveField(7)
  String? routineId;

  /// 브레인덤핑에서 배치된 경우 해당 항목 ID (삭제 시 미완료 복구용)
  @HiveField(8)
  String? brainDumpItemId;

  TimeboxBlock({
    required this.id,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.title,
    this.description,
    this.categoryId,
    this.routineId,
    this.brainDumpItemId,
  }) : assert(startMinute < endMinute, 'startMinute must be before endMinute'),
       assert(startMinute >= 0 && endMinute <= 1440, 'Minutes must be within 0–1440');

  /// 블록 지속 시간 (분)
  int get durationMinutes => endMinute - startMinute;

  TimeboxBlock copyWith({
    String? id,
    DateTime? date,
    int? startMinute,
    int? endMinute,
    String? title,
    String? description,
    String? categoryId,
    String? routineId,
    String? brainDumpItemId,
  }) {
    return TimeboxBlock(
      id: id ?? this.id,
      date: date ?? this.date,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      routineId: routineId ?? this.routineId,
      brainDumpItemId: brainDumpItemId ?? this.brainDumpItemId,
    );
  }

  @override
  String toString() =>
      'TimeboxBlock(id: $id, date: $date, $startMinute–$endMinute, title: $title)';
}

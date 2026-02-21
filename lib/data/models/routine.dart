import 'package:hive/hive.dart';

part 'routine.g.dart';

/// 루틴 모델 - 반복 등록 항목
///
/// 루틴을 일정에 추가할 때 TimeboxBlock으로 변환됨.
///
/// typeId: 2
@HiveType(typeId: 2)
class Routine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  /// 기본 지속 시간 (분) - 더 이상 사용되지 않음, Hive 호환성 유지
  @HiveField(2)
  int durationMinutes;

  /// 연결된 카테고리 ID - 더 이상 사용되지 않음, Hive 호환성 유지
  @HiveField(3)
  String? categoryId;

  @HiveField(4)
  String? description;

  Routine({
    required this.id,
    required this.title,
    this.durationMinutes = 0,
    this.categoryId,
    this.description,
  });

  Routine copyWith({
    String? id,
    String? title,
    int? durationMinutes,
    String? categoryId,
    String? description,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Routine(id: $id, title: $title)';
}

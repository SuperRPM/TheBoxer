import 'package:hive/hive.dart';

part 'brain_dump_item.g.dart';

/// 브레인 덤핑 항목 모델
///
/// typeId: 4
@HiveType(typeId: 4)
class BrainDumpItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  bool isChecked;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  bool isStarred;

  @HiveField(5)
  bool isCancelled;

  BrainDumpItem({
    required this.id,
    required this.content,
    this.isChecked = false,
    required this.createdAt,
    this.isStarred = false,
    this.isCancelled = false,
  });
}

import 'package:hive/hive.dart';

part 'category.g.dart';

/// 카테고리 모델
/// typeId: 1
@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  /// Color.value (ARGB integer)
  @HiveField(2)
  int colorValue;

  Category({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}

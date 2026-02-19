import 'dart:async';
import 'package:hive/hive.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/data/repositories/category_repository.dart';

/// Hive 기반 CategoryRepository 구현체
class HiveCategoryRepository implements CategoryRepository {
  Box<Category> get _box =>
      Hive.box<Category>(AppConstants.categoryBoxName);

  @override
  Future<List<Category>> getAllCategories() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveCategory(Category category) async {
    await _box.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<Category>> watchCategories() {
    final controller = StreamController<List<Category>>();

    // 초기값 즉시 발행
    controller.add(_box.values.toList());

    // Hive 변경 감지 후 새 목록 발행
    final subscription = _box.watch().listen((_) {
      if (!controller.isClosed) {
        controller.add(_box.values.toList());
      }
    });

    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

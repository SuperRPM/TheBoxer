import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/local/hive_category_repository.dart';
import 'package:timebox_planner/data/local/hive_timebox_repository.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/repositories/category_repository.dart';

/// CategoryRepository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return HiveCategoryRepository();
});

/// 카테고리 목록 실시간 스트림 Provider
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategories();
});

/// 카테고리 CRUD Notifier
class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repo;
  final HiveTimeboxRepository _timeboxRepo;

  CategoryNotifier(this._repo, this._timeboxRepo)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repo.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(Category category) async {
    await _repo.saveCategory(category);
    await _load();
  }

  Future<void> updateCategory(Category category) async {
    await _repo.saveCategory(category);
    await _load();
  }

  /// 카테고리 삭제 시 해당 categoryId를 사용 중인 타임박스의 categoryId를 null로 업데이트
  Future<void> deleteCategory(String id) async {
    // 연결된 타임박스의 categoryId를 null로 초기화
    // copyWith는 null을 전달해도 기존값 유지이므로 직접 생성
    final allBlocks = await _timeboxRepo.getAllBlocks();
    for (final block in allBlocks) {
      if (block.categoryId == id) {
        final updated = TimeboxBlock(
          id: block.id,
          date: block.date,
          startMinute: block.startMinute,
          endMinute: block.endMinute,
          title: block.title,
          description: block.description,
          categoryId: null,
          routineId: block.routineId,
        );
        await _timeboxRepo.saveBlock(updated);
      }
    }
    await _repo.deleteCategory(id);
    await _load();
  }

  Future<void> refresh() async {
    await _load();
  }
}

/// 카테고리 Notifier Provider
final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>(
  (ref) {
    final repo = ref.watch(categoryRepositoryProvider);
    final timeboxRepo = HiveTimeboxRepository();
    return CategoryNotifier(repo, timeboxRepo);
  },
);

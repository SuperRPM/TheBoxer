import '../models/category.dart';

/// 카테고리 저장소 인터페이스
abstract class CategoryRepository {
  /// 모든 카테고리 조회
  Future<List<Category>> getAllCategories();

  /// 카테고리 저장 (신규 또는 수정)
  Future<void> saveCategory(Category category);

  /// 카테고리 삭제 (연결된 타임박스의 categoryId는 null로 처리)
  Future<void> deleteCategory(String id);

  /// 카테고리 변경 스트림 (실시간 감지)
  Stream<List<Category>> watchCategories();
}

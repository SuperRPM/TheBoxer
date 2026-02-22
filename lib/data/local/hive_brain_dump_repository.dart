import 'package:hive/hive.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/brain_dump_item.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// Hive 기반 브레인 덤핑 저장소
class HiveBrainDumpRepository {
  Box<BrainDumpItem> get _box =>
      Hive.box<BrainDumpItem>(AppConstants.brainDumpBoxName);

  /// 모든 항목 조회 (생성 시간 역순)
  List<BrainDumpItem> getAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// 항목 저장 (신규 또는 업데이트)
  Future<void> save(BrainDumpItem item) async {
    await _box.put(item.id, item);
  }

  /// 항목 삭제
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// 체크 상태 토글
  Future<void> toggle(String id) async {
    final item = _box.get(id);
    if (item == null) return;
    item.isChecked = !item.isChecked;
    await item.save();
  }

  /// 별표 상태 토글
  Future<void> toggleStar(String id) async {
    final item = _box.get(id);
    if (item == null) return;
    item.isStarred = !item.isStarred;
    await item.save();
  }

  /// 날짜가 바뀌었으면 모든 항목 삭제 (다음날 초기화)
  Future<void> clearAllIfNewDay() async {
    final settingsBox = Hive.box<dynamic>(AppConstants.settingsBoxName);
    final today = TimeUtils.dateOnly(DateTime.now());
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastReset = settingsBox.get(AppConstants.lastBrainDumpResetKey, defaultValue: '') as String;
    if (lastReset != todayKey) {
      await _box.clear();
      await settingsBox.put(AppConstants.lastBrainDumpResetKey, todayKey);
    }
  }
}

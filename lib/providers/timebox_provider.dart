import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/local/hive_timebox_repository.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/repositories/timebox_repository.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 눈금 단위 Provider (설정 상태 저장)
final timeUnitProvider = StateNotifierProvider<TimeUnitNotifier, TimeUnit>(
  (ref) => TimeUnitNotifier(),
);

class TimeUnitNotifier extends StateNotifier<TimeUnit> {
  TimeUnitNotifier() : super(_loadFromHive());

  static TimeUnit _loadFromHive() {
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    final saved = box.get(AppConstants.timeUnitSettingKey, defaultValue: 0) as int;
    if (saved < 0 || saved >= TimeUnit.values.length) return TimeUnit.oneHour;
    return TimeUnit.values[saved];
  }

  Future<void> setUnit(TimeUnit unit) async {
    state = unit;
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    await box.put(AppConstants.timeUnitSettingKey, unit.index);
  }
}

/// TimeboxRepository Provider
final timeboxRepositoryProvider = Provider<TimeboxRepository>((ref) {
  return HiveTimeboxRepository();
});

/// 선택된 날짜 Provider
final selectedDateProvider = StateProvider<DateTime>(
  (ref) => TimeUtils.dateOnly(DateTime.now()),
);

/// 날짜별 타임박스 블록 목록 Provider
final timeboxBlocksProvider =
    FutureProvider.family<List<TimeboxBlock>, DateTime>((ref, date) async {
  final repo = ref.watch(timeboxRepositoryProvider);
  return repo.getBlocksByDate(date);
});

/// 타임박스 CRUD Notifier
class TimeboxNotifier
    extends StateNotifier<AsyncValue<List<TimeboxBlock>>> {
  final TimeboxRepository _repo;
  final DateTime _date;

  TimeboxNotifier(this._repo, this._date)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final blocks = await _repo.getBlocksByDate(_date);
      state = AsyncValue.data(blocks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBlock(TimeboxBlock block) async {
    await _repo.saveBlock(block);
    await _load();
  }

  Future<void> updateBlock(TimeboxBlock block) async {
    await _repo.saveBlock(block);
    await _load();
  }

  Future<void> deleteBlock(String id) async {
    await _repo.deleteBlock(id);
    await _load();
  }

  /// 루틴에서 타임박스 블록 생성 (시간 범위는 사용자가 직접 지정)
  Future<void> addFromRoutine(
      Routine routine, DateTime date, int startMinute, int endMinute) async {
    final block = TimeboxBlock(
      id: const Uuid().v4(),
      date: TimeUtils.dateOnly(date),
      startMinute: startMinute,
      endMinute: endMinute,
      title: routine.title,
      description: routine.description,
      routineId: routine.id,
    );
    await addBlock(block);
  }

  /// 현재 상태 새로고침
  Future<void> refresh() async {
    await _load();
  }
}

/// 날짜별 타임박스 Notifier Provider
final timeboxNotifierProvider = StateNotifierProvider.family<TimeboxNotifier,
    AsyncValue<List<TimeboxBlock>>, DateTime>(
  (ref, date) {
    final repo = ref.watch(timeboxRepositoryProvider);
    return TimeboxNotifier(repo, date);
  },
);

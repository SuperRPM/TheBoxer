import 'package:hive/hive.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/repositories/timebox_repository.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// Hive 기반 TimeboxRepository 구현체
class HiveTimeboxRepository implements TimeboxRepository {
  Box<TimeboxBlock> get _box =>
      Hive.box<TimeboxBlock>(AppConstants.timeboxBoxName);

  @override
  Future<List<TimeboxBlock>> getBlocksByDate(DateTime date) async {
    final dateOnly = TimeUtils.dateOnly(date);
    return _box.values
        .where((b) => TimeUtils.isSameDay(b.date, dateOnly))
        .toList()
      ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  }

  @override
  Future<List<TimeboxBlock>> getAllBlocks() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveBlock(TimeboxBlock block) async {
    await _box.put(block.id, block);
  }

  @override
  Future<void> deleteBlock(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<TimeboxBlock>> watchBlocksByDate(DateTime date) {
    final dateOnly = TimeUtils.dateOnly(date);
    return _box.watch().map(
      (_) => _box.values
          .where((b) => TimeUtils.isSameDay(b.date, dateOnly))
          .toList()
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute)),
    );
  }
}

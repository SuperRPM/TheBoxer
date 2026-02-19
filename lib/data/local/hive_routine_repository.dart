import 'dart:async';
import 'package:hive/hive.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/repositories/routine_repository.dart';

/// Hive 기반 RoutineRepository 구현체
class HiveRoutineRepository implements RoutineRepository {
  Box<Routine> get _box =>
      Hive.box<Routine>(AppConstants.routineBoxName);

  @override
  Future<List<Routine>> getAllRoutines() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveRoutine(Routine routine) async {
    await _box.put(routine.id, routine);
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await _box.delete(id);
  }

  @override
  Stream<List<Routine>> watchRoutines() {
    final controller = StreamController<List<Routine>>();

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

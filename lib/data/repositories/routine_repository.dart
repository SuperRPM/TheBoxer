import '../models/routine.dart';

/// 루틴 저장소 인터페이스
abstract class RoutineRepository {
  /// 모든 루틴 조회
  Future<List<Routine>> getAllRoutines();

  /// 루틴 저장 (신규 또는 수정)
  Future<void> saveRoutine(Routine routine);

  /// 루틴 삭제
  Future<void> deleteRoutine(String id);

  /// 루틴 변경 스트림 (실시간 감지)
  Stream<List<Routine>> watchRoutines();
}

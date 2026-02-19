import '../models/timebox_block.dart';

/// 타임박스 블록 저장소 인터페이스
abstract class TimeboxRepository {
  /// 특정 날짜의 모든 타임박스 블록 조회
  Future<List<TimeboxBlock>> getBlocksByDate(DateTime date);

  /// 모든 타임박스 블록 조회
  Future<List<TimeboxBlock>> getAllBlocks();

  /// 타임박스 블록 저장 (신규 또는 수정)
  Future<void> saveBlock(TimeboxBlock block);

  /// 타임박스 블록 삭제
  Future<void> deleteBlock(String id);

  /// 특정 날짜의 타임박스 블록 스트림 (실시간 감지)
  Stream<List<TimeboxBlock>> watchBlocksByDate(DateTime date);
}

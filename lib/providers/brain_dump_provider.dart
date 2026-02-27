import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/local/hive_brain_dump_repository.dart';
import 'package:timebox_planner/data/models/brain_dump_item.dart';

final brainDumpRepositoryProvider = Provider<HiveBrainDumpRepository>((ref) {
  return HiveBrainDumpRepository();
});

/// 브레인 덤핑 목록 Notifier
class BrainDumpNotifier extends StateNotifier<List<BrainDumpItem>> {
  final HiveBrainDumpRepository _repo;

  BrainDumpNotifier(this._repo) : super([]) {
    _initWithReset();
  }

  Future<void> _initWithReset() async {
    await _repo.clearAllIfNewDay();
    _load();
  }

  void _load() {
    state = _repo.getAll();
  }

  Future<void> add(String content) async {
    final item = BrainDumpItem(
      id: const Uuid().v4(),
      content: content,
      createdAt: DateTime.now(),
    );
    await _repo.save(item);
    _load();
  }

  Future<void> toggle(String id) async {
    await _repo.toggle(id);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> toggleStar(String id) async {
    // 별표 추가 시 기존 별표 항목이 5개 미만인지 확인
    final item = state.firstWhere((i) => i.id == id, orElse: () => throw Exception());
    final starredCount = state.where((i) => i.isStarred).length;
    if (!item.isStarred && starredCount >= 5) return; // 최대 5개 제한
    await _repo.toggleStar(id);
    _load();
  }

  Future<void> cancel(String id) async {
    await _repo.cancel(id);
    _load();
  }
}

final brainDumpProvider =
    StateNotifierProvider<BrainDumpNotifier, List<BrainDumpItem>>((ref) {
  final repo = ref.watch(brainDumpRepositoryProvider);
  return BrainDumpNotifier(repo);
});

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
}

final brainDumpProvider =
    StateNotifierProvider<BrainDumpNotifier, List<BrainDumpItem>>((ref) {
  final repo = ref.watch(brainDumpRepositoryProvider);
  return BrainDumpNotifier(repo);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/models/brain_dump_item.dart';
import 'package:timebox_planner/providers/brain_dump_provider.dart';

/// 태스크 화면
class BrainDumpScreen extends ConsumerStatefulWidget {
  const BrainDumpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends ConsumerState<BrainDumpScreen> {
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(brainDumpProvider.notifier).add(text);
    _inputCtrl.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(brainDumpProvider);
    final starred = items.where((i) => i.isStarred && !i.isCancelled).toList();
    final pending = items.where((i) => !i.isChecked && !i.isStarred && !i.isCancelled).toList();
    final checked = items.where((i) => i.isChecked && !i.isStarred && !i.isCancelled).toList();
    final cancelled = items.where((i) => i.isCancelled).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('태스크'),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // 빠른 입력창
            _QuickInput(
              controller: _inputCtrl,
              focusNode: _focusNode,
              onAdd: _add,
            ),
            const Divider(height: 1),

            // 목록
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        // ── 별표 섹션 (최대 5개) ──
                        if (starred.isNotEmpty) ...[
                          _SectionLabel(
                            icon: Icons.star,
                            color: Colors.amber.shade600,
                            label: '중요 (${starred.length}/5)',
                          ),
                          ...starred.map((item) => _BrainDumpTile(
                                key: ValueKey('star_${item.id}'),
                                item: item,
                                onToggle: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .toggle(item.id),
                                onDelete: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .delete(item.id),
                                onToggleStar: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .toggleStar(item.id),
                                onCancel: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .cancel(item.id),
                              )),
                          const Divider(height: 8),
                        ],

                        // ── 일반 목록 ──
                        if (pending.isNotEmpty) ...[
                          if (starred.isNotEmpty)
                            const _SectionLabel(
                              icon: Icons.inbox_outlined,
                              color: Colors.grey,
                              label: '할 일',
                            ),
                          ...pending.map((item) => _BrainDumpTile(
                                key: ValueKey(item.id),
                                item: item,
                                onToggle: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .toggle(item.id),
                                onDelete: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .delete(item.id),
                                onToggleStar: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .toggleStar(item.id),
                                onCancel: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .cancel(item.id),
                              )),
                        ],

                        // ── 완료 목록 ──
                        if (checked.isNotEmpty) ...[
                          const Divider(height: 8),
                          const _SectionLabel(
                            icon: Icons.check_circle_outline,
                            color: Colors.grey,
                            label: '완료',
                          ),
                          ...checked.map((item) => _BrainDumpTile(
                                key: ValueKey('done_${item.id}'),
                                item: item,
                                onToggle: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .toggle(item.id),
                                onDelete: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .delete(item.id),
                                onToggleStar: null,
                                onCancel: null,
                              )),
                        ],

                        // ── 취소 목록 ──
                        if (cancelled.isNotEmpty) ...[
                          const Divider(height: 8),
                          const _SectionLabel(
                            icon: Icons.cancel_outlined,
                            color: Colors.grey,
                            label: '취소됨',
                          ),
                          ...cancelled.map((item) => _CancelledTile(
                                key: ValueKey('cancel_${item.id}'),
                                item: item,
                                onDelete: () => ref
                                    .read(brainDumpProvider.notifier)
                                    .delete(item.id),
                              )),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 섹션 레이블
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _SectionLabel({
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 상단 빠른 입력창
// ─────────────────────────────────────────────
class _QuickInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;

  const _QuickInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          hintText: '태스크를 입력하고 엔터...',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onAdd(),
      ),
    );
  }
}

/// 빈 상태 안내
class _EmptyState extends StatelessWidget {
  const _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '태스크를 자유롭게 추가하세요',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '시간표에서 시간을 배치할 수 있어요',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 브레인 덤핑 항목 타일
// ─────────────────────────────────────────────
class _BrainDumpTile extends StatelessWidget {
  final BrainDumpItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onToggleStar; // null이면 별표 버튼 숨김 (완료 항목)
  final VoidCallback? onCancel;

  const _BrainDumpTile({
    Key? key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onToggleStar,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${item.id}_${item.isStarred}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.content,
          style: TextStyle(
            decoration: item.isChecked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.isChecked ? Colors.grey : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onToggleStar != null)
              IconButton(
                icon: Icon(
                  item.isStarred ? Icons.star : Icons.star_border,
                  color: item.isStarred ? Colors.amber.shade600 : Colors.grey,
                  size: 22,
                ),
                tooltip: item.isStarred ? '별표 해제' : '별표 등록',
                onPressed: onToggleStar,
              ),
            if (onCancel != null)
              IconButton(
                icon: Icon(Icons.cancel_outlined, size: 20, color: Colors.grey.shade400),
                tooltip: '취소',
                onPressed: onCancel,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 취소된 항목 타일
// ─────────────────────────────────────────────
class _CancelledTile extends StatelessWidget {
  final BrainDumpItem item;
  final VoidCallback onDelete;

  const _CancelledTile({
    Key? key,
    required this.item,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_cancel_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: const Icon(Icons.cancel_outlined, size: 20, color: Colors.grey),
        title: Text(
          item.content,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

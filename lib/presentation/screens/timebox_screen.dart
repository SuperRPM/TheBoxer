import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/providers/brain_dump_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/presentation/widgets/routine/routine_selector_widget.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 타임박스 생성/편집 화면 (바텀시트)
class TimeboxScreen extends ConsumerStatefulWidget {
  final TimeboxBlock? existingBlock;
  final DateTime? initialDate;
  final int? initialStartMinute;
  final String? initialTitle;
  /// 저장 성공 시 호출되는 콜백 (예: 브레인덤프 항목 체크 처리)
  final VoidCallback? onSaved;

  const TimeboxScreen({
    Key? key,
    this.existingBlock,
    this.initialDate,
    this.initialStartMinute,
    this.initialTitle,
    this.onSaved,
  }) : super(key: key);

  static Future<void> showCreate(
    BuildContext context, {
    required DateTime date,
    int startMinute = 540,
    String? initialTitle,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimeboxScreen(
        initialDate: date,
        initialStartMinute: startMinute,
        initialTitle: initialTitle,
        onSaved: onSaved,
      ),
    );
  }

  static Future<void> showEdit(BuildContext context,
      {required TimeboxBlock block}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimeboxScreen(existingBlock: block),
    );
  }

  @override
  ConsumerState<TimeboxScreen> createState() => _TimeboxScreenState();
}

class _TimeboxScreenState extends ConsumerState<TimeboxScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late int _startMinute;
  late int _endMinute;
  String? _routineId;
  bool _isLoading = false;

  bool get _isEdit => widget.existingBlock != null;

  @override
  void initState() {
    super.initState();
    final block = widget.existingBlock;
    if (block != null) {
      _titleCtrl = TextEditingController(text: block.title);
      _descCtrl = TextEditingController(text: block.description ?? '');
      _startMinute = block.startMinute;
      _endMinute = block.endMinute;
      _routineId = block.routineId;
    } else {
      _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
      _descCtrl = TextEditingController();
      _startMinute = widget.initialStartMinute ?? 540;
      // 기본 종료 시간 = 시작 + 현재 TimeUnit 단위
      final timeUnit = ref.read(timeUnitProvider);
      _endMinute = _startMinute + (timeUnit.minuteInterval);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startMinute >= _endMinute) {
      _showError('종료 시간은 시작 시간보다 늦어야 합니다.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final date = widget.existingBlock?.date ??
          widget.initialDate ??
          TimeUtils.dateOnly(DateTime.now());
      final block = TimeboxBlock(
        id: widget.existingBlock?.id ?? const Uuid().v4(),
        date: date,
        startMinute: _startMinute,
        endMinute: _endMinute,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        routineId: _routineId,
      );
      final notifier = ref.read(timeboxNotifierProvider(date).notifier);
      if (_isEdit) {
        await notifier.updateBlock(block);
      } else {
        await notifier.addBlock(block);
      }
      if (mounted) {
        widget.onSaved?.call(); // 저장 완료 콜백 (브레인덤프 체크 등)
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('타임박스 삭제'),
        content: const Text('이 타임박스를 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      final block = widget.existingBlock!;
      await ref
          .read(timeboxNotifierProvider(block.date).notifier)
          .deleteBlock(block.id);
      // 브레인덤핑에서 배치된 블록이면 미완료 상태로 복구
      if (block.brainDumpItemId != null) {
        final items = ref.read(brainDumpProvider);
        final item = items.where((i) => i.id == block.brainDumpItemId).firstOrNull;
        if (item != null && item.isChecked) {
          await ref.read(brainDumpProvider.notifier).toggle(block.brainDumpItemId!);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('삭제 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  /// 드럼롤 시간 선택기 호출 (TimeUnit 단위로 분 스냅)
  Future<void> _pickTime({required bool isStart}) async {
    final timeUnit = ref.read(timeUnitProvider);
    final current = isStart ? _startMinute : _endMinute;
    final picked = await showWheelTimePicker(
      context,
      initialMinute: current,
      snapInterval: timeUnit.minuteInterval,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startMinute = picked;
        if (_endMinute <= _startMinute) {
          _endMinute = _startMinute + (timeUnit.minuteInterval);
        }
      } else {
        _endMinute = picked;
      }
    });
  }

  void _applyRoutine(Routine routine) {
    setState(() {
      _titleCtrl.text = routine.title;
      _descCtrl.text = routine.description ?? '';
      // 시간은 사용자가 직접 설정 (루틴에 사전 시간 없음)
      _routineId = routine.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // 테마 변경 감지 유지

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Row(
                children: [
                  Text(_isEdit ? '타임박스 편집' : '새 타임박스',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 루틴 선택
              RoutineSelectorWidget(onRoutineSelected: _applyRoutine),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // 제목
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목 *',
                  hintText: '타임박스 제목 입력',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '제목을 입력해 주세요.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // 시간 선택 (드럼롤 피커)
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: '시작 시간',
                      minute: _startMinute,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, size: 18, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePicker(
                      label: '종료 시간',
                      minute: _endMinute,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 저장 / 삭제
              Row(
                children: [
                  if (_isEdit) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _delete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('삭제',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isEdit ? '수정 저장' : '저장'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 시간 표시 버튼 위젯
// ─────────────────────────────────────────────
class _TimePicker extends StatelessWidget {
  final String label;
  final int minute;
  final VoidCallback onTap;

  const _TimePicker(
      {Key? key, required this.label, required this.minute, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              TimeUtils.minutesToTimeString(minute),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 드럼롤 시간 선택기
// ─────────────────────────────────────────────

/// [snapInterval] 분 단위로 minutes 목록 생성 (00:00~23:59 범위 내)
Future<int?> showWheelTimePicker(
  BuildContext context, {
  required int initialMinute,
  int snapInterval = 10,
}) {
  return showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _WheelTimePicker(
      initialMinute: initialMinute,
      snapInterval: snapInterval,
    ),
  );
}

class _WheelTimePicker extends StatefulWidget {
  final int initialMinute;
  final int snapInterval;

  const _WheelTimePicker({
    Key? key,
    required this.initialMinute,
    required this.snapInterval,
  }) : super(key: key);

  @override
  State<_WheelTimePicker> createState() => _WheelTimePickerState();
}

class _WheelTimePickerState extends State<_WheelTimePicker> {
  late int _hour;
  late int _minuteIndex;
  late List<int> _minuteOptions;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    _minuteOptions = _buildMinuteOptions(widget.snapInterval);
    _hour = widget.initialMinute ~/ 60;
    final rawMin = widget.initialMinute % 60;
    // 가장 가까운 스냅 인덱스
    _minuteIndex = _nearestIndex(rawMin);
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minCtrl = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  List<int> _buildMinuteOptions(int interval) {
    final opts = <int>[];
    for (int m = 0; m < 60; m += interval) {
      opts.add(m);
    }
    return opts;
  }

  int _nearestIndex(int rawMin) {
    int best = 0;
    int bestDiff = 999;
    for (int i = 0; i < _minuteOptions.length; i++) {
      final diff = (_minuteOptions[i] - rawMin).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    return best;
  }

  int get _selectedTotalMinute =>
      _hour * 60 + _minuteOptions[_minuteIndex];

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 타이틀 + 완료
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('시간 선택',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, _selectedTotalMinute),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),

          // 두 휠 (시 | : | 분)
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // 시 휠 (0~23)
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: _hourCtrl,
                    itemExtent: 44,
                    onSelectedItemChanged: (i) =>
                        setState(() => _hour = i),
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.003,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 24,
                      builder: (ctx, i) => _WheelItem(
                        label: i.toString().padLeft(2, '0'),
                        selected: i == _hour,
                        color: color,
                      ),
                    ),
                  ),
                ),

                // 구분자
                Text(':',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color)),

                // 분 휠 (snapInterval 단위)
                Expanded(
                  child: ListWheelScrollView(
                    controller: _minCtrl,
                    itemExtent: 44,
                    onSelectedItemChanged: (i) =>
                        setState(() => _minuteIndex = i),
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.003,
                    children: _minuteOptions.asMap().entries.map((e) {
                      return _WheelItem(
                        label: e.value.toString().padLeft(2, '0'),
                        selected: e.key == _minuteIndex,
                        color: color,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _WheelItem extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;

  const _WheelItem({
    Key? key,
    required this.label,
    required this.selected,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: selected ? 26 : 20,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}


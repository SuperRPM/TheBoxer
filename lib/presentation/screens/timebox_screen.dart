import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/providers/category_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/presentation/widgets/category/category_chip_widget.dart';
import 'package:timebox_planner/presentation/widgets/routine/routine_selector_widget.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 타임박스 생성/편집 화면 (바텀시트 또는 풀스크린 다이얼로그)
///
/// 사용 예시:
/// ```dart
/// // 새 블록 생성
/// TimeboxScreen.showCreate(context, date: selectedDate, startMinute: 540);
/// // 기존 블록 편집
/// TimeboxScreen.showEdit(context, block: existingBlock);
/// ```
class TimeboxScreen extends ConsumerStatefulWidget {
  /// 편집할 기존 블록 (null이면 새 블록 생성)
  final TimeboxBlock? existingBlock;

  /// 새 블록의 기본 날짜
  final DateTime? initialDate;

  /// 새 블록의 기본 시작 분
  final int? initialStartMinute;

  const TimeboxScreen({
    Key? key,
    this.existingBlock,
    this.initialDate,
    this.initialStartMinute,
  }) : super(key: key);

  /// 새 타임박스 생성 바텀시트
  static Future<void> showCreate(
    BuildContext context, {
    required DateTime date,
    int startMinute = 540,
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
      ),
    );
  }

  /// 기존 타임박스 편집 바텀시트
  static Future<void> showEdit(
    BuildContext context, {
    required TimeboxBlock block,
  }) {
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
  String? _categoryId;
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
      _categoryId = block.categoryId;
      _routineId = block.routineId;
    } else {
      _titleCtrl = TextEditingController();
      _descCtrl = TextEditingController();
      _startMinute = widget.initialStartMinute ?? 540; // 기본 09:00
      _endMinute = _startMinute + 60; // 기본 1시간
      _categoryId = null;
      _routineId = null;
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
        categoryId: _categoryId,
        routineId: _routineId,
      );

      final notifier =
          ref.read(timeboxNotifierProvider(date).notifier);
      if (_isEdit) {
        await notifier.updateBlock(block);
      } else {
        await notifier.addBlock(block);
      }

      if (mounted) Navigator.pop(context);
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
            child: const Text('취소'),
          ),
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
      final date = widget.existingBlock!.date;
      await ref
          .read(timeboxNotifierProvider(date).notifier)
          .deleteBlock(widget.existingBlock!.id);
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

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: (isStart ? _startMinute : _endMinute) ~/ 60,
      minute: (isStart ? _startMinute : _endMinute) % 60,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final totalMin = picked.hour * 60 + picked.minute;
    setState(() {
      if (isStart) {
        _startMinute = totalMin;
        if (_endMinute <= _startMinute) {
          _endMinute = _startMinute + 30;
        }
      } else {
        _endMinute = totalMin;
      }
    });
  }

  /// 루틴 선택 시 필드 자동 채움
  void _applyRoutine(Routine routine) {
    setState(() {
      _titleCtrl.text = routine.title;
      _descCtrl.text = routine.description ?? '';
      _endMinute = _startMinute + routine.durationMinutes;
      _categoryId = routine.categoryId;
      _routineId = routine.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isColorMode = ref.watch(themeProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.when(
      data: (list) => list,
      loading: () => <Category>[],
      error: (_, __) => <Category>[],
    );

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
                  Text(
                    _isEdit ? '타임박스 편집' : '새 타임박스',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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

              // 시간 선택
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
              const SizedBox(height: 12),

              // 카테고리 선택
              const Text(
                '카테고리',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                const Text(
                  '카테고리 없음 (카테고리 화면에서 추가)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 미지정 칩
                    GestureDetector(
                      onTap: () => setState(() => _categoryId = null),
                      child: Chip(
                        label: const Text('미지정'),
                        backgroundColor: _categoryId == null
                            ? Colors.grey.shade300
                            : Colors.grey.shade100,
                        side: BorderSide(
                          color: _categoryId == null
                              ? Colors.grey
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      return CategoryChipWidget(
                        category: cat,
                        isSelected: _categoryId == cat.id,
                        isColorMode: isColorMode,
                        onTap: () => setState(() => _categoryId = cat.id),
                      );
                    }).toList(),
                  ],
                ),
              const SizedBox(height: 12),

              // 설명
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: '설명 (선택)',
                  hintText: '메모나 설명을 입력하세요',
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // 저장 / 삭제 버튼
              Row(
                children: [
                  if (_isEdit) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _delete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        '삭제',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
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

/// 시간 선택 버튼 위젯
class _TimePicker extends StatelessWidget {
  final String label;
  final int minute;
  final VoidCallback onTap;

  const _TimePicker({
    Key? key,
    required this.label,
    required this.minute,
    required this.onTap,
  }) : super(key: key);

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

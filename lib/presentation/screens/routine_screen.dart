import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/providers/routine_provider.dart';
import 'package:timebox_planner/providers/category_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/presentation/widgets/category/category_chip_widget.dart';
import 'package:timebox_planner/utils/color_utils.dart';

/// 루틴 목록 조회 및 관리 화면
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isColorMode = ref.watch(themeProvider);

    final categoryMap = categoriesAsync.when(
      data: (list) => {for (final c in list) c.id: c},
      loading: () => <String, Category>{},
      error: (_, __) => <String, Category>{},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        automaticallyImplyLeading: false,
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    '등록된 루틴이 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '+ 버튼을 눌러 루틴을 추가해 보세요.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: routines.length,
            itemBuilder: (ctx, i) {
              final routine = routines[i];
              final category = routine.categoryId != null
                  ? categoryMap[routine.categoryId]
                  : null;
              return _RoutineCard(
                routine: routine,
                category: category,
                isColorMode: isColorMode,
                onEdit: () => _showDialog(context, ref,
                    existing: routine, categoryMap: categoryMap),
                onDelete: () => _confirmDelete(context, ref, routine),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('루틴 로드 오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final categoryMap = categoriesAsync.when(
            data: (list) => {for (final c in list) c.id: c},
            loading: () => <String, Category>{},
            error: (_, __) => <String, Category>{},
          );
          _showDialog(context, ref, categoryMap: categoryMap);
        },
        tooltip: '루틴 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text('"${routine.title}" 루틴을 삭제하시겠습니까?'),
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
    if (confirmed == true) {
      await ref.read(routineNotifierProvider.notifier).deleteRoutine(routine.id);
    }
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    Routine? existing,
    required Map<String, Category> categoryMap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoutineDialog(
        existing: existing,
        categoryMap: categoryMap,
      ),
    );
  }
}

/// 루틴 카드 위젯
class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final Category? category;
  final bool isColorMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoutineCard({
    Key? key,
    required this.routine,
    required this.category,
    required this.isColorMode,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color chipColor = Colors.blueGrey.shade200;
    if (category != null) {
      final raw = ColorUtils.fromValue(category!.colorValue);
      chipColor = ColorUtils.adaptiveColor(raw, isColorMode: isColorMode);
    }

    return Dismissible(
      key: ValueKey(routine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // 직접 삭제 처리
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: chipColor.withOpacity(0.2),
            child: Icon(Icons.repeat, color: chipColor, size: 20),
          ),
          title: Text(
            routine.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기본 시간: ${routine.durationMinutes}분',
                style: const TextStyle(fontSize: 12),
              ),
              if (category != null)
                Text(
                  category!.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: chipColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}

/// 루틴 추가/편집 다이얼로그 (바텀시트)
class _RoutineDialog extends ConsumerStatefulWidget {
  final Routine? existing;
  final Map<String, Category> categoryMap;

  const _RoutineDialog({
    Key? key,
    this.existing,
    required this.categoryMap,
  }) : super(key: key);

  @override
  ConsumerState<_RoutineDialog> createState() => _RoutineDialogState();
}

class _RoutineDialogState extends ConsumerState<_RoutineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _durationCtrl;
  String? _categoryId;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _durationCtrl =
        TextEditingController(text: r?.durationMinutes.toString() ?? '60');
    _categoryId = r?.categoryId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final duration = int.tryParse(_durationCtrl.text.trim()) ?? 60;
      final routine = Routine(
        id: widget.existing?.id ?? const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        durationMinutes: duration,
        categoryId: _categoryId,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      final notifier = ref.read(routineNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.updateRoutine(routine);
      } else {
        await notifier.addRoutine(routine);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 오류: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isColorMode = ref.watch(themeProvider);
    final categories = widget.categoryMap.values.toList();

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
                    _isEdit ? '루틴 편집' : '새 루틴',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 제목
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: '루틴 이름 *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '이름을 입력해 주세요.' : null,
              ),
              const SizedBox(height: 12),

              // 기본 시간
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: '기본 시간 (분) *',
                  suffixText: '분',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return '양수를 입력해 주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 카테고리 선택
              const Text(
                '카테고리',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _categoryId = null),
                    child: Chip(
                      label: const Text('미지정'),
                      backgroundColor: _categoryId == null
                          ? Colors.grey.shade300
                          : Colors.grey.shade100,
                    ),
                  ),
                  ...categories.map((cat) => CategoryChipWidget(
                        category: cat,
                        isSelected: _categoryId == cat.id,
                        isColorMode: isColorMode,
                        onTap: () =>
                            setState(() => _categoryId = cat.id),
                      )),
                ],
              ),
              const SizedBox(height: 12),

              // 설명
              TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(labelText: '설명 (선택)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
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
        ),
      ),
    );
  }
}

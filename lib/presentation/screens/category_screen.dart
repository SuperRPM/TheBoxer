import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/providers/category_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/presentation/widgets/category/category_color_picker_widget.dart';
import 'package:timebox_planner/utils/color_utils.dart';

/// 카테고리 목록 조회 및 관리 화면
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isColorMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리'),
        automaticallyImplyLeading: false,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.label, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    '등록된 카테고리가 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '+ 버튼을 눌러 카테고리를 추가해 보세요.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return _CategoryCard(
                category: cat,
                isColorMode: isColorMode,
                onEdit: () => _showDialog(context, ref, existing: cat),
                onDelete: () => _confirmDelete(context, ref, cat),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('카테고리 로드 오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, ref),
        tooltip: '카테고리 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text(
          '"${category.name}" 카테고리를 삭제하시겠습니까?\n'
          '해당 카테고리를 사용하는 타임박스의 카테고리가 미지정으로 변경됩니다.',
        ),
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
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);
    }
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryDialog(existing: existing),
    );
  }
}

/// 카테고리 카드 위젯
class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool isColorMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    Key? key,
    required this.category,
    required this.isColorMode,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rawColor = ColorUtils.fromValue(category.colorValue);
    final displayColor =
        ColorUtils.adaptiveColor(rawColor, isColorMode: isColorMode);

    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: displayColor.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            '#${category.colorValue.toRadixString(16).toUpperCase().padLeft(8, '0')}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontFamily: 'monospace',
            ),
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

/// 카테고리 추가/편집 다이얼로그 (바텀시트)
class _CategoryDialog extends ConsumerStatefulWidget {
  final Category? existing;

  const _CategoryDialog({Key? key, this.existing}) : super(key: key);

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late int _selectedColorValue;
  bool _isLoading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColorValue = widget.existing?.colorValue ??
        AppConstants.defaultCategoryColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final category = Category(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        colorValue: _selectedColorValue,
      );
      final notifier = ref.read(categoryNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.updateCategory(category);
      } else {
        await notifier.addCategory(category);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = ColorUtils.fromValue(_selectedColorValue);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
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
                    _isEdit ? '카테고리 편집' : '새 카테고리',
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

              // 미리보기
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: '카테고리 이름 *',
                        hintText: '예: 업무, 운동, 학습',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? '이름을 입력해 주세요.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 색상 선택
              const Text(
                '색상 선택',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              CategoryColorPickerWidget(
                selectedColorValue: _selectedColorValue,
                onColorSelected: (v) =>
                    setState(() => _selectedColorValue = v),
              ),
              const SizedBox(height: 24),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

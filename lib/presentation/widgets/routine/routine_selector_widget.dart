import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/providers/routine_provider.dart';
import 'package:timebox_planner/providers/category_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/utils/color_utils.dart';

/// 루틴을 선택하여 타임박스 필드를 자동 채우는 위젯
class RoutineSelectorWidget extends ConsumerWidget {
  /// 루틴 선택 시 호출되는 콜백
  final void Function(Routine routine) onRoutineSelected;

  const RoutineSelectorWidget({
    Key? key,
    required this.onRoutineSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final isColorMode = ref.watch(themeProvider);

    final categories = categoriesAsync.when(
      data: (list) => {for (final c in list) c.id: c},
      loading: () => <String, Category>{},
      error: (_, __) => <String, Category>{},
    );

    return routinesAsync.when(
      data: (routines) {
        if (routines.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '등록된 루틴이 없습니다.\n루틴 화면에서 먼저 루틴을 추가해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '루틴에서 불러오기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: routines.map((routine) {
                final category = routine.categoryId != null
                    ? categories[routine.categoryId!]
                    : null;

                Color chipColor = Colors.blueGrey;
                if (category != null) {
                  final raw = ColorUtils.fromValue(category.colorValue);
                  chipColor = ColorUtils.adaptiveColor(
                    raw,
                    isColorMode: isColorMode,
                  );
                }

                return ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: chipColor,
                    radius: 10,
                  ),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        routine.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${routine.durationMinutes}분',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () => onRoutineSelected(routine),
                  backgroundColor: chipColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: chipColor.withOpacity(0.4)),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Text('루틴 로드 오류: $e'),
    );
  }
}

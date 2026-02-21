import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/providers/routine_provider.dart';

/// 루틴을 선택하여 타임박스 필드를 자동 채우는 위젯
class RoutineSelectorWidget extends ConsumerWidget {
  final void Function(Routine routine) onRoutineSelected;

  const RoutineSelectorWidget({
    Key? key,
    required this.onRoutineSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);

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
                return ActionChip(
                  avatar: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    radius: 10,
                    child: Icon(Icons.repeat, size: 12, color: Colors.white),
                  ),
                  label: Text(
                    routine.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => onRoutineSelected(routine),
                  backgroundColor: Colors.blueGrey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.blueGrey.withOpacity(0.4)),
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

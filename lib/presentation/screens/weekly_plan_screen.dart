import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/models/weekly_plan.dart';
import 'package:timebox_planner/providers/weekly_plan_provider.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 주간 계획/목표 입력 화면
///
/// - 현재 주의 날짜 범위 표시
/// - 주간 메모 텍스트필드
/// - 목표 체크리스트 (추가/삭제)
/// - 저장 버튼
class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends ConsumerState<WeeklyPlanScreen> {
  final _contentCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final List<String> _goals = [];
  bool _isLoading = false;
  bool _initialized = false;
  WeeklyPlan? _currentPlan;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _initFromPlan(WeeklyPlan? plan) {
    if (_initialized) return;
    _initialized = true;
    if (plan != null) {
      _currentPlan = plan;
      _contentCtrl.text = plan.content;
      _goals
        ..clear()
        ..addAll(plan.goals);
    }
  }

  void _addGoal() {
    final text = _goalCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _goals.add(text);
      _goalCtrl.clear();
    });
  }

  void _removeGoal(int index) {
    setState(() => _goals.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final weekStart = TimeUtils.getWeekStartDate(DateTime.now());
      final plan = WeeklyPlan(
        id: _currentPlan?.id ?? const Uuid().v4(),
        weekStartDate: weekStart,
        content: _contentCtrl.text.trim(),
        goals: List.from(_goals),
      );
      await ref.read(weeklyPlanNotifierProvider.notifier).savePlan(plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주간 플랜이 저장되었습니다.')),
        );
      }
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

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final startDay = weekdays[weekStart.weekday - 1];
    final endDay = weekdays[weekEnd.weekday - 1];
    return '${weekStart.month}월 ${weekStart.day}일($startDay) ~ '
        '${weekEnd.month}월 ${weekEnd.day}일($endDay)';
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(currentWeeklyPlanProvider);
    final weekStart = TimeUtils.getWeekStartDate(DateTime.now());
    final weekRangeLabel = _formatWeekRange(weekStart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('주간 플랜'),
        automaticallyImplyLeading: false,
      ),
      body: planAsync.when(
        data: (plan) {
          _initFromPlan(plan);
          return _buildBody(weekRangeLabel);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildBody(weekRangeLabel),
      ),
    );
  }

  Widget _buildBody(String weekRangeLabel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 주간 날짜 범위
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Text(
                  weekRangeLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 주간 메모
        const Text(
          '주간 메모',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '이번 주의 계획, 목표, 메모를 자유롭게 작성하세요.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),

        // 목표 체크리스트 헤더
        Row(
          children: [
            const Text(
              '목표 체크리스트',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_goals.length}개',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 목표 입력 필드
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _goalCtrl,
                decoration: const InputDecoration(
                  hintText: '새 목표 입력',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addGoal(),
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              child: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 목표 목록
        if (_goals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '아직 목표가 없습니다.\n목표를 추가해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _goals.removeAt(oldIndex);
                _goals.insert(newIndex, item);
              });
            },
            itemBuilder: (ctx, index) {
              return _GoalItem(
                key: ValueKey(_goals[index] + index.toString()),
                text: _goals[index],
                index: index,
                onDelete: () => _removeGoal(index),
              );
            },
          ),

        const SizedBox(height: 24),

        // 저장 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('저장'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 목표 항목 위젯
class _GoalItem extends StatelessWidget {
  final String text;
  final int index;
  final VoidCallback onDelete;

  const _GoalItem({
    Key? key,
    required this.text,
    required this.index,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 12,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(text, style: const TextStyle(fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

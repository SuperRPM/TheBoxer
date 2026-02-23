import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/models/weekly_plan.dart';
import 'package:timebox_planner/providers/weekly_plan_provider.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 주간 계획/목표 입력 화면 (심플 버전)
class WeeklyPlanScreen extends ConsumerStatefulWidget {
  const WeeklyPlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends ConsumerState<WeeklyPlanScreen> {
  final _contentCtrl = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;
  WeeklyPlan? _currentPlan;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _initFromPlan(WeeklyPlan? plan) {
    if (_initialized) return;
    _initialized = true;
    if (plan != null) {
      _currentPlan = plan;
      _contentCtrl.text = plan.content;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final weekStart = TimeUtils.getWeekStartDate(DateTime.now());
      final plan = WeeklyPlan(
        id: _currentPlan?.id ?? const Uuid().v4(),
        weekStartDate: weekStart,
        content: _contentCtrl.text.trim(),
        goals: _currentPlan?.goals ?? [],
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
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '이번 주의 계획, 목표, 메모를 자유롭게 작성하세요.',
            border: OutlineInputBorder(),
          ),
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

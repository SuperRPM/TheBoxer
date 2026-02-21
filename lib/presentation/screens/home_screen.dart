import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:timebox_planner/data/models/brain_dump_item.dart';
import 'package:timebox_planner/data/models/routine.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/providers/brain_dump_provider.dart';
import 'package:timebox_planner/providers/placement_provider.dart';
import 'package:timebox_planner/providers/routine_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/providers/weekly_plan_provider.dart';
import 'package:timebox_planner/presentation/screens/timebox_screen.dart';
import 'package:timebox_planner/presentation/screens/weekly_plan_screen.dart';
import 'package:timebox_planner/presentation/screens/routine_screen.dart';
import 'package:timebox_planner/presentation/screens/brain_dump_screen.dart';
import 'package:timebox_planner/presentation/widgets/timebox_calendar/timebox_calendar_widget.dart';
import 'package:timebox_planner/utils/time_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeContent(),
      const BrainDumpScreen(),
      const WeeklyPlanScreen(),
      const RoutineScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: '브레인덤핑',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_week_outlined),
            selectedIcon: Icon(Icons.view_week),
            label: '주간',
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            selectedIcon: Icon(Icons.repeat),
            label: '루틴',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 홈 탭 본문
// ─────────────────────────────────────────────
class _HomeContent extends ConsumerWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final timeUnit = ref.watch(timeUnitProvider);
    final isColorMode = ref.watch(themeProvider);
    final isToday = TimeUtils.isToday(selectedDate);
    final placement = ref.watch(placementProvider);

    return Scaffold(
      appBar: AppBar(
        title: _DateNavigator(
          selectedDate: selectedDate,
          onPrev: () => ref.read(selectedDateProvider.notifier).state =
              selectedDate.subtract(const Duration(days: 1)),
          onNext: () => ref.read(selectedDateProvider.notifier).state =
              selectedDate.add(const Duration(days: 1)),
          onToday: () => ref.read(selectedDateProvider.notifier).state =
              TimeUtils.dateOnly(DateTime.now()),
          isToday: isToday,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _TimeUnitDropdown(
              selected: timeUnit,
              onChanged: (u) => ref.read(timeUnitProvider.notifier).setUnit(u),
            ),
          ),
          IconButton(
            icon: Icon(
              isColorMode ? Icons.palette_outlined : Icons.invert_colors,
              size: 22,
            ),
            tooltip: isColorMode ? '흑백 모드' : '컬러 모드',
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          // 브레인덤핑 빠른 추가 버튼
          IconButton(
            icon: const Icon(Icons.bolt, size: 22),
            tooltip: '브레인덤핑 추가',
            onPressed: () => _showBrainDumpQuickAdd(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 배치 모드 배너
          if (placement != null)
            _PlacementBanner(
              placement: placement,
              onCancel: () =>
                  ref.read(placementProvider.notifier).clearPlacement(),
            ),

          // 주간 목표 (한 줄 바)
          const _WeeklyGoalBar(),

          // 브레인덤프 인박스 스트립 (미완료 항목 목록, 접기/펼치기)
          _BrainDumpInboxStrip(selectedDate: selectedDate),

          // 구분선
          const Divider(height: 1),

          // 캘린더 (남은 공간 모두 사용)
          Expanded(
            child: TimeboxCalendarWidget(
              selectedDate: selectedDate,
              onTapToCreate: (m) =>
                  TimeboxScreen.showCreate(context, date: selectedDate, startMinute: m),
              onTapBlock: (b) => TimeboxScreen.showEdit(context, block: b),
              onPlacementComplete: (start, end) =>
                  _handlePlacementComplete(context, ref, selectedDate, start, end),
            ),
          ),
        ],
      ),
      // FAB: 브레인덤핑 + 루틴 목록 보기 (배치 모드 진입)
      floatingActionButton: placement == null
          ? FloatingActionButton(
              onPressed: () => _showPlacementSheet(context, ref),
              tooltip: '할 일 목록',
              child: const Icon(Icons.inbox),
            )
          : null,
    );
  }

  /// 배치 완료: 타임박스 생성 + 브레인덤프 체크
  Future<void> _handlePlacementComplete(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    int startMinute,
    int endMinute,
  ) async {
    final placement = ref.read(placementProvider);
    if (placement == null) return;

    final block = TimeboxBlock(
      id: const Uuid().v4(),
      date: TimeUtils.dateOnly(date),
      startMinute: startMinute,
      endMinute: endMinute,
      title: placement.title,
      description: placement.description,
      routineId: placement.type == PendingItemType.routine ? placement.itemId : null,
    );

    await ref.read(timeboxNotifierProvider(date).notifier).addBlock(block);

    // 브레인덤프 항목이면 완료 처리
    if (placement.type == PendingItemType.brainDump) {
      await ref.read(brainDumpProvider.notifier).toggle(placement.itemId);
    }

    ref.read(placementProvider.notifier).clearPlacement();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('배치 완료: ${placement.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 브레인덤핑 + 루틴 목록 바텀시트
  void _showPlacementSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _PlacementSheet(
        onBrainDumpSelected: (item) {
          Navigator.pop(sheetCtx);
          ref.read(placementProvider.notifier).startPlacement(
            itemId: item.id,
            title: item.content,
            type: PendingItemType.brainDump,
          );
        },
        onRoutineSelected: (routine) {
          Navigator.pop(sheetCtx);
          ref.read(placementProvider.notifier).startPlacement(
            itemId: routine.id,
            title: routine.title,
            description: routine.description,
            type: PendingItemType.routine,
          );
        },
      ),
    );
  }

  /// 브레인덤핑 빠른 추가 다이얼로그
  void _showBrainDumpQuickAdd(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('브레인덤핑 추가'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '생각을 입력하세요...',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final text = ctrl.text.trim();
            if (text.isNotEmpty) {
              ref.read(brainDumpProvider.notifier).add(text);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                ref.read(brainDumpProvider.notifier).add(text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 배치 모드 배너
// ─────────────────────────────────────────────
class _PlacementBanner extends StatelessWidget {
  final PendingPlacement placement;
  final VoidCallback onCancel;

  const _PlacementBanner({
    Key? key,
    required this.placement,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasStart = placement.startMinute != null;
    final msg = hasStart
        ? '종료 시간을 선택하세요'
        : '시작 시간을 선택하세요';

    return Material(
      color: Colors.blue.shade700,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    placement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 배치 항목 선택 바텀시트
// ─────────────────────────────────────────────
class _PlacementSheet extends ConsumerWidget {
  final void Function(BrainDumpItem) onBrainDumpSelected;
  final void Function(Routine) onRoutineSelected;

  const _PlacementSheet({
    Key? key,
    required this.onBrainDumpSelected,
    required this.onRoutineSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brainItems = ref.watch(brainDumpProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final pending = brainItems.where((i) => !i.isChecked).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        return Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.inbox_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '캘린더에 배치할 항목 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // 브레인덤핑 섹션
                  _SectionHeader(
                    icon: Icons.lightbulb_outline,
                    title: '브레인덤핑',
                    count: pending.length,
                  ),
                  if (pending.isEmpty)
                    const _EmptySection(message: '미완료 항목이 없습니다.')
                  else
                    ...pending.map((item) => ListTile(
                          leading: const Icon(Icons.circle_outlined, size: 14),
                          title: Text(item.content,
                              style: const TextStyle(fontSize: 14)),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () => onBrainDumpSelected(item),
                        )),

                  const Divider(height: 24),

                  // 루틴 섹션
                  routinesAsync.when(
                    data: (routines) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.repeat,
                            title: '루틴',
                            count: routines.length,
                          ),
                          if (routines.isEmpty)
                            const _EmptySection(message: '등록된 루틴이 없습니다.')
                          else
                            ...routines.map((routine) => ListTile(
                                  leading: const Icon(Icons.repeat,
                                      size: 18, color: Colors.blueGrey),
                                  title: Text(routine.title,
                                      style: const TextStyle(fontSize: 14)),
                                  subtitle: routine.description != null
                                      ? Text(routine.description!,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)
                                      : null,
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Colors.grey),
                                  onTap: () => onRoutineSelected(routine),
                                )),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('오류: $e'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    Key? key,
    required this.icon,
    required this.title,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 주간 목표 — 한 줄 심플 바
// ─────────────────────────────────────────────
class _WeeklyGoalBar extends ConsumerWidget {
  const _WeeklyGoalBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentWeeklyPlanProvider);
    return planAsync.when(
      data: (plan) {
        final content = plan?.content.trim() ?? '';
        if (content.isEmpty) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
            ),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
          ),
          child: Text(
            '🎯 $content',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────
// 브레인덤프 인박스 스트립 (접기/펼치기)
// ─────────────────────────────────────────────
class _BrainDumpInboxStrip extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  const _BrainDumpInboxStrip({Key? key, required this.selectedDate})
      : super(key: key);

  @override
  ConsumerState<_BrainDumpInboxStrip> createState() =>
      _BrainDumpInboxStripState();
}

class _BrainDumpInboxStripState
    extends ConsumerState<_BrainDumpInboxStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(brainDumpProvider);
    final pending = items.where((i) => !i.isChecked).toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final color = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 헤더 탭
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: color.withOpacity(0.07),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  '할 일 ${pending.length}개',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ),
        ),

        // 확장 시 항목 목록
        if (_expanded)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            color: color.withOpacity(0.04),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: pending.length,
              itemBuilder: (ctx, i) {
                final item = pending[i];
                return _InboxItem(
                  item: item,
                  onSchedule: () => _startPlacement(item),
                );
              },
            ),
          ),
      ],
    );
  }

  void _startPlacement(BrainDumpItem item) {
    // 접기
    setState(() => _expanded = false);
    // 배치 모드 진입
    ref.read(placementProvider.notifier).startPlacement(
      itemId: item.id,
      title: item.content,
      type: PendingItemType.brainDump,
    );
  }
}

class _InboxItem extends StatelessWidget {
  final BrainDumpItem item;
  final VoidCallback onSchedule;

  const _InboxItem({Key? key, required this.item, required this.onSchedule})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle_outlined, size: 10, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.content,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          TextButton.icon(
            onPressed: onSchedule,
            icon: const Icon(Icons.place_outlined, size: 14),
            label: const Text('배치', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 날짜 네비게이터
// ─────────────────────────────────────────────
class _DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrev, onNext, onToday;
  final bool isToday;

  const _DateNavigator({
    Key? key,
    required this.selectedDate,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.isToday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[selectedDate.weekday - 1];
    final label = '${selectedDate.month}월 ${selectedDate.day}일 ($weekday)';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: onPrev,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
        ),
        GestureDetector(
          onTap: onToday,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              if (!isToday) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('오늘로',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: onNext,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 눈금 단위 드롭다운
// ─────────────────────────────────────────────
class _TimeUnitDropdown extends StatelessWidget {
  final TimeUnit selected;
  final ValueChanged<TimeUnit> onChanged;

  const _TimeUnitDropdown(
      {Key? key, required this.selected, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<TimeUnit>(
      value: selected,
      onChanged: (v) => v != null ? onChanged(v) : null,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      underline: const SizedBox.shrink(),
      dropdownColor: Theme.of(context).primaryColor,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      selectedItemBuilder: (ctx) => TimeUnit.values
          .map((u) => Center(
                child: Text(u.displayLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ))
          .toList(),
      items: TimeUnit.values
          .map((u) => DropdownMenuItem<TimeUnit>(
                value: u,
                child: Text(u.displayLabel,
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
    );
  }
}

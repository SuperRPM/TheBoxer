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
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/providers/weekly_plan_provider.dart';
import 'package:timebox_planner/presentation/screens/settings_screen.dart';
import 'package:timebox_planner/presentation/screens/timebox_screen.dart';
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
      const RoutineScreen(),
      const SettingsScreen(),
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
            label: '시간표',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: '태스크',
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            selectedIcon: Icon(Icons.repeat),
            label: '루틴',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 홈 탭 본문
// ─────────────────────────────────────────────
class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  bool _isOverviewMode = false;
  bool _isSplitView = false;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final timeUnit = ref.watch(timeUnitProvider);
    final isToday = TimeUtils.isToday(selectedDate);
    final placement = ref.watch(placementProvider);

    final calendarWidget = TimeboxCalendarWidget(
      selectedDate: selectedDate,
      onTapToCreate: (startMinute) =>
          _showPlacementSheet(initialStartMinute: startMinute),
      onTapBlock: (b) => TimeboxScreen.showEdit(context, block: b),
      onPlacementComplete: (start, end) =>
          _handlePlacementComplete(selectedDate, start, end),
      isOverviewMode: _isOverviewMode,
    );

    return Scaffold(
      appBar: AppBar(
        title: _DateNavigator(
          selectedDate: selectedDate,
          onPickDate: (date) =>
              ref.read(selectedDateProvider.notifier).state = date,
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
          // 한눈에 보기 (오버뷰) 버튼
          IconButton(
            icon: Icon(
              _isOverviewMode
                  ? Icons.view_list_outlined
                  : Icons.view_compact_outlined,
              size: 22,
            ),
            tooltip: _isOverviewMode ? '스크롤 보기' : '한눈에 보기',
            onPressed: () =>
                setState(() => _isOverviewMode = !_isOverviewMode),
          ),
          // 스플릿 뷰 버튼
          IconButton(
            icon: Icon(
              _isSplitView ? Icons.view_agenda_outlined : Icons.vertical_split,
              size: 22,
            ),
            tooltip: _isSplitView ? '일반 보기' : '스플릿 뷰',
            onPressed: () => setState(() => _isSplitView = !_isSplitView),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -300) {
            // 왼쪽 스와이프 → 다음 날
            ref.read(selectedDateProvider.notifier).state =
                selectedDate.add(const Duration(days: 1));
          } else if (v > 300) {
            // 오른쪽 스와이프 → 이전 날
            ref.read(selectedDateProvider.notifier).state =
                selectedDate.subtract(const Duration(days: 1));
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // 배치 모드 배너
            if (placement != null)
              _PlacementBanner(
                placement: placement,
                onCancel: () =>
                    ref.read(placementProvider.notifier).clearPlacement(),
              ),

            // 메모 (한 줄 바, 탭하면 편집)
            const _MemoBar(),

            // 스플릿 뷰가 아닐 때만 인박스 스트립 표시
            if (!_isSplitView)
              _BrainDumpInboxStrip(selectedDate: selectedDate),

            // 구분선
            const Divider(height: 1),

            // 캘린더 (스플릿 뷰: 좌우 분할)
            Expanded(
              child: _isSplitView
                  ? Row(
                      children: [
                        Expanded(flex: 3, child: calendarWidget),
                        const VerticalDivider(width: 1, thickness: 1),
                        SizedBox(
                          width: 160,
                          child: _SplitViewTaskPanel(
                            selectedDate: selectedDate,
                            onBrainDumpSelected: (item) =>
                                ref.read(placementProvider.notifier).startPlacement(
                                  itemId: item.id,
                                  title: item.content,
                                  type: PendingItemType.brainDump,
                                ),
                            onRoutineSelected: (routine) =>
                                ref.read(placementProvider.notifier).startPlacement(
                                  itemId: routine.id,
                                  title: routine.title,
                                  description: routine.description,
                                  type: PendingItemType.routine,
                                ),
                          ),
                        ),
                      ],
                    )
                  : calendarWidget,
            ),
          ],
        ),
      ),
      // FAB: 배치 모드가 아닐 때만 표시
      floatingActionButton: placement == null
          ? FloatingActionButton(
              onPressed: _showPlacementSheet,
              tooltip: '할 일 목록',
              child: const Icon(Icons.inbox),
            )
          : null,
    );
  }

  Future<void> _handlePlacementComplete(
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
      routineId:
          placement.type == PendingItemType.routine ? placement.itemId : null,
      brainDumpItemId:
          placement.type == PendingItemType.brainDump ? placement.itemId : null,
    );

    await ref.read(timeboxNotifierProvider(date).notifier).addBlock(block);

    if (placement.type == PendingItemType.brainDump) {
      await ref.read(brainDumpProvider.notifier).toggle(placement.itemId);
    }

    ref.read(placementProvider.notifier).clearPlacement();
  }

  void _showPlacementSheet({int? initialStartMinute}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _PlacementSheet(
        initialStartMinute: initialStartMinute,
        onBrainDumpSelected: (item) {
          Navigator.pop(sheetCtx);
          ref.read(placementProvider.notifier).startPlacement(
            itemId: item.id,
            title: item.content,
            type: PendingItemType.brainDump,
            initialStartMinute: initialStartMinute,
          );
        },
        onRoutineSelected: (routine) {
          Navigator.pop(sheetCtx);
          ref.read(placementProvider.notifier).startPlacement(
            itemId: routine.id,
            title: routine.title,
            description: routine.description,
            type: PendingItemType.routine,
            initialStartMinute: initialStartMinute,
          );
        },
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
class _PlacementSheet extends ConsumerStatefulWidget {
  final void Function(BrainDumpItem) onBrainDumpSelected;
  final void Function(Routine) onRoutineSelected;
  final int? initialStartMinute;

  const _PlacementSheet({
    Key? key,
    required this.onBrainDumpSelected,
    required this.onRoutineSelected,
    this.initialStartMinute,
  }) : super(key: key);

  @override
  ConsumerState<_PlacementSheet> createState() => _PlacementSheetState();
}

class _PlacementSheetState extends ConsumerState<_PlacementSheet> {
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addBrainDump() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(brainDumpProvider.notifier).add(text);
    _inputCtrl.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final brainItems = ref.watch(brainDumpProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final blocksAsync = ref.watch(timeboxNotifierProvider(selectedDate));
    final pending = brainItems.where((i) => !i.isChecked).toList();

    // 오늘 시간표에 등록된 루틴별 횟수 집계
    final scheduledRoutineCounts = blocksAsync.when(
      data: (blocks) {
        final counts = <String, int>{};
        for (final b in blocks) {
          if (b.routineId != null) {
            counts[b.routineId!] = (counts[b.routineId!] ?? 0) + 1;
          }
        }
        return counts;
      },
      loading: () => <String, int>{},
      error: (_, __) => <String, int>{},
    );

    // 타이틀: 셀 탭으로 열린 경우 시작 시간 표시
    final sheetTitle = widget.initialStartMinute != null
        ? '${TimeUtils.minutesToTimeString(widget.initialStartMinute!)}부터 배치할 태스크 선택'
        : '캘린더에 배치할 태스크 선택';

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
                  Expanded(
                    child: Text(
                      sheetTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // 태스크 빠른 입력창
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: '새 태스크 추가...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  prefixIcon: Icon(Icons.add, size: 18),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addBrainDump(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // 태스크 섹션
                  _SectionHeader(
                    icon: Icons.task_outlined,
                    title: '태스크',
                    count: pending.length,
                  ),
                  if (pending.isEmpty)
                    const _EmptySection(message: '태스크가 없습니다.')
                  else
                    ...pending.map((item) => ListTile(
                          leading: const Icon(Icons.circle_outlined, size: 14),
                          title: Text(item.content,
                              style: const TextStyle(fontSize: 14)),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.grey),
                          onTap: () => widget.onBrainDumpSelected(item),
                        )),

                  const Divider(height: 24),

                  // 루틴 섹션 (오늘 이미 배치된 루틴 제외)
                  routinesAsync.when(
                    data: (routines) {
                      final available = routines.where((r) {
                        final scheduled =
                            scheduledRoutineCounts[r.id] ?? 0;
                        return scheduled < r.repeatCount;
                      }).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.repeat,
                            title: '루틴',
                            count: available.length,
                          ),
                          if (available.isEmpty)
                            const _EmptySection(message: '배치 가능한 루틴이 없습니다.')
                          else
                            ...available.map((routine) => ListTile(
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
                                  onTap: () => widget.onRoutineSelected(routine),
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
// 메모 바 — 탭하면 편집 가능
// ─────────────────────────────────────────────
class _MemoBar extends ConsumerWidget {
  const _MemoBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weeklyPlanNotifierProvider);
    return planAsync.when(
      data: (plan) {
        final content = plan?.content.trim() ?? '';
        return GestureDetector(
          onTap: () => _showMemoDialog(context, ref, plan),
          child: Container(
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
            child: Row(
              children: [
                Icon(Icons.note_alt_outlined, size: 13,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    content.isEmpty ? '메모 추가...' : content,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          content.isEmpty ? FontWeight.w400 : FontWeight.w500,
                      color: content.isEmpty ? Colors.grey : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.edit_outlined,
                    size: 12, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showMemoDialog(
      BuildContext context, WidgetRef ref, dynamic plan) async {
    final ctrl = TextEditingController(text: plan?.content ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '메모를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(weeklyPlanNotifierProvider.notifier)
                  .saveMemo(ctrl.text.trim(), plan);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    ctrl.dispose();
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
    // 오늘 탭에는 별표 표시된 미완료 항목만 표시
    final pending = items.where((i) => i.isStarred && !i.isChecked).toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final color = Colors.amber.shade700;

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
                Icon(Icons.star, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  '중요 ${pending.length}개',
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
  final void Function(DateTime) onPickDate;
  final bool isToday;

  const _DateNavigator({
    Key? key,
    required this.selectedDate,
    required this.onPickDate,
    required this.isToday,
  }) : super(key: key);

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPickDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[selectedDate.weekday - 1];
    final label = '${selectedDate.month}월 ${selectedDate.day}일 ($weekday)';

    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.calendar_month_outlined,
                  size: 14, color: Colors.white70),
            ],
          ),
          if (!isToday)
            GestureDetector(
              onTap: () => onPickDate(TimeUtils.dateOnly(DateTime.now())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('오늘로',
                    style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ),
        ],
      ),
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

// ─────────────────────────────────────────────
// 스플릿 뷰 오른쪽 패널: 태스크 목록
// ─────────────────────────────────────────────
class _SplitViewTaskPanel extends ConsumerWidget {
  final DateTime selectedDate;
  final void Function(BrainDumpItem) onBrainDumpSelected;
  final void Function(Routine) onRoutineSelected;

  const _SplitViewTaskPanel({
    Key? key,
    required this.selectedDate,
    required this.onBrainDumpSelected,
    required this.onRoutineSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brainItems = ref.watch(brainDumpProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final blocksAsync = ref.watch(timeboxNotifierProvider(selectedDate));
    final pending = brainItems.where((i) => !i.isChecked).toList();

    final scheduledRoutineCounts = blocksAsync.when(
      data: (blocks) {
        final counts = <String, int>{};
        for (final b in blocks) {
          if (b.routineId != null) {
            counts[b.routineId!] = (counts[b.routineId!] ?? 0) + 1;
          }
        }
        return counts;
      },
      loading: () => <String, int>{},
      error: (_, __) => <String, int>{},
    );

    final primaryColor = Theme.of(context).primaryColor;

    void showAddBrainDumpDialog() {
      final ctrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('태스크 추가', style: TextStyle(fontSize: 16)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '내용을 입력하세요',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                ref.read(brainDumpProvider.notifier).add(v.trim());
                Navigator.pop(ctx);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref.read(brainDumpProvider.notifier).add(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ).then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
      });
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          // 태스크 섹션
          InkWell(
            onTap: showAddBrainDumpDialog,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Row(
                children: [
                  Icon(Icons.task_outlined, size: 13, color: primaryColor),
                  const SizedBox(width: 4),
                  Text('태스크',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryColor)),
                  const Spacer(),
                  Icon(Icons.add, size: 14, color: primaryColor),
                ],
              ),
            ),
          ),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text('없음',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            )
          else
            ...pending.map((item) => InkWell(
                  onTap: () => onBrainDumpSelected(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.circle_outlined,
                            size: 10, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(item.content,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                )),

          const Divider(height: 16),

          // 루틴 섹션
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            child: Row(
              children: [
                Icon(Icons.repeat, size: 13, color: primaryColor),
                const SizedBox(width: 4),
                Text('루틴',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColor)),
              ],
            ),
          ),
          routinesAsync.when(
            data: (routines) {
              final available = routines.where((r) {
                final scheduled = scheduledRoutineCounts[r.id] ?? 0;
                return scheduled < r.repeatCount;
              }).toList();
              if (available.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text('없음',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                );
              }
              return Column(
                children: available
                    .map((r) => InkWell(
                          onTap: () => onRoutineSelected(r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Row(
                              children: [
                                const Icon(Icons.repeat,
                                    size: 12, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(r.title,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

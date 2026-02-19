import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/presentation/screens/timebox_screen.dart';
import 'package:timebox_planner/presentation/screens/weekly_plan_screen.dart';
import 'package:timebox_planner/presentation/screens/routine_screen.dart';
import 'package:timebox_planner/presentation/screens/category_screen.dart';
import 'package:timebox_planner/presentation/widgets/timebox_calendar/timebox_calendar_widget.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 메인 홈 화면
///
/// - 상단 AppBar: 날짜 네비게이션 + 눈금 단위 선택
/// - 중앙: TimeboxCalendarWidget
/// - FAB: 새 타임박스 추가
/// - 하단 NavigationBar: 홈/주간/루틴/카테고리
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;

  final List<Widget> _pages = const [
    _HomeContent(),
    WeeklyPlanScreen(),
    RoutineScreen(),
    CategoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: _pages,
      ),
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
            icon: Icon(Icons.view_week_outlined),
            selectedIcon: Icon(Icons.view_week),
            label: '주간',
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            selectedIcon: Icon(Icons.repeat),
            label: '루틴',
          ),
          NavigationDestination(
            icon: Icon(Icons.label_outlined),
            selectedIcon: Icon(Icons.label),
            label: '카테고리',
          ),
        ],
      ),
    );
  }
}

/// 홈 탭 내용 (날짜 네비게이션 + 캘린더)
class _HomeContent extends ConsumerWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final timeUnit = ref.watch(timeUnitProvider);
    final isColorMode = ref.watch(themeProvider);
    final isToday = TimeUtils.isToday(selectedDate);

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
          // 눈금 단위 드롭다운
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TimeUnitDropdown(
              selected: timeUnit,
              onChanged: (unit) =>
                  ref.read(timeUnitProvider.notifier).setUnit(unit),
            ),
          ),
          // 테마 토글
          IconButton(
            icon: Icon(
              isColorMode ? Icons.palette_outlined : Icons.invert_colors,
              size: 22,
            ),
            tooltip: isColorMode ? '흑백 모드' : '컬러 모드',
            onPressed: () =>
                ref.read(themeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: TimeboxCalendarWidget(
        selectedDate: selectedDate,
        onTapToCreate: (startMinute) => TimeboxScreen.showCreate(
          context,
          date: selectedDate,
          startMinute: startMinute,
        ),
        onTapBlock: (block) => TimeboxScreen.showEdit(
          context,
          block: block,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => TimeboxScreen.showCreate(
          context,
          date: selectedDate,
          startMinute: 540, // 기본: 09:00
        ),
        tooltip: '새 타임박스 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 날짜 네비게이션 위젯 (AppBar title 영역)
class _DateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
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
    // 날짜 포맷: M월 D일 (요일)
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[selectedDate.weekday - 1];
    final dateLabel =
        '${selectedDate.month}월 ${selectedDate.day}일 ($weekday)';

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
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
                  child: const Text(
                    '오늘로',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
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

/// 눈금 단위 드롭다운
class _TimeUnitDropdown extends StatelessWidget {
  final TimeUnit selected;
  final ValueChanged<TimeUnit> onChanged;

  const _TimeUnitDropdown({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<TimeUnit>(
      value: selected,
      onChanged: (v) => v != null ? onChanged(v) : null,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      underline: const SizedBox.shrink(),
      dropdownColor: Theme.of(context).primaryColor,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      selectedItemBuilder: (ctx) => TimeUnit.values.map((unit) {
        return Center(
          child: Text(
            unit.displayLabel,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        );
      }).toList(),
      items: TimeUnit.values.map((unit) {
        return DropdownMenuItem<TimeUnit>(
          value: unit,
          child: Text(
            unit.displayLabel,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
    );
  }
}

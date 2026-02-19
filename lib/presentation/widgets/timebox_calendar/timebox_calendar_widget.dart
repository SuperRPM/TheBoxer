import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/providers/category_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/presentation/widgets/timebox_calendar/time_ruler_widget.dart';
import 'package:timebox_planner/presentation/widgets/timebox_calendar/time_grid_widget.dart';
import 'package:timebox_planner/presentation/widgets/timebox_calendar/timebox_block_widget.dart';

/// 타임박스 캘린더 뷰 전체 컨테이너
///
/// 스크롤 가능한 시간 축 (05:00~24:00) 위에
/// 좌측 TimeRulerWidget + 우측 TimeGridWidget + 블록 오버레이를 렌더링한다.
class TimeboxCalendarWidget extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  /// 탭하여 새 블록 생성 콜백: 탭한 startMinute 전달
  final void Function(int startMinute) onTapToCreate;

  /// 블록 탭하여 편집 콜백
  final void Function(TimeboxBlock block) onTapBlock;

  const TimeboxCalendarWidget({
    Key? key,
    required this.selectedDate,
    required this.onTapToCreate,
    required this.onTapBlock,
  }) : super(key: key);

  @override
  ConsumerState<TimeboxCalendarWidget> createState() =>
      _TimeboxCalendarWidgetState();
}

class _TimeboxCalendarWidgetState
    extends ConsumerState<TimeboxCalendarWidget> {
  final ScrollController _scrollController = ScrollController();

  static const int _startMinute = AppConstants.dayStartMinute; // 300 (05:00)
  static const int _endMinute = AppConstants.dayEndMinute;     // 1440 (24:00)
  static const double _rulerWidth = 52;

  /// TimeUnit 별 pixelsPerMinute
  double _pixelsPerMinute(TimeUnit unit) {
    switch (unit) {
      case TimeUnit.oneHour:
        return 1.0;
      case TimeUnit.thirtyMinutes:
        return 1.5;
      case TimeUnit.tenMinutes:
        return 2.5;
      case TimeUnit.fiveMinutes:
        return 4.0;
      case TimeUnit.morning:
      case TimeUnit.afternoon:
      case TimeUnit.evening:
        return 1.0;
    }
  }

  /// 탭한 Y 오프셋을 분 단위로 변환 (눈금 단위로 스냅)
  int _tapYToMinute(double localY, double ppm, TimeUnit unit) {
    final rawMinute = (localY / ppm + _startMinute).round();
    final clamped =
        rawMinute.clamp(_startMinute, _endMinute - 60); // 최소 60분 공간
    if (unit.isSegment) return clamped;
    final interval = unit.minuteInterval ?? 60;
    // 스냅: interval 단위로 반올림
    final snapped = (clamped / interval).round() * interval;
    return snapped.clamp(_startMinute, _endMinute - interval);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeUnit = ref.watch(timeUnitProvider);
    final isColorMode = ref.watch(themeProvider);
    final blocksAsync =
        ref.watch(timeboxBlocksProvider(widget.selectedDate));
    final categoriesAsync = ref.watch(categoriesProvider);

    final ppm = _pixelsPerMinute(timeUnit);
    final totalHeight = (_endMinute - _startMinute) * ppm;

    // 카테고리 맵 구성
    final categoryMap = categoriesAsync.when(
      data: (list) => {for (final c in list) c.id: c},
      loading: () => <String, Category>{},
      error: (_, __) => <String, Category>{},
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth =
            constraints.maxWidth - _rulerWidth;

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 시간 눈금
                TimeRulerWidget(
                  timeUnit: timeUnit,
                  pixelsPerMinute: ppm,
                ),

                // 우측: 그리드 + 블록 오버레이
                Expanded(
                  child: GestureDetector(
                    onTapDown: (details) {
                      final startMin = _tapYToMinute(
                        details.localPosition.dy,
                        ppm,
                        timeUnit,
                      );
                      widget.onTapToCreate(startMin);
                    },
                    child: SizedBox(
                      width: gridWidth,
                      height: totalHeight,
                      child: Stack(
                        children: [
                          // 배경 그리드
                          TimeGridWidget(
                            timeUnit: timeUnit,
                            pixelsPerMinute: ppm,
                            isColorMode: isColorMode,
                          ),

                          // 블록 오버레이
                          blocksAsync.when(
                            data: (blocks) => _buildBlocks(
                              blocks,
                              categoryMap,
                              isColorMode,
                              ppm,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => Center(
                              child: Text(
                                '블록 로드 오류: $e',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlocks(
    List<TimeboxBlock> blocks,
    Map<String, Category> categoryMap,
    bool isColorMode,
    double ppm,
  ) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: blocks.map((block) {
        final category =
            block.categoryId != null ? categoryMap[block.categoryId] : null;
        return TimeboxBlockWidget(
          key: ValueKey(block.id),
          block: block,
          category: category,
          isColorMode: isColorMode,
          pixelsPerMinute: ppm,
          startMinute: _startMinute,
          onTap: () => widget.onTapBlock(block),
        );
      }).toList(),
    );
  }
}

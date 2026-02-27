import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/providers/placement_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';

/// 타임박스 캘린더 (그리드 레이아웃)
///
/// 1시간 = 1행(Row), 행 안에서 TimeUnit 단위로 열(Column) 분할.
/// isOverviewMode: true이면 스크롤 없이 전체 하루를 한 화면에 표시.
class TimeboxCalendarWidget extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final void Function(int startMinute) onTapToCreate;
  final void Function(TimeboxBlock block) onTapBlock;
  final void Function(int startMinute, int endMinute)? onPlacementComplete;
  final bool isOverviewMode;

  const TimeboxCalendarWidget({
    Key? key,
    required this.selectedDate,
    required this.onTapToCreate,
    required this.onTapBlock,
    this.onPlacementComplete,
    this.isOverviewMode = false,
  }) : super(key: key);

  @override
  ConsumerState<TimeboxCalendarWidget> createState() =>
      _TimeboxCalendarWidgetState();
}

class _TimeboxCalendarWidgetState
    extends ConsumerState<TimeboxCalendarWidget> {
  static const int _startHour = AppConstants.dayStartMinute ~/ 60; // 5
  static const int _endHour = AppConstants.dayEndMinute ~/ 60;     // 24
  static const double _rowHeight = 56.0;

  int? _placementStartMinute;

  void _handleCellTap(int cellMinute) {
    final placement = ref.read(placementProvider);

    if (placement == null) {
      widget.onTapToCreate(cellMinute);
      return;
    }

    final effectiveStartMinute = _placementStartMinute ?? placement.startMinute;

    if (effectiveStartMinute == null) {
      setState(() => _placementStartMinute = cellMinute);
    } else {
      final startMinute = effectiveStartMinute;
      final timeUnit = ref.read(timeUnitProvider);
      final intervalMin = timeUnit.minuteInterval;

      int endMinute = cellMinute + intervalMin;
      if (endMinute <= startMinute) {
        endMinute = startMinute + intervalMin;
      }

      setState(() => _placementStartMinute = null);
      widget.onPlacementComplete?.call(startMinute, endMinute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeUnit = ref.watch(timeUnitProvider);
    final isColorMode = ref.watch(themeProvider);
    final blocksAsync = ref.watch(timeboxNotifierProvider(widget.selectedDate));
    final placement = ref.watch(placementProvider);

    final colsPerHour = 60 ~/ timeUnit.minuteInterval;
    final intervalMin = timeUnit.minuteInterval;
    final totalHours = _endHour - _startHour;

    final blocks = blocksAsync.when(
      data: (b) => b,
      loading: () => <TimeboxBlock>[],
      error: (_, __) => <TimeboxBlock>[],
    );

    ref.listen<PendingPlacement?>(placementProvider, (prev, next) {
      if (next == null && _placementStartMinute != null) {
        setState(() => _placementStartMinute = null);
      }
    });

    _HourRow buildRow(int hour, double rowH, bool compactMode) {
      return _HourRow(
        hour: hour,
        colsPerHour: colsPerHour,
        intervalMin: intervalMin,
        rowHeight: rowH,
        blocks: blocks,
        isColorMode: isColorMode,
        isLast: hour == _endHour - 1,
        isPlacementMode: placement != null,
        placementStartMinute: _placementStartMinute ?? placement?.startMinute,
        onTapCell: _handleCellTap,
        onTapBlock: placement == null ? widget.onTapBlock : (_) {},
        compactMode: compactMode,
      );
    }

    if (widget.isOverviewMode) {
      return LayoutBuilder(
        builder: (ctx, constraints) {
          final rowH = constraints.maxHeight / totalHours;
          final compactMode = rowH < 22;
          return Column(
            children: List.generate(totalHours, (idx) {
              final hour = _startHour + idx;
              return SizedBox(height: rowH, child: buildRow(hour, rowH, compactMode));
            }),
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: totalHours,
      itemBuilder: (ctx, idx) {
        final hour = _startHour + idx;
        return buildRow(hour, _rowHeight, false);
      },
    );
  }
}

// ─────────────────────────────────────────────
// 1시간 행 위젯
// ─────────────────────────────────────────────
class _HourRow extends StatelessWidget {
  final int hour;
  final int colsPerHour;
  final int intervalMin;
  final double rowHeight;
  final List<TimeboxBlock> blocks;
  final bool isColorMode;
  final bool isLast;
  final bool isPlacementMode;
  final int? placementStartMinute;
  final void Function(int) onTapCell;
  final void Function(TimeboxBlock) onTapBlock;
  final bool compactMode;

  const _HourRow({
    Key? key,
    required this.hour,
    required this.colsPerHour,
    required this.intervalMin,
    required this.rowHeight,
    required this.blocks,
    required this.isColorMode,
    required this.isLast,
    required this.isPlacementMode,
    required this.placementStartMinute,
    required this.onTapCell,
    required this.onTapBlock,
    this.compactMode = false,
  }) : super(key: key);

  List<TimeboxBlock> get _overlapping {
    final hStart = hour * 60;
    final hEnd = hStart + 60;
    return blocks
        .where((b) => b.startMinute < hEnd && b.endMinute > hStart)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hStart = hour * 60;
    final hourLabel = '${hour.toString().padLeft(2, '0')}:00';
    final majorColor =
        isColorMode ? const Color(0xFF9E9E9E) : const Color(0xFF757575);
    final minorColor =
        isColorMode ? const Color(0xFFBDBDBD) : const Color(0xFF9E9E9E);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: majorColor, width: isLast ? 0 : 1.0),
        ),
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final totalW = constraints.maxWidth;
          final cellW = totalW / colsPerHour;

          return Stack(
            children: [
              // 수직 구분선
              ...List.generate(colsPerHour - 1, (colIdx) {
                return Positioned(
                  left: cellW * (colIdx + 1),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 0.5, color: minorColor),
                );
              }),

              // 시간 레이블 (컴팩트 모드에서는 숨김)
              if (!compactMode)
                Positioned(
                  left: 3,
                  top: 2,
                  child: Text(
                    hourLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // 배치 모드 하이라이트
              if (isPlacementMode && placementStartMinute != null)
                ..._buildPlacementHighlight(hStart, totalW),

              // 탭 감지 셀
              Row(
                children: List.generate(colsPerHour, (colIdx) {
                  final cellStart = hStart + colIdx * intervalMin;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => onTapCell(cellStart),
                      child: const SizedBox.expand(),
                    ),
                  );
                }),
              ),

              // 블록 세그먼트
              ..._overlapping.map((block) {
                final segStart = max(block.startMinute, hStart);
                final segEnd = min(block.endMinute, hStart + 60);
                final startFrac = (segStart - hStart) / 60.0;
                final endFrac = (segEnd - hStart) / 60.0;

                final left = startFrac * totalW;
                final width = (endFrac - startFrac) * totalW;
                final isFirst = block.startMinute >= hStart;
                final isLast2 = block.endMinute <= hStart + 60;

                return Positioned(
                  left: left + 1,
                  top: compactMode ? 1 : 3,
                  width: width - 2,
                  height: rowHeight - (compactMode ? 2 : 6),
                  child: GestureDetector(
                    onTap: () => onTapBlock(block),
                    child: _BlockSegment(
                      block: block,
                      isColorMode: isColorMode,
                      showTitle: isFirst,
                      isFirst: isFirst,
                      isLast: isLast2,
                      compactMode: compactMode,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPlacementHighlight(int hStart, double totalW) {
    final start = placementStartMinute!;
    final hEnd = hStart + 60;
    if (start < hStart || start >= hEnd) return [];

    final startFrac = (start - hStart) / 60.0;
    final left = startFrac * totalW;
    final width = totalW - left;

    return [
      Positioned(
        left: left,
        top: 0,
        width: width,
        bottom: 0,
        child: Container(
          color: Colors.blue.withOpacity(0.25),
          child: compactMode
              ? null
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue),
                  ),
                ),
        ),
      ),
    ];
  }
}

// ─────────────────────────────────────────────
// 블록 세그먼트
// ─────────────────────────────────────────────
/// 루틴용 파스텔 색상 팔레트 (쿨 톤)
const _kRoutinePalette = [
  Color(0xFFADD8E6), // 파스텔 블루
  Color(0xFF90EE90), // 파스텔 그린
  Color(0xFFDDA0DD), // 파스텔 플럼
  Color(0xFF87CEEB), // 파스텔 스카이
  Color(0xFFB0E0E6), // 파스텔 파우더블루
  Color(0xFFAFEEEE), // 파스텔 터쿼이즈
  Color(0xFFE6E6FA), // 파스텔 라벤더
  Color(0xFF98FB98), // 파스텔 페일그린
];

/// 태스크용 파스텔 색상 팔레트 (웜 톤)
const _kTaskPalette = [
  Color(0xFFFFDAB9), // 파스텔 피치
  Color(0xFFFFB6C1), // 파스텔 핑크
  Color(0xFFFFFACD), // 파스텔 레몬
  Color(0xFFFFE4B5), // 파스텔 모카신
  Color(0xFFFFC0CB), // 파스텔 로즈
  Color(0xFFFFDEAD), // 파스텔 나바호
];

class _BlockSegment extends StatelessWidget {
  final TimeboxBlock block;
  final bool isColorMode;
  final bool showTitle;
  final bool isFirst;
  final bool isLast;
  final bool compactMode;

  const _BlockSegment({
    Key? key,
    required this.block,
    required this.isColorMode,
    required this.showTitle,
    required this.isFirst,
    required this.isLast,
    this.compactMode = false,
  }) : super(key: key);

  Color get _baseColor {
    if (block.routineId != null) {
      // 루틴: routineId 기반 고정 색상
      return _kRoutinePalette[block.routineId!.hashCode.abs() % _kRoutinePalette.length];
    } else {
      // 태스크: brainDumpItemId 또는 id 기반 색상
      final key = block.brainDumpItemId ?? block.id;
      return _kTaskPalette[key.hashCode.abs() % _kTaskPalette.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = isColorMode ? _baseColor : _toGray(_baseColor);
    final bgOpacity = compactMode ? 0.85 : 0.65;
    final bgColor = base.withOpacity(bgOpacity);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white.withOpacity(0.87) : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: base, width: isFirst ? 2.0 : 1.0),
          left: BorderSide(color: base, width: 3.0),
          right: BorderSide(color: base.withOpacity(0.4), width: 0.5),
          bottom: BorderSide(color: base, width: isLast ? 2.0 : 1.0),
        ),
      ),
      padding: compactMode
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      clipBehavior: Clip.hardEdge,
      child: compactMode
          ? null
          : (showTitle
              ? Center(
                  child: Text(
                    block.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Center(
                  child: Container(
                    width: 20,
                    height: 2,
                    color: base.withOpacity(0.6),
                  ),
                )),
    );
  }

  Color _toGray(Color c) {
    final l = (c.computeLuminance() * 255).round().clamp(0, 255);
    return Color.fromARGB(c.alpha, l, l, l);
  }
}



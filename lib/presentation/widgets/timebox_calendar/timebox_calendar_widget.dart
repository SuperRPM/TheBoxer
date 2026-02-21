import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/providers/placement_provider.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 타임박스 캘린더 (그리드 레이아웃)
///
/// 1시간 = 1행(Row), 행 안에서 TimeUnit 단위로 열(Column) 분할.
/// 배치 모드: pendingPlacement != null 일 때 두 번의 탭으로 시간 범위 지정.
class TimeboxCalendarWidget extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final void Function(int startMinute) onTapToCreate;
  final void Function(TimeboxBlock block) onTapBlock;
  /// 배치 모드에서 시간 범위 확정 시 호출 (startMinute, endMinute)
  final void Function(int startMinute, int endMinute)? onPlacementComplete;

  const TimeboxCalendarWidget({
    Key? key,
    required this.selectedDate,
    required this.onTapToCreate,
    required this.onTapBlock,
    this.onPlacementComplete,
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

  // 배치 모드 내부 상태: 시작 시간 선택 완료 여부
  int? _placementStartMinute;

  void _handleCellTap(int cellMinute) {
    final placement = ref.read(placementProvider);

    if (placement == null) {
      // 일반 모드: 타임박스 생성 화면 열기
      widget.onTapToCreate(cellMinute);
      return;
    }

    // 배치 모드
    if (_placementStartMinute == null) {
      // 첫 번째 탭: 시작 시간 설정
      setState(() => _placementStartMinute = cellMinute);
    } else {
      // 두 번째 탭: 종료 시간 결정
      final startMinute = _placementStartMinute!;
      final timeUnit = ref.read(timeUnitProvider);
      final intervalMin = timeUnit.minuteInterval;

      int endMinute = cellMinute;
      // 종료 시간은 시작 시간보다 최소 1 TimeUnit 이후여야 함
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

    final blocks = blocksAsync.when(
      data: (b) => b,
      loading: () => <TimeboxBlock>[],
      error: (_, __) => <TimeboxBlock>[],
    );

    // 배치 모드가 해제되면 내부 시작 시간 초기화
    ref.listen<PendingPlacement?>(placementProvider, (prev, next) {
      if (next == null && _placementStartMinute != null) {
        setState(() => _placementStartMinute = null);
      }
    });

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _endHour - _startHour,
      itemBuilder: (ctx, idx) {
        final hour = _startHour + idx;
        return _HourRow(
          hour: hour,
          colsPerHour: colsPerHour,
          intervalMin: intervalMin,
          rowHeight: _rowHeight,
          blocks: blocks,
          isColorMode: isColorMode,
          isLast: hour == _endHour - 1,
          isPlacementMode: placement != null,
          placementStartMinute: _placementStartMinute,
          onTapCell: _handleCellTap,
          onTapBlock: placement == null ? widget.onTapBlock : (_) {}, // 배치 모드 중 블록 탭 비활성
        );
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
              // 수직 구분선 (sub-interval 구분)
              ...List.generate(colsPerHour - 1, (colIdx) {
                return Positioned(
                  left: cellW * (colIdx + 1),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 0.5,
                    color: minorColor,
                  ),
                );
              }),

              // 시간 레이블 (첫 번째 셀 좌상단 오버레이)
              Positioned(
                left: 3,
                top: 2,
                child: Text(
                  hourLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              // 배치 모드: 시작 시간 선택 셀 하이라이트
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
                  top: 3,
                  width: width - 2,
                  height: rowHeight - 6,
                  child: GestureDetector(
                    onTap: () => onTapBlock(block),
                    child: _BlockSegment(
                      block: block,
                      isColorMode: isColorMode,
                      showTitle: isFirst,
                      isFirst: isFirst,
                      isLast: isLast2,
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

    // 시작 시간이 이 행에 속하는지 확인
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
          child: const Align(
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
// 블록 세그먼트 (행 안에 수평으로 표시)
// ─────────────────────────────────────────────
const _kBlockPalette = [
  Color(0xFF7D1128), // 버건디
  Color(0xFF1A5276), // 딥 블루
  Color(0xFF1D6A41), // 딥 그린
  Color(0xFF784212), // 번트 오렌지
  Color(0xFF4A235A), // 딥 퍼플
];

class _BlockSegment extends StatelessWidget {
  final TimeboxBlock block;
  final bool isColorMode;
  final bool showTitle;
  final bool isFirst;
  final bool isLast;

  const _BlockSegment({
    Key? key,
    required this.block,
    required this.isColorMode,
    required this.showTitle,
    required this.isFirst,
    required this.isLast,
  }) : super(key: key);

  Color get _baseColor {
    return _kBlockPalette[block.id.hashCode.abs() % _kBlockPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final base = isColorMode
        ? _baseColor
        : _toGray(_baseColor);

    final bgColor = base.withOpacity(0.18);
    final effectiveText =
        bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    final startLabel = TimeUtils.minutesToTimeString(block.startMinute);
    final endLabel = TimeUtils.minutesToTimeString(block.endMinute);

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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      clipBehavior: Clip.hardEdge,
      child: showTitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: effectiveText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$startLabel–$endLabel',
                  style: TextStyle(
                    fontSize: 10,
                    color: effectiveText.withOpacity(0.75),
                  ),
                ),
              ],
            )
          : Center(
              child: Container(
                width: 20,
                height: 2,
                color: base.withOpacity(0.6),
              ),
            ),
    );
  }

  Color _toGray(Color c) {
    final l = (c.computeLuminance() * 255).round().clamp(0, 255);
    return Color.fromARGB(c.alpha, l, l, l);
  }
}

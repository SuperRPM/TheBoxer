import 'package:flutter/material.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 좌측 시간 눈금 위젯
///
/// TimeUnit에 따라 분 단위 또는 구간 단위(오전/오후/저녁) 레이블을 표시한다.
class TimeRulerWidget extends StatelessWidget {
  final TimeUnit timeUnit;
  final double pixelsPerMinute;

  /// 전체 표시 범위 (분)
  static const int _startMinute = AppConstants.dayStartMinute; // 300 (05:00)
  static const int _endMinute = AppConstants.dayEndMinute;     // 1440 (24:00)
  static const double _rulerWidth = 52;

  const TimeRulerWidget({
    Key? key,
    required this.timeUnit,
    required this.pixelsPerMinute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontSize: 11,
        );

    if (timeUnit.isSegment) {
      return _buildSegmentRuler(textStyle);
    }
    return _buildMinuteRuler(textStyle);
  }

  /// 분 단위 눈금 (1시간 / 30분 / 10분 / 5분)
  Widget _buildMinuteRuler(TextStyle? style) {
    final interval = timeUnit.minuteInterval!;
    const totalMinutes = _endMinute - _startMinute;
    final labels = <_RulerLabel>[];

    for (int min = _startMinute; min <= _endMinute; min += interval) {
      final relMin = min - _startMinute;
      labels.add(_RulerLabel(
        topOffset: relMin * pixelsPerMinute,
        label: TimeUtils.minutesToTimeString(min),
      ));
    }

    final totalHeight = totalMinutes * pixelsPerMinute;

    return SizedBox(
      width: _rulerWidth,
      height: totalHeight,
      child: Stack(
        children: labels.map((l) {
          return Positioned(
            top: l.topOffset - 9, // 텍스트 중앙 정렬
            left: 0,
            right: 0,
            child: Text(
              l.label,
              textAlign: TextAlign.right,
              style: style,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 구간 단위 눈금 (오전/오후/저녁)
  Widget _buildSegmentRuler(TextStyle? style) {
    // 구간 경계: 05:00, 06:00(360), 12:00(720), 18:00(1080), 24:00(1440)
    final segments = [
      _Segment(start: 300, end: 360, label: '새벽'),
      _Segment(start: 360, end: 720, label: '오전'),
      _Segment(start: 720, end: 1080, label: '오후'),
      _Segment(start: 1080, end: 1440, label: '저녁'),
    ];

    final totalHeight = (_endMinute - _startMinute) * pixelsPerMinute;

    return SizedBox(
      width: _rulerWidth,
      height: totalHeight,
      child: Stack(
        children: segments.map((seg) {
          final top = (seg.start - _startMinute) * pixelsPerMinute;
          final height = (seg.end - seg.start) * pixelsPerMinute;
          return Positioned(
            top: top,
            left: 0,
            right: 0,
            height: height,
            child: Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                seg.label,
                style: style?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RulerLabel {
  final double topOffset;
  final String label;
  _RulerLabel({required this.topOffset, required this.label});
}

class _Segment {
  final int start;
  final int end;
  final String label;
  _Segment({required this.start, required this.end, required this.label});
}

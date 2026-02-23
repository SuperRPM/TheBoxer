import 'package:flutter/material.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 좌측 시간 눈금 위젯
class TimeRulerWidget extends StatelessWidget {
  final TimeUnit timeUnit;
  final double pixelsPerMinute;

  static const int _startMinute = AppConstants.dayStartMinute;
  static const int _endMinute = AppConstants.dayEndMinute;
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
    return _buildMinuteRuler(textStyle);
  }

  Widget _buildMinuteRuler(TextStyle? style) {
    final interval = timeUnit.minuteInterval;
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
            top: l.topOffset - 9,
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
}

class _RulerLabel {
  final double topOffset;
  final String label;
  _RulerLabel({required this.topOffset, required this.label});
}

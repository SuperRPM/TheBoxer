import 'package:flutter/material.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/time_unit.dart';

/// 배경 그리드 위젯 (수평선)
class TimeGridWidget extends StatelessWidget {
  final TimeUnit timeUnit;
  final double pixelsPerMinute;
  final bool isColorMode;

  static const int _startMinute = AppConstants.dayStartMinute;
  static const int _endMinute = AppConstants.dayEndMinute;

  const TimeGridWidget({
    Key? key,
    required this.timeUnit,
    required this.pixelsPerMinute,
    required this.isColorMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalHeight = (_endMinute - _startMinute) * pixelsPerMinute;
    final isDark = !isColorMode;

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: CustomPaint(
        painter: _GridPainter(
          timeUnit: timeUnit,
          pixelsPerMinute: pixelsPerMinute,
          startMinute: _startMinute,
          endMinute: _endMinute,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final TimeUnit timeUnit;
  final double pixelsPerMinute;
  final int startMinute;
  final int endMinute;
  final bool isDark;

  _GridPainter({
    required this.timeUnit,
    required this.pixelsPerMinute,
    required this.startMinute,
    required this.endMinute,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final interval = timeUnit.minuteInterval;

    final majorPaint = Paint()
      ..color = isDark ? Colors.grey.shade400 : Colors.grey.shade300
      ..strokeWidth = 1.0;

    final minorPaint = Paint()
      ..color = isDark ? Colors.grey.shade700 : Colors.grey.shade200
      ..strokeWidth = 0.5;

    for (int min = startMinute; min <= endMinute; min += interval) {
      final y = (min - startMinute) * pixelsPerMinute;
      final isHour = min % 60 == 0;
      final paint = isHour ? majorPaint : minorPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.timeUnit != timeUnit ||
        oldDelegate.pixelsPerMinute != pixelsPerMinute ||
        oldDelegate.isDark != isDark;
  }
}

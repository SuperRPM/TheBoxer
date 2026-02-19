import 'package:flutter/material.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/data/models/time_unit.dart';

/// 배경 그리드 위젯 (수평선)
///
/// TimeUnit에 따라 눈금 밀도가 다름.
/// 구간 모드: 오전/오후/저녁 구간 경계선 표시
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
    if (timeUnit.isSegment) {
      _drawSegmentLines(canvas, size);
    } else {
      _drawMinuteLines(canvas, size);
    }
  }

  void _drawMinuteLines(Canvas canvas, Size size) {
    final interval = timeUnit.minuteInterval!;

    // 주요 눈금 (1시간 단위) 페인트
    final majorPaint = Paint()
      ..color = isDark
          ? Colors.grey.shade400
          : Colors.grey.shade300
      ..strokeWidth = 1.0;

    // 보조 눈금 페인트
    final minorPaint = Paint()
      ..color = isDark
          ? Colors.grey.shade700
          : Colors.grey.shade200
      ..strokeWidth = 0.5;

    for (int min = startMinute; min <= endMinute; min += interval) {
      final y = (min - startMinute) * pixelsPerMinute;
      final isHour = min % 60 == 0;
      final paint = isHour ? majorPaint : minorPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawSegmentLines(Canvas canvas, Size size) {
    // 구간 경계: 300, 360, 720, 1080, 1440
    final boundaries = [300, 360, 720, 1080, 1440];
    final paint = Paint()
      ..color = isDark
          ? Colors.grey.shade400
          : Colors.grey.shade400
      ..strokeWidth = 1.5;

    for (final boundary in boundaries) {
      if (boundary < startMinute || boundary > endMinute) continue;
      final y = (boundary - startMinute) * pixelsPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 내부 보조선 (각 구간 중간)
    final internalLines = [
      _midpoint(360, 720),  // 오전 중간 (09:00 = 540)
      _midpoint(720, 1080), // 오후 중간 (15:00 = 900)
      _midpoint(1080, 1440), // 저녁 중간 (21:00 = 1260)
    ];

    final minorPaint = Paint()
      ..color = isDark
          ? Colors.grey.shade700
          : Colors.grey.shade200
      ..strokeWidth = 0.5;

    for (final m in internalLines) {
      if (m < startMinute || m > endMinute) continue;
      final y = (m - startMinute) * pixelsPerMinute;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }
  }

  int _midpoint(int a, int b) => (a + b) ~/ 2;

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.timeUnit != timeUnit ||
        oldDelegate.pixelsPerMinute != pixelsPerMinute ||
        oldDelegate.isDark != isDark;
  }
}

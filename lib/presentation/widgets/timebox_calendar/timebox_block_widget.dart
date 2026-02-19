import 'package:flutter/material.dart';
import 'package:timebox_planner/data/models/timebox_block.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/utils/color_utils.dart';
import 'package:timebox_planner/utils/time_utils.dart';

/// 개별 타임박스 블록 카드 위젯
///
/// 카테고리 색상으로 배경을 표시하고, 제목/시간/카테고리명을 렌더링.
/// 탭 시 편집 콜백을 호출한다.
class TimeboxBlockWidget extends StatelessWidget {
  final TimeboxBlock block;
  final Category? category;
  final bool isColorMode;
  final double pixelsPerMinute;

  /// 탭 시 편집 다이얼로그 열기
  final VoidCallback onTap;

  /// 캘린더 표시 시작 분 (기본: 300 = 05:00)
  final int startMinute;

  const TimeboxBlockWidget({
    Key? key,
    required this.block,
    required this.category,
    required this.isColorMode,
    required this.pixelsPerMinute,
    required this.onTap,
    this.startMinute = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 카테고리 색상 결정
    final rawColor = category != null
        ? ColorUtils.fromValue(category!.colorValue)
        : Colors.blueGrey.shade300;

    final bgColor =
        ColorUtils.blockBackgroundColor(rawColor, isColorMode: isColorMode);
    final borderColor =
        ColorUtils.blockBorderColor(rawColor, isColorMode: isColorMode);
    final textColor = ColorUtils.adaptiveColor(rawColor, isColorMode: isColorMode)
        .withOpacity(0.9);

    final top = (block.startMinute - startMinute) * pixelsPerMinute;
    final height = block.durationMinutes * pixelsPerMinute;

    // 최소 높이 보장
    final displayHeight = height < 20 ? 20.0 : height;

    final startLabel = TimeUtils.minutesToTimeString(block.startMinute);
    final endLabel = TimeUtils.minutesToTimeString(block.endMinute);

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: displayHeight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              left: BorderSide(color: borderColor, width: 3),
              top: BorderSide(color: borderColor.withOpacity(0.4), width: 0.5),
              bottom:
                  BorderSide(color: borderColor.withOpacity(0.4), width: 0.5),
              right:
                  BorderSide(color: borderColor.withOpacity(0.4), width: 0.5),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: _buildContent(
            height: displayHeight,
            startLabel: startLabel,
            endLabel: endLabel,
            textColor: textColor,
            borderColor: borderColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required double height,
    required String startLabel,
    required String endLabel,
    required Color textColor,
    required Color borderColor,
  }) {
    // 높이에 따라 표시 내용 조정
    if (height < 28) {
      // 매우 좁음: 제목만
      return Text(
        block.title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
      );
    }

    if (height < 50) {
      // 보통: 제목 + 시간
      return Row(
        children: [
          Expanded(
            child: Text(
              block.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$startLabel~$endLabel',
            style: TextStyle(
              fontSize: 10,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      );
    }

    // 넉넉한 높이: 제목 + 시간범위 + 카테고리명
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 2),
        Text(
          '$startLabel ~ $endLabel',
          style: TextStyle(
            fontSize: 11,
            color: textColor.withOpacity(0.8),
          ),
        ),
        if (category != null) ...[
          const SizedBox(height: 2),
          Text(
            category!.name,
            style: TextStyle(
              fontSize: 10,
              color: textColor.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ],
    );
  }
}

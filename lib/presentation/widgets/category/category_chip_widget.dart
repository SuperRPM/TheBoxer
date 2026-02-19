import 'package:flutter/material.dart';
import 'package:timebox_planner/data/models/category.dart';
import 'package:timebox_planner/utils/color_utils.dart';

/// 카테고리를 색상 칩으로 표시하는 위젯
class CategoryChipWidget extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final bool isColorMode;
  final VoidCallback? onTap;

  const CategoryChipWidget({
    Key? key,
    required this.category,
    this.isSelected = false,
    this.isColorMode = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rawColor = ColorUtils.fromValue(category.colorValue);
    final displayColor =
        ColorUtils.adaptiveColor(rawColor, isColorMode: isColorMode);
    final textColor = ColorUtils.contrastColor(displayColor);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? displayColor : displayColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: displayColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: displayColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? textColor
                    : displayColor.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

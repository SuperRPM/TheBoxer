import 'package:flutter/material.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';
import 'package:timebox_planner/utils/color_utils.dart';

/// AppConstants.defaultCategoryColors를 격자 형태로 표시하여 색상 선택
class CategoryColorPickerWidget extends StatelessWidget {
  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;

  const CategoryColorPickerWidget({
    Key? key,
    required this.selectedColorValue,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.defaultCategoryColors.map((colorValue) {
        final color = ColorUtils.fromValue(colorValue);
        final isSelected = colorValue == selectedColorValue;
        return GestureDetector(
          onTap: () => onColorSelected(colorValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black87 : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

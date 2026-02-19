import 'package:flutter/material.dart';

/// 색상 관련 유틸리티
class ColorUtils {
  ColorUtils._();

  /// int(Color.value)를 Color로 변환
  static Color fromValue(int colorValue) => Color(colorValue);

  /// 배경색에 적합한 텍스트 색상 반환 (밝은 배경 → 검정, 어두운 배경 → 흰색)
  static Color contrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// 컬러 모드 여부에 따라 색상 반환
  /// 흑백 모드: 그레이스케일로 변환
  static Color adaptiveColor(Color color, {required bool isColorMode}) {
    if (isColorMode) return color;
    // 흑백 모드: 명도를 기준으로 그레이 변환
    final luminance = color.computeLuminance();
    final gray = (luminance * 255).round();
    return Color.fromARGB(color.alpha, gray, gray, gray);
  }

  /// 카테고리 블록의 배경색 (반투명)
  static Color blockBackgroundColor(Color categoryColor, {required bool isColorMode}) {
    final base = adaptiveColor(categoryColor, isColorMode: isColorMode);
    return base.withOpacity(0.25);
  }

  /// 카테고리 블록의 테두리색
  static Color blockBorderColor(Color categoryColor, {required bool isColorMode}) {
    return adaptiveColor(categoryColor, isColorMode: isColorMode).withOpacity(0.8);
  }
}

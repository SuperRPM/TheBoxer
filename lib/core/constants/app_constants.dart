/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  /// 타임박스 표시 시작 시각 (분 단위, 05:00)
  static const int dayStartMinute = 300;

  /// 타임박스 표시 종료 시각 (분 단위, 24:00)
  static const int dayEndMinute = 1440;

  /// Hive Box 이름
  static const String timeboxBoxName = 'timeboxes';
  static const String categoryBoxName = 'categories';
  static const String routineBoxName = 'routines';
  static const String weeklyPlanBoxName = 'weekly_plans';
  static const String brainDumpBoxName = 'brain_dumps';
  static const String settingsBoxName = 'settings';

  /// 설정 키
  static const String themeSettingKey = 'is_color_mode';
  static const String timeUnitSettingKey = 'time_unit';
  static const String lastBrainDumpResetKey = 'last_brain_dump_reset';

  /// 기본 카테고리 색상 팔레트 (Color.value 형태)
  static const List<int> defaultCategoryColors = [
    0xFFE53935, // Red
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF00BCD4, // Cyan
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFFFF5722, // Deep Orange
    0xFF795548, // Brown
  ];
}

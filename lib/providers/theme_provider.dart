import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timebox_planner/core/constants/app_constants.dart';

/// 테마 상태 관리 Notifier
/// isColorMode: true = 컬러 모드, false = 흑백 모드
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(_loadFromHive());

  static bool _loadFromHive() {
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    return box.get(AppConstants.themeSettingKey, defaultValue: true) as bool;
  }

  Future<void> toggle() async {
    state = !state;
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    await box.put(AppConstants.themeSettingKey, state);
  }

  Future<void> setColorMode(bool isColorMode) async {
    state = isColorMode;
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    await box.put(AppConstants.themeSettingKey, state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

// ── 다크 모드 Provider ─────────────────────────────────
class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(_load());

  static bool _load() {
    final box = Hive.box<dynamic>(AppConstants.settingsBoxName);
    return box.get('dark_mode', defaultValue: false) as bool;
  }

  Future<void> toggle() async {
    state = !state;
    await Hive.box<dynamic>(AppConstants.settingsBoxName).put('dark_mode', state);
  }
}

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>(
  (ref) => DarkModeNotifier(),
);

/// 현재 활성 ThemeMode 반환
final themeModeProvider = Provider<ThemeMode>((ref) {
  final isDark = ref.watch(darkModeProvider);
  return isDark ? ThemeMode.dark : ThemeMode.light;
});

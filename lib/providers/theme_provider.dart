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

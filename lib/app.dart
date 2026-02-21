import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/core/theme/app_theme.dart';
import 'package:timebox_planner/presentation/screens/home_screen.dart';
import 'package:timebox_planner/presentation/screens/routine_screen.dart';
import 'package:timebox_planner/presentation/screens/timebox_screen.dart';
import 'package:timebox_planner/presentation/screens/weekly_plan_screen.dart';
import 'package:timebox_planner/providers/theme_provider.dart';

/// 앱 루트 위젯
///
/// ProviderScope는 main.dart에서 감싸므로, 여기서는 ConsumerWidget 사용.
class TimeboxPlannerApp extends ConsumerWidget {
  const TimeboxPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isColorMode = ref.watch(themeProvider);

    return MaterialApp(
      title: '타임박스 플래너',
      debugShowCheckedModeBanner: false,
      theme: isColorMode ? AppTheme.colorTheme : AppTheme.monoTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/timebox': (context) => const TimeboxScreen(),
        '/weekly_plan': (context) => const WeeklyPlanScreen(),
        '/routine': (context) => const RoutineScreen(),
      },
    );
  }
}

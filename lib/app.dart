import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/core/theme/app_theme.dart';
import 'package:timebox_planner/presentation/screens/home_screen.dart';
import 'package:timebox_planner/presentation/screens/routine_screen.dart';
import 'package:timebox_planner/presentation/screens/timebox_screen.dart';
import 'package:timebox_planner/presentation/screens/weekly_plan_screen.dart';
import 'package:timebox_planner/providers/theme_provider.dart';

class TimeboxPlannerApp extends ConsumerWidget {
  const TimeboxPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isColorMode = ref.watch(themeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: '타임박스 플래너',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: isColorMode ? AppTheme.colorTheme : AppTheme.monoTheme,
      darkTheme: isColorMode ? AppTheme.colorDarkTheme : AppTheme.monoDarkTheme,
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

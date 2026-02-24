import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox_planner/data/models/time_unit.dart';
import 'package:timebox_planner/providers/theme_provider.dart';
import 'package:timebox_planner/providers/timebox_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isColorMode = ref.watch(themeProvider);
    final isDarkMode = ref.watch(darkModeProvider);
    final timeUnit = ref.watch(timeUnitProvider);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // ── 화면 섹션 ─────────────────────────────
          _SectionHeader(title: '화면', color: primary),

          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: const Text('어두운 배경으로 전환'),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode_outlined,
              color: primary,
            ),
            value: isDarkMode,
            activeColor: primary,
            onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),

          SwitchListTile(
            title: const Text('컬러 모드'),
            subtitle: Text(isColorMode ? '버건디 컬러 테마' : '흑백 모노 테마'),
            secondary: Icon(
              isColorMode ? Icons.palette_outlined : Icons.invert_colors,
              color: primary,
            ),
            value: isColorMode,
            activeColor: primary,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),

          const Divider(),

          // ── 시간표 섹션 ───────────────────────────
          _SectionHeader(title: '시간표', color: primary),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.access_time, color: primary, size: 22),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('기본 시간 단위',
                          style: TextStyle(fontSize: 15)),
                      Text('시간표 눈금 간격',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                DropdownButton<TimeUnit>(
                  value: timeUnit,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(timeUnitProvider.notifier).setUnit(v);
                    }
                  },
                  items: TimeUnit.values
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.displayLabel,
                                style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── 앱 정보 ───────────────────────────────
          _SectionHeader(title: '앱 정보', color: primary),

          ListTile(
            leading: Icon(Icons.info_outline, color: primary),
            title: const Text('버전'),
            trailing: const Text('1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({Key? key, required this.title, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

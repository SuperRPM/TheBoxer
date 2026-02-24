import 'package:flutter/material.dart';

const _burgundy = Color(0xFF8B1A36);
const _burgundyLight = Color(0xFFB05070);
const _burgundyContainer = Color(0xFFFFDAE0);

class AppTheme {
  AppTheme._();

  // ── 라이트 컬러 (버건디) ────────────────────────────────
  static ThemeData get colorTheme => _buildTheme(
        brightness: Brightness.light,
        primary: _burgundy,
        primaryContainer: _burgundyContainer,
        secondary: const Color(0xFF6D4C41),
        secondaryContainer: const Color(0xFFEFD8D0),
        surface: Colors.white,
        background: const Color(0xFFF8F4F5),
        onSurface: const Color(0xFF212121),
      );

  // ── 다크 컬러 (버건디) ────────────────────────────────
  static ThemeData get colorDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: _burgundyLight,
        primaryContainer: const Color(0xFF5A0E20),
        secondary: const Color(0xFFA1887F),
        secondaryContainer: const Color(0xFF3E2723),
        surface: const Color(0xFF1E1216),
        background: const Color(0xFF150B0E),
        onSurface: const Color(0xFFF0E0E4),
      );

  // ── 라이트 흑백 ─────────────────────────────────────
  static ThemeData get monoTheme => _buildTheme(
        brightness: Brightness.light,
        primary: const Color(0xFF212121),
        primaryContainer: const Color(0xFFE0E0E0),
        secondary: const Color(0xFF424242),
        secondaryContainer: const Color(0xFFF5F5F5),
        surface: Colors.white,
        background: const Color(0xFFF9F9F9),
        onSurface: const Color(0xFF212121),
      );

  // ── 다크 흑백 ──────────────────────────────────────
  static ThemeData get monoDarkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: const Color(0xFFE0E0E0),
        primaryContainer: const Color(0xFF424242),
        secondary: const Color(0xFFBDBDBD),
        secondaryContainer: const Color(0xFF303030),
        surface: const Color(0xFF121212),
        background: const Color(0xFF0A0A0A),
        onSurface: const Color(0xFFEEEEEE),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color primaryContainer,
    required Color secondary,
    required Color secondaryContainer,
    required Color surface,
    required Color background,
    required Color onSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    final onPrimary = Colors.white;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      primaryContainer: primaryContainer,
      secondary: secondary,
      secondaryContainer: secondaryContainer,
      surface: surface,
      background: background,
      error: const Color(0xFFE53935),
      onPrimary: onPrimary,
      onSecondary: Colors.white,
      onSurface: onSurface,
      onBackground: onSurface,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 1 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? primaryContainer.withOpacity(0.3) : primaryContainer.withOpacity(0.4),
        selectedColor: primary,
        labelStyle: TextStyle(fontSize: 13, color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
        thickness: 1,
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: onSurface.withOpacity(0.87)),
        bodySmall: TextStyle(fontSize: 12, color: onSurface.withOpacity(0.6)),
        labelSmall: TextStyle(fontSize: 11, color: onSurface.withOpacity(0.45)),
      ),
    );
  }
}

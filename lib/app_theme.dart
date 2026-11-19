import 'package:flutter/material.dart';

/// アプリのテーマモード
enum AppThemeMode {
  simple('シンプル', Icons.auto_awesome_mosaic_outlined),
  light('スタンダード', Icons.light_mode_outlined),
  dark('ダーク', Icons.dark_mode_outlined);

  final String label;
  final IconData icon;

  const AppThemeMode(this.label, this.icon);

  static AppThemeMode fromName(String? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return AppThemeMode.simple;
  }

  AppThemeMode get next {
    switch (this) {
      case AppThemeMode.simple:
        return AppThemeMode.light;
      case AppThemeMode.light:
        return AppThemeMode.dark;
      case AppThemeMode.dark:
        return AppThemeMode.simple;
    }
  }
}

/// テーマモードに応じた ThemeData を構築する。
ThemeData buildAppTheme({required AppThemeMode mode}) {
  switch (mode) {
    case AppThemeMode.simple:
      return _buildSimpleTheme();
    case AppThemeMode.light:
      return _buildStandardTheme(isDark: false);
    case AppThemeMode.dark:
      return _buildStandardTheme(isDark: true);
  }
}

/// 余白とモノトーンを活かした、ごちゃごちゃしないシンプルテーマ
ThemeData _buildSimpleTheme() {
  const background = Color(0xFFFAFAFA);
  const cardColor = Colors.white;
  const primary = Color(0xFF1F2937);
  const borderColor = Color(0xFFE5E7EB);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    secondary: const Color(0xFF4B5563),
    surface: background,
    surfaceContainerHighest: cardColor,
    onSurface: const Color(0xFF111827),
    error: const Color(0xFFDC2626),
  );

  final base = ThemeData.light();
  final radius = BorderRadius.circular(14);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      indicatorColor: const Color(0xFFF3F4F6),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? primary
              : const Color(0xFF6B7280),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: borderColor),
      backgroundColor: cardColor,
      selectedColor: const Color(0xFF1F2937).withValues(alpha: 0.1),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
  );
}

/// スタンダード（ライト／ダーク）テーマ
ThemeData _buildStandardTheme({required bool isDark}) {
  const seed = Color(0xFF0F766E);
  final brightness = isDark ? Brightness.dark : Brightness.light;
  final background =
      isDark ? const Color(0xFF111417) : const Color(0xFFF6F7F5);
  final cardColor = isDark ? const Color(0xFF1B2026) : Colors.white;

  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(
    surface: background,
    surfaceContainerHighest: cardColor,
  );

  final base = isDark ? ThemeData.dark() : ThemeData.light();
  final radius = BorderRadius.circular(16);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF232A32)
          : const Color(0xFFF0F2EF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),
  );
}

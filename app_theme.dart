import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Радиусы в духе iOS: карточки/поля 12–14, кнопки 12, чипы — овальные.
class AppRadius {
  static const card = 14.0;
  static const control = 12.0;
  static const chip = 20.0;
}

ThemeData _buildTheme(AppPalette p, Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: p.background,
    // Явный fontFamily не задаём: на iOS Flutter сам подставляет системный
    // San Francisco, на Android — Roboto. Это осознанный выбор, а не
    // недосмотр — легально встроить SF Pro в приложение для Android нельзя
    // (лицензия Apple ограничивает шрифт их платформами).
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: Colors.white,
      secondary: p.accent,
      onSecondary: Colors.white,
      error: p.destructive,
      onError: Colors.white,
      surface: p.cardBackground,
      onSurface: p.label,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: p.label,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: p.label,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: p.separator,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      hintStyle: TextStyle(color: p.tertiaryLabel),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.success : p.fill,
      ),
    ),
    textTheme: Typography.material2021(platform: TargetPlatform.iOS).black.apply(
          bodyColor: p.label,
          displayColor: p.label,
        ),
  );
}

ThemeData buildLightTheme() => _buildTheme(AppPalette.light, Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(AppPalette.dark, Brightness.dark);

/// Cupertino-тема (для CupertinoSwitch/CupertinoSlider/CupertinoActionSheet
/// и т.п.), синхронизированная с текущей палитрой — иначе системные
/// Cupertino-виджеты игнорируют Material ColorScheme и выглядят чужеродно.
CupertinoThemeData buildCupertinoTheme(AppPalette p, Brightness brightness) {
  return CupertinoThemeData(
    brightness: brightness,
    primaryColor: p.accent,
    scaffoldBackgroundColor: p.background,
    barBackgroundColor: p.secondaryBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: p.accent,
      textStyle: TextStyle(color: p.label, fontSize: 15),
    ),
  );
}

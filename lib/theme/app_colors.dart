import 'package:flutter/material.dart';

class AppPalette {
    final Color background;
    final Color secondaryBackground;
    final Color cardBackground;
    final Color label;
    final Color secondaryLabel;
    final Color tertiaryLabel;
    final Color separator;
    final Color accent;
    final Color success;
    final Color destructive;
    final Color warning;
    final Color fill;

    const AppPalette({
          required this.background,
          required this.secondaryBackground,
          required this.cardBackground,
          required this.label,
          required this.secondaryLabel,
          required this.tertiaryLabel,
          required this.separator,
          required this.accent,
          required this.success,
          required this.destructive,
          required this.warning,
          required this.fill,
    });

    static const light = AppPalette(
          background: Color(0xFFF2F2F7),
          secondaryBackground: Color(0xFFFFFFFF),
          cardBackground: Color(0xFFFFFFFF),
          label: Color(0xFF1C1C1E),
          secondaryLabel: Color(0xFF8E8E93),
          tertiaryLabel: Color(0xFFC7C7CC),
          separator: Color(0x4D3C3C43),
          accent: Color(0xFF007AFF),
          success: Color(0xFF34C759),
          destructive: Color(0xFFFF3B30),
          warning: Color(0xFFFF9500),
          fill: Color(0xFFE9E9EB),
        );

    static const dark = AppPalette(
          background: Color(0xFF000000),
          secondaryBackground: Color(0xFF1C1C1E),
          cardBackground: Color(0xFF1C1C1E),
          label: Color(0xFFFFFFFF),
          secondaryLabel: Color(0xFF98989F),
          tertiaryLabel: Color(0xFF48484A),
          separator: Color(0x4D545458),
          accent: Color(0xFF0A84FF),
          success: Color(0xFF30D158),
          destructive: Color(0xFFFF453A),
          warning: Color(0xFFFF9F0A),
          fill: Color(0xFF2C2C2E),
        );
}

extension AppPaletteX on BuildContext {
    AppPalette get colors =>
            Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Карточка в стиле iOS Settings/группированных списков: белая (тёмная —
/// в dark mode) панель с мягкой тенью, заголовок вынесен НАД карточкой
/// мелким серым капсом — так оформлены разделы во всех системных
/// приложениях Apple (Настройки, Здоровье, Кошелёк и т.д.).
class BentoCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets padding;

  const BentoCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.secondaryLabel,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: c.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark ? 0 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

enum ButtonTone { primary, secondary, destructive }

/// Плоская кнопка в стиле iOS — Apple почти никогда не использует градиенты
/// в системных элементах управления, только сплошной тональный заливочный
/// цвет. Раньше здесь был линейный градиент — заменил на flat fill.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ButtonTone tone;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = switch (tone) {
      ButtonTone.primary => c.accent,
      ButtonTone.secondary => c.success,
      ButtonTone.destructive => c.destructive,
    };

    return SizedBox(
      height: 50,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Строка группированного списка — iOS-стиль (заголовок слева, значение/
/// стрелка справа, тонкий разделитель снизу). Используется вместо ручной
/// вёрстки Row+Divider в каждом экране.
class AppleListRow extends StatelessWidget {
  final Widget child;
  final bool showDivider;

  const AppleListRow({super.key, required this.child, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: child),
        if (showDivider) Divider(height: 1, thickness: 0.5, color: context.colors.separator),
      ],
    );
  }
}

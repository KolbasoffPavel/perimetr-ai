import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'ai_chat_screen.dart';
import 'ai_scanner_screen.dart';
import 'project_screen.dart';
import 'prices_screen.dart';
import 'estimate_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    AiChatScreen(),
    AiScannerScreen(),
    ProjectScreen(),
    PricesScreen(),
    EstimateScreen(),
  ];

  static const _items = [
    (icon: CupertinoIcons.chat_bubble_2, label: 'ИИ Чат'),
    (icon: CupertinoIcons.camera, label: 'Сканер'),
    (icon: CupertinoIcons.square_pencil, label: 'Замеры'),
    (icon: CupertinoIcons.tag, label: 'Цены'),
    (icon: CupertinoIcons.money_dollar_circle, label: 'Смета'),
  ];

  // iOS-style action sheet вместо Material bottom sheet — так системно
  // выглядит выбор объекта в приложениях Apple.
  void _showProjectPicker(BuildContext context, AppState appState) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Объекты'),
        actions: [
          ...appState.projects.map((p) {
            final active = p.id == appState.activeProjectId;
            return CupertinoActionSheetAction(
              onPressed: () {
                appState.setActiveProject(p.id);
                Navigator.pop(ctx);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (active) const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(CupertinoIcons.checkmark_alt, size: 18),
                  ),
                  Text(p.name),
                ],
              ),
            );
          }),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final controller = TextEditingController();
              final name = await showCupertinoDialog<String>(
                context: context,
                builder: (dctx) => CupertinoAlertDialog(
                  title: const Text('Новый объект'),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CupertinoTextField(controller: controller, autofocus: true, placeholder: 'Например: Квартира на Ленина 5'),
                  ),
                  actions: [
                    CupertinoDialogAction(onPressed: () => Navigator.pop(dctx), child: const Text('Отмена')),
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.pop(dctx, controller.text),
                      child: const Text('Создать'),
                    ),
                  ],
                ),
              );
              if (name != null) appState.addProject(name);
            },
            child: const Text('Новый объект'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDestructiveAction: false,
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Верхняя панель в духе iOS large-title: крупный жирный заголовок,
            // под ним — переключатель объекта и кнопка настроек.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showProjectPicker(context, appState),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ПЕРИМЕТР',
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.label, letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  appState.activeProject.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15, color: c.secondaryLabel),
                                ),
                              ),
                              Icon(CupertinoIcons.chevron_down, size: 14, color: c.secondaryLabel),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.gear_alt, color: c.label),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: _index, children: _screens)),
          ],
        ),
      ),
      bottomNavigationBar: _AppleTabBar(
        items: _items,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Нижний таб-бар в стиле iOS — полупрозрачный фон с блюром за контентом
/// (как в системных приложениях Apple), тонкая линия сверху, активный пункт
/// подсвечен акцентным цветом.
class _AppleTabBar extends StatelessWidget {
  final List<({IconData icon, String label})> items;
  final int index;
  final ValueChanged<int> onTap;

  const _AppleTabBar({required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: c.secondaryBackground.withOpacity(0.85),
            border: Border(top: BorderSide(color: c.separator, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 50,
              child: Row(
                children: List.generate(items.length, (i) {
                  final active = i == index;
                  final item = items[i];
                  final color = active ? c.accent : c.secondaryLabel;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 24, color: color),
                          const SizedBox(height: 2),
                          Text(item.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

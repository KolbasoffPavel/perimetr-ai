import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const PerimetrApp());
}

class PerimetrApp extends StatelessWidget {
  const PerimetrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'ПЕРИМЕТР Intelligent Core',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.mode,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            // Оборачиваем в CupertinoTheme, синхронизированную с текущей
            // Material-темой — иначе Cupertino-виджеты (свитчи, action sheet,
            // сегмент-контрол) не подхватят выбранную светлую/тёмную палитру.
            builder: (context, child) {
              final brightness = MediaQuery.platformBrightnessOf(context);
              final resolvedBrightness = switch (themeController.mode) {
                ThemeMode.light => Brightness.light,
                ThemeMode.dark => Brightness.dark,
                ThemeMode.system => brightness,
              };
              final palette = resolvedBrightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
              return CupertinoTheme(
                data: buildCupertinoTheme(palette, resolvedBrightness),
                child: child!,
              );
            },
            home: Consumer<AppState>(
              builder: (context, appState, _) {
                if (!appState.loaded) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                return const HomeShell();
              },
            ),
          );
        },
      ),
    );
  }
}

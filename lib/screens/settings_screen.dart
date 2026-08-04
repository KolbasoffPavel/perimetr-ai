import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_store.dart';
import '../services/bitrix24_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';
import '../widgets/bento_card.dart';

class SettingsScreen extends StatefulWidget {
const SettingsScreen({super.key});

@override
State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
final _settings = SettingsStore();

final _app101ClientIdCtrl = TextEditingController();
final _app101ClientSecretCtrl = TextEditingController();
final _bitrixWebhookCtrl = TextEditingController();

bool _testingBitrix = false;
String? _bitrixTestResult;
bool _exportingBackup = false;
bool _importingBackup = false;

@override
void initState() {
super.initState();
_load();
}

Future<void> _load() async {
_app101ClientIdCtrl.text = await _settings.getApp101ClientId() ?? '';
_app101ClientSecretCtrl.text = await _settings.getApp101ClientSecret() ?? '';
_bitrixWebhookCtrl.text = await _settings.getBitrix24WebhookUrl() ?? '';
setState(() {});
}

Future<void> _save() async {
await _settings.setApp101ClientId(_app101ClientIdCtrl.text.trim());
await _settings.setApp101ClientSecret(_app101ClientSecretCtrl.text.trim());
await _settings.setBitrix24WebhookUrl(_bitrixWebhookCtrl.text.trim());
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
}
}

Future<void> _testBitrix() async {
setState(() {
_testingBitrix = true;
_bitrixTestResult = null;
});
await _save();
try {
final ok = await Bitrix24Service(_settings).testConnection();
setState(() => _bitrixTestResult = ok ? '✅ Подключение работает' : '❌ Ошибка подключения');
} catch (e) {
setState(() => _bitrixTestResult = '❌ $e');
} finally {
setState(() => _testingBitrix = false);
}
}

Future<void> _exportBackup() async {
setState(() => _exportingBackup = true);
try {
final appState = context.read<AppState>();
final json = appState.exportBackupJson();
final dir = await getTemporaryDirectory();
final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
final file = File('${dir.path}/perimetr_backup_$stamp.json');
await file.writeAsString(json);
await Share.shareXFiles([XFile(file.path)], text: 'Резервная копия ПЕРИМЕТР');
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
}
} finally {
if (mounted) setState(() => _exportingBackup = false);
}
}

Future<void> _importBackup() async {
final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
if (result == null || result.files.single.path == null) return;
setState(() => _importingBackup = true);
try {
final file = File(result.files.single.path!);
final raw = await file.readAsString();
final appState = context.read<AppState>();
await appState.importBackupJson(raw);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резервная копия восстановлена')));
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка восстановления: $e')));
}
} finally {
if (mounted) setState(() => _importingBackup = false);
}
}
@override
Widget build(BuildContext context) {
final c = context.colors;
final themeController = context.watch<ThemeController>();

return Scaffold(
backgroundColor: c.background,
appBar: AppBar(title: const Text('Настройки')),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
BentoCard(
title: 'Оформление',
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Тема', style: TextStyle(fontSize: 13, color: c.secondaryLabel)),
const SizedBox(height: 10),
CupertinoSlidingSegmentedControl<ThemeMode>(
groupValue: themeController.mode,
backgroundColor: c.fill,
thumbColor: c.cardBackground,
children: {
ThemeMode.system: _segment('Система'),
ThemeMode.light: _segment('Светлая'),
ThemeMode.dark: _segment('Тёмная'),
},
onValueChanged: (mode) {
if (mode != null) themeController.setMode(mode);
},
),
],
),
),
BentoCard(
title: 'ИИ (Anthropic Claude)',
child: Text(
'Чат и AI-сканер работают через встроенный защищённый сервер приложения — '
'вводить свой API-ключ не нужно.',
style: TextStyle(fontSize: 12, color: c.secondaryLabel),
),
),
BentoCard(
title: 'Резервная копия',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Все объекты, замеры, сметы и шаблоны хранятся только на этом устройстве. '
'Сохраните копию перед переустановкой или сменой телефона.',
style: TextStyle(fontSize: 12, color: c.secondaryLabel),
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: _exportingBackup ? null : _exportBackup,
icon: const Icon(Icons.upload),
label: Text(_exportingBackup ? 'Экспорт...' : 'Экспорт'),
),
),
const SizedBox(width: 12),
Expanded(
child: OutlinedButton.icon(
onPressed: _importingBackup ? null : _importBackup,
icon: const Icon(Icons.download),
label: Text(_importingBackup ? 'Импорт...' : 'Импорт'),
),
),
],
),
],
),
),
BentoCard(
title: 'Приложение 101',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextField(
controller: _app101ClientIdCtrl,
style: TextStyle(color: c.label),
decoration: const InputDecoration(labelText: 'Client ID'),
),
const SizedBox(height: 12),
TextField(
controller: _app101ClientSecretCtrl,
obscureText: true,
style: TextStyle(color: c.label),
decoration: const InputDecoration(labelText: 'Client Secret'),
),
const SizedBox(height: 8),
Text(
'Client ID/Secret выдаются техподдержкой 101 после заявки (Telegram: @TechSupport101Bot).',
style: TextStyle(fontSize: 11, color: c.tertiaryLabel),
),
],
),
),
BentoCard(
title: 'Bitrix24',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextField(
controller: _bitrixWebhookCtrl,
style: TextStyle(color: c.label),
decoration: const InputDecoration(
labelText: 'URL входящего вебхука',
hintText: 'https://ваш-домен.bitrix24.ru/rest/1/xxxxx/',
),
),
const SizedBox(height: 8),
Text(
'Bitrix24 → Разработчикам → Другое → Входящий вебхук → права на модуль CRM.',
style: TextStyle(fontSize: 11, color: c.tertiaryLabel),
),
const SizedBox(height: 12),
OutlinedButton(
onPressed: _testingBitrix ? null : _testBitrix,
child: _testingBitrix
? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
: const Text('Проверить подключение'),
),
if (_bitrixTestResult != null) ...[
const SizedBox(height: 8),
Text(_bitrixTestResult!, style: TextStyle(color: c.label)),
],
],
),
),
BentoCard(
title: 'Голосовой ассистент',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Голосовой ввод и озвучка работают через нативные движки устройства — '
'доступны во вкладке «ИИ Чат» (значок микрофона и переключатель озвучки).',
style: TextStyle(fontSize: 12, color: c.label),
),
const SizedBox(height: 8),
Text('Требуется разрешение на микрофон при первом использовании.',
style: TextStyle(fontSize: 11, color: c.tertiaryLabel)),
],
),
),
const SizedBox(height: 8),
GradientButton(label: 'Сохранить настройки', onPressed: _save),
],
),
);
}

Widget _segment(String label) => Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Text(label, style: const TextStyle(fontSize: 13)),
);
}

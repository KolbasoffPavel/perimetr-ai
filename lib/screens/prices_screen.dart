import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';
import '../widgets/voice_mic_button.dart';
import 'material_calculator_screen.dart';

class PricesScreen extends StatefulWidget {
const PricesScreen({super.key});
@override
State<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends State<PricesScreen> {
bool _importing = false;

void _addPrice(BuildContext context, AppState appState) {
final nameCtrl = TextEditingController();
final unitCtrl = TextEditingController(text: 'м²');
final priceCtrl = TextEditingController();
showCupertinoDialog(
context: context,
builder: (ctx) => CupertinoAlertDialog(
title: const Text('Новая позиция'),
content: Padding(
padding: const EdgeInsets.only(top: 12),
child: Column(
children: [
CupertinoTextField(
 controller: nameCtrl,
 placeholder: 'Название работы/материала',
 suffix: VoiceMicButton(controller: nameCtrl),
 ),
const SizedBox(height: 8),
CupertinoTextField(controller: unitCtrl, placeholder: 'Ед. измерения (м², шт, м.п.)'),
const SizedBox(height: 8),
CupertinoTextField(controller: priceCtrl, placeholder: 'Цена, ₽', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
],
),
),
actions: [
CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
CupertinoDialogAction(
isDefaultAction: true,
onPressed: () {
if (nameCtrl.text.trim().isEmpty) return;
appState.addPriceItem(
nameCtrl.text.trim(),
unitCtrl.text.trim().isEmpty ? 'шт' : unitCtrl.text.trim(),
double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
);
Navigator.pop(ctx);
},
child: const Text('Добавить'),
),
],
),
);
}

Future<void> _importCsv(AppState appState) async {
final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt']);
if (result == null || result.files.single.path == null) return;
setState(() => _importing = true);
try {
final file = File(result.files.single.path!);
final text = await file.readAsString();
final count = appState.importPriceListCsv(text);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(count > 0 ? 'Импортировано позиций: $count' : 'Не удалось распознать ни одной позиции в файле')),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка импорта: $e')));
}
} finally {
if (mounted) setState(() => _importing = false);
}
}

void _showImportInfo(BuildContext context) {
showCupertinoDialog(
context: context,
builder: (ctx) => CupertinoAlertDialog(
title: const Text('Формат файла'),
content: const Padding(
padding: EdgeInsets.only(top: 8),
child: Text(
'CSV или текстовый файл, одна позиция на строке:\n'
'Название,Единица,Цена\n\n'
'Например:\nПоклейка обоев,м²,350\nУкладка плитки,м²,900\n\n'
'Загрузка заменит текущий прайс-лист целиком.',
),
),
actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
),
);
}
@override
Widget build(BuildContext context) {
final c = context.colors;
final appState = context.watch<AppState>();
final prices = appState.priceList;

return Scaffold(
backgroundColor: c.background,
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('Цены', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.label)),
Row(
children: [
IconButton(
icon: Icon(Icons.calculate_outlined, color: c.accent, size: 24),
tooltip: 'Калькулятор материалов',
onPressed: () => Navigator.of(context).push(
MaterialPageRoute(builder: (_) => const MaterialCalculatorScreen()),
),
),
IconButton(
icon: Icon(Icons.help_outline, color: c.secondaryLabel, size: 22),
onPressed: () => _showImportInfo(context),
),
IconButton(
icon: _importing
? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))
: Icon(Icons.upload_file, color: c.accent, size: 24),
tooltip: 'Загрузить свой прайс-лист',
onPressed: _importing ? null : () => _importCsv(appState),
),
IconButton(
icon: Icon(Icons.add_circle, color: c.accent, size: 28),
onPressed: () => _addPrice(context, appState),
),
],
),
],
),
const SizedBox(height: 8),
if (prices.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 40),
child: Center(child: Text('Прайс-лист пуст — добавьте позиции или загрузите файл', style: TextStyle(color: c.secondaryLabel), textAlign: TextAlign.center)),
)
else
...prices.map((item) => BentoCard(
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.label)),
const SizedBox(height: 2),
Text('${item.price.toStringAsFixed(0)} ₽ / ${item.unit}', style: TextStyle(color: c.secondaryLabel, fontSize: 13)),
],
),
),
IconButton(
icon: Icon(Icons.add_shopping_cart, color: c.accent, size: 20),
tooltip: 'Добавить в смету',
onPressed: () {
appState.addEstimateItem(item.name, item.unit, 1, item.price);
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('«${item.name}» добавлено в смету')),
);
},
),
IconButton(
icon: Icon(Icons.delete_outline, color: c.destructive, size: 20),
onPressed: () => appState.removePriceItem(item.id),
),
],
),
)),
],
),
),
);
}
}

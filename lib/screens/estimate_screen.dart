import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/settings_store.dart';
import '../services/bitrix24_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

class EstimateScreen extends StatefulWidget {
const EstimateScreen({super.key});
@override
State<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends State<EstimateScreen> {
final _settings = SettingsStore();
bool _pushingToBitrix = false;

void _addItem(BuildContext context, AppState appState) {
final nameCtrl = TextEditingController();
final unitCtrl = TextEditingController(text: 'шт');
final qtyCtrl = TextEditingController(text: '1');
final priceCtrl = TextEditingController();
showCupertinoDialog(
context: context,
builder: (ctx) => CupertinoAlertDialog(
title: const Text('Позиция сметы'),
content: Padding(
padding: const EdgeInsets.only(top: 12),
child: Column(
children: [
CupertinoTextField(controller: nameCtrl, placeholder: 'Название'),
const SizedBox(height: 8),
CupertinoTextField(controller: unitCtrl, placeholder: 'Ед. измерения'),
const SizedBox(height: 8),
CupertinoTextField(controller: qtyCtrl, placeholder: 'Количество', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
const SizedBox(height: 8),
CupertinoTextField(controller: priceCtrl, placeholder: 'Цена за ед., ₽', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
],
),
),
actions: [
CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
CupertinoDialogAction(
isDefaultAction: true,
onPressed: () {
if (nameCtrl.text.trim().isEmpty) return;
appState.addEstimateItem(
nameCtrl.text.trim(),
unitCtrl.text.trim().isEmpty ? 'шт' : unitCtrl.text.trim(),
double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 1,
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

Future<void> _uploadFile(BuildContext context, AppState appState) async {
final result = await FilePicker.platform.pickFiles(allowMultiple: true);
if (result == null) return;
for (final file in result.files) {
if (file.path != null) {
appState.addAttachment(file.name, file.path!);
}
}
}

Future<void> _exportPdf(BuildContext context, AppState appState) async {
final project = appState.activeProject;
final regularFont = await PdfGoogleFonts.interRegular();
final boldFont = await PdfGoogleFonts.interBold();
final doc = pw.Document(theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont));

doc.addPage(
pw.Page(
build: (pw.Context ctx) {
return pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
pw.Text('Смета: ${project.name}', style: pw.TextStyle(fontSize: 20, font: boldFont)),
pw.SizedBox(height: 16),
pw.Table.fromTextArray(
headers: ['#', 'Наименование', 'Ед.', 'Кол-во', 'Цена', 'Сумма'],
headerStyle: pw.TextStyle(font: boldFont),
cellStyle: pw.TextStyle(font: regularFont),
data: [
for (var i = 0; i < project.estimateItems.length; i++)
[
'${i + 1}',
project.estimateItems[i].name,
project.estimateItems[i].unit,
project.estimateItems[i].quantity.toStringAsFixed(2),
project.estimateItems[i].price.toStringAsFixed(0),
project.estimateItems[i].total.toStringAsFixed(0),
],
],
),
pw.SizedBox(height: 16),
pw.Text('Итого: ${appState.estimateTotal.toStringAsFixed(0)} ₽', style: pw.TextStyle(fontSize: 16, font: boldFont)),
],
);
},
),
);
final dir = await getTemporaryDirectory();
final file = File('${dir.path}/estimate.pdf');
await file.writeAsBytes(await doc.save());
await Share.shareXFiles([XFile(file.path)], text: 'Смета: ${project.name}');
}

Future<void> _pushToBitrix(BuildContext context, AppState appState) async {
setState(() => _pushingToBitrix = true);
try {
final project = appState.activeProject;
final items = project.estimateItems
.map((e) => {'name': e.name, 'unit': e.unit, 'quantity': e.quantity, 'price': e.price, 'total': e.total})
.toList();
final dealId = await Bitrix24Service(_settings).pushEstimateAsDeal(
projectName: project.name,
items: items,
total: appState.estimateTotal,
);
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Сделка №$dealId создана в Bitrix24')),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('$e')),
);
}
} finally {
if (mounted) setState(() => _pushingToBitrix = false);
}
}

@override
Widget build(BuildContext context) {
final c = context.colors;
final appState = context.watch<AppState>();
final project = appState.activeProject;
final items = project.estimateItems;
final attachments = project.attachments;

return Scaffold(
backgroundColor: c.background,
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('Смета', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.label)),
IconButton(
icon: Icon(Icons.add_circle, color: c.accent, size: 28),
onPressed: () => _addItem(context, appState),
),
],
),
const SizedBox(height: 8),
if (items.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 24),
child: Center(
child: Text('Смета пуста — добавьте позиции вручную или из раздела «Цены»',
style: TextStyle(color: c.secondaryLabel), textAlign: TextAlign.center),
),
)
else
...items.map((item) => BentoCard(
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.label)),
const SizedBox(height: 2),
Text(
'${item.quantity.toStringAsFixed(2)} ${item.unit} × ${item.price.toStringAsFixed(0)} ₽ = ${item.total.toStringAsFixed(0)} ₽',
style: TextStyle(color: c.secondaryLabel, fontSize: 13),
),
],
),
),
IconButton(
icon: Icon(Icons.delete_outline, color: c.destructive, size: 20),
onPressed: () => appState.removeEstimateItem(item.id),
),
],
),
)),
if (items.isNotEmpty) ...[
const SizedBox(height: 8),
BentoCard(
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('Итого', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.label)),
Text('${appState.estimateTotal.toStringAsFixed(0)} ₽', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accent)),
],
),
),
],
const SizedBox(height: 8),
BentoCard(
title: 'Вложения',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (attachments.isEmpty)
Text('Файлы не загружены', style: TextStyle(color: c.secondaryLabel, fontSize: 13))
else
...attachments.map((a) => Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
children: [
Icon(Icons.description, size: 18, color: c.secondaryLabel),
const SizedBox(width: 8),
Expanded(child: Text(a.name, style: TextStyle(color: c.label), overflow: TextOverflow.ellipsis)),
IconButton(
icon: Icon(Icons.cancel, size: 18, color: c.destructive),
onPressed: () => appState.removeAttachment(a.id),
),
],
),
)),
const SizedBox(height: 8),
OutlinedButton.icon(
onPressed: () => _uploadFile(context, appState),
icon: const Icon(Icons.upload_file),
label: const Text('Загрузить файл'),
),
],
),
),
const SizedBox(height: 16),
if (items.isNotEmpty) ...[
GradientButton(label: 'Экспорт в PDF', icon: Icons.share, onPressed: () => _exportPdf(context, appState)),
const SizedBox(height: 12),
GradientButton(
label: _pushingToBitrix ? 'Отправка...' : 'Выгрузить в Bitrix24',
icon: Icons.cloud_upload,
tone: ButtonTone.secondary,
onPressed: () => _pushingToBitrix ? null : _pushToBitrix(context, appState),
),
],
],
),
),
);
}
}

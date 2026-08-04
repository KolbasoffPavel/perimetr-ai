import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

class PricesScreen extends StatelessWidget {
const PricesScreen({super.key});

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
CupertinoTextField(controller: nameCtrl, placeholder: 'Название работы/материала'),
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
IconButton(
icon: Icon(Icons.add_circle, color: c.accent, size: 28),
onPressed: () => _addPrice(context, appState),
),
],
),
const SizedBox(height: 8),
if (prices.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 40),
child: Center(child: Text('Прайс-лист пуст — добавьте позиции', style: TextStyle(color: c.secondaryLabel))),
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

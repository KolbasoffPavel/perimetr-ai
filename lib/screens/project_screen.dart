import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

class ProjectScreen extends StatelessWidget {
const ProjectScreen({super.key});

void _addRoom(BuildContext context, AppState appState) {
final nameCtrl = TextEditingController();
final lengthCtrl = TextEditingController();
final widthCtrl = TextEditingController();
final heightCtrl = TextEditingController(text: '2.7');
showCupertinoDialog(
context: context,
builder: (ctx) => CupertinoAlertDialog(
title: const Text('Новое помещение'),
content: Padding(
padding: const EdgeInsets.only(top: 12),
child: Column(
children: [
CupertinoTextField(controller: nameCtrl, placeholder: 'Название (напр. Гостиная)'),
const SizedBox(height: 8),
CupertinoTextField(controller: lengthCtrl, placeholder: 'Длина, м', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
const SizedBox(height: 8),
CupertinoTextField(controller: widthCtrl, placeholder: 'Ширина, м', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
const SizedBox(height: 8),
CupertinoTextField(controller: heightCtrl, placeholder: 'Высота, м', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
],
),
),
actions: [
CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
CupertinoDialogAction(
isDefaultAction: true,
onPressed: () {
final name = nameCtrl.text.trim().isEmpty ? 'Помещение' : nameCtrl.text.trim();
appState.addRoom(
name,
double.tryParse(lengthCtrl.text.replaceAll(',', '.')) ?? 0,
double.tryParse(widthCtrl.text.replaceAll(',', '.')) ?? 0,
double.tryParse(heightCtrl.text.replaceAll(',', '.')) ?? 2.7,
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
final rooms = appState.activeProject.rooms;

return Scaffold(
backgroundColor: c.background,
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('Замеры', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.label)),
IconButton(
icon: Icon(Icons.add_circle, color: c.accent, size: 28),
onPressed: () => _addRoom(context, appState),
),
],
),
const SizedBox(height: 8),
if (rooms.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 40),
child: Center(
child: Text('Помещений пока нет — добавьте первое', style: TextStyle(color: c.secondaryLabel)),
),
)
else
...rooms.map((room) => BentoCard(
child: Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(room.name, style: TextStyle(fontWeight: FontWeight.w600, color: c.label, fontSize: 16)),
const SizedBox(height: 4),
Text(
'${room.length.toStringAsFixed(2)} × ${room.width.toStringAsFixed(2)} × ${room.height.toStringAsFixed(2)} м  •  ${room.area.toStringAsFixed(1)} м²',
style: TextStyle(color: c.secondaryLabel, fontSize: 13),
),
],
),
),
IconButton(
icon: Icon(Icons.delete_outline, color: c.destructive, size: 20),
onPressed: () => appState.removeRoom(room.id),
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

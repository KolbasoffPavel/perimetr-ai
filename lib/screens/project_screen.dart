import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'package:flutter/services.dart';
import '../widgets/bento_card.dart';
import '../widgets/swipe_to_delete.dart';
import '../widgets/voice_mic_button.dart';
import 'room_photo_measure_screen.dart';
import 'floor_plan_screen.dart';
import 'project_visualization_screen.dart';
import 'panorama_screen.dart';

class ProjectScreen extends StatelessWidget {
const ProjectScreen({super.key});

void _addRoom(BuildContext context, AppState appState, {Map<String, double>? prefill}) {
final nameCtrl = TextEditingController();
final lengthCtrl = TextEditingController(text: prefill != null ? prefill['length']!.toStringAsFixed(2) : '');
final widthCtrl = TextEditingController(text: prefill != null ? prefill['width']!.toStringAsFixed(2) : '');
final heightCtrl = TextEditingController(text: prefill != null ? prefill['height']!.toStringAsFixed(2) : '2.7');
showCupertinoDialog(
context: context,
builder: (ctx) => CupertinoAlertDialog(
title: const Text('Новое помещение'),
content: Padding(
padding: const EdgeInsets.only(top: 12),
child: Column(
children: [
CupertinoTextField(
 controller: nameCtrl,
 placeholder: 'Название (напр. Гостиная)',
 suffix: VoiceMicButton(controller: nameCtrl),
 ),
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

Future<void> _measureByPhoto(BuildContext context, AppState appState) async {
final result = await Navigator.of(context).push<Map<String, double>>(
MaterialPageRoute(builder: (_) => const RoomPhotoMeasureScreen()),
);
if (result != null && context.mounted) {
_addRoom(context, appState, prefill: result);
}
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
Row(
children: [
IconButton(
icon: Icon(Icons.view_carousel_outlined, color: c.accent, size: 24),
tooltip: 'Визуализация проекта',
onPressed: () => Navigator.of(context).push(
MaterialPageRoute(builder: (_) => const ProjectVisualizationScreen()),
),
),
IconButton(
icon: Icon(Icons.camera_alt, color: c.accent, size: 24),
tooltip: 'Определить размеры по фото',
onPressed: () => _measureByPhoto(context, appState),
),
IconButton(
icon: Icon(Icons.add_circle, color: c.accent, size: 28),
onPressed: () {
HapticFeedback.lightImpact();
_addRoom(context, appState);
},
),
],
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
...rooms.asMap().entries.map((entry) {
final roomIndex = entry.key;
final room = entry.value;
return SwipeToDelete(
itemKey: room.id,
confirmLabel: 'Помещение "${room.name}" удалено',
onDelete: () => appState.removeRoom(room.id),
onUndo: () => appState.insertRoom(roomIndex, room),
child: BentoCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
GestureDetector(
onTap: () {
HapticFeedback.selectionClick();
appState.toggleRoomDone(room.id);
},
child: Padding(
padding: const EdgeInsets.only(right: 10),
child: Icon(
room.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
color: room.isDone ? c.accent : c.tertiaryLabel,
size: 24,
),
),
),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
room.name,
style: TextStyle(
fontWeight: FontWeight.w600,
color: room.isDone ? c.secondaryLabel : c.label,
fontSize: 16,
decoration: room.isDone ? TextDecoration.lineThrough : null,
),
),
const SizedBox(height: 4),
Text(
'${room.length.toStringAsFixed(2)} × ${room.width.toStringAsFixed(2)} × ${room.height.toStringAsFixed(2)} м  •  ${room.area.toStringAsFixed(1)} м²',
style: TextStyle(color: c.secondaryLabel, fontSize: 13),
),
],
),
),
],
),
Wrap(
spacing: 4,
children: [
TextButton.icon(
onPressed: () => Navigator.of(context).push(
MaterialPageRoute(builder: (_) => FloorPlanScreen(room: room)),
),
icon: Icon(room.floorPlan != null ? Icons.map : Icons.add_location_alt, size: 18),
label: const Text('План'),
),
TextButton.icon(
onPressed: () => Navigator.of(context).push(
MaterialPageRoute(builder: (_) => PanoramaScreen(room: room)),
),
icon: Icon(room.panoramaPath != null ? Icons.threesixty : Icons.panorama_photosphere, size: 18),
label: const Text('Панорама'),
),
],
),
],
),
),
);
}),
],
),
),
);
}
}

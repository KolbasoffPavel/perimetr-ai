import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

/// Простой 2D-редактор планировки помещения: сначала контур комнаты
/// (нажатия по холсту ставят точки стен), затем расстановка мебели
/// перетаскиванием иконок. Сохраняется как часть данных помещения.
/// Экспортируется в DXF для открытия в настоящем CAD-редакторе.
class FloorPlanScreen extends StatefulWidget {
final Room room;
const FloorPlanScreen({super.key, required this.room});
@override
State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
static const double _canvasSize = 340;

static const Map<String, IconData> _furnitureTypes = {
'bed': Icons.bed,
'sofa': Icons.weekend,
'table': Icons.table_restaurant,
'chair': Icons.chair,
'wardrobe': Icons.checkroom,
'door': Icons.door_front_door,
'window': Icons.window,
};

late List<Offset> _outline;
late List<FloorPlanItem> _items;
bool _outlineMode = true;

@override
void initState() {
super.initState();
final plan = widget.room.floorPlan;
_outline = plan != null
? plan.outline.map((p) => Offset(p.x * _canvasSize, p.y * _canvasSize)).toList()
: [];
_items = plan != null
? plan.items.map((i) => FloorPlanItem(id: i.id, type: i.type, x: i.x * _canvasSize, y: i.y * _canvasSize)).toList()
: [];
if (_outline.length >= 3) _outlineMode = false;
}

void _handleTap(Offset local) {
if (!_outlineMode) return;
setState(() => _outline.add(local));
}

void _undoPoint() {
if (_outline.isEmpty) return;
setState(() => _outline.removeLast());
}

void _finishOutline() {
if (_outline.length < 3) return;
setState(() => _outlineMode = false);
}

void _resetOutline() {
setState(() {
_outline = [];
_outlineMode = true;
});
}

void _addFurniture(String type) {
setState(() {
_items.add(FloorPlanItem(
id: '${DateTime.now().microsecondsSinceEpoch}',
type: type,
x: _canvasSize / 2,
y: _canvasSize / 2,
));
});
}

void _save(BuildContext context) {
final appState = context.read<AppState>();
final plan = FloorPlan(
outline: _outline.map((o) => WallPoint(x: o.dx / _canvasSize, y: o.dy / _canvasSize)).toList(),
items: _items.map((i) => FloorPlanItem(id: i.id, type: i.type, x: i.x / _canvasSize, y: i.y / _canvasSize)).toList(),
);
appState.saveRoomFloorPlan(widget.room.id, plan);
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('План сохранён')));
}

Future<void> _exportDxf(BuildContext context) async {
if (_outline.length < 2) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Сначала нарисуйте контур помещения')),
);
return;
}
final scaleX = widget.room.length > 0 ? widget.room.length : 5.0;
final scaleY = widget.room.width > 0 ? widget.room.width : 5.0;
final points = _outline
.map((o) => Offset((o.dx / _canvasSize) * scaleX, (1 - o.dy / _canvasSize) * scaleY))
.toList();

final buffer = StringBuffer();
buffer.write('0\nSECTION\n2\nENTITIES\n');
for (var i = 0; i < points.length; i++) {
final a = points[i];
final b = points[(i + 1) % points.length];
buffer.write('0\nLINE\n8\n0\n');
buffer.write('10\n${a.dx.toStringAsFixed(3)}\n20\n${a.dy.toStringAsFixed(3)}\n30\n0.0\n');
buffer.write('11\n${b.dx.toStringAsFixed(3)}\n21\n${b.dy.toStringAsFixed(3)}\n31\n0.0\n');
}
buffer.write('0\nENDSEC\n0\nEOF\n');

final dir = await getTemporaryDirectory();
final safeName = widget.room.name.replaceAll(RegExp(r'[^A-Za-zА-Яа-я0-9_-]'), '_');
final file = File('${dir.path}/plan_$safeName.dxf');
await file.writeAsString(buffer.toString());
await Share.shareXFiles([XFile(file.path)], text: 'План помещения: ${widget.room.name} (DXF)');
}
@override
Widget build(BuildContext context) {
final c = context.colors;

return Scaffold(
backgroundColor: c.background,
appBar: AppBar(
title: Text('План: ${widget.room.name}'),
actions: [
IconButton(icon: const Icon(Icons.ios_share), tooltip: 'Экспорт в DXF', onPressed: () => _exportDxf(context)),
IconButton(icon: const Icon(Icons.save), tooltip: 'Сохранить', onPressed: () => _save(context)),
],
),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
Text(
_outlineMode
? 'Нажимайте по холсту, чтобы отметить углы комнаты (минимум 3 точки), затем «Готово».'
: 'Перетаскивайте иконки мебели. Долгое нажатие — удалить предмет.',
style: TextStyle(fontSize: 12, color: c.secondaryLabel),
),
const SizedBox(height: 12),
Center(
child: Container(
width: _canvasSize,
height: _canvasSize,
decoration: BoxDecoration(
color: c.fill,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: c.cardBackground, width: 2),
),
child: Stack(
clipBehavior: Clip.none,
children: [
GestureDetector(
onTapUp: (d) => _handleTap(d.localPosition),
child: CustomPaint(
size: const Size(_canvasSize, _canvasSize),
painter: _OutlinePainter(outline: _outline, closed: !_outlineMode, color: c.accent),
),
),
for (var i = 0; i < _items.length; i++)
Positioned(
left: _items[i].x - 18,
top: _items[i].y - 18,
child: GestureDetector(
onPanUpdate: (d) => setState(() {
_items[i].x = (_items[i].x + d.delta.dx).clamp(0, _canvasSize);
_items[i].y = (_items[i].y + d.delta.dy).clamp(0, _canvasSize);
}),
onLongPress: () => setState(() => _items.removeAt(i)),
child: Container(
width: 36,
height: 36,
decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle, boxShadow: const [
BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
]),
child: Icon(_furnitureTypes[_items[i].type] ?? Icons.square, size: 18, color: Colors.white),
),
),
),
],
),
),
),
const SizedBox(height: 16),
if (_outlineMode)
Row(
children: [
Expanded(
child: OutlinedButton(onPressed: _undoPoint, child: const Text('Отменить точку')),
),
const SizedBox(width: 12),
Expanded(
child: GradientButton(label: 'Готово', icon: Icons.check, onPressed: _finishOutline),
),
],
)
else ...[
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('Мебель', style: TextStyle(fontWeight: FontWeight.w600, color: c.label)),
TextButton(onPressed: _resetOutline, child: const Text('Перерисовать контур')),
],
),
const SizedBox(height: 8),
SizedBox(
height: 56,
child: ListView(
scrollDirection: Axis.horizontal,
children: _furnitureTypes.entries
.map((e) => Padding(
padding: const EdgeInsets.only(right: 10),
child: InkWell(
onTap: () => _addFurniture(e.key),
borderRadius: BorderRadius.circular(28),
child: Container(
width: 48,
height: 48,
decoration: BoxDecoration(color: c.cardBackground, shape: BoxShape.circle),
child: Icon(e.value, color: c.accent),
),
),
))
.toList(),
),
),
],
],
),
),
);
}
}

class _OutlinePainter extends CustomPainter {
final List<Offset> outline;
final bool closed;
final Color color;
_OutlinePainter({required this.outline, required this.closed, required this.color});

@override
void paint(Canvas canvas, Size size) {
if (outline.isEmpty) return;
final linePaint = Paint()
..color = color
..strokeWidth = 3
..style = PaintingStyle.stroke;
final fillPaint = Paint()..color = color.withOpacity(0.12);
final path = Path()..moveTo(outline.first.dx, outline.first.dy);
for (final p in outline.skip(1)) {
path.lineTo(p.dx, p.dy);
}
if (closed) {
path.close();
canvas.drawPath(path, fillPaint);
}
canvas.drawPath(path, linePaint);
final dotPaint = Paint()..color = color;
for (final p in outline) {
canvas.drawCircle(p, 4, dotPaint);
}
}

@override
bool shouldRepaint(covariant _OutlinePainter oldDelegate) =>
oldDelegate.outline != outline || oldDelegate.closed != closed;
}

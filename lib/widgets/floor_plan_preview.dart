import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// Компактный неинтерактивный превью плана помещения (контур + мебель) —
/// используется в визуализации проекта. Если план ещё не создан, рисует
/// заглушку.
class FloorPlanPreview extends StatelessWidget {
final FloorPlan? plan;
final double size;
const FloorPlanPreview({super.key, this.plan, this.size = 260});

static const Map<String, IconData> _furnitureTypes = {
'bed': Icons.bed,
'sofa': Icons.weekend,
'table': Icons.table_restaurant,
'chair': Icons.chair,
'wardrobe': Icons.checkroom,
'door': Icons.door_front_door,
'window': Icons.window,
};

@override
Widget build(BuildContext context) {
final c = context.colors;
final currentPlan = plan;
if (currentPlan == null || currentPlan.outline.length < 3) {
return SizedBox(
width: size,
height: size,
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.map_outlined, size: 48, color: c.tertiaryLabel),
const SizedBox(height: 8),
Text('План не создан', style: TextStyle(color: c.tertiaryLabel, fontSize: 12)),
],
),
),
);
}
final outline = currentPlan.outline.map((p) => Offset(p.x * size, p.y * size)).toList();
return SizedBox(
width: size,
height: size,
child: Stack(
children: [
CustomPaint(size: Size(size, size), painter: _PreviewPainter(outline: outline, color: c.accent)),
for (final item in currentPlan.items)
Positioned(
left: item.x * size - 13,
top: item.y * size - 13,
child: Container(
width: 26,
height: 26,
decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
child: Icon(_furnitureTypes[item.type] ?? Icons.square, size: 13, color: Colors.white),
),
),
],
),
);
}
}

class _PreviewPainter extends CustomPainter {
final List<Offset> outline;
final Color color;
_PreviewPainter({required this.outline, required this.color});

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
path.close();
canvas.drawPath(path, fillPaint);
canvas.drawPath(path, linePaint);
}

@override
bool shouldRepaint(covariant _PreviewPainter oldDelegate) => true;
}

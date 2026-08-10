import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/floor_plan_preview.dart';
import 'ai_chat_screen.dart';

/// Визуализация проекта: пролистывание помещений (по одному на страницу),
/// с планом каждого. Тап по плану открывает ИИ-чат с этим помещением —
/// готовый запрос для обработки (расчёт материалов, вопросы и т.п.).
class ProjectVisualizationScreen extends StatefulWidget {
const ProjectVisualizationScreen({super.key});
@override
State<ProjectVisualizationScreen> createState() => _ProjectVisualizationScreenState();
}

class _ProjectVisualizationScreenState extends State<ProjectVisualizationScreen> {
final _pageController = PageController();
int _index = 0;

void _sendToAi(Room room) {
final prompt =
'Помещение "${room.name}": ${room.length.toStringAsFixed(2)}×${room.width.toStringAsFixed(2)}×${room.height.toStringAsFixed(2)} м, '
'${room.area.toStringAsFixed(1)} м². ';
Navigator.of(context).push(
MaterialPageRoute(builder: (_) => AiChatScreen(initialPrompt: prompt)),
);
}

@override
void dispose() {
_pageController.dispose();
super.dispose();
}
@override
Widget build(BuildContext context) {
final c = context.colors;
final rooms = context.watch<AppState>().activeProject.rooms;

return Scaffold(
backgroundColor: c.background,
appBar: AppBar(title: const Text('Визуализация проекta')),
body: rooms.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Text(
'Сначала добавьте помещения в «Замерах»',
style: TextStyle(color: c.secondaryLabel),
textAlign: TextAlign.center,
),
),
)
: SafeArea(
child: Column(
children: [
Expanded(
child: PageView.builder(
controller: _pageController,
itemCount: rooms.length,
onPageChanged: (i) => setState(() => _index = i),
itemBuilder: (context, i) {
final room = rooms[i];
return Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
Text(room.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.label)),
const SizedBox(height: 4),
Text(
'${room.length.toStringAsFixed(2)} × ${room.width.toStringAsFixed(2)} × ${room.height.toStringAsFixed(2)} м · ${room.area.toStringAsFixed(1)} м²',
style: TextStyle(color: c.secondaryLabel, fontSize: 13),
),
const SizedBox(height: 16),
Expanded(
child: Center(
child: GestureDetector(
onTap: () => _sendToAi(room),
child: Container(
decoration: BoxDecoration(
border: Border.all(color: c.cardBackground, width: 2),
borderRadius: BorderRadius.circular(16),
color: c.fill,
),
padding: const EdgeInsets.all(12),
child: FloorPlanPreview(plan: room.floorPlan),
),
),
),
),
const SizedBox(height: 16),
OutlinedButton.icon(
onPressed: () => _sendToAi(room),
icon: const Icon(Icons.smart_toy_outlined),
label: const Text('Обработать в ИИ'),
),
],
),
);
},
),
),
const SizedBox(height: 12),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: List.generate(
rooms.length,
(i) => Container(
margin: const EdgeInsets.symmetric(horizontal: 3),
width: i == _index ? 10 : 6,
height: 6,
decoration: BoxDecoration(
color: i == _index ? c.accent : c.cardBackground,
borderRadius: BorderRadius.circular(3),
),
),
),
),
const SizedBox(height: 16),
],
),
),
);
}
}

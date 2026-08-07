import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/material_calculator.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

const Map<String, String> _categories = {
'wallpaper': 'Обои',
'paint': 'Краска',
'flooring': 'Напольное покрытие',
'tile': 'Плитка',
'plaster': 'Штукатурка/шпаклёвка',
};

/// Расчёт нужного количества материала по площади помещения —
/// стандартные формулы (обои, краска, напольное покрытие, плитка,
/// штукатурка) с запасом на подрезку. Результат можно сразу добавить
/// в смету.
class MaterialCalculatorScreen extends StatefulWidget {
const MaterialCalculatorScreen({super.key});
@override
State<MaterialCalculatorScreen> createState() => _MaterialCalculatorScreenState();
}

class _MaterialCalculatorScreenState extends State<MaterialCalculatorScreen> {
String _category = 'wallpaper';
final _lengthCtrl = TextEditingController();
final _widthCtrl = TextEditingController();
final _heightCtrl = TextEditingController(text: '2.7');

final _rollWidthCtrl = TextEditingController(text: '1.06');
final _rollLengthCtrl = TextEditingController(text: '10');
final _wasteCtrl = TextEditingController(text: '10');
final _coverageCtrl = TextEditingController(text: '10');
final _coatsCtrl = TextEditingController(text: '2');
final _kgPerSqmCtrl = TextEditingController(text: '8');

MaterialResult? _result;
String? _selectedRoomId;

void _applyRoom(Room room) {
setState(() {
_selectedRoomId = room.id;
_lengthCtrl.text = room.length.toStringAsFixed(2);
_widthCtrl.text = room.width.toStringAsFixed(2);
_heightCtrl.text = room.height.toStringAsFixed(2);
_result = null;
});
}

double _d(TextEditingController c, double fallback) => double.tryParse(c.text.replaceAll(',', '.')) ?? fallback;

void _calculate() {
final length = _d(_lengthCtrl, 0);
final width = _d(_widthCtrl, 0);
final height = _d(_heightCtrl, 2.7);
MaterialResult result;
switch (_category) {
case 'wallpaper':
result = MaterialCalculator.wallpaper(
length: length,
width: width,
height: height,
rollWidth: _d(_rollWidthCtrl, 1.06),
rollLength: _d(_rollLengthCtrl, 10),
wastePercent: _d(_wasteCtrl, 10),
);
break;
case 'paint':
final area = MaterialCalculator.wallArea(length, width, height);
result = MaterialCalculator.paint(
areaToPaint: area,
coveragePerLiter: _d(_coverageCtrl, 10),
coats: _d(_coatsCtrl, 2).round(),
);
break;
case 'flooring':
result = MaterialCalculator.flooring(length: length, width: width, wastePercent: _d(_wasteCtrl, 10));
break;
case 'tile':
result = MaterialCalculator.tile(area: length * width, wastePercent: _d(_wasteCtrl, 10));
break;
case 'plaster':
final area = MaterialCalculator.wallArea(length, width, height);
result = MaterialCalculator.plaster(area: area, kgPerSqm: _d(_kgPerSqmCtrl, 8));
break;
default:
return;
}
setState(() => _result = result);
}
void _addToEstimate(AppState appState) {
if (_result == null) return;
final nameCtrl = TextEditingController(text: _categories[_category]);
final priceCtrl = TextEditingController();
showCupertinoDialog(
context: context,
builder: (ctx) => CupertinoAlertDialog(
title: const Text('Добавить в смету'),
content: Padding(
padding: const EdgeInsets.only(top: 12),
child: Column(
children: [
CupertinoTextField(controller: nameCtrl, placeholder: 'Название позиции'),
const SizedBox(height: 8),
Text('Количество: ${_result!.quantity} ${_result!.unit}', style: const TextStyle(fontSize: 13)),
const SizedBox(height: 8),
CupertinoTextField(
controller: priceCtrl,
placeholder: 'Цена за ${_result!.unit}, ₽',
keyboardType: const TextInputType.numberWithOptions(decimal: true),
),
],
),
),
actions: [
CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
CupertinoDialogAction(
isDefaultAction: true,
onPressed: () {
appState.addEstimateItem(
nameCtrl.text.trim().isEmpty ? _categories[_category]! : nameCtrl.text.trim(),
_result!.unit,
_result!.quantity,
double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0,
);
Navigator.pop(ctx);
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавлено в смету')));
},
child: const Text('Добавить'),
),
],
),
);
}

Widget _paramField(String label, TextEditingController controller) {
final c = context.colors;
return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: TextField(
controller: controller,
style: TextStyle(color: c.label),
keyboardType: const TextInputType.numberWithOptions(decimal: true),
decoration: InputDecoration(labelText: label),
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
appBar: AppBar(title: const Text('Калькулятор материалов')),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
BentoCard(
title: 'Тип материала',
child: Wrap(
spacing: 8,
runSpacing: 8,
children: _categories.entries.map((e) {
final selected = _category == e.key;
return ChoiceChip(
label: Text(e.value),
selected: selected,
onSelected: (_) => setState(() {
_category = e.key;
_result = null;
}),
);
}).toList(),
),
),
const SizedBox(height: 8),
if (rooms.isNotEmpty)
BentoCard(
title: 'Помещение (необязательно)',
child: Wrap(
spacing: 8,
runSpacing: 8,
children: rooms
.map((r) => ChoiceChip(
label: Text(r.name),
selected: _selectedRoomId == r.id,
onSelected: (_) => _applyRoom(r),
))
.toList(),
),
),
const SizedBox(height: 8),
BentoCard(
title: 'Размеры помещения, м',
child: Column(
children: [
_paramField('Длина', _lengthCtrl),
_paramField('Ширина', _widthCtrl),
if (_category != 'flooring' && _category != 'tile') _paramField('Высота', _heightCtrl),
],
),
),
const SizedBox(height: 8),
BentoCard(
title: 'Параметры расчёта',
child: Column(
children: [
if (_category == 'wallpaper') ...[
_paramField('Ширина рулона, м', _rollWidthCtrl),
_paramField('Длина рулона, м', _rollLengthCtrl),
_paramField('Запас на подрезку, %', _wasteCtrl),
],
if (_category == 'paint') ...[
_paramField('Расход краски, м²/л', _coverageCtrl),
_paramField('Количество слоёв', _coatsCtrl),
],
if (_category == 'flooring' || _category == 'tile') _paramField('Запас на подрезку, %', _wasteCtrl),
if (_category == 'plaster') _paramField('Расход, кг/м²', _kgPerSqmCtrl),
],
),
),
const SizedBox(height: 16),
GradientButton(label: 'Рассчитать', icon: Icons.calculate, onPressed: _calculate),
if (_result != null) ...[
const SizedBox(height: 16),
BentoCard(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Нужно: ${_result!.quantity} ${_result!.unit}',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.accent),
),
const SizedBox(height: 6),
Text(_result!.explanation, style: TextStyle(fontSize: 12, color: c.secondaryLabel)),
const SizedBox(height: 12),
GradientButton(
label: 'Добавить в смету',
icon: Icons.add_shopping_cart,
tone: ButtonTone.secondary,
onPressed: () => _addToEstimate(appState),
),
],
),
),
],
],
),
),
);
}
}

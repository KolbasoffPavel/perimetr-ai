import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

/// Экран "фото-линейки": снимок помещения -> ИИ оценивает примерные
/// размеры по видимым ориентирам (высота двери и т.п.) -> пользователь
/// может подправить цифры перед добавлением помещения в замеры.
class RoomPhotoMeasureScreen extends StatefulWidget {
const RoomPhotoMeasureScreen({super.key});
@override
State<RoomPhotoMeasureScreen> createState() => _RoomPhotoMeasureScreenState();
}

class _RoomPhotoMeasureScreenState extends State<RoomPhotoMeasureScreen> {
CameraController? _controller;
Future<void>? _initFuture;
XFile? _photo;
bool _analyzing = false;
String? _error;
final _lengthCtrl = TextEditingController();
final _widthCtrl = TextEditingController();
final _heightCtrl = TextEditingController(text: '2.7');

@override
void initState() {
super.initState();
_initCamera();
}

Future<void> _initCamera() async {
try {
final cameras = await availableCameras();
if (cameras.isEmpty) {
setState(() => _error = 'Камера не найдена на устройстве');
return;
}
_controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
_initFuture = _controller!.initialize();
setState(() {});
} catch (e) {
setState(() => _error = 'Не удалось включить камеру: $e');
}
}

Future<void> _takeAndAnalyze() async {
if (_controller == null || !_controller!.value.isInitialized || _analyzing) return;
setState(() {
_analyzing = true;
_error = null;
});
try {
final file = await _controller!.takePicture();
setState(() => _photo = file);
final bytes = await File(file.path).readAsBytes();
final base64Image = base64Encode(bytes);
final result = await AiService().estimateRoomDimensions(base64Image, 'image/jpeg');
_lengthCtrl.text = ((result['length'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
_widthCtrl.text = ((result['width'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
_heightCtrl.text = ((result['height'] as num?)?.toDouble() ?? 2.7).toStringAsFixed(2);
} catch (e) {
setState(() => _error = 'Не удалось оценить размеры: $e. Введите вручную.');
} finally {
setState(() => _analyzing = false);
}
}

void _useResult() {
Navigator.pop(context, {
'length': double.tryParse(_lengthCtrl.text.replaceAll(',', '.')) ?? 0,
'width': double.tryParse(_widthCtrl.text.replaceAll(',', '.')) ?? 0,
'height': double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 2.7,
});
}

@override
void dispose() {
_controller?.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final c = context.colors;

return Scaffold(
backgroundColor: c.background,
appBar: AppBar(title: const Text('Размеры по фото')),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
if (_error != null)
Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Text(_error!, style: TextStyle(color: c.destructive)),
),
if (_photo == null) ...[
AspectRatio(
aspectRatio: 3 / 4,
child: ClipRRect(
borderRadius: BorderRadius.circular(14),
child: (_controller != null && _initFuture != null)
? FutureBuilder(
future: _initFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.done) {
return CameraPreview(_controller!);
}
return Container(color: c.fill, child: const Center(child: CircularProgressIndicator()));
},
)
: Container(
color: c.fill,
child: Center(child: Text('Камера недоступна', style: TextStyle(color: c.secondaryLabel))),
),
),
),
const SizedBox(height: 8),
Text(
'Снимите помещение так, чтобы в кадре была дверь или окно — по ним ИИ '
'прикинет масштаб.',
style: TextStyle(color: c.secondaryLabel, fontSize: 12),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
GradientButton(
label: _analyzing ? 'Анализ...' : 'Снять и оценить размеры',
icon: Icons.camera_alt,
onPressed: _takeAndAnalyze,
),
] else ...[
ClipRRect(
borderRadius: BorderRadius.circular(14),
child: Image.file(File(_photo!.path), height: 200, fit: BoxFit.cover, width: double.infinity),
),
const SizedBox(height: 16),
BentoCard(
title: 'Размеры (можно поправить)',
child: Column(
children: [
TextField(
controller: _lengthCtrl,
style: TextStyle(color: c.label),
keyboardType: const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(labelText: 'Длина, м'),
),
const SizedBox(height: 8),
TextField(
controller: _widthCtrl,
style: TextStyle(color: c.label),
keyboardType: const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(labelText: 'Ширина, м'),
),
const SizedBox(height: 8),
TextField(
controller: _heightCtrl,
style: TextStyle(color: c.label),
keyboardType: const TextInputType.numberWithOptions(decimal: true),
decoration: const InputDecoration(labelText: 'Высота, м'),
),
],
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () => setState(() => _photo = null),
child: const Text('Переснять'),
),
),
const SizedBox(width: 12),
Expanded(
child: GradientButton(label: 'Использовать', icon: Icons.check, onPressed: _useResult),
),
],
),
],
],
),
),
);
}
}

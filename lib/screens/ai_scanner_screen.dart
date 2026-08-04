import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

class AiScannerScreen extends StatefulWidget {
const AiScannerScreen({super.key});
@override
State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
CameraController? _controller;
Future<void>? _initFuture;
XFile? _photo;
bool _analyzing = false;
String? _result;
String? _error;

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

Future<void> _takePhoto() async {
if (_controller == null || !_controller!.value.isInitialized) return;
try {
final file = await _controller!.takePicture();
setState(() {
_photo = file;
_result = null;
_error = null;
});
} catch (e) {
setState(() => _error = 'Не удалось сделать снимок: $e');
}
}

Future<void> _analyze() async {
if (_analyzing || _photo == null) return;
setState(() {
_analyzing = true;
_error = null;
});
try {
final bytes = await File(_photo!.path).readAsBytes();
final base64Image = base64Encode(bytes);
final reply = await AiService().analyzeImage(
base64Image,
'image/jpeg',
'Ты помощник по ремонту квартир. Опиши состояние помещения на фото и предположи, '
'какие работы по ремонту понадобятся. Дай краткий структурированный ответ на русском.',
);
setState(() => _result = reply);
} catch (e) {
setState(() => _error = 'Ошибка анализа: $e');
} finally {
setState(() => _analyzing = false);
}
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
const SizedBox(height: 16),
GradientButton(label: 'Сделать снимок', icon: Icons.camera_alt, onPressed: _takePhoto),
] else ...[
ClipRRect(
borderRadius: BorderRadius.circular(14),
child: Image.file(File(_photo!.path)),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () => setState(() {
_photo = null;
_result = null;
}),
child: const Text('Переснять'),
),
),
const SizedBox(width: 12),
Expanded(
child: GradientButton(
label: _analyzing ? 'Анализ...' : 'Анализировать',
icon: Icons.auto_awesome,
onPressed: _analyze,
),
),
],
),
if (_result != null) ...[
const SizedBox(height: 16),
BentoCard(
title: 'Результат анализа',
child: Text(_result!, style: TextStyle(color: c.label)),
),
],
],
],
),
),
);
}
}

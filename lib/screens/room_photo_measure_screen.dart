import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

/// Экран "фото-линейки": до 4 снимков помещения с разных углов -> ИИ
/// сопоставляет их и оценивает примерные размеры по видимым ориентирам
/// (высота двери и т.п.) -> пользователь может подправить цифры перед
/// добавлением помещения в замеры. Несколько фото заметно точнее одного.
class RoomPhotoMeasureScreen extends StatefulWidget {
const RoomPhotoMeasureScreen({super.key});
@override
State<RoomPhotoMeasureScreen> createState() => _RoomPhotoMeasureScreenState();
}

class _RoomPhotoMeasureScreenState extends State<RoomPhotoMeasureScreen> {
static const _maxPhotos = 4;
CameraController? _controller;
Future<void>? _initFuture;
final List<XFile> _photos = [];
bool _analyzing = false;
bool _hasResult = false;
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

Future<void> _takePhoto() async {
if (_controller == null || !_controller!.value.isInitialized || _photos.length >= _maxPhotos) return;
try {
final file = await _controller!.takePicture();
setState(() {
_photos.add(file);
_error = null;
});
} catch (e) {
setState(() => _error = 'Не удалось сделать снимок: $e');
}
}

void _removePhoto(int index) {
setState(() => _photos.removeAt(index));
}

Future<void> _analyze() async {
if (_analyzing || _photos.isEmpty) return;
setState(() {
_analyzing = true;
_error = null;
});
try {
final images = <(String, String)>[];
for (final photo in _photos) {
final bytes = await File(photo.path).readAsBytes();
images.add((base64Encode(bytes), 'image/jpeg'));
}
final result = await AiService().estimateRoomDimensionsMulti(images);
_lengthCtrl.text = ((result['length'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
_widthCtrl.text = ((result['width'] as num?)?.toDouble() ?? 0).toStringAsFixed(2);
_heightCtrl.text = ((result['height'] as num?)?.toDouble() ?? 2.7).toStringAsFixed(2);
setState(() => _hasResult = true);
} catch (e) {
setState(() => _error = 'Не удалось оценить размеры: $e. Введите вручную.');
setState(() => _hasResult = true);
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
if (!_hasResult) ...[
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
'Снимите помещение с ${_maxPhotos} разных углов (двери/окна в кадре помогают точнее оценить масштаб). '
'Можно оценить и по одному фото.',
style: TextStyle(color: c.secondaryLabel, fontSize: 12),
textAlign: TextAlign.center,
),
if (_photos.isNotEmpty) ...[
const SizedBox(height: 12),
SizedBox(
height: 72,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _photos.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (context, i) => Stack(
children: [
ClipRRect(
borderRadius: BorderRadius.circular(8),
child: Image.file(File(_photos[i].path), width: 72, height: 72, fit: BoxFit.cover),
),
Positioned(
top: 0,
right: 0,
child: GestureDetector(
onTap: () => _removePhoto(i),
child: Container(
decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
padding: const EdgeInsets.all(2),
child: const Icon(Icons.close, size: 14, color: Colors.white),
),
),
),
],
),
),
),
],
const SizedBox(height: 16),
Row(
children: [
if (_photos.length < _maxPhotos)
Expanded(
child: OutlinedButton.icon(
onPressed: _takePhoto,
icon: const Icon(Icons.camera_alt),
label: Text('Снимок (${_photos.length}/${_maxPhotos})'),
),
),
if (_photos.isNotEmpty) ...[
const SizedBox(width: 12),
Expanded(
child: GradientButton(
label: _analyzing ? 'Анализ...' : 'Оценить размеры',
icon: Icons.auto_awesome,
onPressed: _analyze,
),
),
],
],
),
] else ...[
if (_photos.isNotEmpty)
SizedBox(
height: 90,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _photos.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (context, i) => ClipRRect(
borderRadius: BorderRadius.circular(10),
child: Image.file(File(_photos[i].path), width: 90, height: 90, fit: BoxFit.cover),
),
),
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
onPressed: () => setState(() {
_hasResult = false;
_photos.clear();
}),
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

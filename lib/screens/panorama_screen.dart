import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// Просмотр панорамы 360° для помещения. Съёмку панорамы в приложении
/// сознательно не делаем (готовые пакеты сшивки для Flutter несовместимы
/// с современной Android-сборкой) — вместо этого используем панорамный
/// режим штатной камеры телефона (есть почти на любом Android) и просто
/// импортируем готовый снимок для интерактивного просмотра.
class PanoramaScreen extends StatefulWidget {
final Room room;
const PanoramaScreen({super.key, required this.room});
@override
State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
bool _importing = false;
String? _error;

Future<void> _importPanorama() async {
final result = await FilePicker.platform.pickFiles(type: FileType.image);
if (result == null || result.files.single.path == null) return;
setState(() {
_importing = true;
_error = null;
});
try {
final sourceFile = File(result.files.single.path!);
final dir = await getApplicationDocumentsDirectory();
final panoramasDir = Directory('${dir.path}/panoramas');
if (!await panoramasDir.exists()) {
await panoramasDir.create(recursive: true);
}
final destPath = '${panoramasDir.path}/${widget.room.id}.jpg';
await sourceFile.copy(destPath);
if (mounted) {
context.read<AppState>().saveRoomPanorama(widget.room.id, destPath);
}
} catch (e) {
setState(() => _error = 'Не удалось загрузить панораму: $e');
} finally {
if (mounted) setState(() => _importing = false);
}
}
@override
Widget build(BuildContext context) {
final c = context.colors;
final panoramaPath = widget.room.panoramaPath;

return Scaffold(
backgroundColor: Colors.black,
appBar: AppBar(
title: Text('Панорама: ${widget.room.name}'),
actions: [
IconButton(
icon: _importing
? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
: const Icon(Icons.add_photo_alternate_outlined),
tooltip: panoramaPath != null ? 'Заменить панораму' : 'Загрузить панораму',
onPressed: _importing ? null : _importPanorama,
),
],
),
body: panoramaPath != null
? PanoramaViewer(child: Image.file(File(panoramaPath)))
: Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.panorama_photosphere_outlined, size: 56, color: c.tertiaryLabel),
const SizedBox(height: 16),
Text(
'Панорама ещё не загружена',
style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
Text(
'Снимите панораму штатной камерой телефона (режим «Панорама» есть почти на любом Android) '
'и загрузите готовый снимок сюда для просмотра.',
style: TextStyle(color: Colors.white70, fontSize: 13),
textAlign: TextAlign.center,
),
const SizedBox(height: 20),
ElevatedButton.icon(
onPressed: _importing ? null : _importPanorama,
icon: const Icon(Icons.add_photo_alternate_outlined),
label: Text(_importing ? 'Загрузка...' : 'Загрузить панораму'),
),
],
),
),
),
bottomNavigationBar: _error != null
? Container(
color: Colors.black87,
padding: const EdgeInsets.all(12),
child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
)
: null,
);
}
}

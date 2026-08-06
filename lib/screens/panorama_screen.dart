import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_panorama/flutter_panorama.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// Панорама 360° для помещения: съёмка серии кадров по кругу со сшивкой
/// (OpenCV, в фоновом изоляте) через panorama_creator, затем интерактивный
/// просмотр готовой панорамы через panorama_viewer.
class PanoramaScreen extends StatefulWidget {
final Room room;
const PanoramaScreen({super.key, required this.room});
@override
State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
late bool _capturing;
String? _error;

@override
void initState() {
super.initState();
_capturing = widget.room.panoramaPath == null;
}

dynamic _onSuccess(dynamic panoramaPath) {
final appState = context.read<AppState>();
appState.saveRoomPanorama(widget.room.id, panoramaPath as String);
setState(() {
_capturing = false;
_error = null;
});
}
@override
Widget build(BuildContext context) {
final c = context.colors;

return Scaffold(
backgroundColor: Colors.black,
appBar: AppBar(
title: Text('Панорама: ${widget.room.name}'),
actions: [
if (!_capturing)
IconButton(
icon: const Icon(Icons.camera_alt),
tooltip: 'Переснять',
onPressed: () => setState(() => _capturing = true),
),
],
),
body: _capturing
? PanoramaCreator(
displayStatus: true,
backgroundColor: Colors.black,
loadingWidget: const Center(child: CircularProgressIndicator()),
onError: (error) => setState(() => _error = 'Ошибка сшивки: $error'),
onSuccess: _onSuccess,
)
: (widget.room.panoramaPath != null
? PanoramaViewer(
child: Image.file(File(widget.room.panoramaPath!)),
)
: Center(
child: Text('Панорама ещё не снята', style: TextStyle(color: c.secondaryLabel)),
)),
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

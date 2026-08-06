import 'dart:io';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// Просмотр панорамы 360° для помещения. Съёмка временно отключена —
/// идёт проверка совместимости пакета сшивки со сборкой.
class PanoramaScreen extends StatefulWidget {
final Room room;
const PanoramaScreen({super.key, required this.room});
@override
State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen> {
@override
Widget build(BuildContext context) {
final c = context.colors;

return Scaffold(
backgroundColor: Colors.black,
appBar: AppBar(title: Text('Панорама: ${widget.room.name}')),
body: widget.room.panoramaPath != null
? PanoramaViewer(child: Image.file(File(widget.room.panoramaPath!)))
: Center(
child: Text('Панорама ещё не снята', style: TextStyle(color: c.secondaryLabel)),
),
);
}
}

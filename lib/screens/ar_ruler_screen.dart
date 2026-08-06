import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// Простое AR-измерение расстояния между двумя точками через ARCore/ARKit.
/// Наведите камеру на пол/стену, коснитесь двух точек — приложение
/// покажет расстояние между ними. Экспериментальная функция.
class ArRulerScreen extends StatefulWidget {
const ArRulerScreen({super.key});
@override
State<ArRulerScreen> createState() => _ArRulerScreenState();
}

class _ArRulerScreenState extends State<ArRulerScreen> {
ARSessionManager? _sessionManager;
ARObjectManager? _objectManager;
vm.Vector3? _pointA;
vm.Vector3? _pointB;
double? _distance;
String? _error;

void _onARViewCreated(
ARSessionManager sessionManager,
ARObjectManager objectManager,
ARAnchorManager anchorManager,
ARLocationManager locationManager,
) {
_sessionManager = sessionManager;
_objectManager = objectManager;
sessionManager.onInitialize(
showFeaturePoints: false,
showPlanes: true,
showWorldOrigin: false,
handlePans: false,
handleRotation: false,
);
objectManager.onInitialize();
sessionManager.onPlaneOrPointTap = _onPlaneTap;
}

void _onPlaneTap(List<ARHitTestResult> hits) {
if (hits.isEmpty) return;
ARHitTestResult hit = hits.first;
for (final h in hits) {
if (h.type == ARHitTestResultType.plane) {
hit = h;
break;
}
}
try {
final m = hit.worldTransform;
final position = vm.Vector3(m.getColumn(3).x, m.getColumn(3).y, m.getColumn(3).z);
setState(() {
if (_pointA == null || _pointB != null) {
_pointA = position;
_pointB = null;
_distance = null;
} else {
_pointB = position;
_distance = _pointA!.distanceTo(_pointB!);
}
_error = null;
});
} catch (e) {
setState(() => _error = 'Ошибка измерения: $e');
}
}

void _reset() {
setState(() {
_pointA = null;
_pointB = null;
_distance = null;
});
}

@override
void dispose() {
_sessionManager?.dispose();
super.dispose();
}
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('AR-линейка')),
body: Stack(
children: [
ARView(
onARViewCreated: _onARViewCreated,
planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
),
Positioned(
left: 16,
right: 16,
bottom: 24,
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.65),
borderRadius: BorderRadius.circular(14),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
_distance != null
? 'Расстояние: ${_distance!.toStringAsFixed(2)} м'
: _pointA == null
? 'Коснитесь первой точки (пол/стена)'
: 'Коснитесь второй точки',
style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
TextButton(
onPressed: _reset,
child: const Text('Сбросить', style: TextStyle(color: Colors.white70)),
),
],
),
),
),
if (_error != null)
Positioned(
top: 16,
left: 16,
right: 16,
child: Container(
padding: const EdgeInsets.all(8),
color: Colors.black54,
child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
),
),
],
),
);
}
}

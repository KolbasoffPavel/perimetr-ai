import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallPoint {
double x;
double y;
WallPoint({required this.x, required this.y});
Map<String, dynamic> toJson() => {'x': x, 'y': y};
factory WallPoint.fromJson(Map<String, dynamic> j) => WallPoint(x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble());
}

class FloorPlanItem {
final String id;
String type;
double x;
double y;
FloorPlanItem({required this.id, required this.type, required this.x, required this.y});
Map<String, dynamic> toJson() => {'id': id, 'type': type, 'x': x, 'y': y};
factory FloorPlanItem.fromJson(Map<String, dynamic> j) => FloorPlanItem(
id: j['id'] as String,
type: j['type'] as String,
x: (j['x'] as num).toDouble(),
y: (j['y'] as num).toDouble(),
);
}

class FloorPlan {
List<WallPoint> outline;
List<FloorPlanItem> items;
FloorPlan({List<WallPoint>? outline, List<FloorPlanItem>? items})
: outline = outline ?? [],
items = items ?? [];
Map<String, dynamic> toJson() => {
'outline': outline.map((p) => p.toJson()).toList(),
'items': items.map((i) => i.toJson()).toList(),
};
factory FloorPlan.fromJson(Map<String, dynamic> j) => FloorPlan(
outline: (j['outline'] as List).map((x) => WallPoint.fromJson(x as Map<String, dynamic>)).toList(),
items: (j['items'] as List).map((x) => FloorPlanItem.fromJson(x as Map<String, dynamic>)).toList(),
);
}

class Room {
final String id;
String name;
double length;
double width;
double height;
FloorPlan? floorPlan;
String? panoramaPath;
bool isDone;
Room({required this.id, required this.name, this.length = 0, this.width = 0, this.height = 2.7, this.floorPlan, this.panoramaPath, this.isDone = false});
double get area => length * width;
Map<String, dynamic> toJson() => {
'id': id,
'name': name,
'length': length,
'width': width,
'height': height,
if (floorPlan != null) 'floorPlan': floorPlan!.toJson(),
if (panoramaPath != null) 'panoramaPath': panoramaPath,
'isDone': isDone,
};
factory Room.fromJson(Map<String, dynamic> j) => Room(
id: j['id'] as String,
name: j['name'] as String,
length: (j['length'] as num).toDouble(),
width: (j['width'] as num).toDouble(),
height: (j['height'] as num).toDouble(),
floorPlan: j['floorPlan'] != null ? FloorPlan.fromJson(j['floorPlan'] as Map<String, dynamic>) : null,
panoramaPath: j['panoramaPath'] as String?,
isDone: j['isDone'] as bool? ?? false,
);
}

class PriceItem {
final String id;
String name;
String unit;
double price;
PriceItem({required this.id, required this.name, required this.unit, required this.price});
Map<String, dynamic> toJson() => {'id': id, 'name': name, 'unit': unit, 'price': price};
factory PriceItem.fromJson(Map<String, dynamic> j) => PriceItem(
id: j['id'] as String,
name: j['name'] as String,
unit: j['unit'] as String,
price: (j['price'] as num).toDouble(),
);
}

class EstimateItem {
final String id;
String name;
String unit;
double quantity;
double price;
EstimateItem({required this.id, required this.name, required this.unit, required this.quantity, required this.price});
double get total => quantity * price;
Map<String, dynamic> toJson() => {'id': id, 'name': name, 'unit': unit, 'quantity': quantity, 'price': price};
factory EstimateItem.fromJson(Map<String, dynamic> j) => EstimateItem(
id: j['id'] as String,
name: j['name'] as String,
unit: j['unit'] as String,
quantity: (j['quantity'] as num).toDouble(),
price: (j['price'] as num).toDouble(),
);
}
class Attachment {
final String id;
String name;
String path;
Attachment({required this.id, required this.name, required this.path});
Map<String, dynamic> toJson() => {'id': id, 'name': name, 'path': path};
factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
id: j['id'] as String,
name: j['name'] as String,
path: j['path'] as String,
);
}

class ChatMessage {
final String id;
final String role;
final String text;
ChatMessage({required this.id, required this.role, required this.text});
Map<String, dynamic> toJson() => {'id': id, 'role': role, 'text': text};
factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
id: j['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
role: j['role'] as String,
text: j['text'] as String,
);
}

class TemplateItem {
String name;
String unit;
double quantity;
double price;
TemplateItem({required this.name, required this.unit, required this.quantity, required this.price});
Map<String, dynamic> toJson() => {'name': name, 'unit': unit, 'quantity': quantity, 'price': price};
factory TemplateItem.fromJson(Map<String, dynamic> j) => TemplateItem(
name: j['name'] as String,
unit: j['unit'] as String,
quantity: (j['quantity'] as num).toDouble(),
price: (j['price'] as num).toDouble(),
);
}

class EstimateTemplate {
final String id;
String name;
final List<TemplateItem> items;
EstimateTemplate({required this.id, required this.name, required this.items});
Map<String, dynamic> toJson() => {'id': id, 'name': name, 'items': items.map((i) => i.toJson()).toList()};
factory EstimateTemplate.fromJson(Map<String, dynamic> j) => EstimateTemplate(
id: j['id'] as String,
name: j['name'] as String,
items: (j['items'] as List).map((x) => TemplateItem.fromJson(x as Map<String, dynamic>)).toList(),
);
}

class Project {
final String id;
String name;
final List<Room> rooms = [];
final List<EstimateItem> estimateItems = [];
final List<Attachment> attachments = [];
final List<ChatMessage> chatMessages = [];
Project({required this.id, required this.name});

Map<String, dynamic> toJson() => {
'id': id,
'name': name,
'rooms': rooms.map((r) => r.toJson()).toList(),
'estimateItems': estimateItems.map((e) => e.toJson()).toList(),
'attachments': attachments.map((a) => a.toJson()).toList(),
'chatMessages': chatMessages.map((c) => c.toJson()).toList(),
};

factory Project.fromJson(Map<String, dynamic> j) {
final p = Project(id: j['id'] as String, name: j['name'] as String);
p.rooms.addAll((j['rooms'] as List).map((x) => Room.fromJson(x as Map<String, dynamic>)));
p.estimateItems.addAll((j['estimateItems'] as List).map((x) => EstimateItem.fromJson(x as Map<String, dynamic>)));
p.attachments.addAll((j['attachments'] as List).map((x) => Attachment.fromJson(x as Map<String, dynamic>)));
p.chatMessages.addAll((j['chatMessages'] as List).map((x) => ChatMessage.fromJson(x as Map<String, dynamic>)));
return p;
}
}
class AppState extends ChangeNotifier {
bool loaded = false;
int _seq = 0;
String _nextId() => '${++_seq}_${DateTime.now().millisecondsSinceEpoch}';

static const _storageKey = 'app_state_v1';

final List<Project> projects = [];
String activeProjectId = '';

final List<PriceItem> priceList = [];
final List<EstimateTemplate> templates = [];

AppState() {
_init();
}

Future<void> _init() async {
try {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_storageKey);
if (raw != null) {
final data = jsonDecode(raw) as Map<String, dynamic>;
_seq = data['seq'] as int? ?? 0;
final loadedProjects = (data['projects'] as List)
.map((x) => Project.fromJson(x as Map<String, dynamic>))
.toList();
final loadedPrices = (data['priceList'] as List)
.map((x) => PriceItem.fromJson(x as Map<String, dynamic>))
.toList();
final loadedTemplates = ((data['templates'] as List?) ?? [])
.map((x) => EstimateTemplate.fromJson(x as Map<String, dynamic>))
.toList();
if (loadedProjects.isNotEmpty) {
projects.addAll(loadedProjects);
priceList.addAll(loadedPrices);
templates.addAll(loadedTemplates);
activeProjectId = data['activeProjectId'] as String? ?? projects.first.id;
loaded = true;
notifyListeners();
return;
}
}
} catch (_) {
// Повреждённые или несовместимые данные — продолжаем с чистого листа.
}

final p = Project(id: _nextId(), name: 'Новый объект');
projects.add(p);
activeProjectId = p.id;

priceList.addAll([
PriceItem(id: _nextId(), name: 'Поклейка обоев', unit: 'м²', price: 350),
PriceItem(id: _nextId(), name: 'Укладка ламината', unit: 'м²', price: 500),
PriceItem(id: _nextId(), name: 'Покраска стен', unit: 'м²', price: 250),
PriceItem(id: _nextId(), name: 'Штукатурка стен', unit: 'м²', price: 450),
PriceItem(id: _nextId(), name: 'Демонтаж старой отделки', unit: 'м²', price: 200),
]);

loaded = true;
notifyListeners();
await _persist();
}

Future<void> _persist() async {
try {
final prefs = await SharedPreferences.getInstance();
final data = {
'seq': _seq,
'activeProjectId': activeProjectId,
'projects': projects.map((p) => p.toJson()).toList(),
'priceList': priceList.map((p) => p.toJson()).toList(),
'templates': templates.map((t) => t.toJson()).toList(),
};
await prefs.setString(_storageKey, jsonEncode(data));
} catch (_) {
// Сохранение — best effort, не должно ронять приложение при ошибке.
}
}

Project get activeProject =>
projects.firstWhere((p) => p.id == activeProjectId, orElse: () => projects.first);

void setActiveProject(String id) {
activeProjectId = id;
notifyListeners();
_persist();
}

void addProject(String name) {
final p = Project(id: _nextId(), name: name);
projects.add(p);
activeProjectId = p.id;
notifyListeners();
_persist();
}

void addRoom(String name, double length, double width, double height) {
activeProject.rooms.add(Room(id: _nextId(), name: name, length: length, width: width, height: height));
notifyListeners();
_persist();
}

void removeRoom(String id) {
activeProject.rooms.removeWhere((r) => r.id == id);
notifyListeners();
_persist();
}

void insertRoom(int index, Room room) {
final i = index.clamp(0, activeProject.rooms.length);
activeProject.rooms.insert(i, room);
notifyListeners();
_persist();
}

void toggleRoomDone(String id) {
final room = activeProject.rooms.firstWhere((r) => r.id == id);
room.isDone = !room.isDone;
notifyListeners();
_persist();
}

void saveRoomFloorPlan(String roomId, FloorPlan plan) {
final room = activeProject.rooms.firstWhere((r) => r.id == roomId);
room.floorPlan = plan;
notifyListeners();
_persist();
}

void saveRoomPanorama(String roomId, String path) {
final room = activeProject.rooms.firstWhere((r) => r.id == roomId);
room.panoramaPath = path;
notifyListeners();
_persist();
}

void clearRoomPanorama(String roomId) {
final room = activeProject.rooms.firstWhere((r) => r.id == roomId);
room.panoramaPath = null;
notifyListeners();
_persist();
}

void addPriceItem(String name, String unit, double price) {
priceList.add(PriceItem(id: _nextId(), name: name, unit: unit, price: price));
notifyListeners();
_persist();
}

void removePriceItem(String id) {
priceList.removeWhere((p) => p.id == id);
notifyListeners();
_persist();
}

void insertPriceItem(int index, PriceItem item) {
final i = index.clamp(0, priceList.length);
priceList.insert(i, item);
notifyListeners();
_persist();
}

int importPriceListCsv(String csvText) {
final lines = csvText.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
final imported = <PriceItem>[];
for (final line in lines) {
final parts = line.split(RegExp(r'[,;]'));
if (parts.length < 3) continue;
final name = parts[0].trim();
final unit = parts[1].trim();
final price = double.tryParse(parts[2].trim().replaceAll(',', '.'));
if (name.isEmpty || price == null) continue;
imported.add(PriceItem(id: _nextId(), name: name, unit: unit.isEmpty ? 'шт' : unit, price: price));
}
if (imported.isNotEmpty) {
priceList
..clear()
..addAll(imported);
notifyListeners();
_persist();
}
return imported.length;
}
void addEstimateItem(String name, String unit, double quantity, double price) {
activeProject.estimateItems.add(EstimateItem(id: _nextId(), name: name, unit: unit, quantity: quantity, price: price));
notifyListeners();
_persist();
}

void removeEstimateItem(String id) {
activeProject.estimateItems.removeWhere((e) => e.id == id);
notifyListeners();
_persist();
}

void insertEstimateItem(int index, EstimateItem item) {
final i = index.clamp(0, activeProject.estimateItems.length);
activeProject.estimateItems.insert(i, item);
notifyListeners();
_persist();
}

void updateEstimateItem(String id, {String? name, String? unit, double? quantity, double? price}) {
final item = activeProject.estimateItems.firstWhere((e) => e.id == id);
if (name != null) item.name = name;
if (unit != null) item.unit = unit;
if (quantity != null) item.quantity = quantity;
if (price != null) item.price = price;
notifyListeners();
_persist();
}

double get estimateTotal => activeProject.estimateItems.fold(0.0, (s, i) => s + i.total);

void addAttachment(String name, String path) {
activeProject.attachments.add(Attachment(id: _nextId(), name: name, path: path));
notifyListeners();
_persist();
}

void removeAttachment(String id) {
activeProject.attachments.removeWhere((a) => a.id == id);
notifyListeners();
_persist();
}

void addChatMessage(String role, String text) {
activeProject.chatMessages.add(ChatMessage(id: _nextId(), role: role, text: text));
notifyListeners();
_persist();
}

void removeChatMessage(String id) {
activeProject.chatMessages.removeWhere((m) => m.id == id);
notifyListeners();
_persist();
}

void insertChatMessage(int index, ChatMessage message) {
final i = index.clamp(0, activeProject.chatMessages.length);
activeProject.chatMessages.insert(i, message);
notifyListeners();
_persist();
}

void clearChat() {
activeProject.chatMessages.clear();
notifyListeners();
_persist();
}

void saveCurrentAsTemplate(String name) {
final items = activeProject.estimateItems
.map((e) => TemplateItem(name: e.name, unit: e.unit, quantity: e.quantity, price: e.price))
.toList();
templates.add(EstimateTemplate(id: _nextId(), name: name, items: items));
notifyListeners();
_persist();
}

void applyTemplate(String templateId) {
final tpl = templates.firstWhere((t) => t.id == templateId);
for (final item in tpl.items) {
activeProject.estimateItems.add(EstimateItem(
id: _nextId(),
name: item.name,
unit: item.unit,
quantity: item.quantity,
price: item.price,
));
}
notifyListeners();
_persist();
}

void removeTemplate(String id) {
templates.removeWhere((t) => t.id == id);
notifyListeners();
_persist();
}

String exportBackupJson() {
final data = {
'seq': _seq,
'activeProjectId': activeProjectId,
'projects': projects.map((p) => p.toJson()).toList(),
'priceList': priceList.map((p) => p.toJson()).toList(),
'templates': templates.map((t) => t.toJson()).toList(),
'exportedAt': DateTime.now().toIso8601String(),
};
return const JsonEncoder.withIndent('  ').convert(data);
}

Future<void> importBackupJson(String raw) async {
final data = jsonDecode(raw) as Map<String, dynamic>;
final newProjects = (data['projects'] as List)
.map((x) => Project.fromJson(x as Map<String, dynamic>))
.toList();
final newPrices = (data['priceList'] as List)
.map((x) => PriceItem.fromJson(x as Map<String, dynamic>))
.toList();
final newTemplates = ((data['templates'] as List?) ?? [])
.map((x) => EstimateTemplate.fromJson(x as Map<String, dynamic>))
.toList();
if (newProjects.isEmpty) {
throw Exception('В файле резервной копии нет объектов');
}
projects
..clear()
..addAll(newProjects);
priceList
..clear()
..addAll(newPrices);
templates
..clear()
..addAll(newTemplates);
activeProjectId = data['activeProjectId'] as String? ?? projects.first.id;
_seq = data['seq'] as int? ?? _seq;
notifyListeners();
await _persist();
}
}

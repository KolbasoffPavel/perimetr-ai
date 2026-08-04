import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Room {
final String id;
String name;
double length;
double width;
double height;
Room({required this.id, required this.name, this.length = 0, this.width = 0, this.height = 2.7});
double get area => length * width;
Map<String, dynamic> toJson() => {'id': id, 'name': name, 'length': length, 'width': width, 'height': height};
factory Room.fromJson(Map<String, dynamic> j) => Room(
id: j['id'] as String,
name: j['name'] as String,
length: (j['length'] as num).toDouble(),
width: (j['width'] as num).toDouble(),
height: (j['height'] as num).toDouble(),
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
final String role;
final String text;
ChatMessage({required this.role, required this.text});
Map<String, dynamic> toJson() => {'role': role, 'text': text};
factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(role: j['role'] as String, text: j['text'] as String);
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

/// Общее состояние приложения: объекты (проекты), их помещения, сметы,
/// вложения и переписка с ИИ, плюс общий прайс-лист. Автоматически
/// сохраняется на устройство и восстанавливается при следующем запуске.
class AppState extends ChangeNotifier {
bool loaded = false;
int _seq = 0;
String _nextId() => '${++_seq}_${DateTime.now().millisecondsSinceEpoch}';

static const _storageKey = 'app_state_v1';

final List<Project> projects = [];
String activeProjectId = '';

final List<PriceItem> priceList = [];

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
if (loadedProjects.isNotEmpty) {
projects.addAll(loadedProjects);
priceList.addAll(loadedPrices);
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
activeProject.chatMessages.add(ChatMessage(role: role, text: text));
notifyListeners();
_persist();
}
}

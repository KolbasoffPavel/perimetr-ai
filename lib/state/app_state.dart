import 'package:flutter/foundation.dart';

class Room {
final String id;
String name;
double length;
double width;
double height;
Room({required this.id, required this.name, this.length = 0, this.width = 0, this.height = 2.7});
double get area => length * width;
}

class PriceItem {
final String id;
String name;
String unit;
double price;
PriceItem({required this.id, required this.name, required this.unit, required this.price});
}

class EstimateItem {
final String id;
String name;
String unit;
double quantity;
double price;
EstimateItem({required this.id, required this.name, required this.unit, required this.quantity, required this.price});
double get total => quantity * price;
}

class Attachment {
final String id;
String name;
String path;
Attachment({required this.id, required this.name, required this.path});
}

class ChatMessage {
final String role;
final String text;
ChatMessage({required this.role, required this.text});
}

class Project {
final String id;
String name;
final List<Room> rooms = [];
final List<EstimateItem> estimateItems = [];
final List<Attachment> attachments = [];
final List<ChatMessage> chatMessages = [];
Project({required this.id, required this.name});
}

/// Общее состояние приложения: объекты (проекты), их помещения, сметы,
/// вложения и переписка с ИИ, плюс общий прайс-лист.
class AppState extends ChangeNotifier {
bool loaded = false;
int _seq = 0;
String _nextId() => '${++_seq}_${DateTime.now().millisecondsSinceEpoch}';

final List<Project> projects = [];
String activeProjectId = '';

final List<PriceItem> priceList = [];

AppState() {
_init();
}

Future<void> _init() async {
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
}

Project get activeProject =>
projects.firstWhere((p) => p.id == activeProjectId, orElse: () => projects.first);

void setActiveProject(String id) {
activeProjectId = id;
notifyListeners();
}

void addProject(String name) {
final p = Project(id: _nextId(), name: name);
projects.add(p);
activeProjectId = p.id;
notifyListeners();
}

void addRoom(String name, double length, double width, double height) {
activeProject.rooms.add(Room(id: _nextId(), name: name, length: length, width: width, height: height));
notifyListeners();
}

void removeRoom(String id) {
activeProject.rooms.removeWhere((r) => r.id == id);
notifyListeners();
}

void addPriceItem(String name, String unit, double price) {
priceList.add(PriceItem(id: _nextId(), name: name, unit: unit, price: price));
notifyListeners();
}

void removePriceItem(String id) {
priceList.removeWhere((p) => p.id == id);
notifyListeners();
}

void addEstimateItem(String name, String unit, double quantity, double price) {
activeProject.estimateItems.add(EstimateItem(id: _nextId(), name: name, unit: unit, quantity: quantity, price: price));
notifyListeners();
}

void removeEstimateItem(String id) {
activeProject.estimateItems.removeWhere((e) => e.id == id);
notifyListeners();
}

double get estimateTotal => activeProject.estimateItems.fold(0.0, (s, i) => s + i.total);

void addAttachment(String name, String path) {
activeProject.attachments.add(Attachment(id: _nextId(), name: name, path: path));
notifyListeners();
}

void removeAttachment(String id) {
activeProject.attachments.removeWhere((a) => a.id == id);
notifyListeners();
}

void addChatMessage(String role, String text) {
activeProject.chatMessages.add(ChatMessage(role: role, text: text));
notifyListeners();
}
}

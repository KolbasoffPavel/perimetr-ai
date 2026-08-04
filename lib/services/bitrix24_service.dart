import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_store.dart';

/// Интеграция с Bitrix24: проверка вебхука и выгрузка сметы как сделки.
class Bitrix24Service {
final SettingsStore settings;
Bitrix24Service(this.settings);

Future<bool> testConnection() async {
final url = await settings.getBitrix24WebhookUrl();
if (url == null || url.isEmpty) return false;
try {
final response = await http.get(Uri.parse('${url}profile'));
return response.statusCode == 200;
} catch (_) {
return false;
}
}

/// Создаёт сделку в Bitrix24 CRM на основе сметы объекта.
/// Возвращает ID созданной сделки или бросает исключение с описанием ошибки.
Future<String> pushEstimateAsDeal({
required String projectName,
required List<Map<String, dynamic>> items,
required double total,
}) async {
final url = await settings.getBitrix24WebhookUrl();
if (url == null || url.isEmpty) {
throw Exception('Сначала укажите URL вебхука Bitrix24 в Настройках');
}

final comments = StringBuffer('Смета из приложения ПЕРИМЕТР:\n');
for (final item in items) {
comments.writeln('- ${item['name']}: ${item['quantity']} ${item['unit']} × ${item['price']} ₽ = ${item['total']} ₽');
}
comments.writeln('\nИтого: $total ₽');

final response = await http.post(
Uri.parse('${url}crm.deal.add'),
headers: {'content-type': 'application/json'},
body: jsonEncode({
'fields': {
'TITLE': 'Смета: $projectName',
'OPPORTUNITY': total,
'COMMENTS': comments.toString(),
},
}),
);

if (response.statusCode != 200) {
throw Exception('Ошибка Bitrix24 (${response.statusCode}): ${response.body}');
}

final data = jsonDecode(utf8.decode(response.bodyBytes));
if (data['error'] != null) {
throw Exception('Bitrix24: ${data['error_description'] ?? data['error']}');
}
return data['result'].toString();
}
}

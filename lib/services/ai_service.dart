import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Обёртка над собственным прокси-сервером (Cloudflare Worker), который
/// хранит ключи Anthropic и Cloudflare AI на стороне сервера. Приложение
/// НЕ содержит и НЕ хранит эти ключи — только адрес прокси и общий пароль
/// для защиты от постороннего использования (см. server/README.md).
class AiService {
  static const _proxyEndpoint = 'https://perimetr-ai-proxy.koolbasoff-pavel.workers.dev/';
  static const _appSharedSecret = 'Badman777';
  static const _model = 'claude-sonnet-4-5-20250929';

  Future<String> _send(List<Map<String, dynamic>> messages) async {
    final response = await http.post(
      Uri.parse(_proxyEndpoint),
      headers: {
        'content-type': 'application/json',
        'x-app-secret': _appSharedSecret,
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'messages': messages,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Ошибка сервера (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final content = data['content'] as List;
    final buffer = StringBuffer();
    for (final block in content) {
      if (block['type'] == 'text') buffer.write(block['text']);
    }
    return buffer.toString();
  }

  Future<String> chat(List<Map<String, String>> history) async {
    final messages = history
        .map((m) => {'role': m['role'], 'content': m['text']})
        .toList();
    return _send(messages);
  }

  Future<String> analyzeImage(String base64Image, String mediaType, String prompt) async {
    final messages = [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image',
            'source': {'type': 'base64', 'media_type': mediaType, 'data': base64Image},
          },
          {'type': 'text', 'text': prompt},
        ],
      }
    ];
    return _send(messages);
  }

  Future<Map<String, dynamic>> estimateRoomDimensions(String base64Image, String mediaType) async {
    final raw = await analyzeImage(
      base64Image,
      mediaType,
      'Оцени примерные размеры помещения на фото в метрах, ориентируясь на '
      'стандартные объекты (высота дверного проёма ~2 м, розетка ~0.3 м от '
      'пола и т.п.). Ответь СТРОГО в формате JSON без markdown-разметки и '
      'пояснений, только одна строка: {"length": число, "width": число, "height": число}',
    );
    final jsonStr = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  Future<Uint8List> visualizeRenovation(String base64Image, String prompt) async {
    final response = await http.post(
      Uri.parse('${_proxyEndpoint}visualize'),
      headers: {
        'content-type': 'application/json',
        'x-app-secret': _appSharedSecret,
      },
      body: jsonEncode({'image': base64Image, 'prompt': prompt}),
    );
    if (response.statusCode != 200) {
      throw Exception('Ошибка визуализации (${response.statusCode}): ${response.body}');
    }
    return response.bodyBytes;
  }
  /// Создаёт ссылку на смету для клиента (веб-страница с онлайн-согласованием).
  Future<String> createEstimateShareLink({
    required String projectName,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    final response = await http.post(
      Uri.parse('${_proxyEndpoint}estimate'),
      headers: {
        'content-type': 'application/json',
        'x-app-secret': _appSharedSecret,
      },
      body: jsonEncode({'projectName': projectName, 'items': items, 'total': total}),
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось создать ссылку (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['url'] as String;
  }

  /// Проверяет, согласовал ли клиент смету по ранее выданной ссылке.
  Future<bool> checkEstimateApproved(String estimateId) async {
    final response = await http.get(
      Uri.parse('${_proxyEndpoint}estimate/$estimateId/status'),
      headers: {'x-app-secret': _appSharedSecret},
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['approved'] == true;
  }

  /// Отправляет отчёт о сбое на сервер (лёгкая замена Firebase Crashlytics
  /// без необходимости заводить отдельный аккаунт — видно в логах Worker'а).
  Future<void> reportCrash(String error, String stackTrace) async {
    try {
      await http.post(
        Uri.parse('${_proxyEndpoint}crash-report'),
        headers: {
          'content-type': 'application/json',
          'x-app-secret': _appSharedSecret,
        },
        body: jsonEncode({
          'error': error,
          'stack': stackTrace,
          'time': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // Не удалось отправить отчёт — не критично, приложение продолжает работу.
    }
  }
}

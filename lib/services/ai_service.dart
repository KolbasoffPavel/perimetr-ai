import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Обёртка над собственным прокси-сервером (Cloudflare Worker на своём
/// домене), который хранит ключи Anthropic и Cloudflare AI на стороне
/// сервера. Приложение НЕ содержит и НЕ хранит эти ключи — только адрес
/// прокси и общий пароль для защиты от постороннего использования
/// (см. server/README.md).
class AiService {
  static const _proxyEndpoint = 'https://api.perimetr-app.uk/';
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
    return analyzeImages([(base64Image, mediaType)], prompt);
  }

  /// То же самое, но можно передать сразу несколько фото одного помещения
  /// (например, из разных углов) — это заметно повышает точность оценки
  /// формы и размеров по сравнению с одним снимком.
  Future<String> analyzeImages(List<(String, String)> images, String prompt) async {
    final content = <Map<String, dynamic>>[
      for (final img in images)
        {
          'type': 'image',
          'source': {'type': 'base64', 'media_type': img.$2, 'data': img.$1},
        },
      {'type': 'text', 'text': prompt},
    ];
    final messages = [
      {'role': 'user', 'content': content}
    ];
    return _send(messages);
  }
  Future<Map<String, dynamic>> estimateRoomDimensions(String base64Image, String mediaType) async {
    return estimateRoomDimensionsMulti([(base64Image, mediaType)]);
  }

  /// Оценивает размеры помещения по одному или нескольким фото (в метрах),
  /// опираясь на стандартные ориентиры (высота дверного проёма ~2 м,
  /// розетка ~0.3 м от пола и т.п.). Несколько фото из разных углов
  /// помещения дают заметно более точный результат, чем один снимок.
  Future<Map<String, dynamic>> estimateRoomDimensionsMulti(List<(String, String)> images) async {
    final raw = await analyzeImages(
      images,
      'На фото ${images.length == 1 ? "одно помещение" : "одно и то же помещение с ${images.length} разных ракурсов"}. '
      'Оцени примерные размеры помещения в метрах, ориентируясь на стандартные объекты '
      '(высота дверного проёма ~2 м, розетка ~0.3 м от пола и т.п.). Если снимков несколько — '
      'сопоставь их между собой для более точной оценки формы и размеров помещения. '
      'Ответь СТРОГО в формате JSON без markdown-разметки и пояснений, только одна строка: '
      '{"length": число, "width": число, "height": число}',
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

  Future<bool> checkEstimateApproved(String estimateId) async {
    final response = await http.get(
      Uri.parse('${_proxyEndpoint}estimate/$estimateId/status'),
      headers: {'x-app-secret': _appSharedSecret},
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['approved'] == true;
  }

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

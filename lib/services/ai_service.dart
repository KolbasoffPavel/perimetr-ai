import 'dart:convert';
import 'package:http/http.dart' as http;

/// Обёртка над собственным прокси-сервером (Cloudflare Worker), который
/// хранит ключ Anthropic на стороне сервера. Приложение НЕ содержит и
/// НЕ хранит ключ Anthropic — только адрес прокси и общий пароль для
/// защиты от постороннего использования (см. server/README.md).
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
}

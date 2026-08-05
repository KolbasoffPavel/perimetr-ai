import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Обходит системный DNS-резолвер устройства (у части пользователей он не
/// может найти адрес нашего сервера, хотя браузер на том же телефоне и той
/// же сети открывает его без проблем). Резолвит домены через DNS-over-HTTPS
/// (Cloudflare 1.1.1.1) — тем же способом, каким это делают браузеры.
class DohHttpOverrides extends HttpOverrides {
  static final Map<String, String> _cache = {};

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
      if (InternetAddress.tryParse(uri.host) != null) {
        return Socket.startConnect(uri.host, uri.port);
      }
      final ip = await _resolve(uri.host);
      if (ip == null) {
        // DoH не удался — пробуем как обычно, через системный DNS.
        return Socket.startConnect(uri.host, uri.port);
      }
      return Socket.startConnect(ip, uri.port);
    };
    return client;
  }

  static Future<String?> _resolve(String host) async {
    if (_cache.containsKey(host)) return _cache[host];
    try {
      final response = await http
          .get(
            Uri.parse('https://1.1.1.1/dns-query?name=$host&type=A'),
            headers: {'accept': 'application/dns-json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final answers = data['Answer'] as List?;
      if (answers == null || answers.isEmpty) return null;
      for (final a in answers) {
        if (a['type'] == 1) {
          final ip = a['data'] as String;
          _cache[host] = ip;
          return ip;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

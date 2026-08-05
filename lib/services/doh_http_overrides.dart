import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Обходит системный DNS-резолвер устройства (у части пользователей он не
/// может найти адрес нашего сервера, хотя браузер на том же телефоне и той
/// же сети открывает его без проблем). Резолвит домены через DNS-over-HTTPS
/// (сначала Cloudflare, затем Google как запасной вариант) — тем же
/// способом, каким это делают браузеры.
class DohHttpOverrides extends HttpOverrides {
  static final Map<String, String> _cache = {};

  static const _resolvers = [
    ('1.1.1.1', '/dns-query'),
    ('8.8.8.8', '/resolve'),
  ];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
      if (InternetAddress.tryParse(uri.host) != null) {
        return Socket.startConnect(uri.host, uri.port);
      }
      final ip = await _resolve(uri.host);
      return Socket.startConnect(ip, uri.port);
    };
    return client;
  }

  static Future<String> _resolve(String host) async {
    if (_cache.containsKey(host)) return _cache[host]!;
    final errors = <String>[];
    for (final resolver in _resolvers) {
      final ip = resolver.$1;
      final path = resolver.$2;
      try {
        final response = await http
            .get(
              Uri.parse('https://$ip$path?name=$host&type=A'),
              headers: {'accept': 'application/dns-json'},
            )
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) {
          errors.add('$ip: HTTP ${response.statusCode}');
          continue;
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = data['Answer'] as List?;
        if (answers == null || answers.isEmpty) {
          errors.add('$ip: нет A-записи в ответе');
          continue;
        }
        for (final a in answers) {
          if (a['type'] == 1) {
            final resolvedIp = a['data'] as String;
            _cache[host] = resolvedIp;
            return resolvedIp;
          }
        }
        errors.add('$ip: в ответе нет типа A');
      } catch (e) {
        errors.add('$ip: $e');
      }
    }
    throw SocketException(
      'DNS-over-HTTPS не смог найти адрес для $host (пробовали ${_resolvers.map((r) => r.$1).join(", ")}). '
      'Подробности: ${errors.join(" | ")}',
    );
  }
}

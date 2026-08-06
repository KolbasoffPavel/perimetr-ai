import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray/flutter_v2ray.dart';

/// Один сервер из подписки: имя и готовая конфигурация V2Ray/Xray.
class VpnServer {
final String remark;
final String config;
VpnServer({required this.remark, required this.config});
}

/// Встроенный VPN-клиент (V2Ray/Xray) с поддержкой ссылки-подписки —
/// той же самой, что используется в обычных VPN-приложениях (Happ и т.п.).
/// Позволяет обойтись без стороннего VPN-приложения на телефоне.
class V2RayService {
static FlutterV2ray? _v2ray;
static bool _initialized = false;

/// Должен быть вызван один раз при старте экрана VPN, с обработчиком
/// изменения статуса подключения.
static Future<void> init(void Function(V2RayStatus) onStatusChanged) async {
_v2ray = FlutterV2ray(onStatusChanged: onStatusChanged);
if (!_initialized) {
await _v2ray!.initializeV2Ray();
_initialized = true;
}
}

/// Загружает подписку по ссылке и разбирает её на список серверов.
/// Подписки обычно закодированы в base64 и содержат по одной ссылке
/// (vmess://, vless://, trojan://, ss://) на строку.
static Future<List<VpnServer>> fetchSubscription(String url) async {
final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
if (response.statusCode != 200) {
throw Exception('Не удалось загрузить подписку (${response.statusCode})');
}
final raw = response.body.trim();
String decoded;
try {
decoded = utf8.decode(base64.decode(base64.normalize(raw)));
} catch (_) {
decoded = raw;
}
final lines = decoded.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
final servers = <VpnServer>[];
for (final line in lines) {
try {
final parsed = FlutterV2ray.parseFromURL(line.trim());
servers.add(VpnServer(remark: parsed.remark, config: parsed.getFullConfiguration()));
} catch (_) {
// пропускаем строки, которые не являются ссылками на сервер
}
}
if (servers.isEmpty) {
throw Exception('В подписке не найдено ни одного сервера');
}
return servers;
}
/// Запрашивает разрешение на VPN у системы Android и поднимает тоннель.
/// Возвращает false, если пользователь отклонил системный запрос.
static Future<bool> connect(VpnServer server) async {
final v2ray = _v2ray;
if (v2ray == null) throw Exception('V2RayService не инициализирован');
final granted = await v2ray.requestPermission();
if (!granted) return false;
await v2ray.startV2Ray(
remark: server.remark,
config: server.config,
proxyOnly: false,
notificationDisconnectButtonName: 'Отключить',
);
return true;
}

static Future<void> disconnect() async {
await _v2ray?.stopV2Ray();
}

static Future<int> ping(VpnServer server) async {
final v2ray = _v2ray;
if (v2ray == null) return -1;
return v2ray.getServerDelay(config: server.config);
}
}

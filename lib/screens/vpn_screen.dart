import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../services/settings_store.dart';
import '../services/v2ray_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bento_card.dart';

/// Встроенный VPN-клиент: ссылка-подписка -> список серверов -> подключение.
/// Позволяет обойтись без стороннего VPN-приложения, если сеть блокирует
/// доступ к серверу ПЕРИМЕТРа напрямую.
class VpnScreen extends StatefulWidget {
const VpnScreen({super.key});
@override
State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
final _settings = SettingsStore();
final _urlCtrl = TextEditingController();
List<VpnServer> _servers = [];
VpnServer? _connectedServer;
bool _loadingSub = false;
bool _connecting = false;
String? _error;
String _statusText = 'Отключено';

@override
void initState() {
super.initState();
_init();
}

Future<void> _init() async {
await V2RayService.init((status) {
if (mounted) setState(() => _statusText = status.toString());
});
final saved = await _settings.getVpnSubscriptionUrl();
if (saved != null && saved.isNotEmpty) {
_urlCtrl.text = saved;
_loadSubscription();
}
}

Future<void> _loadSubscription() async {
final url = _urlCtrl.text.trim();
if (url.isEmpty) return;
setState(() {
_loadingSub = true;
_error = null;
});
try {
final servers = await V2RayService.fetchSubscription(url);
await _settings.setVpnSubscriptionUrl(url);
setState(() => _servers = servers);
} catch (e) {
setState(() => _error = 'Ошибка загрузки подписки: $e');
} finally {
setState(() => _loadingSub = false);
}
}

Future<void> _connect(VpnServer server) async {
setState(() {
_connecting = true;
_error = null;
});
try {
final ok = await V2RayService.connect(server);
if (ok) {
setState(() => _connectedServer = server);
} else {
setState(() => _error = 'Разрешение на VPN не получено');
}
} catch (e) {
setState(() => _error = 'Ошибка подключения: $e');
} finally {
setState(() => _connecting = false);
}
}

Future<void> _disconnect() async {
await V2RayService.disconnect();
setState(() => _connectedServer = null);
}
@override
Widget build(BuildContext context) {
final c = context.colors;

return Scaffold(
backgroundColor: c.background,
appBar: AppBar(title: const Text('VPN')),
body: SafeArea(
child: ListView(
padding: const EdgeInsets.all(16),
children: [
BentoCard(
title: 'Подписка',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Вставьте ссылку-подписку от вашего VPN-провайдера (та же, что используется в Happ и подобных приложениях).',
style: TextStyle(fontSize: 12, color: c.secondaryLabel),
),
const SizedBox(height: 12),
TextField(
controller: _urlCtrl,
style: TextStyle(color: c.label),
decoration: const InputDecoration(hintText: 'https://...'),
),
const SizedBox(height: 12),
GradientButton(
label: _loadingSub ? 'Загрузка...' : 'Загрузить серверы',
icon: Icons.cloud_download,
onPressed: _loadSubscription,
),
],
),
),
const SizedBox(height: 8),
BentoCard(
title: 'Статус',
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(_statusText, style: TextStyle(color: c.label, fontSize: 13)),
if (_connectedServer != null) ...[
const SizedBox(height: 8),
Text('Сервер: ${_connectedServer!.remark}', style: TextStyle(color: c.secondaryLabel, fontSize: 12)),
const SizedBox(height: 12),
OutlinedButton(onPressed: _disconnect, child: const Text('Отключить VPN')),
],
],
),
),
if (_error != null)
Padding(
padding: const EdgeInsets.only(top: 12),
child: Text(_error!, style: TextStyle(color: c.destructive, fontSize: 12)),
),
const SizedBox(height: 8),
if (_servers.isNotEmpty)
...(_servers.map((s) => BentoCard(
child: Row(
children: [
Expanded(
child: Text(s.remark, style: TextStyle(color: c.label)),
),
if (_connectedServer == s)
Icon(Icons.check_circle, color: c.accent)
else
TextButton(
onPressed: _connecting ? null : () => _connect(s),
child: Text(_connecting ? '...' : 'Подключить'),
),
],
),
))),
],
),
),
);
}
}

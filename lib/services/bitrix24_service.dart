import 'package:http/http.dart' as http;
import 'settings_store.dart';

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
}

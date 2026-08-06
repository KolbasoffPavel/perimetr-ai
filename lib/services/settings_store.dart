import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsStore {
final _storage = const FlutterSecureStorage();

static const _kAnthropicKey = 'anthropic_api_key';
static const _kApp101ClientId = 'app101_client_id';
static const _kApp101ClientSecret = 'app101_client_secret';
static const _kBitrixWebhook = 'bitrix24_webhook_url';
static const _kVpnSubscriptionUrl = 'vpn_subscription_url';

Future<String?> getAnthropicKey() => _storage.read(key: _kAnthropicKey);
Future<void> setAnthropicKey(String v) => _storage.write(key: _kAnthropicKey, value: v);

Future<String?> getApp101ClientId() => _storage.read(key: _kApp101ClientId);
Future<void> setApp101ClientId(String v) => _storage.write(key: _kApp101ClientId, value: v);

Future<String?> getApp101ClientSecret() => _storage.read(key: _kApp101ClientSecret);
Future<void> setApp101ClientSecret(String v) => _storage.write(key: _kApp101ClientSecret, value: v);

Future<String?> getBitrix24WebhookUrl() => _storage.read(key: _kBitrixWebhook);
Future<void> setBitrix24WebhookUrl(String v) => _storage.write(key: _kBitrixWebhook, value: v);

Future<String?> getVpnSubscriptionUrl() => _storage.read(key: _kVpnSubscriptionUrl);
Future<void> setVpnSubscriptionUrl(String v) => _storage.write(key: _kVpnSubscriptionUrl, value: v);
}

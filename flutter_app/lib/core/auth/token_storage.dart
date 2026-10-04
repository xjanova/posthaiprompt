// Thaiprompt POS — Secure token storage.
//
// Sanctum bearer tokens live in flutter_secure_storage ONLY (Keychain / Keystore
// / Windows DPAPI) — never SharedPreferences or the plain JSON store. This
// mirrors the ecosystem rule in thaipromptapp/ARCHITECTURE §9 and the global
// security rules (no secrets in plaintext / logs).
//
// by xman studio

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kToken = 'tp_pos_token';
  static const _kRefresh = 'tp_pos_refresh';
  static const _kUser = 'tp_pos_user';

  final FlutterSecureStorage _s;
  TokenStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  Future<String?> readToken() => _s.read(key: _kToken);
  Future<void> writeToken(String token) => _s.write(key: _kToken, value: token);

  Future<String?> readRefresh() => _s.read(key: _kRefresh);
  Future<void> writeRefresh(String? token) =>
      token == null ? _s.delete(key: _kRefresh) : _s.write(key: _kRefresh, value: token);

  Future<String?> readUserJson() => _s.read(key: _kUser);
  Future<void> writeUserJson(String? json) =>
      json == null ? _s.delete(key: _kUser) : _s.write(key: _kUser, value: json);

  Future<bool> get hasToken async => (await readToken())?.isNotEmpty ?? false;

  Future<void> clear() async {
    await _s.delete(key: _kToken);
    await _s.delete(key: _kRefresh);
    await _s.delete(key: _kUser);
  }
}

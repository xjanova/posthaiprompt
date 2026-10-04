// Thaiprompt POS — Authentication.
//
// Two-tier, offline-first:
//   • Local PIN session  → unlocks the terminal without network (fast cashier
//     login). Works fully offline.
//   • Server pairing      → authenticates the terminal with main.thaiprompt.online
//     (Sanctum) to obtain the bearer token the sync layer uses. Optional; the POS
//     keeps selling offline if the server is unreachable.
//
// by xman studio

import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../api/api_exceptions.dart';
import '../api/pos_api.dart';
import 'token_storage.dart';

/// The signed-in identity (from the server when paired, else a local cashier).
class PosSession {
  final String name;
  final String? userId;
  final String role;
  final bool serverAuthenticated;

  const PosSession({
    required this.name,
    this.userId,
    this.role = 'cashier',
    this.serverAuthenticated = false,
  });

  factory PosSession.fromUser(Map<String, dynamic> user, {bool server = true}) => PosSession(
        name: (user['name'] as String?) ?? '—',
        userId: user['id']?.toString(),
        role: (user['role'] as String?) ?? 'cashier',
        serverAuthenticated: server,
      );
}

class AuthRepository extends ChangeNotifier {
  final PosApi api;
  final TokenStorage tokens;

  AuthRepository({required this.api, required this.tokens});

  PosSession? _session;
  PosSession? get session => _session;
  bool get isSignedIn => _session != null;
  bool get isServerPaired => _session?.serverAuthenticated ?? false;

  /// Restore a previously-paired server session (token in secure storage) on
  /// app launch — no network required, just rehydrate the cached identity.
  Future<void> restore() async {
    final userJson = await tokens.readUserJson();
    if (userJson != null && await tokens.hasToken) {
      try {
        _session = PosSession.fromUser((jsonDecode(userJson) as Map).cast<String, dynamic>());
        notifyListeners();
      } catch (_) {/* ignore corrupt cache */}
    }
  }

  /// Local PIN unlock — offline, no server call. [name] is the chosen cashier.
  void signInLocal(String name) {
    _session = PosSession(name: name);
    notifyListeners();
  }

  /// Pair the terminal with the real backend using its device API key (issued
  /// by the Thaiprompt admin). Persists the key (X-API-Key) and confirms with
  /// /api/pos/validate. The product key + device id must already be on the
  /// ApiConfig (set via the store). Throws ApiException on bad key / offline.
  Future<PosSession> pairTerminal({required String apiKey}) async {
    await tokens.writeToken(apiKey);
    try {
      final res = await api.validate();
      final ok = res['success'] == true && (res['valid'] == true || res['valid'] == null);
      if (!ok) {
        throw ApiException((res['message'] as String?) ?? 'จับคู่ terminal ไม่สำเร็จ');
      }
      final shop = (res['shop'] as Map?)?.cast<String, dynamic>();
      final name = (shop?['name'] as String?) ?? 'POS Terminal';
      await tokens.writeUserJson(jsonEncode({'name': name, 'role': 'terminal'}));
      _session = PosSession(name: name, role: 'terminal', serverAuthenticated: true);
      notifyListeners();
      return _session!;
    } catch (_) {
      await tokens.clear(); // don't keep a key that didn't validate
      rethrow;
    }
  }

  /// Unpair the terminal — clears the stored API key + cached identity. (The
  /// terminal API has no logout endpoint; the key is simply forgotten locally.)
  Future<void> signOut() async {
    await tokens.clear();
    _session = null;
    notifyListeners();
  }
}

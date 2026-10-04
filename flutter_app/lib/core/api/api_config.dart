// Thaiprompt POS — API configuration (REAL terminal API).
//
// Backend: main.thaiprompt.online · the LIVE PosTerminalController under
// `/api/pos/*` (confirmed: GET /api/pos/ping → 200). POS terminals authenticate
// with a device API key, sent as headers on every call:
//   X-API-Key      (the secret — stored in flutter_secure_storage)
//   X-Product-Key  (the terminal's product key, issued by Thaiprompt admin)
//   X-Device-ID    (a stable per-install id)
//
// Offline-first: the local store is the source of truth; sync pulls the real
// catalog and pushes orders when the terminal is paired and online.
//
// by xman studio

class ApiConfig {
  static const String defaultBaseUrl = 'https://main.thaiprompt.online';

  /// Runtime-configurable so a terminal can target staging/prod.
  String baseUrl;

  /// Terminal identity headers (the API key itself lives in secure storage).
  String productKey; // X-Product-Key
  String deviceId; // X-Device-ID

  ApiConfig({
    this.baseUrl = defaultBaseUrl,
    this.productKey = '',
    this.deviceId = '',
  });

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// True once the terminal has its product key + device id (still needs the
  /// API key in secure storage to actually authenticate).
  bool get hasTerminal => productKey.trim().isNotEmpty && deviceId.trim().isNotEmpty;
}

/// Real endpoint paths on the live PosTerminalController (routes/api.php
/// `Route::prefix('pos')`). NOTE: the sync endpoints are POST.
class ApiPaths {
  ApiPaths._();

  static const ping = '/api/pos/ping';
  static const health = '/api/pos/health';
  static const validate = '/api/pos/validate';
  static const status = '/api/pos/status';
  static const registerDevice = '/api/pos/register-device';
  static const verify = '/api/pos/verify';

  // Catalog pull (POST)
  static const syncProducts = '/api/pos/sync/products';
  static const syncCategories = '/api/pos/sync/categories';

  // Order push + reporting (POST)
  static const syncOrders = '/api/pos/sync/orders';
  static const reportSales = '/api/pos/report/sales';
}

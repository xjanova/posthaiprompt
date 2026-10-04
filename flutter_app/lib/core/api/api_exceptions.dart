// Thaiprompt POS — API error types.
//
// Normalises dio/transport/HTTP/Laravel-envelope failures into a small set the
// UI can reason about. Networking errors are non-fatal in an offline-first app:
// the caller falls back to the local store and the sync layer retries later.
//
// by xman studio

/// Base for all API failures.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors; // Laravel 422 field errors
  final String? code; // machine code from the server envelope, e.g. ITEMS_NOT_IN_STORE
  final Object? data; // envelope `data` on an error (e.g. the missing items)

  ApiException(this.message, {this.statusCode, this.errors, this.code, this.data});

  /// True when the failure is "no usable connection to the server" — the signal
  /// the app uses to switch to offline mode rather than surfacing a hard error.
  bool get isOffline => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 401 — token missing/expired. The session should re-authenticate.
class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'ต้องเข้าสู่ระบบใหม่']) : super(statusCode: 401);
}

/// 409 — last-write-wins conflict; body carries the server's latest version.
class ConflictException extends ApiException {
  final Map<String, dynamic>? latest;
  ConflictException(super.message, {this.latest, super.code, super.data}) : super(statusCode: 409);
}

/// Transport-level failure (no response): timeout, DNS, connection refused,
/// offline. Caller should degrade to local + queue for later sync.
class NetworkException extends ApiException {
  NetworkException([super.message = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้']);
}

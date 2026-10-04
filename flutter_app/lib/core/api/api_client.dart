// Thaiprompt POS — HTTP client (dio + Sanctum bearer + Laravel envelope).
//
// Consistent with the rest of the Thaiprompt ecosystem: a dio instance with an
// interceptor that attaches the Sanctum bearer token, unwraps the standard
// `{success, message, data}` envelope, and maps failures to typed exceptions.
// Transient failures retry with exponential backoff; connection failures bubble
// up as NetworkException so callers can degrade to offline.
//
// by xman studio

import 'dart:math';

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  final ApiConfig config;
  final TokenStorage tokens;
  final Dio _dio;
  final Random _rng = Random();

  ApiClient({required this.config, required this.tokens, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
              // Don't throw on any status — we map them ourselves below.
              validateStatus: (_) => true,
            ));

  Future<dynamic> get(String path, {Map<String, dynamic>? query, int retries = 2}) =>
      _request('GET', path, query: query, retries: retries);

  Future<dynamic> post(String path, {Object? data, int retries = 1}) =>
      _request('POST', path, data: data, retries: retries);

  Future<dynamic> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    int retries = 1,
  }) async {
    final url = '${config.baseUrl}$path';
    final apiKey = await tokens.readToken(); // the terminal's X-API-Key (secret)

    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final res = await _dio.request<dynamic>(
          url,
          data: data,
          queryParameters: query,
          options: Options(
            method: method,
            headers: {
              if (apiKey != null && apiKey.isNotEmpty) 'X-API-Key': apiKey,
              if (config.productKey.isNotEmpty) 'X-Product-Key': config.productKey,
              if (config.deviceId.isNotEmpty) 'X-Device-ID': config.deviceId,
            },
          ),
        );
        return _handle(res);
      } on ApiException catch (e) {
        // Retry transient server errors (5xx, 429) and offline; not 4xx.
        final retryable = e.isOffline || e.statusCode == 429 || (e.statusCode ?? 0) >= 500;
        if (retryable && attempt <= retries) {
          await _backoff(attempt);
          continue;
        }
        rethrow;
      } on DioException catch (e) {
        final mapped = _mapDio(e);
        final retryable = mapped.isOffline || mapped.statusCode == 429 || (mapped.statusCode ?? 0) >= 500;
        if (retryable && attempt <= retries) {
          await _backoff(attempt);
          continue;
        }
        throw mapped;
      }
    }
  }

  Future<void> _backoff(int attempt) async {
    final seconds = min(30.0, pow(2, attempt).toDouble()) + _rng.nextDouble();
    await Future.delayed(Duration(milliseconds: (seconds * 1000).round()));
  }

  /// Unwrap the Laravel envelope and map non-2xx to typed exceptions.
  dynamic _handle(Response res) {
    final status = res.statusCode ?? 0;
    final body = res.data;

    if (status >= 200 && status < 300) {
      if (body is Map && body.containsKey('success')) {
        if (body['success'] == false) {
          throw ApiException(
            (body['message'] as String?) ?? 'คำขอไม่สำเร็จ',
            statusCode: status,
            errors: (body['errors'] as Map?)?.cast<String, dynamic>(),
          );
        }
        return body.containsKey('data') ? body['data'] : body;
      }
      return body; // raw payload (array / value)
    }

    final message = (body is Map ? body['message'] as String? : null) ?? 'เกิดข้อผิดพลาด ($status)';
    if (status == 401) throw UnauthorizedException(message);
    if (status == 409) {
      throw ConflictException(message, latest: (body is Map ? body['latest'] : null)?.cast<String, dynamic>());
    }
    throw ApiException(
      message,
      statusCode: status,
      errors: (body is Map ? body['errors'] as Map? : null)?.cast<String, dynamic>(),
    );
  }

  ApiException _mapDio(DioException e) {
    if (e.response != null) {
      try {
        return _handle(e.response!) as ApiException;
      } catch (mapped) {
        if (mapped is ApiException) return mapped;
      }
    }
    // No response → transport/connection problem → offline.
    return NetworkException();
  }
}

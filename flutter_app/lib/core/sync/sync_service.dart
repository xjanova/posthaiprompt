// Thaiprompt POS — Sync orchestrator (offline-first).
//
// Drains the outbox to main.thaiprompt.online (orders, voids, stock movements)
// and pulls catalog/stock deltas back into the store. Runs every 30s and
// on-demand. All failures are non-fatal: the POS keeps selling on the local
// store and the queue is retried later. Exposes a SyncState the UI shows as a
// status banner.
//
// by xman studio

import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../state/pos_store.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../api/pos_api.dart';
import 'outbox.dart';

enum SyncState { disabled, idle, syncing, offline, error }

extension SyncStateX on SyncState {
  String get label => switch (this) {
        SyncState.disabled => 'ยังไม่ตั้งค่าเซิร์ฟเวอร์',
        SyncState.idle => 'ซิงก์แล้ว',
        SyncState.syncing => 'กำลังซิงก์…',
        SyncState.offline => 'ออฟไลน์ · คิวไว้แล้ว',
        SyncState.error => 'ซิงก์ไม่สำเร็จ',
      };
}

class SyncService extends ChangeNotifier {
  final PosApi api;
  final ApiConfig config;
  final OutboxQueue outbox;

  /// Set once after construction (avoids a constructor cycle with the store).
  PosStore? store;

  SyncState _state = SyncState.disabled;
  SyncState get state => _state;
  String? message;
  DateTime? lastSyncAt;

  Timer? _timer;
  bool _running = false;

  SyncService({required this.api, required this.config, required this.outbox});

  int get pendingCount => outbox.pendingCount;
  bool get isConfigured => config.isConfigured;

  void start() {
    _timer?.cancel();
    if (!config.isConfigured) {
      _set(SyncState.disabled);
      return;
    }
    _set(SyncState.idle);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── enqueue (called by the store on every server-bound mutation) ──

  void enqueueOrder(Map<String, dynamic> orderJson) {
    outbox.enqueue('Order', orderJson['id'] as String? ?? newOutboxId(), {
      'idempotencyKey': newOutboxId(),
      'order': orderJson,
    });
    notifyListeners();
    _kick();
  }

  /// Fire a sync soon if we're configured (debounced via the running guard).
  void _kick() {
    if (config.isConfigured && !_running) {
      // best-effort, fire and forget
      syncNow();
    }
  }

  // ── the cycle ──

  Future<void> syncNow() async {
    if (_running) return;
    if (!config.isConfigured) {
      _set(SyncState.disabled);
      return;
    }
    // Not paired yet (no product key or API key) → stay quiet (offline-only).
    if (!config.hasTerminal || !await api.client.tokens.hasToken) {
      message = 'ยังไม่ได้จับคู่ terminal (ไปที่ ตั้งค่า)';
      _set(SyncState.disabled);
      return;
    }
    _running = true;
    _set(SyncState.syncing);
    try {
      await _pushOrders();
      await _pullCatalog();
      lastSyncAt = DateTime.now();
      message = null;
      _set(SyncState.idle);
    } on NetworkException {
      message = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
      _set(SyncState.offline);
    } on UnauthorizedException {
      message = 'ต้องจับคู่เซิร์ฟเวอร์ใหม่ (ตั้งค่า)';
      _set(SyncState.error);
    } on ApiException catch (e) {
      message = e.message;
      _set(SyncState.error);
    } catch (e) {
      message = 'ผิดพลาด: $e';
      _set(SyncState.error);
    } finally {
      _running = false;
    }
  }

  Future<void> _pushOrders() async {
    final pend = outbox.pendingOfType('Order');
    if (pend.isEmpty) return;
    // Map each queued order to the server shape:
    // {local_id, total, created_at, items:[{product_id?, name, quantity, price}]}
    final orders = pend.map((m) {
      final o = (m.payload['order'] as Map).cast<String, dynamic>();
      final lines = (o['lines'] as List?) ?? const [];
      return <String, dynamic>{
        'local_id': o['id'],
        'total': o['total'],
        'created_at': o['createdAt'],
        'items': lines.map((l) {
          final line = (l as Map).cast<String, dynamic>();
          return <String, dynamic>{
            'product_id': null,
            'name': line['name'],
            'quantity': line['qty'],
            'price': line['price'],
          };
        }).toList(),
      };
    }).toList();
    final res = await api.uploadOrders(orders); // throws → caught by syncNow
    // The server answers 200 even when individual orders fail to save
    // ({uploaded, errors:[{local_id, error}]}) — only mark the ones it took.
    final failed = <String, String>{};
    final errs = res['errors'];
    if (errs is List) {
      for (final e in errs) {
        if (e is Map && e['local_id'] != null) failed['${e['local_id']}'] = '${e['error'] ?? 'บันทึกไม่สำเร็จ'}';
      }
    }
    final ok = <String>[];
    for (final m in pend) {
      final localId = '${(m.payload['order'] as Map)['id']}';
      final err = failed[localId];
      if (err == null) {
        ok.add(m.id);
      } else {
        outbox.markFailed(m.id, err);
      }
    }
    if (ok.isNotEmpty) outbox.markSent(ok);
    if (failed.isNotEmpty) {
      message = 'เซิร์ฟเวอร์ยังรับบิลไม่ได้ ${failed.length} รายการ — จะลองส่งใหม่อัตโนมัติ';
      throw ApiException(message!);
    }
  }

  /// Pull the shop's real catalog (products + categories) into the store.
  Future<void> _pullCatalog() async {
    final products = await api.syncProducts();
    if (products.isNotEmpty) store?.upsertProductsFromApi(products);
    final categories = await api.syncCategories();
    if (categories.isNotEmpty) store?.upsertCategoriesFromApi(categories);
  }

  void _set(SyncState s) {
    _state = s;
    notifyListeners();
  }
}

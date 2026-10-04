// Thai Prompt POS — keeps Thai Prompt rider jobs in step with the server.
//
// Polls GET /api/pos/delivery-requests/{id} for every open Thai Prompt rider
// job: every 4 s while one is waiting for the customer to pay (its QR is up),
// every 20 s while riders are on the way, idle otherwise. Each snapshot goes
// through PosStore.applyTpRiderStatus, which books the POS bill the moment the
// request turns paid. Offline / server errors are silent — the next tick
// retries; a request the server no longer knows (404) is closed locally.
//
// by xman studio

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_exceptions.dart';
import '../models/extra_models.dart';
import '../state/pos_store.dart';

class RiderTracker {
  RiderTracker._();
  static final RiderTracker instance = RiderTracker._();

  static const fast = Duration(seconds: 4);
  static const slow = Duration(seconds: 20);

  PosStore? _store;
  Timer? _timer;
  bool _polling = false;
  Duration? _interval;

  void attach(PosStore store) {
    if (_store != null) return;
    _store = store;
    store.addListener(_reschedule);
    _reschedule();
  }

  void _reschedule() {
    final s = _store;
    if (s == null) return;
    final jobs = s.tpActiveJobs;
    final want = jobs.isEmpty ? null : (jobs.any((j) => j.awaitingPayment) ? fast : slow);
    if (want == _interval && (_timer?.isActive ?? false) == (want != null)) return;
    _timer?.cancel();
    _interval = want;
    _timer = want == null ? null : Timer.periodic(want, (_) => pollAll());
  }

  /// Poll every open job once (also used by the "รีเฟรช" buttons).
  Future<void> pollAll() async {
    final s = _store;
    if (s == null || _polling) return;
    _polling = true;
    try {
      for (final j in s.tpActiveJobs) {
        await refresh(j);
      }
    } finally {
      _polling = false;
    }
  }

  /// Poll one job. Returns false when the server could not be reached.
  Future<bool> refresh(DeliveryJob j) async {
    final s = _store;
    final api = s?.sync?.api;
    final id = j.requestId;
    if (s == null || api == null || id == null) return false;
    try {
      final data = await api.deliveryRequest(id);
      if (data.isNotEmpty) s.applyTpRiderStatus(j, data);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 404 && j.orderId.isEmpty) {
        s.markTpRiderClosed(j, payStatus: 'cancelled');
        return true;
      }
      if (!e.isOffline) debugPrint('[RiderTracker] ${j.id}: ${e.statusCode} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[RiderTracker] ${j.id}: $e');
      return false;
    }
  }
}

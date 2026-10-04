// Thaiprompt POS — Sync outbox (offline write queue).
//
// Mirrors the OutboxMessages schema in docs/SYNC_API.md. Every server-bound
// write (order, payment, stock movement, void) is appended here first and
// persisted to its own JSON file, so a sale made offline is never lost — the
// SyncService drains the queue when connectivity returns. Each message carries a
// GUID idempotency-key so re-sends are safe.
//
// by xman studio

import 'dart:math';

import '../../data/local_store.dart';

/// Generate a UUID-ish idempotency key. (No `uuid` dep; time + randomness is
/// plenty for a single-terminal queue.)
String newOutboxId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final rng = Random();
  final tail = List.generate(8, (_) => rng.nextInt(16).toRadixString(16)).join();
  return 'ob_${now}_$tail';
}

enum OutboxStatus { pending, sent, failed }

class OutboxMessage {
  final String id; // GUID = idempotency-key
  final String entityType; // Order | Payment | StockMovement | Void
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attemptCount;
  String? lastError;
  OutboxStatus status;

  OutboxMessage({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
    this.status = OutboxStatus.pending,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attemptCount': attemptCount,
        'lastError': lastError,
        'status': status.name,
      };

  factory OutboxMessage.fromJson(Map<String, dynamic> j) => OutboxMessage(
        id: j['id'] as String,
        entityType: j['entityType'] as String,
        entityId: j['entityId'] as String,
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        attemptCount: (j['attemptCount'] as int?) ?? 0,
        lastError: j['lastError'] as String?,
        status: OutboxStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => OutboxStatus.pending),
      );
}

class OutboxQueue {
  final LocalStore _disk;
  final List<OutboxMessage> _messages = [];

  OutboxQueue({LocalStore? disk}) : _disk = disk ?? LocalStore(fileName: 'pos_outbox.json');

  Future<void> load() async {
    final snap = await _disk.load();
    final raw = snap?['messages'] as List?;
    if (raw != null) {
      _messages
        ..clear()
        ..addAll(raw.map((e) => OutboxMessage.fromJson((e as Map).cast<String, dynamic>())));
    }
  }

  List<OutboxMessage> get all => List.unmodifiable(_messages);
  List<OutboxMessage> get pending => _messages.where((m) => m.status != OutboxStatus.sent).toList();
  int get pendingCount => pending.length;
  bool get isEmpty => pending.isEmpty;

  List<OutboxMessage> pendingOfType(String entityType) =>
      _messages.where((m) => m.status != OutboxStatus.sent && m.entityType == entityType).toList();

  void add(OutboxMessage m) {
    _messages.add(m);
    _persist();
  }

  void enqueue(String entityType, String entityId, Map<String, dynamic> payload) {
    add(OutboxMessage(
      id: newOutboxId(),
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    ));
  }

  void markSent(Iterable<String> ids) {
    final set = ids.toSet();
    for (final m in _messages) {
      if (set.contains(m.id)) m.status = OutboxStatus.sent;
    }
    // Keep the last 200 sent rows for audit; drop older.
    final sent = _messages.where((m) => m.status == OutboxStatus.sent).toList();
    if (sent.length > 200) {
      _messages.removeWhere((m) => m.status == OutboxStatus.sent && sent.indexOf(m) < sent.length - 200);
    }
    _persist();
  }

  void markFailed(String id, String error) {
    for (final m in _messages) {
      if (m.id == id) {
        m.attemptCount++;
        m.lastError = error;
        if (m.attemptCount >= 5) m.status = OutboxStatus.failed;
      }
    }
    _persist();
  }

  /// Retry failed rows (called on the 5-min slow retry cycle).
  void revivefailed() {
    for (final m in _messages) {
      if (m.status == OutboxStatus.failed) m.status = OutboxStatus.pending;
    }
    _persist();
  }

  void _persist() => _disk.save({'messages': _messages.map((m) => m.toJson()).toList()});
}

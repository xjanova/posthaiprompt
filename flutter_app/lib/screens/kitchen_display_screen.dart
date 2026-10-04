// Thaiprompt POS — จอครัว KDS (/display/kitchen).
//
// Dark work screen fed by PosStore.kitchenQueue (FIFO — unpaid table /
// self-order / waiter tickets + paid counter orders not yet served). Three
// lanes (รอทำ · กำลังทำ · พร้อมเสิร์ฟ) side by side on wide screens, tabs on
// narrow ones. Every ticket card shows the big label, source, id, a live
// mm:ss timer that turns amber after 10 min and lacquer after 20 min, every
// line with its options / notes, and the ticket note. Tap a card (or its gold
// button) to advance; "ย้อนกลับ" steps back; "เสิร์ฟแล้ว" can be undone from
// the toast or recalled from "เสิร์ฟแล้วล่าสุด". New tickets chime when sound
// is on. Waiter calls show as chips (tap = acknowledge). No item caps.
//
// by xman studio

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const _kStages = [PrepStatus.queued, PrepStatus.preparing, PrepStatus.ready];

Color _stageColor(PrepStatus s) => switch (s) {
      PrepStatus.queued => Nv.amber,
      PrepStatus.preparing => const Color(0xFF5B8BD9),
      PrepStatus.ready => Nv.jadeLight,
      PrepStatus.served => Nv.ink4,
    };

NvTint _sourceTint(OrderSource s) => switch (s) {
      OrderSource.counter => NvTint.gold,
      OrderSource.table => NvTint.sapphire,
      OrderSource.self => NvTint.amethyst,
      OrderSource.mobile => NvTint.jade,
      OrderSource.delivery => NvTint.amber,
    };

class KitchenDisplayScreen extends StatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  State<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends State<KitchenDisplayScreen> {
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  Timer? _timer;
  late final PosStore _store;
  final Set<String> _seen = <String>{};
  PrepStatus _tab = PrepStatus.queued;
  DateTime _lastAction = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _store = AppScope.read(context);
    _seen.addAll(_store.kitchenQueue.map((e) => e.id));
    _store.addListener(_onStore);
    // one ticker for every card timer — only the cards listen, not the page
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _now.value = DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _store.removeListener(_onStore);
    _now.dispose();
    super.dispose();
  }

  /// Chime once for every ticket that was never on this screen before.
  void _onStore() {
    if (!mounted) return;
    final queue = _store.kitchenQueue;
    var fresh = false;
    for (final e in queue) {
      if (_seen.add(e.id)) fresh = true;
    }
    if (_seen.length > 800) {
      _seen
        ..clear()
        ..addAll(queue.map((e) => e.id));
    }
    if (fresh && _store.soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// Swallow the second tap of a double-tap (the card under the finger
  /// changes after the first one moves the ticket to the next lane).
  bool _debounced() {
    final now = DateTime.now();
    if (now.difference(_lastAction) < const Duration(milliseconds: 450)) return true;
    _lastAction = now;
    return false;
  }

  void _advance(KitchenEntry e) {
    if (_debounced()) return;
    final store = AppScope.read(context);
    final served = e.prep == PrepStatus.ready;
    store.advanceEntry(e);
    if (served) {
      nvToast(
        context,
        'เสิร์ฟ ${e.label} (${e.id}) แล้ว',
        kind: NvToastKind.success,
        actionLabel: 'เลิกทำ',
        onAction: () => store.setEntryPrep(e, PrepStatus.ready),
      );
    }
  }

  void _revert(KitchenEntry e) {
    if (_debounced()) return;
    AppScope.read(context).revertEntry(e);
  }

  void _ackCall(int table) {
    AppScope.read(context).setCallWaiter(table, false);
    nvToast(context, 'รับทราบการเรียกจากโต๊ะ $table แล้ว', kind: NvToastKind.success);
  }

  /// Recently served tickets (last 12 h) so a wrong "เสิร์ฟแล้ว" can be recalled.
  List<KitchenEntry> _recentServed(PosStore store) {
    final now = DateTime.now();
    bool recent(DateTime d) => now.difference(d) < const Duration(hours: 12);
    final out = <KitchenEntry>[];
    for (final t in store.tickets) {
      if (t.prep != PrepStatus.served || t.status == TicketStatus.cancelled || !recent(t.createdAt)) continue;
      out.add(KitchenEntry(
        id: t.id,
        label: t.tableNumber != null ? 'โต๊ะ ${t.tableNumber}' : (t.customerName ?? t.source.label),
        createdAt: t.createdAt,
        lines: t.lines,
        prep: t.prep,
        source: t.source,
        note: t.note,
        ticket: t,
      ));
    }
    var scanned = 0;
    for (final o in store.orders) {
      if (++scanned > 400 || !recent(o.createdAt)) break; // orders are newest first
      if (o.status != OrderStatus.paid || o.ticketId != null || o.prep != PrepStatus.served) continue;
      out.add(KitchenEntry(
        id: o.id,
        label: o.type == OrderType.dineIn && o.tableNumber != null ? 'โต๊ะ ${o.tableNumber}' : o.type.label,
        createdAt: o.createdAt,
        lines: o.lines,
        prep: o.prep,
        source: o.source,
        order: o,
      ));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out.take(12).toList();
  }

  Future<void> _showServed() async {
    final store = AppScope.read(context);
    final list = _recentServed(store);
    await showNvDialog<void>(
      context,
      title: 'เสิร์ฟแล้วล่าสุด',
      subtitle: 'เรียกคืนรายการที่กดเสิร์ฟผิด กลับเข้าช่อง "พร้อมเสิร์ฟ"',
      art: 'kitchen',
      maxWidth: 520,
      body: Builder(
        builder: (ctx) => list.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('ยังไม่มีรายการที่เสิร์ฟแล้วใน 12 ชั่วโมงที่ผ่านมา',
                    textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink3)),
              )
            : Column(
                children: [
                  for (final e in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NvSheet(
                        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                        radius: Nv.rMd,
                        color: Nv.paper,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
                                  Text('${e.id} · สั่ง ${hm(e.createdAt)} · ${e.itemCount} จาน',
                                      style: Nv.ui(12, color: Nv.ink3)),
                                ],
                              ),
                            ),
                            NvButton.soft(
                              'เรียกคืน',
                              icon: NvIcons.refund,
                              size: NvButtonSize.sm,
                              onPressed: () {
                                store.setEntryPrep(e, PrepStatus.ready);
                                Navigator.of(ctx).pop();
                                nvToast(context, 'เรียกคืน ${e.label} (${e.id}) แล้ว', kind: NvToastKind.success);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      actions: (ctx) => [NvButton.soft('ปิด', onPressed: () => Navigator.of(ctx).pop())],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final queue = store.kitchenQueue;
    final by = {for (final s in _kStages) s: queue.where((e) => e.prep == s).toList()};
    final dishes = queue.fold<int>(0, (s, e) => s + e.itemCount);
    final calls = store.tablesCallingWaiter;

    return NvScaffold(
      tone: NvTone.night,
      title: 'จอครัว',
      art: 'kitchen',
      subtitle: 'เรียงตามเวลาที่สั่ง · แตะการ์ดเพื่อเลื่อนสถานะ',
      actions: [
        NvButton.ghost('เสิร์ฟแล้วล่าสุด', icon: NvIcons.history, onNight: true, size: NvButtonSize.sm, onPressed: _showServed),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final header = _KdsHeader(
          counts: {for (final s in _kStages) s: by[s]!.length},
          dishes: dishes,
          calls: calls,
          kitchenOn: store.kitchenEnabled,
          onAck: _ackCall,
        );
        if (queue.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Expanded(
                child: NvEmptyState(
                  mascot: 'chef',
                  onNight: true,
                  title: 'ยังไม่มีออเดอร์ในครัว',
                  message: 'ออเดอร์ใหม่จากแคชเชียร์ โต๊ะ มือถือพนักงาน และลูกค้าสั่งเอง จะขึ้นที่นี่ทันทีตามลำดับเวลา',
                ),
              ),
            ],
          );
        }
        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _kStages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(
                        child: _KdsColumn(
                          stage: _kStages[i],
                          entries: by[_kStages[i]]!,
                          now: _now,
                          onAdvance: _advance,
                          onRevert: _revert,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 10),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: NvSegmented<PrepStatus>(
                  onNight: true,
                  options: [for (final s in _kStages) (s, '${s.label} ${by[s]!.length}')],
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _KdsList(
                entries: by[_tab]!,
                now: _now,
                onAdvance: _advance,
                onRevert: _revert,
                emptyText: 'ไม่มีรายการ${_tab.label}',
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ───────────────────────── header ─────────────────────────

class _KdsHeader extends StatelessWidget {
  final Map<PrepStatus, int> counts;
  final int dishes;
  final List<int> calls;
  final bool kitchenOn;
  final ValueChanged<int> onAck;

  const _KdsHeader({required this.counts, required this.dishes, required this.calls, required this.kitchenOn, required this.onAck});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in _kStages) _CountPill(label: s.label, value: counts[s] ?? 0, color: _stageColor(s)),
        _CountPill(label: 'จานในคิว', value: dishes, color: Nv.gold300),
        if (!kitchenOn) const NvBadge('ระบบครัวปิดอยู่ · ออเดอร์ใหม่ไม่เข้าคิว', tint: NvTint.amber, icon: NvIcons.warning),
        for (final n in calls)
          Tooltip(
            message: 'แตะเพื่อรับทราบ',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(Nv.rPill),
                onTap: () => onAck(n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: Nv.btnLacquer,
                    borderRadius: BorderRadius.circular(Nv.rPill),
                    boxShadow: Nv.tintGlow(Nv.lacquer),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(NvIcons.bellConcierge, size: 13, color: Colors.white),
                      const SizedBox(width: 7),
                      Text('โต๊ะ $n เรียกพนักงาน', style: Nv.ui(13, color: Colors.white, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CountPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Nv.rPill),
          border: Border.all(color: Nv.lineNight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 8),
            Text(label, style: Nv.ui(13, color: Nv.onNight2, weight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('$value', style: Nv.money(17, color: Nv.onNight)),
          ],
        ),
      );
}

// ───────────────────────── lanes ─────────────────────────

class _KdsColumn extends StatelessWidget {
  final PrepStatus stage;
  final List<KitchenEntry> entries;
  final ValueListenable<DateTime> now;
  final ValueChanged<KitchenEntry> onAdvance;
  final ValueChanged<KitchenEntry> onRevert;

  const _KdsColumn({required this.stage, required this.entries, required this.now, required this.onAdvance, required this.onRevert});

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(stage);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Nv.rLg),
        border: Border.all(color: Nv.lineNight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: Nv.tintGlow(color)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(stage.label, style: Nv.display(19, color: Nv.onNight))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(Nv.rPill),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text('${entries.length}', style: Nv.money(14, color: Nv.onNight)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Nv.lineNight),
          Expanded(
            child: _KdsList(entries: entries, now: now, onAdvance: onAdvance, onRevert: onRevert, emptyText: 'ไม่มีรายการ'),
          ),
        ],
      ),
    );
  }
}

class _KdsList extends StatelessWidget {
  final List<KitchenEntry> entries;
  final ValueListenable<DateTime> now;
  final ValueChanged<KitchenEntry> onAdvance;
  final ValueChanged<KitchenEntry> onRevert;
  final String emptyText;

  const _KdsList({required this.entries, required this.now, required this.onAdvance, required this.onRevert, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(child: Text(emptyText, style: Nv.ui(13.5, color: Nv.onNight3)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _KdsCard(
        key: ValueKey(entries[i].id),
        entry: entries[i],
        now: now,
        onAdvance: onAdvance,
        onRevert: onRevert,
      ),
    );
  }
}

// ───────────────────────── ticket card ─────────────────────────

class _KdsCard extends StatelessWidget {
  final KitchenEntry entry;
  final ValueListenable<DateTime> now;
  final ValueChanged<KitchenEntry> onAdvance;
  final ValueChanged<KitchenEntry> onRevert;

  const _KdsCard({super.key, required this.entry, required this.now, required this.onAdvance, required this.onRevert});

  Widget _primary(KitchenEntry e) => switch (e.prep) {
        PrepStatus.queued => NvButton.gold('เริ่มทำ', icon: NvIcons.fire, expand: true, onPressed: () => onAdvance(e)),
        PrepStatus.preparing =>
          NvButton.success('พร้อมเสิร์ฟ', icon: NvIcons.bellConcierge, expand: true, onPressed: () => onAdvance(e)),
        _ => NvButton.gold('เสิร์ฟแล้ว', icon: NvIcons.check, expand: true, onPressed: () => onAdvance(e)),
      };

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final paid = e.order != null || e.ticket?.status == TicketStatus.settled;
    return ValueListenableBuilder<DateTime>(
      valueListenable: now,
      builder: (context, n, _) {
        var age = n.difference(e.createdAt);
        if (age.isNegative) age = Duration.zero;
        final mins = age.inMinutes;
        final ageColor = mins >= 20 ? Nv.lacquerLight : (mins >= 10 ? Nv.amber : Nv.jadeLight);
        return NvNightCard(
          padding: EdgeInsets.zero,
          onTap: () => onAdvance(e),
          glow: e.prep == PrepStatus.ready,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Nv.rLg - 1)),
                child: Container(height: 5, color: ageColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Nv.display(23, color: Nv.onNight, weight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        _ElapsedChip(age: age, color: ageColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        NvBadge(e.source.label, tint: _sourceTint(e.source)),
                        if (paid) const NvBadge('ชำระแล้ว', tint: NvTint.jade),
                        if (mins < 1) const NvBadge('ใหม่', tint: NvTint.gold, icon: NvIcons.bolt),
                        Text('${e.id} · ${hm(e.createdAt)} · ${e.itemCount} จาน',
                            style: Nv.money(12, color: Nv.onNight3, weight: FontWeight.w600)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(height: 1, color: Nv.lineNight),
                    ),
                    for (final l in e.lines) _KdsLine(line: l),
                    if (e.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Nv.amber.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(Nv.rSm),
                          border: Border.all(color: Nv.amber.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(NvIcons.note, size: 14, color: Nv.gold300),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('หมายเหตุ: ${e.note}', style: Nv.ui(14.5, color: Nv.gold200, weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, c) => Row(
                        children: [
                          if (e.prep != PrepStatus.queued) ...[
                            // narrow lanes (3 columns at 1024 px): icon-only so the main label fits
                            if (c.maxWidth < 300)
                              NvIconButton(NvIcons.refund, onNight: true, tooltip: 'ย้อนกลับ', onPressed: () => onRevert(e))
                            else
                              NvButton.ghost('ย้อนกลับ',
                                  icon: NvIcons.refund, onNight: true, size: NvButtonSize.sm, onPressed: () => onRevert(e)),
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: _primary(e)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ElapsedChip extends StatelessWidget {
  final Duration age;
  final Color color;
  const _ElapsedChip({required this.age, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(Nv.rPill),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(NvIcons.stopwatch, size: 12, color: color),
            const SizedBox(width: 6),
            Text(elapsed(age), style: Nv.money(16, color: color)),
          ],
        ),
      );
}

class _KdsLine extends StatelessWidget {
  final OrderLine line;
  const _KdsLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final l = line;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Nv.gold400.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Nv.lineNight),
            ),
            child: Text('${l.qty}×', style: Nv.money(17, color: Nv.gold200)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, style: Nv.ui(17, color: Nv.onNight, weight: FontWeight.w600, height: 1.25)),
                if (l.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l.detail, style: Nv.ui(14, color: Nv.gold300, weight: FontWeight.w600, height: 1.3)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

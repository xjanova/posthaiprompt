// Thaiprompt POS — Sales dashboard (Nova).
//
// Live numbers from the store only: pick a period (วันนี้ / 7 วัน / 30 วัน),
// see KPI tiles compared with the previous period, and five charts drawn with
// CustomPainter in the Nova style (gold bars on ivory, navy labels, mono
// numbers): sales by day, by hour, by payment method, by category and the
// best sellers. Every chart has an honest empty state — no sample numbers.
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/order_models.dart';
import '../print/pnl_doc.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _Period { today, week, month }

extension _PeriodX on _Period {
  int get days => switch (this) {
        _Period.today => 1,
        _Period.week => 7,
        _Period.month => 30,
      };

  String get label => switch (this) {
        _Period.today => 'วันนี้',
        _Period.week => '7 วัน',
        _Period.month => '30 วัน',
      };

  String get prevLabel => switch (this) {
        _Period.today => 'เมื่อวาน',
        _Period.week => '7 วันก่อนหน้า',
        _Period.month => '30 วันก่อนหน้า',
      };
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Period _period = _Period.today;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final to = DateTime(now.year, now.month, now.day + 1);
    final from = DateTime(now.year, now.month, now.day - (_period.days - 1));
    final prevFrom = DateTime(from.year, from.month, from.day - _period.days);
    final list = store.ordersBetween(from, to);
    final pnl = PnlSummary.of(store, list, from: from, to: to);
    final prev = PnlSummary.of(store, store.ordersBetween(prevFrom, from), from: prevFrom, to: from);
    final neverSold = store.settledOrders.isEmpty;

    return NvScaffold(
      title: 'แดชบอร์ด',
      eyebrow: 'รายงานยอดขาย',
      subtitle: '${store.shopName} · ${store.branch}',
      art: 'dashboard',
      actions: [
        NvButton.soft('บัญชี', icon: NvIcons.calculator, size: NvButtonSize.sm, onPressed: () => context.go('/accounting')),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                NvSegmented<_Period>(
                  options: [for (final p in _Period.values) (p, p.label)],
                  value: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                Text(
                  _period == _Period.today ? thaiDateFull(today) : '${thaiDate(from)} – ${thaiDate(today)}',
                  style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w600),
                ),
                const NvBadge('อัปเดตสดจากการขาย', tint: NvTint.jade),
              ],
            ),
            const SizedBox(height: 16),
            if (neverSold)
              NvSheet(
                child: NvEmptyState(
                  mascot: 'present',
                  title: 'ยังไม่มียอดขายในเครื่องนี้',
                  message: 'เมื่อเริ่มขาย ตัวเลขและกราฟทั้งหมดจะคำนวณจากบิลจริงทันที',
                  actionLabel: 'เริ่มขาย',
                  actionIcon: NvIcons.cashier,
                  onAction: () => context.go('/cashier'),
                ),
              )
            else ...[
              _kpis(context, w, pnl, prev),
              const SizedBox(height: 18),
              ..._charts(store, w, list, now),
            ],
          ],
        );
      }),
    );
  }

  // ───────────────────────── KPI tiles ─────────────────────────

  Widget _kpis(BuildContext context, double w, PnlSummary pnl, PnlSummary prev) {
    final cols = w >= 1250 ? 5 : (w >= 820 ? 3 : (w >= 520 ? 2 : 1));
    final tileW = (w - (cols - 1) * 12) / cols;

    ({String text, NvTint tint})? delta(int cur, int before) {
      if (cur == 0 && before == 0) return null;
      if (before == 0) return (text: '${_period.prevLabel}ไม่มียอด', tint: NvTint.neutral);
      final pct = (cur - before) * 100 / before.abs();
      final sign = pct > 0 ? '+' : '';
      return (text: '$sign${pct.toStringAsFixed(1)}% จาก${_period.prevLabel}', tint: pct >= 0 ? NvTint.jade : NvTint.lacquer);
    }

    final dNet = delta(pnl.net, prev.net);
    final dBills = delta(pnl.bills, prev.bills);
    final refundBills = pnl.refundedBills + pnl.partialRefundBills;
    final tiles = <Widget>[
      NvStatTile(label: 'ยอดขายสุทธิ', value: baht(pnl.net), art: 'cash', caption: dNet?.text, tint: dNet?.tint ?? NvTint.gold),
      NvStatTile(label: 'จำนวนบิล', value: groupDigits(pnl.bills), art: 'receipt', caption: dBills?.text, tint: dBills?.tint ?? NvTint.gold),
      NvStatTile(
        label: 'เฉลี่ยต่อบิล',
        value: baht(pnl.avgBill),
        art: 'payment',
        caption: 'ขายได้ ${groupDigits(pnl.items)} ชิ้น',
        tint: NvTint.sapphire,
      ),
      NvStatTile(
        label: 'คืนเงิน',
        value: baht(pnl.refunds),
        art: 'refund',
        caption: refundBills == 0 ? 'ไม่มีการคืนเงิน' : '$refundBills บิลมีการคืนเงิน',
        tint: refundBills == 0 ? NvTint.neutral : NvTint.lacquer,
      ),
      NvStatTile(
        label: 'กำไรขั้นต้น',
        value: baht(pnl.profit),
        art: 'accounting',
        caption: pnl.missingCostLines > 0
            ? 'ต้นทุนไม่ครบ ${groupDigits(pnl.missingCostLines)} รายการ'
            : 'อัตรากำไร ${pnl.marginPct.toStringAsFixed(1)}%',
        tint: pnl.missingCostLines > 0 ? NvTint.amber : NvTint.jade,
        onTap: () => context.go('/accounting'),
      ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final t in tiles) SizedBox(width: tileW, child: t)],
    );
  }

  // ───────────────────────── charts ─────────────────────────

  List<Widget> _charts(PosStore store, double w, List<Order> list, DateTime now) {
    final paid = list.where((o) => o.status == OrderStatus.paid).toList();

    // sales by day (at least the last 7 days so "today" still has context)
    final dayCount = math.max(7, _period.days);
    final daily = store.salesByDay(days: dayCount);
    final dayValues = [for (final d in daily) d.total];
    final dayLabels = [for (final d in daily) dayCount <= 7 ? thaiWeekdayShort(d.day) : '${d.day.day}'];
    final dayTips = [for (final d in daily) '${thaiDayMonth(d.day)} · ${d.orders} บิล'];
    final byDay = _ChartCard(
      title: 'ยอดขายรายวัน',
      trailing: '$dayCount วันล่าสุด',
      icon: NvIcons.chartBar,
      child: dayValues.every((v) => v == 0)
          ? _ChartEmpty('ยังไม่มียอดขายใน $dayCount วันล่าสุด')
          : _BarChart(values: dayValues, labels: dayLabels, tips: dayTips, highlight: dayValues.length - 1),
    );

    // sales by hour — today, or summed over the chosen period
    final hours = _period == _Period.today ? store.salesByHour(now) : _hoursOf(paid);
    final peak = hours.every((v) => v == 0) ? -1 : hours.indexOf(hours.reduce(math.max));
    String hh(int h) => h.toString().padLeft(2, '0');
    final byHour = _ChartCard(
      title: 'ยอดขายรายชั่วโมง',
      trailing: peak < 0 ? (_period == _Period.today ? 'วันนี้' : 'รวม ${_period.label}') : 'ชั่วโมงทอง ${hh(peak)}:00–${hh((peak + 1) % 24)}:00',
      icon: NvIcons.clock,
      child: peak < 0
          ? _ChartEmpty(_period == _Period.today ? 'วันนี้ยังไม่มียอดขาย' : 'ยังไม่มียอดขายในช่วงนี้')
          : _BarChart(
              values: hours,
              labels: [for (var h = 0; h < 24; h++) hh(h)],
              tips: [for (var h = 0; h < 24; h++) '${hh(h)}:00–${hh((h + 1) % 24)}:00'],
              highlight: _period == _Period.today ? now.hour : peak,
            ),
    );

    // payment methods
    final byMethod = store.salesByMethod(list);
    final methodTotal = byMethod.values.fold<int>(0, (s, v) => s + v);
    final methods = _ChartCard(
      title: 'ช่องทางชำระเงิน',
      trailing: _period.label,
      icon: NvIcons.wallet,
      child: methodTotal <= 0
          ? const _ChartEmpty('ยังไม่มีการชำระเงินในช่วงนี้')
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final m in PaymentMethod.values)
                  _MethodRow(
                    method: m,
                    amount: byMethod[m] ?? 0,
                    bills: paid.where((o) => o.method == m).length,
                    fraction: (byMethod[m] ?? 0) / methodTotal,
                  ),
              ],
            ),
    );

    // categories
    final cats = store.salesByCategory(list).entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final catEntries = <({String name, int value})>[];
    for (var i = 0; i < cats.length; i++) {
      if (i < 5) {
        catEntries.add((name: cats[i].key, value: cats[i].value));
      } else if (i == 5) {
        catEntries.add((name: 'อื่น ๆ', value: cats.skip(5).fold<int>(0, (s, e) => s + e.value)));
      }
    }
    final categories = _ChartCard(
      title: 'ยอดขายตามหมวดหมู่',
      trailing: _period.label,
      icon: NvIcons.chartPie,
      child: catEntries.isEmpty ? const _ChartEmpty('ยังไม่มีสินค้าที่ขายในช่วงนี้') : _CategoryDonut(entries: catEntries),
    );

    // best sellers
    final top = store.topProducts(limit: 5, from: list);
    final best = _ChartCard(
      title: 'สินค้าขายดี',
      trailing: 'ตามจำนวนชิ้น',
      icon: NvIcons.trophy,
      child: top.isEmpty ? const _ChartEmpty('ยังไม่มีสินค้าที่ขายในช่วงนี้') : _TopList(rows: top),
    );

    const gap = SizedBox(width: 14, height: 14);
    Widget row(List<Widget> items, List<int> flex) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) gap,
              Expanded(flex: flex[i], child: items[i]),
            ],
          ],
        );

    if (w >= 1250) {
      return [row([byDay, byHour], [3, 2]), gap, row([methods, categories, best], [1, 1, 1])];
    }
    if (w >= 820) {
      return [row([byDay, byHour], [1, 1]), gap, row([methods, categories], [1, 1]), gap, best];
    }
    return [byDay, gap, byHour, gap, methods, gap, categories, gap, best];
  }

  static List<int> _hoursOf(List<Order> paid) {
    final out = List<int>.filled(24, 0);
    for (final o in paid) {
      out[o.createdAt.hour] += o.netTotal;
    }
    return out;
  }
}

// ───────────────────────── chart pieces ─────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final IconData icon;
  final Widget child;
  static const height = 250.0;
  const _ChartCard({required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => NvSheet(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: Nv.gold100, borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, size: 14, color: Nv.goldInk),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
                ),
                if (trailing != null)
                  Flexible(
                    child: Text(trailing!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: height, child: child),
          ],
        ),
      );
}

class _ChartEmpty extends StatelessWidget {
  final String message;
  const _ChartEmpty(this.message);

  @override
  Widget build(BuildContext context) =>
      NvEmptyState(mascot: 'sleepy', size: 92, title: 'ยังไม่มีข้อมูล', message: message);
}

/// Compact baht for axis ticks: ฿850 · ฿1.2k · ฿35k · ฿1.4M.
String _compactBaht(int v) {
  if (v >= 1000000) return '฿${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}M';
  if (v >= 1000) return '฿${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
  return '฿$v';
}

/// Round [v] up to a "nice" axis maximum (1 · 2 · 2.5 · 5 × 10ⁿ).
int _niceMax(int v) {
  if (v <= 0) return 1;
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final k in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (v <= k * mag) return (k * mag).ceil();
  }
  return v;
}

/// Vertical bar chart with hover/tap read-out.
class _BarChart extends StatefulWidget {
  final List<int> values;
  final List<String> labels;
  final List<String> tips;
  final int? highlight;
  const _BarChart({required this.values, required this.labels, required this.tips, this.highlight});

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart> {
  int? _sel;

  int? _indexAt(Offset p, Size size) {
    final n = widget.values.length;
    if (n == 0) return null;
    final chartW = size.width - _BarPainter.left;
    if (p.dx < _BarPainter.left || chartW <= 0) return null;
    final i = ((p.dx - _BarPainter.left) / (chartW / n)).floor();
    return i.clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return MouseRegion(
        onHover: (e) {
          final i = _indexAt(e.localPosition, size);
          if (i != _sel) setState(() => _sel = i);
        },
        onExit: (_) {
          if (mounted && _sel != null) setState(() => _sel = null);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => setState(() => _sel = _indexAt(d.localPosition, size)),
          child: CustomPaint(
            size: size,
            painter: _BarPainter(
              values: widget.values,
              labels: widget.labels,
              tips: widget.tips,
              highlight: widget.highlight,
              selected: _sel,
            ),
          ),
        ),
      );
    });
  }
}

class _BarPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final List<String> tips;
  final int? highlight;
  final int? selected;

  _BarPainter({required this.values, required this.labels, required this.tips, this.highlight, this.selected});

  static const left = 46.0;
  static const bottom = 24.0;
  static const top = 30.0;

  TextPainter _text(String s, TextStyle style) =>
      TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr, maxLines: 1)..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0 || size.width <= left + 10 || size.height <= top + bottom + 10) return;
    final maxV = values.reduce(math.max);
    final axisMax = _niceMax(maxV);
    final chartW = size.width - left;
    final chartH = size.height - top - bottom;
    final baseY = top + chartH;

    // grid + ticks (0, ½, max)
    final grid = Paint()
      ..color = Nv.line
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = baseY - chartH * f;
      var x = left;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, size.width), y), grid);
        x += 9;
      }
      final tp = _text(_compactBaht((axisMax * f).round()), Nv.money(10, color: Nv.ink3, weight: FontWeight.w500));
      tp.paint(canvas, Offset(left - 8 - tp.width, y - tp.height / 2));
      tp.dispose();
    }

    final slot = chartW / n;
    final barW = math.min(slot * 0.62, 34.0);

    // label stride so labels never collide
    var maxLabel = 0.0;
    for (final l in labels) {
      final tp = _text(l, Nv.ui(10.5, color: Nv.navy700, weight: FontWeight.w600));
      maxLabel = math.max(maxLabel, tp.width);
      tp.dispose();
    }
    final stride = math.max(1, ((maxLabel + 6) / slot).ceil());

    for (var i = 0; i < n; i++) {
      final v = values[i];
      final cx = left + slot * i + slot / 2;
      final h = v <= 0 ? 0.0 : math.max(3.0, chartH * v / axisMax);
      final rect = Rect.fromLTWH(cx - barW / 2, baseY - h, barW, h);
      if (v <= 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, baseY - 2, barW, 2), const Radius.circular(1)),
          Paint()..color = Nv.ivoryDeep,
        );
      } else {
        final isSel = selected == i;
        final isHi = highlight == i;
        final gradient = isSel
            ? Nv.btnNavy
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isHi ? const [Nv.gold300, Nv.gold600] : const [Nv.gold200, Nv.gold500],
              );
        if (isHi && !isSel) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(rect.inflate(2), topLeft: const Radius.circular(7), topRight: const Radius.circular(7)),
            Paint()
              ..color = Nv.gold400.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
          Paint()..shader = gradient.createShader(rect),
        );
      }

      if (i % stride == 0 || i == highlight) {
        final tp = _text(labels[i],
            Nv.ui(10.5, color: i == highlight ? Nv.goldInk : Nv.navy700, weight: i == highlight ? FontWeight.w800 : FontWeight.w600));
        tp.paint(canvas, Offset(cx - tp.width / 2, baseY + 6));
        tp.dispose();
      }
    }

    // read-out bubble
    final s = selected;
    if (s != null && s >= 0 && s < n) {
      final cx = left + slot * s + slot / 2;
      final h = values[s] <= 0 ? 0.0 : math.max(3.0, chartH * values[s] / axisMax);
      final tipText = '${tips[s]} · ${baht(values[s])}';
      final tp = _text(tipText, Nv.money(11.5, color: Nv.gold200, weight: FontWeight.w600));
      final bw = tp.width + 18;
      const bh = 24.0;
      final bx = (cx - bw / 2).clamp(0.0, math.max(0.0, size.width - bw)).toDouble();
      final by = math.max(0.0, baseY - h - bh - 6);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(8));
      canvas.drawRRect(r, Paint()..color = Nv.navy800);
      canvas.drawRRect(
        r,
        Paint()
          ..color = Nv.gold500.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      tp.paint(canvas, Offset(bx + 9, by + (bh - tp.height) / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.selected != selected || old.highlight != highlight || !_same(old.values, values) || !_sameS(old.labels, labels);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameS(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One payment method: 3D art, amount, bill count, share bar.
class _MethodRow extends StatelessWidget {
  final PaymentMethod method;
  final int amount;
  final int bills;
  final double fraction;
  const _MethodRow({required this.method, required this.amount, required this.bills, required this.fraction});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          NvArt.icon(method.art, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(method.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13, weight: FontWeight.w600)),
                    ),
                    Text(baht(amount), style: Nv.money(13.5)),
                  ],
                ),
                const SizedBox(height: 5),
                _HBar(fraction: fraction),
                const SizedBox(height: 3),
                Text('$bills บิล · ${(fraction * 100).toStringAsFixed(1)}%', style: Nv.money(10.5, color: Nv.ink3, weight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      );
}

class _HBar extends StatelessWidget {
  final double fraction;
  final Color? color;
  const _HBar({required this.fraction, this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Nv.ivoryDeep)),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    gradient: color == null ? const LinearGradient(colors: [Nv.gold300, Nv.gold500]) : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      );
}

const _catColors = [Nv.gold500, Nv.navy600, Nv.jade, Nv.sapphire, Nv.amethyst, Nv.ink4];

class _CategoryDonut extends StatelessWidget {
  final List<({String name, int value})> entries;
  const _CategoryDonut({required this.entries});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    return LayoutBuilder(builder: (context, c) {
      final d = math.min(150.0, math.min(c.maxHeight, c.maxWidth * 0.42));
      return Row(
        children: [
          SizedBox(
            width: d,
            height: d,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DonutPainter(values: [for (final e in entries) e.value], colors: _catColors),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(child: Text(_compactBaht(total), style: Nv.money(15))),
                    Text('รวม', style: Nv.ui(11, color: Nv.ink3)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: _catColors[i % _catColors.length], borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(entries[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink2)),
                        ),
                        Text(baht(entries[i].value), style: Nv.money(12)),
                        SizedBox(
                          width: 48,
                          child: Text('${(entries[i].value * 100 / total).toStringAsFixed(0)}%',
                              textAlign: TextAlign.right, style: Nv.money(11, color: Nv.ink3, weight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (s, v) => s + v);
    if (total <= 0) return;
    final stroke = math.max(14.0, size.shortestSide * 0.16);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2 - 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = Nv.ivoryDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    var start = -math.pi / 2;
    final gap = values.where((v) => v > 0).length > 1 ? 0.025 : 0.0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = math.pi * 2 * values[i] / total;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0.001, sweep - gap),
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => !_BarPainter._same(old.values, values);
}

class _TopList extends StatelessWidget {
  final List<({String name, int qty, int revenue})> rows;
  const _TopList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final maxQty = rows.map((r) => r.qty).fold<int>(1, math.max);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < rows.length; i++)
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: i == 0 ? Nv.btnGold : (i < 3 ? Nv.btnNavy : null),
                  color: i < 3 ? null : Nv.ivoryDeep,
                ),
                child: Text('${i + 1}',
                    style: Nv.money(12.5, color: i == 0 ? const Color(0xFF1A1405) : (i < 3 ? Nv.gold200 : Nv.ink2))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(rows[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13, weight: FontWeight.w600)),
                        ),
                        Text('×${groupDigits(rows[i].qty)}', style: Nv.money(12.5, color: Nv.goldInk)),
                        const SizedBox(width: 10),
                        Text(baht(rows[i].revenue), style: Nv.money(12.5)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _HBar(fraction: rows[i].qty / maxQty, color: i == 0 ? null : Nv.navy600.withValues(alpha: 0.75)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

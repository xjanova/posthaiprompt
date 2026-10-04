// Thaiprompt POS — Accounting (Nova): P&L, output-VAT report, sales journal.
//
// Pick a period (เดือนนี้ / เดือนก่อน / กำหนดเอง) and every number is computed
// from the recorded bills: gross → discounts → refunds → net (incl. VAT) →
// output VAT → revenue before tax → COGS → gross profit + margin. The VAT
// report and the daily journal list only days that had sales. "พิมพ์งบ" /
// "แชร์ PDF" render an A4 black-on-white statement (lib/print/pnl_doc.dart).
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../print/pnl_doc.dart';
import '../print/receipt_doc.dart' show ShopInfo;
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

enum _Range { thisMonth, lastMonth, custom }

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  _Range _range = _Range.thisMonth;
  DateTimeRange? _custom;
  bool _busy = false;

  (DateTime, DateTime) _bounds() {
    final now = DateTime.now();
    switch (_range) {
      case _Range.thisMonth:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month, now.day + 1));
      case _Range.lastMonth:
        return (DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 1));
      case _Range.custom:
        final r = _custom!;
        return (
          DateTime(r.start.year, r.start.month, r.start.day),
          DateTime(r.end.year, r.end.month, r.end.day + 1),
        );
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final res = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: _custom ?? DateTimeRange(start: DateTime(now.year, now.month, 1), end: today),
      helpText: 'เลือกช่วงวันที่ของงบ',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      saveText: 'ใช้ช่วงนี้',
      fieldStartLabelText: 'วันเริ่มต้น',
      fieldEndLabelText: 'วันสิ้นสุด',
    );
    if (!mounted || res == null) return;
    setState(() {
      _custom = res;
      _range = _Range.custom;
    });
  }

  void _onRange(_Range r) {
    if (r == _Range.custom) {
      _pickCustom();
      return;
    }
    setState(() => _range = r);
  }

  /// 0.07 → "7" · 0.075 → "7.50" (rounded first — never trust raw double math).
  static String _ratePct(double rate) {
    final hundredths = (rate * 10000).round();
    return hundredths % 100 == 0 ? '${hundredths ~/ 100}' : (hundredths / 100).toStringAsFixed(2);
  }

  static String _ymd(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> _output(PnlSummary s, {required bool share}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final store = AppScope.read(context);
      final doc = PnlDoc(summary: s, shop: ShopInfo.of(store), printedAt: DateTime.now(), printedBy: store.actorName);
      final last = s.to.subtract(const Duration(days: 1));
      final Future<PrintResult> job = share
          ? PrintService.shareDoc(context, doc, fileName: 'pnl-${_ymd(s.from)}-${_ymd(last)}', medium: PrintMedium.a4)
          // A4 goes through the system dialog — the saved printer is the receipt roll.
          : PrintService.printDoc(context, doc, jobName: 'งบกำไรขาดทุน ${thaiDate(s.from)}–${thaiDate(last)}', medium: PrintMedium.a4);
      final res = await job;
      if (!mounted) return;
      nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final (from, to) = _bounds();
    final last = to.subtract(const Duration(days: 1));
    final s = PnlSummary.of(store, store.ordersBetween(from, to), from: from, to: to);
    final vatNote = !store.vatEnabled
        ? 'ปิด VAT อยู่ (บิลเก่าที่เคยคิด VAT ยังนับตามจริง)'
        : 'VAT ${_ratePct(store.vatRate)}% · ${store.vatInclusive ? 'ราคารวม VAT แล้ว' : 'บวก VAT เพิ่มจากราคา'}';

    return NvScaffold(
      title: 'บัญชี',
      eyebrow: 'กำไรขาดทุน · ภาษีขาย',
      subtitle: '${store.shopName} · ${store.branch}',
      art: 'accounting',
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final toolbar = Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            NvSegmented<_Range>(
              options: const [(_Range.thisMonth, 'เดือนนี้'), (_Range.lastMonth, 'เดือนก่อน'), (_Range.custom, 'กำหนดเอง')],
              value: _range,
              onChanged: _onRange,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(Nv.rPill),
              onTap: _pickCustom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(NvIcons.calendar, size: 14, color: Nv.goldInk),
                    const SizedBox(width: 8),
                    Text('${thaiDate(from)} – ${thaiDate(last)}', style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            NvButton.gold('พิมพ์งบ',
                icon: NvIcons.print, size: NvButtonSize.sm, loading: _busy, onPressed: s.isEmpty ? null : () => _output(s, share: false)),
            NvButton.soft('แชร์ PDF',
                icon: NvIcons.filePdf, size: NvButtonSize.sm, onPressed: s.isEmpty || _busy ? null : () => _output(s, share: true)),
          ],
        );

        if (s.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toolbar,
              const SizedBox(height: 16),
              Expanded(
                child: NvSheet(
                  child: NvEmptyState(
                    mascot: 'search',
                    title: 'ไม่มีรายการขายในช่วงนี้',
                    message: 'งบกำไรขาดทุนคำนวณจากบิลที่ชำระแล้วเท่านั้น ลองเลือกช่วงวันที่อื่น',
                    actionLabel: 'เลือกช่วงวันที่',
                    actionIcon: NvIcons.calendar,
                    onAction: _pickCustom,
                  ),
                ),
              ),
            ],
          );
        }

        final pnlCard = _PnlCard(s: s, vatNote: vatNote);
        final vatCard = _VatCard(s: s, narrow: w < 640);
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            toolbar,
            const SizedBox(height: 16),
            if (w >= 1100)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: pnlCard),
                  const SizedBox(width: 14),
                  Expanded(flex: 6, child: vatCard),
                ],
              )
            else ...[
              pnlCard,
              const SizedBox(height: 14),
              vatCard,
            ],
            const SizedBox(height: 14),
            _JournalCard(s: s, narrow: w < 720),
          ],
        );
      }),
    );
  }
}

// ───────────────────────── P&L ─────────────────────────

class _PnlCard extends StatelessWidget {
  final PnlSummary s;
  final String vatNote;
  const _PnlCard({required this.s, required this.vatNote});

  @override
  Widget build(BuildContext context) {
    Widget line(String label, int amount, {bool minus = false, bool strong = false, String? hint}) => Container(
          padding: EdgeInsets.symmetric(vertical: strong ? 9 : 7, horizontal: strong ? 10 : 2),
          margin: EdgeInsets.only(top: strong ? 4 : 0),
          decoration: strong
              ? BoxDecoration(color: Nv.ivoryDeep.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10))
              : const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Nv.ui(strong ? 14.5 : 13.5, color: strong ? Nv.ink : Nv.ink2, weight: strong ? FontWeight.w700 : FontWeight.w500)),
                    if (hint != null) Text(hint, style: Nv.ui(11.5, color: Nv.ink3)),
                  ],
                ),
              ),
              Text(
                minus && amount != 0 ? baht(-amount) : baht(amount),
                style: Nv.money(strong ? 16 : 14, color: minus && amount != 0 ? Nv.lacquerDeep : Nv.ink, weight: strong ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        );

    return NvSheet(
      goldEdge: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('accounting', size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('งบกำไรขาดทุน', style: Nv.display(19)),
                    Text(vatNote, style: Nv.ui(12, color: Nv.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          line('ยอดขายรวม', s.gross, hint: '${groupDigits(s.bills)} บิล · ${groupDigits(s.items)} ชิ้น'),
          line('หัก ส่วนลด', s.discounts, minus: true),
          if (s.addOnVat != 0) line('บวก VAT ที่เรียกเก็บเพิ่ม', s.addOnVat, hint: 'บิลที่ตั้งราคาไม่รวม VAT'),
          line('หัก คืนเงิน', s.refunds,
              minus: true, hint: s.refundedBills + s.partialRefundBills == 0 ? null : 'คืนทั้งบิล ${s.refundedBills} · คืนบางส่วน ${s.partialRefundBills}'),
          line('ยอดขายสุทธิ (รวม VAT)', s.net, strong: true),
          line('หัก ภาษีขาย (VAT)', s.vat, minus: true, hint: s.vatOnRefunds > 0 ? 'หัก VAT ส่วนที่คืนเงินแล้ว ${baht(s.vatOnRefunds)}' : null),
          line('รายได้ก่อนภาษี', s.revenueExVat, strong: true),
          line('หัก ต้นทุนขาย (COGS)', s.cogs, minus: true),
          const SizedBox(height: 10),
          Stack(
            children: [
              NvNightCard(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('กำไรขั้นต้น', style: Nv.ui(13, color: Nv.onNight2, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: NvFoilText(baht(s.profit), style: Nv.money(28)),
                          ),
                        ],
                      ),
                    ),
                    NvBadge('อัตรากำไร ${s.marginPct.toStringAsFixed(1)}%', tint: s.profit >= 0 ? NvTint.jade : NvTint.lacquer),
                  ],
                ),
              ),
              const NvKanokCorners(size: 34, opacity: 0.5, inset: EdgeInsets.all(3), bottom: false),
            ],
          ),
          if (s.missingCostLines > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Nv.amberTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Nv.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 2), child: Icon(NvIcons.warning, size: 15, color: Nv.amber)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ต้นทุนไม่ครบ ${groupDigits(s.missingCostLines)} รายการ — กำไรจะสูงกว่าความจริง',
                            style: Nv.ui(13, color: const Color(0xFF8A5A00), weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          'สินค้าที่ขายโดยไม่มีราคาทุน: ${s.missingCostNames.take(5).join(', ')}${s.missingCostNames.length > 5 ? ' และอีก ${s.missingCostNames.length - 5} รายการ' : ''}',
                          style: Nv.ui(12, color: Nv.ink2, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        NvButton.ghost('ตั้งต้นทุนในเมนู', icon: NvIcons.menuBook, size: NvButtonSize.sm, onPressed: () => context.go('/menu-editor')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── tables ─────────────────────────

Widget _cells(List<String> cells, List<int> flex, {bool head = false, bool strong = false, Color? bg}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: head ? null : const Border(bottom: BorderSide(color: Nv.lineSoft)),
        borderRadius: head ? BorderRadius.circular(10) : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(
                cells[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                style: head
                    ? Nv.ui(12, color: Nv.ink3, weight: FontWeight.w700)
                    : (i == 0
                        ? Nv.ui(13, color: Nv.ink, weight: strong ? FontWeight.w700 : FontWeight.w500)
                        : Nv.money(12.5, color: Nv.ink, weight: strong ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
        ],
      ),
    );

class _VatCard extends StatelessWidget {
  final PnlSummary s;
  final bool narrow;
  const _VatCard({required this.s, required this.narrow});

  @override
  Widget build(BuildContext context) {
    const flex = [3, 3, 2, 3];
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('tax', size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('รายงานภาษีขาย', style: Nv.display(19)),
                    Text('รายวัน · หัก VAT ของยอดที่คืนเงินแล้ว', style: Nv.ui(12, color: Nv.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _mini('ยอดขายก่อน VAT', baht(s.revenueExVat)),
              _mini('ภาษีขาย', baht(s.vat), gold: true),
              _mini('รวมรับ', baht(s.net)),
            ],
          ),
          const SizedBox(height: 14),
          _cells(const ['วันที่', 'ก่อน VAT', 'VAT', 'รวม'], flex, head: true, bg: Nv.ivoryDeep.withValues(alpha: 0.6)),
          for (final d in s.days.reversed) _cells([narrow ? thaiDayMonth(d.day) : thaiDate(d.day), groupDigits(d.exVat), groupDigits(d.vat), groupDigits(d.net)], flex),
          _cells(['รวม ${s.days.length} วัน', groupDigits(s.revenueExVat), groupDigits(s.vat), groupDigits(s.net)], flex, strong: true),
        ],
      ),
    );
  }

  Widget _mini(String k, String v, {bool gold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: gold ? Nv.gold100 : Nv.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold ? Nv.gold500.withValues(alpha: 0.5) : Nv.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(k, style: Nv.ui(11.5, color: Nv.ink3, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(v, style: Nv.money(16, color: gold ? Nv.goldInk : Nv.ink)),
          ],
        ),
      );
}

class _JournalCard extends StatelessWidget {
  final PnlSummary s;
  final bool narrow;
  const _JournalCard({required this.s, required this.narrow});

  @override
  Widget build(BuildContext context) {
    const flex = [3, 1, 3, 2, 2, 2, 3];
    final days = s.days.reversed.toList();
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('receipt', size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สมุดรายวันขาย', style: Nv.display(19)),
                    Text('เฉพาะวันที่มีรายการ · คืนเงินนับตามวันที่ของบิล', style: Nv.ui(12, color: Nv.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (narrow)
            for (final d in days)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(thaiDate(d.day), style: Nv.ui(13.5, weight: FontWeight.w700))),
                        Text(baht(d.net), style: Nv.money(14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.bills} บิล · รวม ${baht(d.gross)} · ส่วนลด ${baht(d.discounts)} · คืน ${baht(d.refunds)} · VAT ${baht(d.vat)}',
                      style: Nv.money(11.5, color: Nv.ink3, weight: FontWeight.w500),
                    ),
                  ],
                ),
              )
          else ...[
            _cells(const ['วันที่', 'บิล', 'ยอดขายรวม', 'ส่วนลด', 'คืนเงิน', 'VAT', 'สุทธิ'], flex,
                head: true, bg: Nv.ivoryDeep.withValues(alpha: 0.6)),
            for (final d in days)
              _cells([
                thaiDate(d.day),
                groupDigits(d.bills),
                groupDigits(d.gross),
                groupDigits(d.discounts),
                groupDigits(d.refunds),
                groupDigits(d.vat),
                groupDigits(d.net),
              ], flex),
            _cells([
              'รวม',
              groupDigits(s.bills),
              groupDigits(s.gross),
              groupDigits(s.discounts),
              groupDigits(s.refunds),
              groupDigits(s.vat),
              groupDigits(s.net),
            ], flex, strong: true),
          ],
        ],
      ),
    );
  }
}

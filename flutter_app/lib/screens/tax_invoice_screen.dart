// Thaiprompt POS — ใบกำกับภาษีเต็มรูป (full tax invoice) · Nova.
//
// Choose a bill (/tax-invoice?id=, else the last sale, or pick from recent
// paid bills), fill the buyer (name, 13-digit tax id validated with the Thai
// checksum, address, head office / branch no.) and issue it through
// PosStore.issueTaxInvoice — a gap-free running number per Buddhist year that
// is kept on re-issue. The A4 document (lib/print/tax_invoice_doc.dart) is
// previewed live on a paper card and printed / shared as PDF. Issuing is
// blocked until the shop's own tax id is set in Settings.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../models/order_models.dart';
import '../print/receipt_doc.dart' show ShopInfo;
import '../print/tax_invoice_doc.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const _hqLabel = 'สำนักงานใหญ่';

/// Thai 13-digit tax id checksum: Σ d[i]·(13−i) for i<12, (11 − Σ mod 11) mod 10 == d[12].
bool _validTaxId(String d) {
  if (!RegExp(r'^\d{13}$').hasMatch(d)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += (d.codeUnitAt(i) - 48) * (13 - i);
  }
  return (11 - sum % 11) % 10 == d.codeUnitAt(12) - 48;
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

class TaxInvoiceScreen extends StatefulWidget {
  const TaxInvoiceScreen({super.key});

  @override
  State<TaxInvoiceScreen> createState() => _TaxInvoiceScreenState();
}

class _TaxInvoiceScreenState extends State<TaxInvoiceScreen> {
  String? _orderId;
  String? _lastParam;
  bool _init = false;
  String? _missing;
  GlobalKey<FormState> _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _taxId = TextEditingController();
  final _address = TextEditingController();
  final _branchNo = TextEditingController();
  bool _hq = true;
  bool _copy = false;
  bool _printing = false;
  bool _sharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = GoRouterState.of(context).uri.queryParameters['id'];
    if (!_init || id != _lastParam) {
      _init = true;
      _lastParam = id;
      final store = AppScope.read(context);
      Order? o = id == null ? null : store.orderById(id);
      _missing = id != null && o == null ? id : null;
      o ??= _defaultOrder(store);
      _select(o);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _taxId.dispose();
    _address.dispose();
    _branchNo.dispose();
    super.dispose();
  }

  Order? _defaultOrder(PosStore s) {
    final last = s.lastOrder;
    if (last != null && (last.status == OrderStatus.paid || last.status == OrderStatus.refunded)) return last;
    final settled = s.settledOrders;
    return settled.isEmpty ? null : settled.first;
  }

  /// Point the screen at [o] and load its saved buyer (or the bill's customer name).
  void _select(Order? o) {
    _orderId = o?.id;
    final b = o?.taxBuyer;
    _name.text = b?.name ?? (o?.customerName ?? '');
    _taxId.text = b?.taxId ?? '';
    _address.text = b?.address ?? '';
    if (b == null || b.branch == _hqLabel) {
      _hq = true;
      _branchNo.text = '';
    } else {
      _hq = false;
      _branchNo.text = _digits(b.branch);
    }
    _copy = false;
    // fresh form key: drops stale validation errors (FormState.reset() would
    // wipe the controllers we just filled)
    _form = GlobalKey<FormState>();
  }

  TaxBuyer _draft() => TaxBuyer(
        name: _name.text.trim(),
        taxId: _digits(_taxId.text),
        address: _address.text.trim(),
        branch: _hq ? _hqLabel : 'สาขาที่ ${_branchNo.text.trim().padLeft(5, '0')}',
      );

  bool _dirty(Order o) {
    final b = o.taxBuyer;
    if (b == null) return true;
    final d = _draft();
    return d.name != b.name || d.taxId != b.taxId || d.address != b.address || d.branch != b.branch;
  }

  void _changed(String _) => setState(() {});

  String? _validateTaxId(String? v) {
    final d = _digits(v ?? '');
    if (d.isEmpty) return 'กรุณากรอกเลขประจำตัวผู้เสียภาษี';
    if (d.length != 13) return 'ต้องมี 13 หลัก (ตอนนี้ ${d.length} หลัก)';
    if (!_validTaxId(d)) return 'เลขไม่ถูกต้อง — ตรวจสอบอีกครั้ง (หลักสุดท้ายไม่ตรง)';
    return null;
  }

  // ─────────────────────────── actions ───────────────────────────

  Future<void> _pickBill() async {
    final store = AppScope.read(context);
    final id = await showNvDialog<String>(
      context,
      title: 'เลือกบิล',
      subtitle: 'บิลที่ชำระแล้ว · ล่าสุดก่อน',
      art: 'receipt',
      maxWidth: 560,
      body: _BillPicker(orders: store.settledOrders, selectedId: _orderId),
    );
    if (id == null || !mounted) return;
    final o = AppScope.read(context).orderById(id);
    setState(() {
      _missing = null;
      _select(o);
    });
  }

  Future<void> _issue(Order o) async {
    final store = AppScope.read(context);
    if (store.taxId.isEmpty) {
      nvToast(context, 'ต้องตั้งเลขประจำตัวผู้เสียภาษีของร้านก่อน', kind: NvToastKind.error);
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) {
      nvToast(context, 'กรุณาตรวจสอบข้อมูลผู้ซื้อ', kind: NvToastKind.warning);
      return;
    }
    final buyer = _draft();
    final reissue = o.taxInvoiceNo != null;
    final ok = await showNvConfirm(
      context,
      title: reissue ? 'บันทึกข้อมูลผู้ซื้อใหม่?' : 'ออกใบกำกับภาษี?',
      message: reissue
          ? 'ใบกำกับภาษี ${o.taxInvoiceNo} จะใช้เลขที่เดิม แต่ข้อมูลผู้ซื้อจะเปลี่ยนเป็น\n${buyer.name} · ${formatTaxId(buyer.taxId)}'
          : 'บิล ${o.id} ยอด ${baht(o.total)}\nออกให้ ${buyer.name} · ${formatTaxId(buyer.taxId)}\n\nเลขที่ใบกำกับจะถูกจองถาวร (รันต่อเนื่อง ไม่ข้ามเลข)',
      confirmLabel: reissue ? 'บันทึก' : 'ออกใบกำกับ',
      danger: false,
      art: 'tax',
    );
    if (!ok || !mounted) return;
    final no = AppScope.read(context).issueTaxInvoice(o, buyer);
    setState(() => _copy = false);
    nvToast(
      context,
      reissue ? 'บันทึกข้อมูลผู้ซื้อแล้ว · เลขที่เดิม $no' : 'ออกใบกำกับภาษี $no แล้ว',
      kind: NvToastKind.success,
      actionLabel: 'พิมพ์',
      onAction: () {
        if (mounted) _print(o);
      },
    );
  }

  TaxInvoiceDoc? _issuedDoc(PosStore store, Order o) {
    final no = o.taxInvoiceNo;
    final buyer = o.taxBuyer;
    if (no == null || buyer == null) return null;
    return TaxInvoiceDoc(order: o, shop: ShopInfo.of(store), buyer: buyer, invoiceNo: no, copy: _copy);
  }

  Future<void> _print(Order o) async {
    final store = AppScope.read(context);
    final doc = _issuedDoc(store, o);
    if (doc == null || _printing) return;
    setState(() => _printing = true);
    // A4 always goes through the system dialog — the saved printer is the receipt roll.
    final res = await PrintService.printDoc(
      context,
      doc,
      jobName: 'ใบกำกับภาษี ${o.taxInvoiceNo}${_copy ? ' (สำเนา)' : ''}',
      medium: PrintMedium.a4,
      precache: TaxInvoiceDoc.precache,
    );
    if (!mounted) return;
    setState(() => _printing = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  Future<void> _share(Order o) async {
    final store = AppScope.read(context);
    final doc = _issuedDoc(store, o);
    if (doc == null || _sharing) return;
    setState(() => _sharing = true);
    final res = await PrintService.shareDoc(
      context,
      doc,
      fileName: 'tax-invoice-${o.taxInvoiceNo}${_copy ? '-copy' : ''}',
      medium: PrintMedium.a4,
      precache: TaxInvoiceDoc.precache,
    );
    if (!mounted) return;
    setState(() => _sharing = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final order = _orderId == null ? null : store.orderById(_orderId!);
    return NvScaffold(
      title: 'ใบกำกับภาษี',
      eyebrow: 'ใบกำกับภาษีเต็มรูป',
      subtitle: 'ออกให้ลูกค้าที่ต้องการใช้ภาษีซื้อ · เลขที่รันต่อเนื่องไม่ข้ามเลข',
      art: 'tax',
      actions: [
        NvButton.soft('บิลย้อนหลัง', icon: NvIcons.receipt, size: NvButtonSize.sm, onPressed: () => context.go('/orders')),
      ],
      body: order == null
          ? _empty(store)
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 860;
              final form = _formColumn(store, order);
              final preview = _previewColumn(store, order);
              if (!wide) {
                return ListView(padding: const EdgeInsets.only(bottom: 16), children: [form, const SizedBox(height: 18), preview]);
              }
              final fw = (c.maxWidth * 0.42).clamp(360.0, 460.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: fw, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 16), child: form)),
                  const SizedBox(width: 18),
                  Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 16), child: preview)),
                ],
              );
            }),
    );
  }

  Widget _empty(PosStore store) {
    if (store.settledOrders.isEmpty) {
      return NvEmptyState(
        mascot: 'empty',
        title: 'ยังไม่มีบิลที่ออกใบกำกับได้',
        message: 'ขายและรับชำระเงินก่อน แล้วกลับมาออกใบกำกับภาษีเต็มรูปให้ลูกค้า',
        actionLabel: 'ไปหน้าขาย',
        actionIcon: NvIcons.cashier,
        onAction: () => context.go('/cashier'),
      );
    }
    return NvEmptyState(
      mascot: 'search',
      title: _missing != null ? 'ไม่พบบิล $_missing' : 'เลือกบิลที่จะออกใบกำกับภาษี',
      message: 'เลือกจากบิลที่ชำระแล้วในเครื่องนี้',
      actionLabel: 'เลือกบิล',
      actionIcon: NvIcons.search,
      onAction: _pickBill,
    );
  }

  Widget _banner(NvTint tint, IconData icon, String text, {Widget? action}) {
    final c = nvTint(tint);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(Nv.rSm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 14, color: c.fg)),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: Nv.ui(13, color: c.fg, weight: FontWeight.w600, height: 1.45))),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 8), Padding(padding: const EdgeInsets.only(left: 24), child: action)],
        ],
      ),
    );
  }

  Widget _formColumn(PosStore store, Order o) {
    final issued = o.taxInvoiceNo != null;
    final dirty = _dirty(o);
    final taxIdOk = store.taxId.isNotEmpty;
    final canIssue = taxIdOk && o.status == OrderStatus.paid && (!issued || dirty);
    final digits = _digits(_taxId.text);
    final manager = store.isManager;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSheet(
          goldEdge: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  NvArt.icon(o.method.art, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('บิล ${o.id}', style: Nv.display(20)),
                        Text('${thaiDateTime(o.createdAt)} · ${o.method.label}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink3)),
                      ],
                    ),
                  ),
                  NvMoney(o.total, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (issued)
                    NvBadge('ออกแล้ว ${o.taxInvoiceNo}', tint: NvTint.jade, icon: NvIcons.fileInvoice)
                  else
                    const NvBadge('ยังไม่ออกใบกำกับ', tint: NvTint.amber),
                  NvButton.soft('เลือกบิลอื่น', icon: NvIcons.rightLeft, size: NvButtonSize.sm, onPressed: _pickBill),
                ],
              ),
            ],
          ),
        ),
        if (!taxIdOk)
          _banner(
            NvTint.lacquer,
            NvIcons.warning,
            manager
                ? 'ร้านยังไม่ได้ตั้งเลขประจำตัวผู้เสียภาษี — ออกใบกำกับภาษีไม่ได้จนกว่าจะตั้งค่า'
                : 'ร้านยังไม่ได้ตั้งเลขประจำตัวผู้เสียภาษี — ให้ผู้จัดการตั้งค่าที่ ตั้งค่า → ข้อมูลร้าน',
            action: manager ? NvButton.soft('ไปตั้งค่าร้าน', icon: NvIcons.settings, size: NvButtonSize.sm, onPressed: () => context.go('/settings')) : null,
          ),
        if (taxIdOk && store.shopAddress.isEmpty)
          _banner(
            NvTint.amber,
            NvIcons.location,
            'ยังไม่ได้ใส่ที่อยู่ร้าน — ใบกำกับภาษีเต็มรูปควรมีที่อยู่ของผู้ขาย',
            action: manager ? NvButton.soft('ไปตั้งค่าร้าน', icon: NvIcons.settings, size: NvButtonSize.sm, onPressed: () => context.go('/settings')) : null,
          ),
        if (o.status == OrderStatus.refunded)
          _banner(NvTint.lacquer, NvIcons.refund,
              'บิลนี้คืนเงินครบแล้ว — ออกหรือแก้ไขใบกำกับภาษีไม่ได้${issued ? ' (พิมพ์ฉบับเดิมซ้ำได้)' : ''}'),
        if (o.isPartiallyRefunded)
          _banner(NvTint.amber, NvIcons.info,
              'บิลนี้มีการคืนเงินบางส่วน ${baht(o.refundAmount)} — ใบกำกับแสดงยอดตามบิลขายเดิม ส่วนที่คืนต้องออกใบลดหนี้แยก'),
        if (o.tax == 0)
          _banner(NvTint.amber, NvIcons.info, 'บิลนี้ไม่มีภาษีมูลค่าเพิ่ม (ขายขณะปิด VAT) — ใบกำกับจะแสดง VAT ฿0'),
        const SizedBox(height: 14),
        NvSheet(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const NvSectionTitle('ข้อมูลผู้ซื้อ', icon: NvIcons.building),
                NvField(
                  label: 'ชื่อผู้ซื้อ / ชื่อบริษัท',
                  controller: _name,
                  icon: NvIcons.user,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อผู้ซื้อ' : null,
                  onChanged: _changed,
                ),
                const SizedBox(height: 12),
                NvField(
                  label: 'เลขประจำตัวผู้เสียภาษี (13 หลัก)',
                  controller: _taxId,
                  icon: NvIcons.idCard,
                  keyboard: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                  suffixText: digits.length == 13 ? (_validTaxId(digits) ? 'ถูกต้อง' : 'ไม่ถูกต้อง') : '${digits.length}/13',
                  validator: _validateTaxId,
                  onChanged: _changed,
                ),
                const SizedBox(height: 12),
                NvField(
                  label: 'ที่อยู่',
                  controller: _address,
                  icon: NvIcons.location,
                  maxLines: 3,
                  validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกที่อยู่ผู้ซื้อ' : null,
                  onChanged: _changed,
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('สาขาของผู้ซื้อ', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: NvSegmented<bool>(
                    options: const [(true, _hqLabel), (false, 'สาขา')],
                    value: _hq,
                    onChanged: (v) => setState(() => _hq = v),
                  ),
                ),
                if (!_hq) ...[
                  const SizedBox(height: 12),
                  NvField(
                    label: 'เลขที่สาขา (5 หลัก)',
                    controller: _branchNo,
                    icon: NvIcons.branch,
                    hint: 'เช่น 00001',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                    validator: (v) => !_hq && (v ?? '').trim().isEmpty ? 'กรอกเลขที่สาขา' : null,
                    onChanged: _changed,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        NvButton.gold(
          !issued ? 'ออกใบกำกับภาษี' : (dirty ? 'บันทึกข้อมูลผู้ซื้อ (ใช้เลขเดิม)' : 'ออกแล้ว · ${o.taxInvoiceNo}'),
          icon: NvIcons.fileInvoice,
          size: NvButtonSize.lg,
          expand: true,
          onPressed: canIssue ? () => _issue(o) : null,
        ),
        if (issued && dirty && o.status == OrderStatus.paid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('มีการแก้ไขข้อมูลผู้ซื้อที่ยังไม่บันทึก — เอกสารที่พิมพ์จะใช้ข้อมูลเดิมจนกว่าจะกดบันทึก',
                style: Nv.ui(12, color: const Color(0xFF8A5A00), weight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _previewColumn(PosStore store, Order o) {
    final issued = o.taxInvoiceNo != null && o.taxBuyer != null;
    final canPrint = issued && store.taxId.isNotEmpty;
    final doc = _issuedDoc(store, o) ??
        TaxInvoiceDoc(order: o, shop: ShopInfo.of(store), buyer: _draft(), invoiceNo: 'ยังไม่ออกเลขที่', draft: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSectionTitle('ตัวอย่างเอกสาร (A4)', icon: NvIcons.filePdf, trailing: issued ? o.taxInvoiceNo : 'ร่าง — ยังไม่ออกเลขที่'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (issued)
              NvSegmented<bool>(
                options: const [(false, 'ต้นฉบับ'), (true, 'สำเนา')],
                value: _copy,
                onChanged: (v) => setState(() => _copy = v),
              ),
            NvButton.navy('พิมพ์ A4', icon: NvIcons.print, loading: _printing, onPressed: canPrint && !_printing ? () => _print(o) : null),
            NvButton.soft('แชร์ PDF', icon: NvIcons.share, loading: _sharing, onPressed: canPrint && !_sharing ? () => _share(o) : null),
          ],
        ),
        if (!canPrint)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(issued ? 'ต้องตั้งเลขผู้เสียภาษีของร้านก่อนจึงจะพิมพ์ได้' : 'ออกใบกำกับภาษีก่อน จึงจะพิมพ์หรือแชร์ได้ (ตัวอย่างด้านล่างอัปเดตตามที่กรอก)',
                style: Nv.ui(12, color: Nv.ink3)),
          ),
        const SizedBox(height: 14),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Nv.line),
                boxShadow: Nv.shadowLift,
              ),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                child: SizedBox(width: TaxInvoiceDoc.pageWidth, child: doc),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bill chooser (search + recent settled bills); pops the chosen bill id.
class _BillPicker extends StatefulWidget {
  final List<Order> orders;
  final String? selectedId;
  const _BillPicker({required this.orders, this.selectedId});

  @override
  State<_BillPicker> createState() => _BillPickerState();
}

class _BillPickerState extends State<_BillPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final matches = q.isEmpty
        ? widget.orders
        : widget.orders
            .where((o) => '${o.id} ${o.reference} ${o.customerName ?? ''} ${o.taxInvoiceNo ?? ''} ${o.taxBuyer?.name ?? ''}'.toLowerCase().contains(q))
            .toList();
    final shown = matches.take(60).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NvSearchField(hint: 'ค้นหาเลขบิล / ลูกค้า / เลขใบกำกับ', autofocus: true, onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('ไม่พบบิล', textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink3)),
          )
        else
          for (final o in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NvSheet(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                color: Nv.paper,
                shadow: const [],
                selected: o.id == widget.selectedId,
                onTap: () => Navigator.of(context).pop(o.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(o.id, style: Nv.money(14.5)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(thaiDateTime(o.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                              ),
                            ],
                          ),
                          if ((o.taxBuyer?.name ?? o.customerName) != null)
                            Text(o.taxBuyer?.name ?? o.customerName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink2)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(baht(o.total), style: Nv.money(15)),
                        if (o.taxInvoiceNo != null)
                          const NvBadge('มีใบกำกับ', tint: NvTint.jade)
                        else if (o.status == OrderStatus.refunded)
                          const NvBadge('คืนเงินแล้ว', tint: NvTint.lacquer),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        if (matches.length > shown.length)
          Text('แสดง ${shown.length} บิลล่าสุด · พิมพ์ค้นหาเพื่อหาบิลที่เก่ากว่า', textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.ink3)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
        ),
      ],
    );
  }
}

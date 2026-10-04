// Thai Prompt POS — "Thai Prompt · ส่งไรเดอร์" (cashier side).
//
// The customer pays goods + delivery from their Thai Prompt wallet in the app;
// a Thai Prompt rider then collects here. Steps in one dialog:
//   form     → optional customer phone (push) + note
//   creating → POST /api/pos/delivery-requests (server prices the cart)
//   waiting  → QR on this screen AND on the customer display, countdown,
//              live status (RiderTracker polls every 4 s)
//   paid     → the POS bill was booked from the server-priced lines; the cart
//              is cleared → caller opens the receipt
// "พักไว้" parks the request on the delivery board (cart cleared, QR off the
// customer display) — a payment that lands later is still booked once.
//
// by xman studio

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/api/api_exceptions.dart';
import '../models/extra_models.dart';
import '../services/rider_tracker.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum TpRiderOutcome { paid, parked, closed }

class TpRiderResult {
  final TpRiderOutcome outcome;
  final DeliveryJob? job; // its orderId is the POS bill when [outcome] is paid
  const TpRiderResult(this.outcome, this.job);
}

/// Start a request from the counter cart, or re-open a parked job's QR
/// ([resume]). Returns how it ended (null = dismissed).
Future<TpRiderResult?> showTpRiderDialog(BuildContext context, {DeliveryJob? resume}) => showDialog<TpRiderResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Nv.navy950.withValues(alpha: 0.55),
      builder: (_) => _TpRiderDialog(resume: resume),
    );

/// Why the counter cart can't go out as a Thai Prompt rider request ('' = ok).
String tpRiderBlockReason(PosStore store) {
  final block = store.checkoutBlockReason;
  if (block.isNotEmpty) return block;
  if (store.activeTicketIds.isNotEmpty) return 'บิลโต๊ะส่งไรเดอร์ไม่ได้ — ใช้กับการขายหน้าร้าน/เดลิเวอรี่';
  if (store.sync?.config.hasTerminal != true) return 'เชื่อมเครื่องนี้กับร้าน Thai Prompt ก่อน (ตั้งค่า → การเชื่อมต่อ)';
  return '';
}

enum _Step { form, creating, waiting }

class _TpRiderDialog extends StatefulWidget {
  final DeliveryJob? resume;
  const _TpRiderDialog({this.resume});

  @override
  State<_TpRiderDialog> createState() => _TpRiderDialogState();
}

class _TpRiderDialogState extends State<_TpRiderDialog> {
  final _phone = TextEditingController();
  final _note = TextEditingController();
  final _rng = Random.secure();
  _Step _step = _Step.form;
  DeliveryJob? _job;
  String _localId = '';
  String? _error;
  List<String> _missing = const [];
  bool _pushSent = false;
  bool _cancelling = false;
  bool _cartCleared = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    final r = widget.resume;
    if (r != null) {
      _job = r;
      _step = _Step.waiting;
      // notifies the store — not allowed while this dialog is being built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        store.showRiderQr(r);
        RiderTracker.instance.refresh(r);
      });
    } else {
      _newLocalId(store);
      _phone.text = (store.linkedCustomer?.phone ?? '').replaceAll(RegExp(r'\D'), '');
      _note.text = store.tpRiderCartNote();
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _step == _Step.waiting) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  /// One id per attempt: a retry after a lost response returns the same
  /// server request; a fresh attempt (new cart) gets a fresh one.
  void _newLocalId(PosStore store) {
    final nonce = List.generate(6, (_) => 'abcdefghjkmnpqrstuvwxyz23456789'[_rng.nextInt(31)]).join();
    _localId = '${store.nextDeliveryId}-$nonce';
  }

  void _close(TpRiderOutcome outcome) {
    final store = AppScope.read(context);
    if (store.riderQrJobId == _job?.id) store.showRiderQr(null);
    if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.of(context).pop(TpRiderResult(outcome, _job));
  }

  // ─────────────────────────── actions ───────────────────────────

  Future<void> _create() async {
    final store = AppScope.read(context);
    final block = tpRiderBlockReason(store);
    if (block.isNotEmpty) {
      setState(() => _error = block);
      return;
    }
    final api = store.sync?.api;
    if (api == null) return;
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (phone.isNotEmpty && !RegExp(r'^0\d{8,9}$').hasMatch(phone)) {
      setState(() => _error = 'เบอร์ลูกค้าต้องเป็นตัวเลข 9–10 หลัก ขึ้นต้นด้วย 0');
      return;
    }
    // options / notes per product (the online catalog has no POS modifiers)
    final detail = <String, List<String>>{};
    for (final l in store.cart) {
      final d = [...l.options, if (l.note.isNotEmpty) l.note];
      if (d.isNotEmpty) detail.putIfAbsent(l.product.code, () => []).addAll(d);
    }
    setState(() {
      _step = _Step.creating;
      _error = null;
      _missing = const [];
    });
    try {
      final data = await api.createDeliveryRequest({
        'local_id': _localId,
        'order_local_id': store.openOrderId,
        'items': store.tpRiderRequestItems(),
        if (phone.isNotEmpty) 'customer_phone': phone,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      if (!mounted) return;
      final id = (data['id'] as num?)?.toInt();
      final qr = (data['qr_payload'] as String?) ?? '';
      if (id == null || qr.isEmpty) throw ApiException('เซิร์ฟเวอร์ตอบกลับไม่ครบ ลองใหม่อีกครั้ง', statusCode: 500);
      final lines = <TpRiderLine>[
        for (final raw in (data['items'] as List? ?? const []).whereType<Map>())
          () {
            final j = raw.cast<String, dynamic>();
            final sid = (j['product_id'] as num?)?.toInt();
            var code = (j['sku'] ?? '').toString();
            if (code.isEmpty || store.productByCode(code) == null) {
              final byId = store.products.where((p) => sid != null && p.serverId == sid);
              if (byId.isNotEmpty) code = byId.first.code;
            }
            return TpRiderLine(
              code: code,
              name: (j['name'] ?? store.productByCode(code)?.name ?? code).toString(),
              qty: (j['qty'] as num?)?.toInt() ?? 1,
              price: (j['price'] as num?)?.round() ?? 0,
              options: (detail[code] ?? const []).join(' · '),
            );
          }(),
      ];
      final job = store.createTpRiderJob(
        requestId: id,
        qrPayload: qr,
        expiresAt: DateTime.tryParse('${data['expires_at'] ?? ''}')?.toLocal(),
        lines: lines,
        subtotal: (data['subtotal'] as num?)?.round() ?? lines.fold<int>(0, (s, l) => s + l.total),
        customerName: store.linkedCustomer?.name ?? store.customerName ?? '',
        phone: phone,
        note: _note.text,
      );
      store.showRiderQr(job);
      setState(() {
        _job = job;
        _pushSent = data['push_sent'] == true;
        _step = _Step.waiting;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      var missing = const <String>[];
      if (e.code == 'ITEMS_NOT_IN_STORE' && e.data is Map) {
        missing = [
          for (final m in ((e.data as Map)['missing'] as List? ?? const []).whereType<Map>())
            '${m['name'] ?? m['sku'] ?? ''}'.trim(),
        ].where((s) => s.isNotEmpty).toList();
      }
      setState(() {
        _step = _Step.form;
        _missing = missing;
        _error = e.isOffline
            ? 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ — ตรวจอินเทอร์เน็ตแล้วลองอีกครั้ง'
            : e.statusCode == 404 && e.code == null
                ? 'เซิร์ฟเวอร์ร้านยังไม่เปิดใช้การส่งด้วยไรเดอร์ Thai Prompt — ติดต่อผู้ดูแลระบบ'
                : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _Step.form;
        _error = 'สร้างคำขอไม่สำเร็จ ลองอีกครั้ง';
      });
    }
  }

  Future<void> _cancelRequest() async {
    final j = _job;
    final store = AppScope.read(context);
    final api = store.sync?.api;
    if (j == null || api == null || j.requestId == null || _cancelling) return;
    final ok = await showNvConfirm(
      context,
      title: 'ยกเลิกคำขอส่งไรเดอร์?',
      message: 'QR นี้จะใช้จ่ายไม่ได้อีก ถ้าลูกค้ากำลังจะจ่าย ให้รอสักครู่ก่อน',
      confirmLabel: 'ยกเลิกคำขอ',
      cancelLabel: 'ไม่ยกเลิก',
    );
    if (!ok || !mounted) return;
    setState(() => _cancelling = true);
    try {
      final data = await api.cancelDeliveryRequest(j.requestId!);
      if (!mounted) return;
      if (data.isNotEmpty) store.applyTpRiderStatus(j, data);
      if (j.payStatus != 'paid') store.markTpRiderClosed(j);
    } on ApiException catch (e) {
      if (!mounted) return;
      // already paid / expired → the latest status decides what we show
      await RiderTracker.instance.refresh(j);
      if (!mounted) return;
      if (j.payStatus == 'pending') nvToast(context, e.isOffline ? 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้' : e.message, kind: NvToastKind.error);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _park() {
    final store = AppScope.read(context);
    if (widget.resume == null) store.clearCart();
    nvToast(context, 'พักคำขอ ${_job?.id ?? ''} ไว้ที่ "งานจัดส่ง" — เปิด QR อีกครั้งได้จากที่นั่น', kind: NvToastKind.info);
    _close(TpRiderOutcome.parked);
  }

  // ─────────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // rebuild on every status poll
    final j = _job;
    final paid = j != null && j.payStatus == 'paid' && j.orderId.isNotEmpty;
    final expired = j != null &&
        (j.payStatus == 'expired' || (j.payStatus == 'pending' && j.qrExpiresAt != null && DateTime.now().isAfter(j.qrExpiresAt!)));
    final cancelled = j != null && j.payStatus == 'cancelled';

    // paid: the bill is booked from the job — the counter cart must not be sold again
    if (paid && !_cartCleared && widget.resume == null) {
      _cartCleared = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => store.clearCart());
    }

    final (String title, String? subtitle, Widget body, List<Widget> actions) = switch (_step) {
      _Step.form || _Step.creating => _formView(store),
      _Step.waiting when paid => _paidView(store, j),
      _Step.waiting when cancelled => (
          'ยกเลิกคำขอแล้ว',
          null,
          Text('QR นี้ใช้จ่ายไม่ได้แล้ว', textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink2)),
          [NvButton.gold('ปิด', onPressed: () => _close(TpRiderOutcome.closed))],
        ),
      _Step.waiting when expired => _expiredView(store),
      _Step.waiting => _waitingView(store, j!),
    };

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NvArt.icon('delivery', size: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Nv.display(20)),
                          if (subtitle != null) Text(subtitle, style: Nv.ui(13, color: Nv.ink3, height: 1.35)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(child: SingleChildScrollView(child: body)),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 10, children: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, String?, Widget, List<Widget>) _formView(PosStore store) {
    final busy = _step == _Step.creating;
    final hasOptions = store.cart.any((l) => l.options.isNotEmpty || l.optionDelta != 0);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSheet(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          radius: Nv.rMd,
          child: Row(
            children: [
              const Icon(NvIcons.basket, size: 15, color: Nv.goldInk),
              const SizedBox(width: 10),
              Expanded(child: Text('${store.cartItemCount} ชิ้น · ราคาในเครื่อง', style: Nv.ui(14, color: Nv.ink2))),
              NvMoney(store.cartTotal, size: 16),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ลูกค้าสแกน QR ด้วยแอป Thai Prompt เลือกที่อยู่ที่ปักหมุด แล้วจ่ายค่าสินค้า (ราคาร้านออนไลน์) + ค่าส่ง จากกระเป๋าเงินในแอป — ไม่มีเก็บเงินปลายทาง',
          style: Nv.ui(13, color: Nv.ink2, height: 1.45),
        ),
        if (store.cartDiscount > 0) _hint('ส่วนลด/คูปองในเครื่องไม่ถูกนำไปใช้ — ลูกค้าจ่ายตามราคาร้านออนไลน์'),
        if (hasOptions) _hint('ตัวเลือกเสริมส่งเป็นหมายเหตุถึงร้าน (ไม่คิดราคาเพิ่มในแอป)'),
        const SizedBox(height: 12),
        NvField(
          label: 'เบอร์ลูกค้า (ไม่บังคับ)',
          controller: _phone,
          icon: NvIcons.phone,
          keyboard: TextInputType.phone,
          hint: 'ใส่เบอร์ที่ใช้กับแอป เพื่อส่งแจ้งเตือนให้กดจ่าย',
          enabled: !busy,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        ),
        const SizedBox(height: 10),
        NvField(
          label: 'หมายเหตุถึงไรเดอร์ / ร้าน',
          controller: _note,
          icon: NvIcons.note,
          maxLines: 2,
          enabled: !busy,
          formatters: [LengthLimitingTextInputFormatter(300)],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: Nv.ui(13.5, color: Nv.lacquer, weight: FontWeight.w600)),
          for (final m in _missing)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 6),
              child: Text('• $m', style: Nv.ui(13, color: Nv.lacquer)),
            ),
          if (_missing.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('นำรายการเหล่านี้ออก หรือเพิ่มสินค้าในร้านออนไลน์ก่อน แล้วซิงก์อีกครั้ง',
                  style: Nv.ui(12.5, color: Nv.ink3)),
            ),
        ],
      ],
    );
    return (
      'ส่งด้วยไรเดอร์ Thai Prompt',
      'ลูกค้าจ่ายในแอป Thai Prompt · ไรเดอร์มารับที่ร้าน',
      body,
      [
        NvButton.soft('ยกเลิก', onPressed: busy ? null : () => _close(TpRiderOutcome.closed)),
        NvButton.gold('สร้าง QR ให้ลูกค้า', icon: NvIcons.qrcode, loading: busy, onPressed: busy ? null : _create),
      ],
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 2), child: Icon(NvIcons.info, size: 12, color: Nv.amber)),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: Nv.ui(12.5, color: Nv.amber, height: 1.4))),
          ],
        ),
      );

  (String, String?, Widget, List<Widget>) _waitingView(PosStore store, DeliveryJob j) {
    final left = j.qrExpiresAt?.difference(DateTime.now());
    String mmss(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    final posTotal = j.lines.fold<int>(0, (s, l) {
      final p = store.productByCode(l.code);
      return s + (p?.price ?? l.price) * l.qty;
    });
    final body = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Nv.rMd),
            border: Border.all(color: Nv.gold400, width: 2),
            boxShadow: Nv.goldGlow(0.35),
          ),
          child: QrImageView(
            data: j.qrPayload,
            size: min(240, MediaQuery.sizeOf(context).height * 0.32),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            semanticsLabel: 'QR สั่งส่งด้วยไรเดอร์ Thai Prompt',
          ),
        ),
        const SizedBox(height: 10),
        Text('ให้ลูกค้าสแกนด้วยแอป Thai Prompt', style: Nv.ui(15, weight: FontWeight.w700)),
        if (store.secondScreenEnabled) Text('QR แสดงบนจอลูกค้าด้วย', style: Nv.ui(12.5, color: Nv.ink3)),
        if (_pushSent) Text('ส่งแจ้งเตือนไปที่แอปของลูกค้าแล้ว', style: Nv.ui(12.5, color: Nv.jade)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ค่าสินค้า ', style: Nv.ui(14, color: Nv.ink2)),
            NvMoney(j.subtotal, size: 20),
            Text('  + ค่าส่ง (คิดในแอป)', style: Nv.ui(12.5, color: Nv.ink3)),
          ],
        ),
        if (posTotal != j.subtotal)
          Text('ราคาร้านออนไลน์ต่างจากในเครื่อง (${baht(posTotal)}) — บิลจะบันทึกตามที่ลูกค้าจ่ายจริง',
              textAlign: TextAlign.center, style: Nv.ui(12, color: Nv.amber)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Flexible(child: Text(j.tpStatusLabel, style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w600))),
          ],
        ),
        if (left != null && !left.isNegative)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('QR ใช้ได้อีก ${mmss(left)}', style: Nv.money(13.5, color: left.inSeconds < 60 ? Nv.lacquer : Nv.ink3)),
          ),
      ],
    );
    return (
      'รอลูกค้าชำระในแอป',
      '${j.id} · ${j.lines.fold<int>(0, (s, l) => s + l.qty)} ชิ้น',
      body,
      [
        NvButton.ghost('ยกเลิกคำขอ', icon: NvIcons.xCircle, loading: _cancelling, onPressed: _cancelling ? null : _cancelRequest),
        NvButton.soft('พักไว้ ทำรายการอื่น', icon: NvIcons.pause, onPressed: _park),
        NvIconButton(NvIcons.sync, tooltip: 'ตรวจสอบสถานะ', onPressed: () => RiderTracker.instance.refresh(j)),
      ],
    );
  }

  (String, String?, Widget, List<Widget>) _paidView(PosStore store, DeliveryJob j) {
    final body = Column(
      children: [
        NvArt.mascot('cheer', height: 120),
        const SizedBox(height: 6),
        Text('ลูกค้าชำระแล้ว', style: Nv.display(22)),
        const SizedBox(height: 6),
        Text('บิล ${j.orderId} · ค่าสินค้า ${baht(j.subtotal)}${j.fee > 0 ? ' · ค่าส่ง ${baht(j.fee)} (ลูกค้าจ่ายในแอป)' : ''}',
            textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink2)),
        const SizedBox(height: 4),
        Text(j.tpStatusLabel, textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.jade, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('เตรียมของให้พร้อม — ติดตามไรเดอร์ได้ที่หน้า "งานจัดส่ง"',
            textAlign: TextAlign.center, style: Nv.ui(12.5, color: Nv.ink3)),
      ],
    );
    return (
      'ชำระเรียบร้อย',
      j.remoteOrderNo.isEmpty ? null : 'คำสั่งซื้อ Thai Prompt ${j.remoteOrderNo}',
      body,
      [NvButton.gold('ดูใบเสร็จ', icon: NvIcons.receipt, onPressed: () => _close(TpRiderOutcome.paid))],
    );
  }

  (String, String?, Widget, List<Widget>) _expiredView(PosStore store) {
    final canRetry = widget.resume == null && store.cart.isNotEmpty;
    return (
      'QR หมดอายุ',
      'ลูกค้ายังไม่ได้ชำระภายในเวลาที่กำหนด',
      Text(canRetry ? 'สร้าง QR ใหม่ให้ลูกค้าสแกนได้ รายการในตะกร้ายังอยู่' : 'คำขอนี้ปิดแล้ว',
          textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.ink2)),
      [
        NvButton.soft('ปิด', onPressed: () {
          final j = _job;
          if (j != null && j.payStatus == 'pending') store.markTpRiderClosed(j, payStatus: 'expired');
          _close(TpRiderOutcome.closed);
        }),
        if (canRetry)
          NvButton.gold('สร้าง QR ใหม่', icon: NvIcons.qrcode, onPressed: () {
            final j = _job;
            if (j != null && j.payStatus == 'pending') store.markTpRiderClosed(j, payStatus: 'expired');
            _newLocalId(store);
            setState(() {
              _job = null;
              _step = _Step.form;
              _error = null;
            });
          }),
      ],
    );
  }
}

// Thaiprompt POS — Barcode labels (/barcode) · Nova.
//
// Pick real products (search or scan, tick, copies per product with a stepper
// or typed), choose label options (50×30 mm sticker · show price · show shop
// name) and see a live preview of exactly what prints (label_doc.dart, black
// on white). Symbology is automatic per product: EAN-13 when the scan code is
// a valid 13-digit EAN, otherwise Code 128; products without a barcode use
// their product code. "พิมพ์ฉลาก" prints each product sequentially with
// `copies: qty` (chunks of 50 — the print service's per-job cap) and stops on
// the first failure; "แชร์ PDF" exports the first selected label.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../models/catalog_models.dart';
import '../print/label_doc.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const int _kMaxCopies = 999;
const int _kJobCap = 50; // PrintService.printDoc clamps copies to 50 per job

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final Map<String, int> _sel = <String, int>{}; // product code → copies (insertion order)
  final TextEditingController _search = TextEditingController();
  String _q = '';
  bool _showPrice = true;
  bool _showShop = true;
  bool _printing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  LabelDoc _doc(PosStore store, Product p) =>
      LabelDoc(name: p.name, price: p.price, data: p.scanCode, showPrice: _showPrice, showShop: _showShop, shopName: store.shopName);

  void _toggle(Product p) => setState(() {
    if (_sel.containsKey(p.code)) {
      _sel.remove(p.code);
    } else {
      _sel[p.code] = 1;
    }
  });

  void _setQty(Product p, int v) => setState(() => _sel[p.code] = v.clamp(1, _kMaxCopies));

  Future<void> _typeQty(Product p) async {
    final raw = await showNvTextDialog(
      context,
      title: 'จำนวนฉลาก',
      subtitle: p.name,
      initial: '${_sel[p.code] ?? 1}',
      hint: '1–$_kMaxCopies',
      confirmLabel: 'ตั้งจำนวน',
    );
    if (raw == null || !mounted) return;
    final n = int.tryParse(raw.trim());
    if (n == null || n < 1 || n > _kMaxCopies) {
      nvToast(context, 'จำนวนต้องเป็นตัวเลข 1–$_kMaxCopies', kind: NvToastKind.error);
      return;
    }
    if (!_sel.containsKey(p.code) && AppScope.read(context).productByCode(p.code) == null) return;
    _setQty(p, n);
  }

  void _scan(String raw) {
    final store = AppScope.read(context);
    final p = store.productByScan(raw);
    if (p == null) {
      if (raw.trim().isNotEmpty) nvToast(context, 'ไม่พบสินค้ารหัส "${raw.trim()}"', kind: NvToastKind.warning);
      return;
    }
    _search.clear();
    setState(() {
      _q = '';
      _sel[p.code] = ((_sel[p.code] ?? 0) + 1).clamp(1, _kMaxCopies);
    });
  }

  Future<void> _print(List<(Product, int)> picked) async {
    final store = AppScope.read(context);
    final bad = picked.where((e) => !canEncodeLabel(e.$1.scanCode)).toList();
    if (bad.isNotEmpty) {
      nvToast(context, 'บาร์โค้ดของ "${bad.first.$1.name}" มีตัวอักษรที่พิมพ์เป็นแท่งไม่ได้ — แก้ที่หน้าเมนู', kind: NvToastKind.error);
      return;
    }
    setState(() => _printing = true);
    var printed = 0;
    for (final (p, qty) in picked) {
      var left = qty;
      while (left > 0) {
        final n = left > _kJobCap ? _kJobCap : left;
        final res = await PrintService.printDoc(
          context,
          _doc(store, p),
          jobName: 'ฉลาก ${p.code}',
          medium: PrintMedium.label50x30,
          copies: n,
          printerName: store.printerName,
        );
        if (!mounted) return;
        if (!res.ok) {
          setState(() => _printing = false);
          nvToast(
            context,
            printed > 0 ? '${res.message} (พิมพ์ไปแล้ว ${groupDigits(printed)} ดวง)' : res.message,
            kind: NvToastKind.warning,
          );
          return;
        }
        left -= n;
        printed += n;
      }
    }
    setState(() => _printing = false);
    nvToast(context, 'ส่งพิมพ์ฉลาก ${groupDigits(printed)} ดวง (${picked.length} สินค้า) แล้ว', kind: NvToastKind.success);
  }

  Future<void> _share(Product p) async {
    final store = AppScope.read(context);
    if (!canEncodeLabel(p.scanCode)) {
      nvToast(context, 'บาร์โค้ดของ "${p.name}" พิมพ์เป็นแท่งไม่ได้ — แก้ที่หน้าเมนู', kind: NvToastKind.error);
      return;
    }
    setState(() => _printing = true);
    final res = await PrintService.shareDoc(context, _doc(store, p), fileName: 'label-${p.code}', medium: PrintMedium.label50x30);
    if (!mounted) return;
    setState(() => _printing = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final q = _q.trim().toLowerCase();
    final list =
        store.products
            .where(
              (p) =>
                  q.isEmpty || p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.barcode.toLowerCase().contains(q),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    // resolve the selection against the live catalog (deleted products drop out)
    final picked = <(Product, int)>[
      for (final e in _sel.entries)
        if (store.productByCode(e.key) case final p?) (p, e.value),
    ];

    return NvScaffold(
      title: 'บาร์โค้ดและฉลาก',
      eyebrow: 'สินค้าและสต็อก',
      subtitle: 'พิมพ์สติกเกอร์ราคาพร้อมบาร์โค้ดสำหรับติดสินค้า',
      art: 'barcode',
      actions: [
        if (store.isManager) NvButton.ghost('แก้บาร์โค้ดที่หน้าเมนู', icon: NvIcons.barcode, onPressed: () => context.go('/menu-editor')),
      ],
      body: store.products.isEmpty
          ? NvEmptyState(
              mascot: 'empty',
              title: 'ยังไม่มีสินค้าให้พิมพ์ฉลาก',
              message: 'เพิ่มสินค้าพร้อมบาร์โค้ดที่หน้า "เมนูและสินค้า" ก่อน',
              actionLabel: store.isManager ? 'ไปหน้าเมนูและสินค้า' : null,
              actionIcon: NvIcons.menuBook,
              onAction: store.isManager ? () => context.go('/menu-editor') : null,
            )
          : LayoutBuilder(
              builder: (context, c) {
                final picker = _picker(store, list);
                if (c.maxWidth >= 960) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: picker),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _settings(store, picked),
                            const SizedBox(height: 14),
                            Expanded(child: _grid(store, picked, shrink: false)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                // narrow / short screens: everything in one scroll (no fixed-height squeeze)
                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    SizedBox(height: 380, child: picker),
                    const SizedBox(height: 12),
                    _settings(store, picked),
                    const SizedBox(height: 14),
                    if (picked.isEmpty)
                      SizedBox(height: 300, child: _grid(store, picked, shrink: true))
                    else
                      _grid(store, picked, shrink: true),
                  ],
                );
              },
            ),
    );
  }

  Widget _picker(PosStore store, List<Product> list) {
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSearchField(
            hint: 'ค้นหาสินค้า หรือสแกนบาร์โค้ดเพื่อเพิ่ม',
            controller: _search,
            onChanged: (v) => setState(() => _q = v),
            onSubmitted: _scan,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'เลือกแล้ว ${_sel.length} สินค้า',
                style: Nv.ui(12.5, color: Nv.ink3, weight: FontWeight.w600),
              ),
              NvButton.soft(
                'เลือกทั้งหมดที่แสดง',
                icon: NvIcons.squareCheck,
                size: NvButtonSize.sm,
                onPressed: list.isEmpty
                    ? null
                    : () => setState(() {
                        for (final p in list) {
                          _sel.putIfAbsent(p.code, () => 1);
                        }
                      }),
              ),
              NvButton.ghost('ล้างการเลือก', size: NvButtonSize.sm, onPressed: _sel.isEmpty ? null : () => setState(_sel.clear)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? const NvEmptyState(mascot: 'search', title: 'ไม่พบสินค้า', size: 110)
                : ListView.builder(itemCount: list.length, itemBuilder: (context, i) => _pickRow(list[i])),
          ),
        ],
      ),
    );
  }

  Widget _pickRow(Product p) {
    final sel = _sel[p.code];
    final data = p.scanCode;
    final ok = canEncodeLabel(data);
    final sym = symbologyFor(data);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rSm),
        onTap: () => _toggle(p),
        child: AnimatedContainer(
          duration: Nv.fast,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.fromLTRB(2, 6, 6, 6),
          decoration: BoxDecoration(color: sel != null ? Nv.gold100 : Colors.transparent, borderRadius: BorderRadius.circular(Nv.rSm)),
          child: Row(
            children: [
              Checkbox(value: sel != null, onChanged: (_) => _toggle(p)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Nv.ui(14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          data,
                          style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500),
                        ),
                        NvBadge(
                          ok ? sym.label : 'พิมพ์เป็นแท่งไม่ได้',
                          tint: !ok ? NvTint.lacquer : (sym == LabelSymbology.ean13 ? NvTint.jade : NvTint.sapphire),
                          dot: false,
                        ),
                        if (p.barcode.isEmpty) Text('ใช้รหัสสินค้า', style: Nv.ui(11.5, color: Nv.ink4)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                baht(p.price),
                style: Nv.money(14, color: Nv.ink2, weight: FontWeight.w600),
              ),
              if (sel != null) ...[
                const SizedBox(width: 8),
                NvStepper(
                  value: sel,
                  onMinus: sel > 1 ? () => _setQty(p, sel - 1) : null,
                  onPlus: sel < _kMaxCopies ? () => _setQty(p, sel + 1) : null,
                ),
                const SizedBox(width: 4),
                NvIconButton(NvIcons.keyboard, size: 30, tooltip: 'พิมพ์จำนวน', onPressed: () => _typeQty(p)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _settings(PosStore store, List<(Product, int)> picked) {
    final total = picked.fold<int>(0, (s, e) => s + e.$2);
    Widget toggle(String label, bool v, ValueChanged<bool> f) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: v, onChanged: f),
        const SizedBox(width: 2),
        Text(
          label,
          style: Nv.ui(13.5, color: Nv.ink2, weight: FontWeight.w600),
        ),
      ],
    );
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const NvBadge('ฉลาก 50×30 มม.', tint: NvTint.navy, icon: NvIcons.tag),
              toggle('แสดงราคา', _showPrice, (v) => setState(() => _showPrice = v)),
              toggle('แสดงชื่อร้าน', _showShop, (v) => setState(() => _showShop = v)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            picked.isEmpty
                ? 'ยังไม่ได้เลือกสินค้า · บาร์โค้ดเลือกอัตโนมัติ: EAN-13 เมื่อเป็นเลข 13 หลักที่ถูกต้อง นอกนั้น Code 128'
                : '${picked.length} สินค้า · รวม ${groupDigits(total)} ดวง · ส่งไปที่ ${store.printerName.isEmpty ? 'หน้าต่างเลือกเครื่องพิมพ์' : store.printerName}',
            style: Nv.ui(12.5, color: Nv.ink3, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              NvButton.gold(
                picked.isEmpty ? 'พิมพ์ฉลาก' : 'พิมพ์ฉลาก ${groupDigits(total)} ดวง',
                icon: NvIcons.print,
                loading: _printing,
                onPressed: picked.isEmpty || _printing ? null : () => _print(picked),
              ),
              NvButton.soft(
                'แชร์ PDF',
                icon: NvIcons.share,
                tooltip: 'ฉลากของสินค้าแรกที่เลือก',
                onPressed: picked.isEmpty || _printing ? null : () => _share(picked.first.$1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grid(PosStore store, List<(Product, int)> picked, {required bool shrink}) {
    return picked.isEmpty
        ? const NvEmptyState(
            mascot: 'search',
            title: 'เลือกสินค้าที่จะพิมพ์ฉลาก',
            message: 'ติ๊กสินค้าแล้วกำหนดจำนวนดวงต่อสินค้า ตัวอย่างด้านนี้คือสิ่งที่พิมพ์ออกจริง',
            size: 140,
          )
        : GridView.builder(
            shrinkWrap: shrink,
            physics: shrink ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.only(bottom: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 5 / 3.7,
            ),
            itemCount: picked.length,
            itemBuilder: (context, i) {
              final (p, qty) = picked[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Nv.line),
                        boxShadow: Nv.shadowSheet,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FittedBox(fit: BoxFit.contain, child: _doc(store, p)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Nv.ui(12.5, weight: FontWeight.w600),
                        ),
                      ),
                      NvBadge('×$qty', tint: NvTint.gold, dot: false),
                    ],
                  ),
                ],
              );
            },
          );
  }
}

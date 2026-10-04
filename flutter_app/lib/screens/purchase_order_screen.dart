// Thaiprompt POS — Purchase orders & suppliers (/po) · Nova.
//
// Suppliers: real store.suppliers — add / edit (name*, category, phone,
// contact, note) / delete (confirm; old POs keep the supplier name).
// Purchase orders: status chips + search over store.purchaseOrders; cards show
// id, supplier, date, lines, total and a status badge. "สร้างใบสั่งซื้อ" opens a
// composer (supplier picker, product search / scan, qty stepper, unit cost
// defaulting to the product cost, note) → createPurchaseOrder (draft) or
// create + markPoOrdered. Detail actions follow the status:
//   draft    → ยืนยันสั่งซื้อ · ยกเลิก
//   ordered  → รับของเข้าสต็อก (preview stock before → after, cost changes) · ยกเลิก
//   received / cancelled → read-only
// Every PO prints / shares as an A4 document (po_doc.dart).
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/print/print_service.dart';
import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../print/po_doc.dart';
import '../print/receipt_doc.dart' show ShopInfo;
import '../print/stock_report_doc.dart' show A4Pages;
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

NvTint _poTint(PoStatus s) => switch (s) {
      PoStatus.draft => NvTint.neutral,
      PoStatus.ordered => NvTint.sapphire,
      PoStatus.received => NvTint.jade,
      PoStatus.cancelled => NvTint.lacquer,
    };

typedef _SupplierInput = ({String name, String category, String phone, String contact, String note});

class _PoDraft {
  final String supplierId;
  final List<PoLine> lines;
  final String note;
  final bool confirm; // create + mark ordered
  const _PoDraft(this.supplierId, this.lines, this.note, this.confirm);
}

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final TextEditingController _search = TextEditingController();
  String _q = '';
  PoStatus? _status;
  bool _showSuppliers = false; // narrow layout tab
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ───────────────────────── suppliers ─────────────────────────

  Future<Supplier?> _editSupplier(Supplier? s) async {
    final r = await showNvDialog<_SupplierInput>(
      context,
      title: s == null ? 'เพิ่มซัพพลายเออร์' : 'แก้ไขซัพพลายเออร์',
      art: 'po',
      maxWidth: 540,
      body: _SupplierForm(initial: s),
    );
    if (r == null || !mounted) return null;
    final store = AppScope.read(context);
    if (s == null) {
      final ns = store.addSupplier(name: r.name, category: r.category, phone: r.phone, contact: r.contact, note: r.note);
      nvToast(context, 'เพิ่มซัพพลายเออร์ "${ns.name}" แล้ว', kind: NvToastKind.success);
      return ns;
    }
    store.updateSupplier(s, name: r.name, category: r.category, phone: r.phone, contact: r.contact, note: r.note);
    nvToast(context, 'บันทึก "${s.name}" แล้ว', kind: NvToastKind.success);
    return s;
  }

  Future<void> _deleteSupplier(Supplier s) async {
    final store = AppScope.read(context);
    final all = store.purchaseOrders.where((p) => p.supplierId == s.id).toList();
    final open = all.where((p) => p.status == PoStatus.draft || p.status == PoStatus.ordered).length;
    final ok = await showNvConfirm(
      context,
      title: 'ลบซัพพลายเออร์ "${s.name}"?',
      message: [
        if (all.isEmpty) 'ยังไม่เคยมีใบสั่งซื้อกับผู้ขายรายนี้',
        if (all.isNotEmpty) 'ใบสั่งซื้อเดิม ${all.length} ใบยังอยู่ และยังเก็บชื่อผู้ขายไว้',
        if (open > 0) 'มี $open ใบที่ยังไม่ปิด — ยังรับของหรือยกเลิกได้ตามปกติ',
      ].join('\n'),
      confirmLabel: 'ลบซัพพลายเออร์',
    );
    if (!ok || !mounted) return;
    store.removeSupplier(s);
    nvToast(context, 'ลบซัพพลายเออร์ "${s.name}" แล้ว', kind: NvToastKind.success);
  }

  // ───────────────────────── purchase orders ─────────────────────────

  Future<void> _createPo([Supplier? preset]) async {
    var store = AppScope.read(context);
    if (store.products.isEmpty) {
      nvToast(context, 'ยังไม่มีสินค้า — เพิ่มที่หน้า "เมนูและสินค้า" ก่อน',
          kind: NvToastKind.error, actionLabel: 'ไปหน้าเมนู', onAction: () => context.go('/menu-editor'));
      return;
    }
    var supplier = preset;
    if (store.suppliers.isEmpty) {
      nvToast(context, 'เพิ่มซัพพลายเออร์ก่อนสร้างใบสั่งซื้อ', kind: NvToastKind.info);
      supplier = await _editSupplier(null);
      if (supplier == null || !mounted) return;
    }
    store = AppScope.read(context);
    final initial = supplier?.id ?? (store.suppliers.length == 1 ? store.suppliers.first.id : null);
    final draft = await showDialog<_PoDraft>(
      context: context,
      barrierDismissible: false,
      barrierColor: Nv.navy950.withValues(alpha: 0.55),
      builder: (_) => _PoComposer(initialSupplierId: initial),
    );
    if (draft == null || !mounted) return;
    store = AppScope.read(context);
    final sup = store.supplierById(draft.supplierId);
    if (sup == null) {
      nvToast(context, 'ไม่พบซัพพลายเออร์ที่เลือก (อาจถูกลบไปแล้ว)', kind: NvToastKind.error);
      return;
    }
    final po = store.createPurchaseOrder(sup, draft.lines, note: draft.note);
    if (draft.confirm) store.markPoOrdered(po);
    setState(() {
      _status = null;
      _showSuppliers = false;
    });
    nvToast(
      context,
      draft.confirm ? 'สร้างและยืนยัน ${po.id} แล้ว · ${baht(po.total)}' : 'บันทึกร่าง ${po.id} แล้ว · ${baht(po.total)}',
      kind: NvToastKind.success,
    );
  }

  Future<void> _openPo(PurchaseOrder po) async {
    final action = await showNvDialog<String>(
      context,
      title: 'ใบสั่งซื้อ ${po.id}',
      subtitle: '${po.supplierName} · ${thaiDate(po.createdAt)}',
      art: 'po',
      maxWidth: 700,
      body: _PoDetail(po: po),
      actions: (ctx) {
        void go(String a) => Navigator.of(ctx).pop(a);
        final open = po.status == PoStatus.draft || po.status == PoStatus.ordered;
        return [
          NvButton.soft('พิมพ์', icon: NvIcons.print, onPressed: _busy ? null : () => go('print')),
          NvButton.soft('แชร์ PDF', icon: NvIcons.share, onPressed: _busy ? null : () => go('share')),
          if (open) NvButton.ghost('ยกเลิกใบสั่งซื้อ', icon: NvIcons.xmark, onPressed: () => go('cancel')),
          if (po.status == PoStatus.draft) NvButton.gold('ยืนยันสั่งซื้อ', icon: NvIcons.check, onPressed: () => go('order')),
          if (po.status == PoStatus.ordered)
            NvButton.success('รับของเข้าสต็อก', icon: NvIcons.dolly, onPressed: () => go('receive')),
          if (!open) NvButton.gold('ปิด', onPressed: () => Navigator.of(ctx).pop()),
        ];
      },
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'print':
        await _printPo(po, share: false);
      case 'share':
        await _printPo(po, share: true);
      case 'order':
        _order(po);
      case 'cancel':
        await _cancel(po);
      case 'receive':
        await _receive(po);
    }
  }

  void _order(PurchaseOrder po) {
    if (po.status != PoStatus.draft) return;
    AppScope.read(context).markPoOrdered(po);
    nvToast(context, 'ยืนยันสั่งซื้อ ${po.id} แล้ว — เมื่อของมาส่ง กด "รับของเข้าสต็อก"', kind: NvToastKind.success);
  }

  Future<void> _cancel(PurchaseOrder po) async {
    final ok = await showNvConfirm(
      context,
      title: 'ยกเลิก ${po.id}?',
      message: 'ใบสั่งซื้อ ${po.supplierName} ยอด ${baht(po.total)} จะถูกยกเลิก และรับของเข้าสต็อกไม่ได้อีก',
      confirmLabel: 'ยกเลิกใบสั่งซื้อ',
      cancelLabel: 'ไม่ยกเลิก',
    );
    if (!ok || !mounted) return;
    if (po.status == PoStatus.received || po.status == PoStatus.cancelled) return;
    AppScope.read(context).cancelPurchaseOrder(po);
    nvToast(context, 'ยกเลิก ${po.id} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _receive(PurchaseOrder po) async {
    final ok = await showNvDialog<bool>(
      context,
      title: 'รับของเข้าสต็อก?',
      subtitle: '${po.id} · ${po.supplierName} · ${groupDigits(po.itemCount)} หน่วย',
      art: 'inventory',
      maxWidth: 640,
      body: _ReceivePreview(po: po),
      actions: (ctx) => [
        NvButton.soft('ยังไม่รับ', onPressed: () => Navigator.of(ctx).pop(false)),
        NvButton.success('ยืนยันรับของ', icon: NvIcons.check, onPressed: () => Navigator.of(ctx).pop(true)),
      ],
    );
    if (ok != true || !mounted) return;
    if (po.status != PoStatus.ordered) {
      nvToast(context, '${po.id} ถูกรับของหรือยกเลิกไปแล้ว', kind: NvToastKind.warning);
      return;
    }
    AppScope.read(context).receivePurchaseOrder(po);
    nvToast(context, 'รับของ ${po.id} เข้าสต็อกแล้ว (${groupDigits(po.itemCount)} หน่วย)', kind: NvToastKind.success);
  }

  Future<void> _printPo(PurchaseOrder po, {required bool share}) async {
    final store = AppScope.read(context);
    final pages = poDocPages(
      po: po,
      shop: ShopInfo.of(store),
      supplier: store.supplierById(po.supplierId),
      printedAt: DateTime.now(),
    );
    setState(() => _busy = true);
    // A4 → system dialog (the saved printer is the receipt roll)
    final Future<PrintResult> job =
        share ? A4Pages.sharePages(context, pages, fileName: po.id) : A4Pages.printPages(context, pages, jobName: 'ใบสั่งซื้อ ${po.id}');
    final res = await job;
    if (!mounted) return;
    setState(() => _busy = false);
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pos = store.purchaseOrders;
    final q = _q.trim().toLowerCase();
    final base = pos.where((p) => q.isEmpty || p.id.toLowerCase().contains(q) || p.supplierName.toLowerCase().contains(q)).toList();
    final shown = _status == null ? base : base.where((p) => p.status == _status).toList();
    final waiting = pos.where((p) => p.status == PoStatus.ordered).toList();
    final waitingValue = waiting.fold<int>(0, (s, p) => s + p.total);

    return NvScaffold(
      title: 'ใบสั่งซื้อ',
      eyebrow: 'จัดซื้อ',
      subtitle: 'รอรับของ ${waiting.length} ใบ · มูลค่า ${baht(waitingValue)} · ซัพพลายเออร์ ${store.suppliers.length} ราย',
      art: 'po',
      actions: [
        NvButton.ghost('เพิ่มซัพพลายเออร์', icon: NvIcons.userPlus, onPressed: () => _editSupplier(null)),
        NvButton.gold('สร้างใบสั่งซื้อ', icon: NvIcons.plus, onPressed: () => _createPo()),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 1080;
        final suppliers = _SuppliersPanel(
          store: store,
          onAdd: () => _editSupplier(null),
          onEdit: _editSupplier,
          onDelete: _deleteSupplier,
          onOrder: _createPo,
        );
        final orders = _ordersPanel(store, base, shown);
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 350, child: suppliers),
              const SizedBox(width: 20),
              Expanded(child: orders),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: NvSegmented<bool>(
                options: [(false, 'ใบสั่งซื้อ (${pos.length})'), (true, 'ซัพพลายเออร์ (${store.suppliers.length})')],
                value: _showSuppliers,
                onChanged: (v) => setState(() => _showSuppliers = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _showSuppliers ? suppliers : orders),
          ],
        );
      }),
    );
  }

  Widget _ordersPanel(PosStore store, List<PurchaseOrder> base, List<PurchaseOrder> shown) {
    int n(PoStatus s) => base.where((p) => p.status == s).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSectionTitle('ใบสั่งซื้อ', trailing: '${store.purchaseOrders.length} ใบ'),
        NvSearchField(hint: 'ค้นหาเลขที่ PO หรือชื่อซัพพลายเออร์', controller: _search, onChanged: (v) => setState(() => _q = v)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            NvChip('ทั้งหมด', selected: _status == null, count: base.length, onTap: () => setState(() => _status = null)),
            for (final s in PoStatus.values)
              NvChip(s.label, selected: _status == s, count: n(s), onTap: () => setState(() => _status = s)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: store.purchaseOrders.isEmpty
              ? NvEmptyState(
                  mascot: 'present',
                  title: 'ยังไม่มีใบสั่งซื้อ',
                  message: 'สร้างใบสั่งซื้อถึงซัพพลายเออร์ เมื่อของมาส่งกด "รับของเข้าสต็อก" ระบบจะเพิ่มสต็อกและอัปเดตต้นทุนให้',
                  actionLabel: 'สร้างใบสั่งซื้อ',
                  actionIcon: NvIcons.plus,
                  onAction: () => _createPo(),
                )
              : shown.isEmpty
                  ? const NvEmptyState(mascot: 'search', title: 'ไม่พบใบสั่งซื้อตามตัวกรอง', size: 130)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: shown.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PoCard(po: shown[i], onTap: () => _openPo(shown[i])),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ═════════════════════════════ suppliers ═════════════════════════════

class _SuppliersPanel extends StatelessWidget {
  final PosStore store;
  final VoidCallback onAdd;
  final ValueChanged<Supplier> onEdit;
  final ValueChanged<Supplier> onDelete;
  final ValueChanged<Supplier> onOrder;

  const _SuppliersPanel({
    required this.store,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final list = List.of(store.suppliers)..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvSectionTitle(
          'ซัพพลายเออร์',
          trailing: '${list.length} ราย',
          action: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: NvIconButton(NvIcons.userPlus, size: 34, tooltip: 'เพิ่มซัพพลายเออร์', onPressed: onAdd),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? NvEmptyState(
                  mascot: 'welcome',
                  title: 'ยังไม่มีซัพพลายเออร์',
                  message: 'เพิ่มผู้ขายที่ร้านสั่งของประจำ เพื่อออกใบสั่งซื้อและติดตามการรับของ',
                  actionLabel: 'เพิ่มซัพพลายเออร์',
                  actionIcon: NvIcons.userPlus,
                  onAction: onAdd,
                  size: 130,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final s = list[i];
                    final pos = store.purchaseOrders.where((p) => p.supplierId == s.id).toList();
                    final open = pos.where((p) => p.status == PoStatus.ordered).length;
                    final contact = [if (s.phone.isNotEmpty) phoneFmt(s.phone), if (s.contact.isNotEmpty) s.contact].join(' · ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NvSheet(
                        padding: const EdgeInsets.fromLTRB(12, 10, 2, 10),
                        radius: Nv.rMd,
                        onTap: () => onEdit(s),
                        child: Row(
                          children: [
                            NvAvatar(s.name.trim().isEmpty ? '?' : s.name.trim().characters.first, hue: stableHue(s.name), size: 42),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                      child: Text(s.name,
                                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14.5, weight: FontWeight.w700)),
                                    ),
                                    if (s.category.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      NvBadge(
                                        s.category.characters.length > 16 ? '${s.category.characters.take(16)}…' : s.category,
                                        tint: NvTint.gold,
                                        dot: false,
                                      ),
                                    ],
                                  ]),
                                  if (contact.isNotEmpty)
                                    Text(contact, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.ink2)),
                                  Text(
                                    'PO ${pos.length} ใบ${open > 0 ? ' · รอรับ $open' : ''} · สั่งล่าสุด ${s.lastOrder}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Nv.ui(12, color: Nv.ink3),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'จัดการ',
                              icon: const Icon(NvIcons.ellipsisV, size: 14, color: Nv.ink3),
                              onSelected: (v) {
                                switch (v) {
                                  case 'order':
                                    onOrder(s);
                                  case 'edit':
                                    onEdit(s);
                                  case 'delete':
                                    onDelete(s);
                                }
                              },
                              itemBuilder: (_) => [
                                _item('order', NvIcons.clipboardCheck, 'สร้างใบสั่งซื้อ'),
                                _item('edit', NvIcons.edit, 'แก้ไข'),
                                const PopupMenuDivider(),
                                _item('delete', NvIcons.trash, 'ลบ', danger: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static PopupMenuItem<String> _item(String v, IconData i, String t, {bool danger = false}) => PopupMenuItem<String>(
        value: v,
        child: Row(children: [
          Icon(i, size: 13, color: danger ? Nv.lacquer : Nv.goldInk),
          const SizedBox(width: 10),
          Text(t, style: Nv.ui(14, color: danger ? Nv.lacquer : Nv.ink)),
        ]),
      );
}

/// Supplier add / edit. Pops a [_SupplierInput].
class _SupplierForm extends StatefulWidget {
  final Supplier? initial;
  const _SupplierForm({this.initial});

  @override
  State<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<_SupplierForm> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _category = TextEditingController(text: widget.initial?.category ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final TextEditingController _contact = TextEditingController(text: widget.initial?.contact ?? '');
  late final TextEditingController _note = TextEditingController(text: widget.initial?.note ?? '');
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _category, _phone, _contact, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'กรุณาใส่ชื่อซัพพลายเออร์');
    final store = AppScope.read(context);
    final dup = store.suppliers.any((s) => s.id != widget.initial?.id && s.name.trim().toLowerCase() == name.toLowerCase());
    if (dup) return setState(() => _error = 'มีซัพพลายเออร์ชื่อ "$name" อยู่แล้ว');
    Navigator.of(context).pop<_SupplierInput>((
      name: name,
      category: _category.text.trim(),
      phone: _phone.text.trim(),
      contact: _contact.text.trim(),
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    final category = NvField(label: 'หมวดสินค้าที่ส่ง', controller: _category, icon: NvIcons.tags, hint: 'เช่น วัตถุดิบ · เครื่องดื่ม');
    final phone = NvField(
      label: 'เบอร์โทร',
      controller: _phone,
      icon: NvIcons.phone,
      keyboard: TextInputType.phone,
      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NvField(
          label: 'ชื่อซัพพลายเออร์ *',
          controller: _name,
          autofocus: true,
          icon: NvIcons.store,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 12),
        if (narrow) ...[category, const SizedBox(height: 12), phone] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: category), const SizedBox(width: 12), Expanded(child: phone)],
          ),
        const SizedBox(height: 12),
        NvField(label: 'ผู้ติดต่อ', controller: _contact, icon: NvIcons.user, hint: 'ชื่อพนักงานขาย / LINE ID'),
        const SizedBox(height: 12),
        NvField(label: 'หมายเหตุ', controller: _note, maxLines: 2, hint: 'เงื่อนไขการส่ง · เครดิต · วันตัดรอบ'),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
            NvButton.gold('บันทึก', icon: NvIcons.check, onPressed: _submit),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════ PO cards & detail ═════════════════════════════

class _PoCard extends StatelessWidget {
  final PurchaseOrder po;
  final VoidCallback onTap;
  const _PoCard({required this.po, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = [
      thaiDate(po.createdAt),
      '${po.lines.length} รายการ',
      '${groupDigits(po.itemCount)} หน่วย',
      if (po.receivedAt != null) 'รับ ${thaiDate(po.receivedAt!)}',
    ].join(' · ');
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      radius: Nv.rMd,
      onTap: onTap,
      child: Row(
        children: [
          NvArt.icon('po', size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(po.id, style: Nv.money(15)),
                    NvBadge(po.status.label, tint: _poTint(po.status)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(po.supplierName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              NvMoney(po.total, size: 18),
              Text('ยอดรวม', style: Nv.ui(11.5, color: Nv.ink4)),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(NvIcons.angleRight, size: 13, color: Nv.ink4),
        ],
      ),
    );
  }
}

class _PoDetail extends StatelessWidget {
  final PurchaseOrder po;
  const _PoDetail({required this.po});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    Text h(String t, {TextAlign a = TextAlign.left}) => Text(t, textAlign: a, style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w700));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            NvBadge(po.status.label, tint: _poTint(po.status)),
            if (po.createdBy.isNotEmpty) NvBadge('สร้างโดย ${po.createdBy}', tint: NvTint.neutral, icon: NvIcons.user),
            if (po.receivedAt != null) NvBadge('รับของ ${thaiDateTime(po.receivedAt!)}', tint: NvTint.jade, icon: NvIcons.dolly),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Nv.ivoryDeep.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(Nv.rXs)),
          child: Row(children: [
            Expanded(child: h('รายการ')),
            SizedBox(width: 56, child: h('จำนวน', a: TextAlign.right)),
            SizedBox(width: 88, child: h('ราคา/หน่วย', a: TextAlign.right)),
            SizedBox(width: 96, child: h('รวม', a: TextAlign.right)),
          ]),
        ),
        for (final l in po.lines)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                      Text(
                        () {
                          final p = store.productByCode(l.code);
                          if (p == null) return '${l.code} · ไม่พบสินค้าในระบบแล้ว';
                          return p.trackStock ? '${l.code} · คงเหลือตอนนี้ ${groupDigits(p.stock)}' : '${l.code} · ไม่ติดตามสต็อก';
                        }(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Nv.ui(12, color: Nv.ink3),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 56, child: Text(groupDigits(l.qty), textAlign: TextAlign.right, style: Nv.money(14))),
                SizedBox(
                  width: 88,
                  child: Text(l.unitCost > 0 ? baht(l.unitCost) : '—',
                      textAlign: TextAlign.right, style: Nv.money(13.5, color: Nv.ink2, weight: FontWeight.w600)),
                ),
                SizedBox(width: 96, child: Text(baht(l.total), textAlign: TextAlign.right, style: Nv.money(14))),
              ],
            ),
          ),
        const SizedBox(height: 8),
        NvKeyValue('รวม ${po.lines.length} รายการ · ${groupDigits(po.itemCount)} หน่วย', baht(po.total), strong: true),
        if (po.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          NvSheet(
            padding: const EdgeInsets.all(12),
            radius: Nv.rSm,
            color: Nv.paper,
            child: Text('หมายเหตุ: ${po.note}', style: Nv.ui(13.5, color: Nv.ink2)),
          ),
        ],
      ],
    );
  }
}

/// Receive confirmation: each line's stock before → after and cost changes.
class _ReceivePreview extends StatelessWidget {
  final PurchaseOrder po;
  const _ReceivePreview({required this.po});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final running = <String, int>{};
    final rows = <Widget>[];
    for (final l in po.lines) {
      final p = store.productByCode(l.code);
      String change;
      Color color;
      if (p == null) {
        change = 'ไม่พบสินค้าแล้ว — ข้าม';
        color = Nv.lacquer;
      } else if (!p.trackStock) {
        change = 'ไม่ติดตามสต็อก — ไม่เปลี่ยนยอด';
        color = Nv.ink3;
      } else {
        final before = running[l.code] ?? p.stock;
        final after = before + l.qty;
        running[l.code] = after;
        change = '${groupDigits(before)} → ${groupDigits(after)}';
        color = nvTint(NvTint.jade).fg;
      }
      final costNote = (p != null && l.unitCost > 0 && l.unitCost != p.cost) ? 'ทุน ${baht(p.cost)} → ${baht(l.unitCost)}' : null;
      rows.add(Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                  Text(costNote ?? l.code, style: Nv.ui(12, color: costNote != null ? Nv.goldInk : Nv.ink3)),
                ],
              ),
            ),
            SizedBox(width: 64, child: Text('+${groupDigits(l.qty)}', textAlign: TextAlign.right, style: Nv.money(14, color: nvTint(NvTint.jade).fg))),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: Text(change, textAlign: TextAlign.right, style: Nv.money(13.5, color: color, weight: FontWeight.w600)),
            ),
          ],
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('สต็อกจะเพิ่มตามรายการด้านล่าง (บันทึกในสมุดสต็อกอ้างอิง ${po.id}) และต้นทุนต่อหน่วยจะอัปเดตตามราคาในใบสั่งซื้อ',
            textAlign: TextAlign.center, style: Nv.ui(13.5, color: Nv.ink2, height: 1.45)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Text('สินค้า', style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w700))),
          SizedBox(width: 64, child: Text('รับเข้า', textAlign: TextAlign.right, style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w700))),
          const SizedBox(width: 12),
          SizedBox(width: 150, child: Text('สต็อก ก่อน → หลัง', textAlign: TextAlign.right, style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w700))),
        ]),
        ...rows,
      ],
    );
  }
}

// ═════════════════════════════ PO composer ═════════════════════════════

class _LineDraft {
  final String code;
  final String name;
  final TextEditingController qty;
  final TextEditingController cost;
  _LineDraft(this.code, this.name, int q, int c)
      : qty = TextEditingController(text: '$q'),
        cost = TextEditingController(text: c > 0 ? '$c' : '');
  int get qtyValue => int.tryParse(qty.text.trim()) ?? 0;
  int get costValue => int.tryParse(cost.text.trim()) ?? 0;
  void dispose() {
    qty.dispose();
    cost.dispose();
  }
}

class _PoComposer extends StatefulWidget {
  final String? initialSupplierId;
  const _PoComposer({this.initialSupplierId});

  @override
  State<_PoComposer> createState() => _PoComposerState();
}

class _PoComposerState extends State<_PoComposer> {
  late String? _supplierId = widget.initialSupplierId;
  final TextEditingController _search = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String _q = '';
  final List<_LineDraft> _lines = <_LineDraft>[];
  final List<_LineDraft> _trash = <_LineDraft>[];
  String? _error;
  bool _dirty = false;

  @override
  void dispose() {
    _search.dispose();
    _note.dispose();
    for (final l in [..._lines, ..._trash]) {
      l.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() {
        _dirty = true;
        _error = null;
      });

  void _add(Product p) {
    final i = _lines.indexWhere((l) => l.code == p.code);
    setState(() {
      if (i >= 0) {
        _lines[i].qty.text = '${_lines[i].qtyValue + 1}';
      } else {
        _lines.add(_LineDraft(p.code, p.name, 1, p.cost));
      }
      _dirty = true;
      _error = null;
    });
  }

  void _step(_LineDraft l, int d) {
    final v = (l.qtyValue + d).clamp(1, 99999);
    l.qty.text = '$v';
    _changed();
  }

  void _remove(int i) => setState(() {
        _trash.add(_lines.removeAt(i));
        _dirty = true;
      });

  Future<void> _close() async {
    if (_dirty) {
      final ok = await showNvConfirm(context,
          title: 'ทิ้งใบสั่งซื้อนี้?', message: 'รายการที่เลือกไว้จะไม่ถูกบันทึก', confirmLabel: 'ทิ้ง');
      if (!ok || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  void _submit(bool confirm) {
    final store = AppScope.read(context);
    final sid = _supplierId;
    if (sid == null || store.supplierById(sid) == null) return setState(() => _error = 'เลือกซัพพลายเออร์ก่อน');
    if (_lines.isEmpty) return setState(() => _error = 'เพิ่มสินค้าอย่างน้อย 1 รายการ');
    final out = <PoLine>[];
    for (final l in _lines) {
      final q = l.qtyValue;
      if (q <= 0) return setState(() => _error = 'จำนวนของ "${l.name}" ต้องมากกว่า 0');
      final raw = l.cost.text.trim();
      final c = raw.isEmpty ? 0 : int.tryParse(raw);
      if (c == null) return setState(() => _error = 'ราคาต่อหน่วยของ "${l.name}" ไม่ถูกต้อง');
      out.add(PoLine(code: l.code, name: l.name, qty: q, unitCost: c));
    }
    Navigator.of(context).pop(_PoDraft(sid, out, _note.text.trim(), confirm));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 820;
    final total = _lines.fold<int>(0, (s, l) => s + l.qtyValue * l.costValue);
    final noCost = _lines.where((l) => l.costValue <= 0).length;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        insetPadding: narrow ? const EdgeInsets.all(10) : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 1060,
          height: size.height - (narrow ? 20 : 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                child: Row(
                  children: [
                    NvArt.icon('po', size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('สร้างใบสั่งซื้อ', style: Nv.display(21)),
                          Text('เลือกซัพพลายเออร์ แล้วแตะสินค้าเพื่อเพิ่มรายการ', style: Nv.ui(13, color: Nv.ink3)),
                        ],
                      ),
                    ),
                    NvIconButton(NvIcons.xmark, tooltip: 'ปิด', onPressed: _close),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: narrow
                    // phones: one scroll for picker + lines so the soft keyboard never overflows
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 240, child: _picker(store)),
                            const Divider(),
                            _linesPane(store, narrow),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 360, child: _picker(store)),
                          const VerticalDivider(width: 1),
                          Expanded(child: _linesPane(store, narrow)),
                        ],
                      ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    if (_error != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(NvIcons.warning, size: 14, color: Nv.lacquer),
                          const SizedBox(width: 8),
                          Text(_error!, style: Nv.ui(13, color: Nv.lacquer, weight: FontWeight.w600)),
                        ],
                      )
                    else if (noCost > 0)
                      Text('ยังไม่ระบุราคา $noCost รายการ', style: Nv.ui(12.5, color: nvTint(NvTint.amber).fg, weight: FontWeight.w600)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('รวม ', style: Nv.ui(14, color: Nv.ink3)),
                        Text(baht(total), style: Nv.money(22)),
                      ],
                    ),
                    NvButton.soft('ยกเลิก', onPressed: _close),
                    NvButton.navy('บันทึกร่าง', icon: NvIcons.floppy, onPressed: () => _submit(false)),
                    NvButton.gold('สร้างและยืนยันสั่งซื้อ', icon: NvIcons.check, onPressed: () => _submit(true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _picker(PosStore store) {
    final q = _q.trim().toLowerCase();
    var items = store.products
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.code.toLowerCase().contains(q) || p.barcode.contains(q))
        .toList()
      ..sort((a, b) {
        final la = a.trackStock && a.stock <= 5;
        final lb = b.trackStock && b.stock <= 5;
        if (la != lb) return la ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    final total = items.length;
    if (items.length > 80) items = items.sublist(0, 80);
    final inLines = {for (final l in _lines) l.code: l.qtyValue};

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvSearchField(
            hint: 'ค้นหาสินค้า หรือสแกนบาร์โค้ด',
            controller: _search,
            onChanged: (v) => setState(() => _q = v),
            onSubmitted: (v) {
              final p = store.productByScan(v);
              if (p == null) return;
              _add(p);
              _search.clear();
              setState(() => _q = '');
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
            child: Text(
              q.isEmpty ? 'สินค้าใกล้หมดแสดงก่อน · ${groupDigits(total)} รายการ' : 'พบ ${groupDigits(total)} รายการ${total > items.length ? ' (แสดง ${items.length})' : ''}',
              style: Nv.ui(11.5, color: Nv.ink3),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('ไม่พบสินค้า', style: Nv.ui(13, color: Nv.ink3)))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final added = inLines[p.code];
                      final low = p.trackStock && p.stock <= 5;
                      return InkWell(
                        borderRadius: BorderRadius.circular(Nv.rSm),
                        onTap: () => _add(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
                                    Text(
                                      '${p.code} · ${p.trackStock ? 'คงเหลือ ${groupDigits(p.stock)}' : 'ไม่ติดตามสต็อก'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Nv.ui(12, color: low ? nvTint(NvTint.amber).fg : Nv.ink3, weight: low ? FontWeight.w600 : FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                              Text(p.cost > 0 ? baht(p.cost) : '—', style: Nv.money(13, color: Nv.ink2, weight: FontWeight.w600)),
                              const SizedBox(width: 10),
                              added != null
                                  ? NvBadge('×$added', tint: NvTint.jade, dot: false)
                                  : const Icon(NvIcons.plusCircle, size: 18, color: Nv.goldInk),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _linesPane(PosStore store, bool narrow) {
    final validSupplier = _supplierId != null && store.supplierById(_supplierId!) != null;
    final empty = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NvArt.icon('po', size: 72, opacity: 0.6),
        const SizedBox(height: 8),
        Text(narrow ? 'แตะสินค้าด้านบนเพื่อเพิ่มรายการ' : 'แตะสินค้าทางซ้ายเพื่อเพิ่มรายการ', style: Nv.ui(13.5, color: Nv.ink3)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('ซัพพลายเออร์ *', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Nv.paper,
              borderRadius: BorderRadius.circular(Nv.rSm),
              border: Border.all(color: validSupplier ? Nv.line : Nv.gold500),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: validSupplier ? _supplierId : null,
                hint: Text('เลือกซัพพลายเออร์', style: Nv.ui(14.5, color: Nv.ink4)),
                isExpanded: true,
                icon: const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
                style: Nv.ui(14.5),
                dropdownColor: Nv.ivory2,
                borderRadius: BorderRadius.circular(Nv.rMd),
                items: [
                  for (final s in store.suppliers)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.category.isEmpty ? s.name : '${s.name} · ${s.category}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _supplierId = v;
                  _dirty = true;
                  _error = null;
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('รายการสั่งซื้อ (${_lines.length})', style: Nv.ui(13.5, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (_lines.isEmpty)
            narrow ? Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: empty) : Expanded(child: Center(child: empty))
          else if (narrow)
            Column(children: [for (var i = 0; i < _lines.length; i++) _lineRow(store, i, narrow)])
          else
            Expanded(
              child: ListView.builder(
                itemCount: _lines.length,
                itemBuilder: (context, i) => _lineRow(store, i, narrow),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            onChanged: (_) => _dirty ? null : setState(() => _dirty = true),
            decoration: const InputDecoration(hintText: 'หมายเหตุถึงซัพพลายเออร์ (ไม่บังคับ)', prefixIcon: Icon(NvIcons.note, size: 14)),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(PosStore store, int i, bool narrow) {
    final l = _lines[i];
    final p = store.productByCode(l.code);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(14, weight: FontWeight.w600)),
        Text(
          '${l.code} · ${p == null ? 'ไม่พบสินค้าแล้ว' : (p.trackStock ? 'คงเหลือ ${groupDigits(p.stock)}' : 'ไม่ติดตามสต็อก')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Nv.ui(12, color: p == null ? Nv.lacquer : Nv.ink3),
        ),
      ],
    );
    final qty = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NvIconButton(NvIcons.minus, size: 32, tooltip: 'ลด', onPressed: l.qtyValue > 1 ? () => _step(l, -1) : null),
        SizedBox(
          width: 62,
          child: TextField(
            controller: l.qty,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
            style: Nv.money(15),
            onChanged: (_) => _changed(),
          ),
        ),
        NvIconButton(NvIcons.plus, size: 32, tooltip: 'เพิ่ม', onPressed: () => _step(l, 1)),
      ],
    );
    final cost = SizedBox(
      width: 112,
      child: TextField(
        controller: l.cost,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
        style: Nv.money(14, weight: FontWeight.w600),
        decoration: const InputDecoration(prefixText: '฿ ', hintText: 'ราคา/หน่วย'),
        onChanged: (_) => _changed(),
      ),
    );
    final lineTotal = SizedBox(
      width: 96,
      child: Text(baht(l.qtyValue * l.costValue), textAlign: TextAlign.right, style: Nv.money(15)),
    );
    final remove = NvIconButton(NvIcons.trash, size: 32, tooltip: 'ลบรายการ', color: Nv.lacquer, onPressed: () => _remove(i));

    return Container(
      key: ObjectKey(l),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Nv.lineSoft))),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [Expanded(child: info), remove]),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [qty, cost, lineTotal],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 8),
                qty,
                const SizedBox(width: 10),
                cost,
                const SizedBox(width: 10),
                lineTotal,
                const SizedBox(width: 6),
                remove,
              ],
            ),
    );
  }
}

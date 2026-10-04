// Thaiprompt POS — คูปอง · /coupons
//
// Real coupon book (store.couponDefs): status (ใช้งาน / ยังไม่เริ่ม / ปิด /
// หมดอายุ / ใช้ครบ), code with copy-to-clipboard, discount summary, minimum
// spend, usage counter and validity dates. Create / edit (code A–Z0–9 unique,
// baht or percent, cap, dates, usage limit) → upsertCoupon; on/off switch →
// setCouponActive; delete with confirmation; "ใช้กับบิลปัจจุบัน" →
// tryApplyCoupon on the live cart with the store's own Thai reason on failure.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

enum _CStatus { active, upcoming, off, expired, usedUp }

extension on _CStatus {
  String get label => switch (this) {
        _CStatus.active => 'ใช้งาน',
        _CStatus.upcoming => 'ยังไม่เริ่ม',
        _CStatus.off => 'ปิด',
        _CStatus.expired => 'หมดอายุ',
        _CStatus.usedUp => 'ใช้ครบ',
      };
  NvTint get tint => switch (this) {
        _CStatus.active => NvTint.jade,
        _CStatus.upcoming => NvTint.sapphire,
        _CStatus.off => NvTint.neutral,
        _CStatus.expired => NvTint.lacquer,
        _CStatus.usedUp => NvTint.amber,
      };
}

_CStatus _statusOf(CouponDef d, DateTime now) {
  if (!d.active) return _CStatus.off;
  if (d.endsAt != null && now.isAfter(d.endsAt!)) return _CStatus.expired;
  if (d.usageLimit > 0 && d.usedCount >= d.usageLimit) return _CStatus.usedUp;
  if (d.startsAt != null && now.isBefore(d.startsAt!)) return _CStatus.upcoming;
  return _CStatus.active;
}

String _discountText(CouponDef d) {
  final base = d.kind == DiscountKind.amount ? 'ลด ${baht(d.value)}' : 'ลด ${d.value}%';
  if (d.kind == DiscountKind.percent && d.maxDiscount > 0) return '$base (สูงสุด ${baht(d.maxDiscount)})';
  return base;
}

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  _CStatus? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    final all = store.couponDefs;
    final q = _query.trim().toLowerCase();
    final list = all.where((d) {
      if (_filter != null && _statusOf(d, now) != _filter) return false;
      if (q.isEmpty) return true;
      return d.code.toLowerCase().contains(q) || d.name.toLowerCase().contains(q);
    }).toList();
    final compact = MediaQuery.sizeOf(context).width < 760;

    return NvScaffold(
      title: 'คูปอง',
      eyebrow: 'COUPONS',
      subtitle: 'รหัสส่วนลดที่ลูกค้านำมาใช้ที่หน้าขาย',
      art: 'coupon',
      actions: [
        if (!compact) NvButton.ghost('โปรโมชั่นอัตโนมัติ', icon: NvIcons.tags, onPressed: () => context.go('/discount-center')),
        NvButton.gold(compact ? '' : 'สร้างคูปอง', icon: NvIcons.plus, tooltip: 'สร้างคูปอง', onPressed: () => _editCoupon(context, null)),
      ],
      body: all.isEmpty
          ? NvEmptyState(
              mascot: 'gift',
              title: 'ยังไม่มีคูปอง',
              message: 'สร้างรหัสส่วนลด เช่น WELCOME50 ลด ฿50 หรือ VIP10 ลด 10% แล้วให้แคชเชียร์กรอกรหัสที่หน้าขาย',
              actionLabel: 'สร้างคูปองแรก',
              actionIcon: NvIcons.plus,
              onAction: () => _editCoupon(context, null),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _CartBar(store: store),
                const SizedBox(height: 14),
                LayoutBuilder(builder: (context, c) {
                  final search = NvSearchField(hint: 'ค้นหารหัสหรือชื่อคูปอง', onChanged: (v) => setState(() => _query = v));
                  return c.maxWidth < 620
                      ? search
                      : Row(children: [SizedBox(width: (c.maxWidth * 0.42).clamp(280.0, 460.0), child: search), const Spacer()]);
                }),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      NvChip('ทั้งหมด', selected: _filter == null, count: all.length, onTap: () => setState(() => _filter = null)),
                      for (final s in _CStatus.values) ...[
                        const SizedBox(width: 8),
                        NvChip(
                          s.label,
                          selected: _filter == s,
                          count: all.where((d) => _statusOf(d, now) == s).length,
                          onTap: () => setState(() => _filter = _filter == s ? null : s),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: NvEmptyState(mascot: 'search', size: 120, title: 'ไม่พบคูปองตามเงื่อนไข', message: 'ลองล้างคำค้นหาหรือเลือก "ทั้งหมด"'),
                  )
                else
                  LayoutBuilder(builder: (context, c) {
                    final cols = c.maxWidth > 1320 ? 3 : (c.maxWidth > 820 ? 2 : 1);
                    final w = (c.maxWidth - (cols - 1) * 14) / cols;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (final d in list)
                          SizedBox(
                            width: w,
                            child: _CouponCard(
                              def: d,
                              status: _statusOf(d, now),
                              applied: store.appliedCouponCode == d.code,
                              cartEmpty: store.cart.isEmpty,
                            ),
                          ),
                      ],
                    );
                  }),
              ],
            ),
    );
  }
}

// ───────────────────────────── live cart bar ─────────────────────────────

class _CartBar extends StatelessWidget {
  final PosStore store;
  const _CartBar({required this.store});

  @override
  Widget build(BuildContext context) {
    final code = store.appliedCouponCode;
    if (store.cart.isEmpty) {
      return NvSheet(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(NvIcons.cart, size: 15, color: Nv.ink3),
            const SizedBox(width: 10),
            Expanded(
              child: Text('ตะกร้าที่หน้าขายยังว่าง — ปุ่ม "ใช้กับบิลปัจจุบัน" จะกดได้เมื่อมีสินค้าในตะกร้า',
                  style: Nv.ui(13, color: Nv.ink3)),
            ),
          ],
        ),
      );
    }
    final ok = code != null && store.couponDiscount > 0;
    return NvNightCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(NvIcons.cart, size: 15, color: Nv.gold300),
              const SizedBox(width: 10),
              Text('บิลปัจจุบัน ${store.cartItemCount} ชิ้น · ', style: Nv.ui(13.5, color: Nv.onNight2)),
              Text(baht(store.cartSubtotal), style: Nv.money(15, color: Nv.gold200)),
            ],
          ),
          if (code == null)
            Text('ยังไม่ได้ใช้คูปอง', style: Nv.ui(13, color: Nv.onNight3))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                NvBadge(ok ? 'คูปอง $code · -${baht(store.couponDiscount)}' : 'คูปอง $code ใช้ไม่ได้กับยอดนี้',
                    tint: ok ? NvTint.jade : NvTint.amber, icon: NvIcons.coupon),
                NvButton.ghost('เอาออก', icon: NvIcons.xmark, size: NvButtonSize.sm, onNight: true, onPressed: () {
                  AppScope.read(context).removeCoupon();
                  nvToast(context, 'นำคูปอง $code ออกจากบิลแล้ว');
                }),
              ],
            ),
          NvButton.ghost('ไปหน้าขาย', icon: NvIcons.cashier, size: NvButtonSize.sm, onNight: true, onPressed: () => context.go('/cashier')),
        ],
      ),
    );
  }
}

// ───────────────────────────── coupon card ─────────────────────────────

class _CouponCard extends StatelessWidget {
  final CouponDef def;
  final _CStatus status;
  final bool applied;
  final bool cartEmpty;
  const _CouponCard({required this.def, required this.status, required this.applied, required this.cartEmpty});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: def.code));
    if (!context.mounted) return;
    nvToast(context, 'คัดลอกรหัส ${def.code} แล้ว', kind: NvToastKind.success);
  }

  void _apply(BuildContext context) {
    final store = AppScope.read(context);
    if (store.cart.isEmpty) {
      nvToast(context, 'ตะกร้าว่าง — เพิ่มสินค้าที่หน้าขายก่อน', kind: NvToastKind.warning);
      return;
    }
    final err = store.tryApplyCoupon(def.code);
    if (err != null) {
      nvToast(context, err, kind: NvToastKind.error);
      return;
    }
    final router = GoRouter.of(context);
    nvToast(context, 'ใช้คูปอง ${def.code} กับบิลปัจจุบันแล้ว · ลด ${baht(store.couponDiscount)}',
        kind: NvToastKind.success, actionLabel: 'ไปหน้าขาย', onAction: () => router.go('/cashier'));
  }

  @override
  Widget build(BuildContext context) {
    final d = def;
    final dim = status != _CStatus.active && status != _CStatus.upcoming;
    String dates;
    if (d.startsAt == null && d.endsAt == null) {
      dates = 'ไม่กำหนดวันหมดอายุ';
    } else if (d.startsAt != null && d.endsAt != null) {
      dates = '${thaiDate(d.startsAt!)} – ${thaiDate(d.endsAt!)}';
    } else if (d.startsAt != null) {
      dates = 'เริ่ม ${thaiDate(d.startsAt!)}';
    } else {
      dates = 'ถึง ${thaiDate(d.endsAt!)}';
    }

    Widget meta(IconData i, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 11.5, color: Nv.goldInk),
            const SizedBox(width: 6),
            Flexible(child: Text(t, style: Nv.ui(12.5, color: Nv.ink2))),
          ],
        );

    return NvSheet(
      padding: EdgeInsets.zero,
      selected: applied,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 124,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                gradient: dim ? null : Nv.night,
                color: dim ? Nv.ivoryDeep : null,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(Nv.rLg)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(NvIcons.coupon, size: 20, color: dim ? Nv.ink3 : Nv.gold300),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(d.code, style: Nv.money(17, color: dim ? Nv.ink2 : Nv.gold200)),
                  ),
                  const SizedBox(height: 8),
                  NvButton.ghost('คัดลอก', icon: NvIcons.copy, size: NvButtonSize.sm, onNight: !dim, onPressed: () => _copy(context)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(d.name.isEmpty ? d.code : d.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15, weight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        if (applied) ...[const NvBadge('อยู่ในบิล', tint: NvTint.gold), const SizedBox(width: 6)],
                        NvBadge(status.label, tint: status.tint),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_discountText(d), style: Nv.display(18, color: dim ? Nv.ink3 : Nv.goldInk)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        meta(NvIcons.receipt, d.minSpend > 0 ? 'ขั้นต่ำ ${baht(d.minSpend)}' : 'ไม่มียอดขั้นต่ำ'),
                        meta(NvIcons.calendar, dates),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                          d.usageLimit > 0
                              ? 'ใช้แล้ว ${groupDigits(d.usedCount)}/${groupDigits(d.usageLimit)} ครั้ง'
                              : 'ใช้แล้ว ${groupDigits(d.usedCount)} ครั้ง · ไม่จำกัดจำนวน',
                          style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w600),
                        ),
                        ),
                        if (d.usageLimit > 0) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (d.usedCount / d.usageLimit).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Nv.ivoryDeep,
                                color: status == _CStatus.usedUp ? Nv.amber : Nv.gold500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Tooltip(
                          message: d.active ? 'ปิดการใช้คูปองนี้' : 'เปิดการใช้คูปองนี้',
                          child: Switch(
                            value: d.active,
                            onChanged: (v) {
                              AppScope.read(context).setCouponActive(d, v);
                              nvToast(context, v ? 'เปิดใช้คูปอง ${d.code} แล้ว' : 'ปิดคูปอง ${d.code} แล้ว');
                            },
                          ),
                        ),
                        Text(d.active ? 'เปิด' : 'ปิด', style: Nv.ui(12.5, color: Nv.ink3)),
                        NvButton.gold(
                          'ใช้กับบิล',
                          icon: NvIcons.cashier,
                          size: NvButtonSize.sm,
                          tooltip: cartEmpty ? 'ตะกร้าว่าง' : 'ใช้คูปองนี้กับบิลที่หน้าขาย',
                          onPressed: cartEmpty || dim ? null : () => _apply(context),
                        ),
                        NvIconButton(NvIcons.edit, size: 36, tooltip: 'แก้ไข', onPressed: () => _editCoupon(context, d)),
                        NvIconButton(NvIcons.trash, size: 36, tooltip: 'ลบ', color: Nv.lacquer, onPressed: () => _deleteCoupon(context, d)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── actions ─────────────────────────────

Future<void> _editCoupon(BuildContext context, CouponDef? edit) async {
  final key = GlobalKey<_CouponFormState>();
  final res = await showNvDialog<CouponDef>(
    context,
    title: edit == null ? 'สร้างคูปอง' : 'แก้ไขคูปอง ${edit.code}',
    art: 'coupon',
    maxWidth: 560,
    body: _CouponForm(key: key, edit: edit),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold('บันทึก', icon: NvIcons.floppy, onPressed: () => key.currentState?._save()),
    ],
  );
  if (res == null || !context.mounted) return;
  final store = AppScope.read(context);
  if (edit == null && store.couponByCode(res.code) != null) {
    nvToast(context, 'มีคูปองรหัส ${res.code} แล้ว', kind: NvToastKind.error);
    return;
  }
  store.upsertCoupon(res);
  nvToast(context, edit == null ? 'สร้างคูปอง ${res.code} แล้ว' : 'บันทึกคูปอง ${res.code} แล้ว', kind: NvToastKind.success);
}

Future<void> _deleteCoupon(BuildContext context, CouponDef d) async {
  final ok = await showNvConfirm(
    context,
    title: 'ลบคูปอง ${d.code}?',
    message: d.usedCount > 0
        ? 'คูปองนี้ถูกใช้ไปแล้ว ${d.usedCount} ครั้ง — บิลเดิมยังแสดงรหัสเดิม แต่จะใช้รหัสนี้ไม่ได้อีก'
        : 'ลูกค้าจะใช้รหัสนี้ไม่ได้อีก',
    confirmLabel: 'ลบคูปอง',
  );
  if (!ok || !context.mounted) return;
  AppScope.read(context).deleteCoupon(d);
  nvToast(context, 'ลบคูปอง ${d.code} แล้ว', kind: NvToastKind.success);
}

// ───────────────────────────── form ─────────────────────────────

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

class _CouponForm extends StatefulWidget {
  final CouponDef? edit;
  const _CouponForm({super.key, this.edit});

  @override
  State<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<_CouponForm> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.edit?.code ?? '');
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _value = TextEditingController(text: widget.edit?.value.toString() ?? '');
  late final _min = TextEditingController(text: (widget.edit?.minSpend ?? 0) > 0 ? widget.edit!.minSpend.toString() : '');
  late final _max = TextEditingController(text: (widget.edit?.maxDiscount ?? 0) > 0 ? widget.edit!.maxDiscount.toString() : '');
  late final _limit = TextEditingController(text: (widget.edit?.usageLimit ?? 0) > 0 ? widget.edit!.usageLimit.toString() : '');
  late DiscountKind _kind = widget.edit?.kind ?? DiscountKind.amount;
  late DateTime? _start = widget.edit?.startsAt;
  late DateTime? _end = widget.edit?.endsAt;
  String? _dateError;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _value.dispose();
    _min.dispose();
    _max.dispose();
    _limit.dispose();
    super.dispose();
  }

  int _n(TextEditingController c) => int.tryParse(c.text) ?? 0;

  CouponDef _build() => CouponDef(
        code: _code.text.trim().toUpperCase(),
        name: _name.text.trim(),
        kind: _kind,
        value: _n(_value),
        minSpend: _n(_min),
        maxDiscount: _kind == DiscountKind.percent ? _n(_max) : 0,
        active: widget.edit?.active ?? true,
        startsAt: _start == null ? null : DateTime(_start!.year, _start!.month, _start!.day),
        endsAt: _end == null ? null : DateTime(_end!.year, _end!.month, _end!.day, 23, 59, 59),
        usageLimit: _n(_limit),
        usedCount: widget.edit?.usedCount ?? 0,
      );

  void _save() {
    final okForm = _form.currentState?.validate() ?? false;
    String? dateErr;
    if (_start != null && _end != null && DateTime(_end!.year, _end!.month, _end!.day).isBefore(DateTime(_start!.year, _start!.month, _start!.day))) {
      dateErr = 'วันสิ้นสุดต้องไม่ก่อนวันเริ่ม';
    }
    setState(() => _dateError = dateErr);
    if (!okForm || dateErr != null) return;
    _close(context, _build());
  }

  Future<void> _pick(bool start) async {
    final now = DateTime.now();
    final current = start ? _start : _end;
    final first = DateTime(2020);
    final last = DateTime(now.year + 5, 12, 31);
    var initial = current ?? (start ? now : (_start ?? now));
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: start ? 'วันเริ่มใช้คูปอง' : 'วันสุดท้ายที่ใช้ได้',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _dateError = null;
    });
  }

  Widget _dateBox(String label, DateTime? value, bool start) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(Nv.rSm),
            onTap: () => _pick(start),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(NvIcons.calendar, size: 14, color: Nv.goldInk),
                suffixIcon: value == null
                    ? null
                    : IconButton(
                        tooltip: 'ล้างวันที่',
                        icon: const Icon(NvIcons.xmark, size: 13, color: Nv.ink3),
                        onPressed: () => setState(() {
                          if (start) {
                            _start = null;
                          } else {
                            _end = null;
                          }
                          _dateError = null;
                        }),
                      ),
              ),
              child: Text(value == null ? 'ไม่กำหนด' : thaiDate(value), style: Nv.ui(14, color: value == null ? Nv.ink4 : Nv.ink)),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.edit != null;
    final percent = _kind == DiscountKind.percent;
    final sample = _build();
    final sampleBill = sample.minSpend > 500 ? sample.minSpend : 500;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvField(
            label: editing ? 'รหัสคูปอง (แก้ไขไม่ได้)' : 'รหัสคูปอง * (A–Z, 0–9)',
            controller: _code,
            icon: NvIcons.coupon,
            hint: 'เช่น WELCOME50',
            enabled: !editing,
            autofocus: !editing,
            formatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')), _UpperCase(), LengthLimitingTextInputFormatter(20)],
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (editing) return null;
              final s = (v ?? '').trim().toUpperCase();
              if (s.length < 3) return 'รหัสต้องมีอย่างน้อย 3 ตัวอักษร';
              if (AppScope.read(context).couponByCode(s) != null) return 'มีคูปองรหัสนี้แล้ว';
              return null;
            },
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'ชื่อคูปอง *',
            controller: _name,
            icon: NvIcons.tag,
            hint: 'เช่น ส่วนลดลูกค้าใหม่',
            formatters: [LengthLimitingTextInputFormatter(60)],
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณาตั้งชื่อคูปอง' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('ประเภทส่วนลด', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
              const SizedBox(width: 12),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: NvSegmented<DiscountKind>(
                    options: const [(DiscountKind.amount, 'ลดเป็นบาท'), (DiscountKind.percent, 'ลดเป็นเปอร์เซ็นต์')],
                    value: _kind,
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NvField(
                  label: percent ? 'ลดกี่เปอร์เซ็นต์ *' : 'ลดกี่บาท *',
                  controller: _value,
                  icon: percent ? NvIcons.percent : NvIcons.moneyBill,
                  keyboard: TextInputType.number,
                  suffixText: percent ? '%' : '฿',
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(percent ? 3 : 7)],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '') ?? 0;
                    if (n <= 0) return 'ต้องมากกว่า 0';
                    if (percent && n > 100) return 'ไม่เกิน 100%';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NvField(
                  label: 'ยอดซื้อขั้นต่ำ',
                  controller: _min,
                  icon: NvIcons.receipt,
                  keyboard: TextInputType.number,
                  hint: '0 = ไม่มี',
                  suffixText: '฿',
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (percent) ...[
            const SizedBox(height: 12),
            NvField(
              label: 'ลดสูงสุดไม่เกิน',
              controller: _max,
              icon: NvIcons.shield,
              keyboard: TextInputType.number,
              hint: '0 = ไม่จำกัด',
              suffixText: '฿',
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _dateBox('เริ่มใช้ได้', _start, true)),
              const SizedBox(width: 12),
              Expanded(child: _dateBox('ใช้ได้ถึง (รวมวันนั้น)', _end, false)),
            ],
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(_dateError!, style: Nv.ui(12, color: Nv.lacquer, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          NvField(
            label: 'จำนวนครั้งที่ใช้ได้',
            controller: _limit,
            icon: NvIcons.listCheck,
            keyboard: TextInputType.number,
            hint: '0 = ไม่จำกัด',
            suffixText: 'ครั้ง',
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            validator: (v) {
              final n = int.tryParse(v ?? '') ?? 0;
              final used = widget.edit?.usedCount ?? 0;
              if (n > 0 && n < used) return 'ใช้ไปแล้ว $used ครั้ง — ตั้งได้ไม่น้อยกว่านี้';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Nv.gold100, borderRadius: BorderRadius.circular(Nv.rSm)),
            child: Row(
              children: [
                const Icon(NvIcons.calculator, size: 14, color: Nv.goldInk),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sample.value <= 0
                        ? 'กรอกมูลค่าส่วนลดเพื่อดูตัวอย่าง'
                        : 'ตัวอย่าง: บิล ${baht(sampleBill)} → ลด ${baht(sample.discountFor(sampleBill))}',
                    style: Nv.ui(13, color: Nv.ink2, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pop [ctx]'s route only while it is still the top route — a double tap
/// during the exit animation must never pop the page underneath.
void _close(BuildContext ctx, [Object? result]) {
  if (ModalRoute.of(ctx)?.isCurrent ?? false) Navigator.of(ctx).pop(result);
}

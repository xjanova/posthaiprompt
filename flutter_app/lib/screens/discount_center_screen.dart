// Thaiprompt POS — โปรโมชั่นอัตโนมัติ · /discount-center
//
// Automatic promotions (store.promotions — no code needed): cards with a
// persisted on/off switch, summary, scope (whole bill / one category) and
// happy-hour window, plus a "live now" badge that refreshes every minute.
// Create / edit → upsertPromotion; delete with confirmation. The live
// "บิลปัจจุบัน" panel shows exactly what the store applies to the counter
// cart right now: best promotion, coupon, member discount, discountNote.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

String _hh(int h) => '${h.toString().padLeft(2, '0')}:00';

String _windowText(Promotion p) {
  if (p.startHour == p.endHour) return 'ทั้งวัน';
  final over = p.startHour > p.endHour ? ' (ข้ามเที่ยงคืน)' : '';
  return '${_hh(p.startHour)}–${_hh(p.endHour)}$over';
}

class DiscountCenterScreen extends StatefulWidget {
  const DiscountCenterScreen({super.key});

  @override
  State<DiscountCenterScreen> createState() => _DiscountCenterScreenState();
}

class _DiscountCenterScreenState extends State<DiscountCenterScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // ช่วงเวลา happy hour เปลี่ยนตามนาฬิกา — รีเฟรชป้าย "กำลังใช้อยู่" ทุกนาที
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final promos = store.promotions;
    final now = DateTime.now();
    final applied = store.appliedPromotion;
    final compact = MediaQuery.sizeOf(context).width < 760;

    Widget promoList(double width) {
      final cols = width > 1000 ? 2 : 1;
      final w = (width - (cols - 1) * 14) / cols;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final p in promos)
            SizedBox(
              width: w,
              child: _PromoCard(
                promo: p,
                category: p.scope == PromoScope.category ? store.categoryById(p.categoryId) : null,
                liveNow: p.activeAt(now),
                applied: applied?.id == p.id && store.promoDiscount > 0,
              ),
            ),
        ],
      );
    }

    return NvScaffold(
      title: 'โปรโมชั่นอัตโนมัติ',
      eyebrow: 'DISCOUNT CENTER',
      subtitle: 'ส่วนลดที่ระบบใช้ให้เองโดยไม่ต้องกรอกรหัส — เลือกโปรฯ ที่ลดได้มากที่สุด 1 รายการต่อบิล',
      art: 'discount',
      actions: [
        if (!compact) NvButton.ghost('คูปอง', icon: NvIcons.coupon, onPressed: () => context.go('/coupons')),
        NvButton.gold(compact ? '' : 'สร้างโปรโมชั่น', icon: NvIcons.plus, tooltip: 'สร้างโปรโมชั่น', onPressed: () => _editPromo(context, null)),
      ],
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 980;
        final panel = _LivePanel(store: store);
        final empty = NvEmptyState(
          mascot: 'gift',
          title: 'ยังไม่มีโปรโมชั่นอัตโนมัติ',
          message: 'เช่น ลด 10% ทั้งบิลเมื่อซื้อครบ ฿300 · ลด 20% หมวดเครื่องดื่มช่วง 14:00–16:00',
          actionLabel: 'สร้างโปรโมชั่นแรก',
          actionIcon: NvIcons.plus,
          onAction: () => _editPromo(context, null),
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: promos.isEmpty
                    ? empty
                    : LayoutBuilder(
                        builder: (context, lc) => ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            NvSectionTitle('โปรโมชั่นทั้งหมด', icon: NvIcons.tags,
                                trailing: '${promos.where((p) => p.active).length} เปิดอยู่ · ${promos.length} รายการ'),
                            promoList(lc.maxWidth),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              SizedBox(width: c.maxWidth >= 1300 ? 380 : 340, child: SingleChildScrollView(child: panel)),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            panel,
            const SizedBox(height: 18),
            if (promos.isEmpty)
              SizedBox(height: 380, child: empty)
            else ...[
              NvSectionTitle('โปรโมชั่นทั้งหมด', icon: NvIcons.tags, trailing: '${promos.length} รายการ'),
              promoList(c.maxWidth),
            ],
          ],
        );
      }),
    );
  }
}

// ───────────────────────────── live panel ─────────────────────────────

class _LivePanel extends StatelessWidget {
  final PosStore store;
  const _LivePanel({required this.store});

  @override
  Widget build(BuildContext context) {
    final promo = store.appliedPromotion;
    final member = store.linkedCustomer;
    final empty = store.cart.isEmpty;
    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NvArt.icon('discount', size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('บิลปัจจุบัน', style: Nv.display(18, color: Nv.onNight)),
                    Text(empty ? 'ตะกร้าว่าง' : '${store.cartItemCount} ชิ้น · ${store.openOrderId}', style: Nv.ui(12, color: Nv.onNight3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (empty)
            Text('เพิ่มสินค้าที่หน้าขาย แล้วกลับมาดูว่าโปรโมชั่นไหนถูกใช้กับบิลนี้',
                style: Nv.ui(13, color: Nv.onNight2, height: 1.45))
          else ...[
            NvKeyValue('ยอดรวมสินค้า', baht(store.cartSubtotal), onNight: true),
            NvKeyValue(
              promo != null && store.promoDiscount > 0 ? 'โปรฯ: ${promo.name}' : 'โปรโมชั่น',
              store.promoDiscount > 0 ? '-${baht(store.promoDiscount)}' : 'ไม่เข้าเงื่อนไข',
              onNight: true,
              valueColor: store.promoDiscount > 0 ? Nv.jadeLight : Nv.onNight3,
            ),
            NvKeyValue(
              store.appliedCouponCode != null ? 'คูปอง ${store.appliedCouponCode}' : 'คูปอง',
              store.couponDiscount > 0 ? '-${baht(store.couponDiscount)}' : (store.appliedCouponCode != null ? 'ใช้ไม่ได้' : '—'),
              onNight: true,
              valueColor: store.couponDiscount > 0 ? Nv.jadeLight : Nv.onNight3,
            ),
            NvKeyValue(
              member != null ? 'สมาชิก ${member.name} (${store.tierFor(member).name})' : 'ส่วนลดสมาชิก',
              store.memberDiscount > 0 ? '-${baht(store.memberDiscount)}' : '—',
              onNight: true,
              valueColor: store.memberDiscount > 0 ? Nv.jadeLight : Nv.onNight3,
            ),
            const Divider(color: Nv.lineNight, height: 18),
            NvKeyValue('ส่วนลดรวม', '-${baht(store.cartDiscount)}', onNight: true, strong: true, valueColor: Nv.gold200),
            NvKeyValue('ยอดชำระ (รวม VAT)', baht(store.cartTotal), onNight: true, strong: true),
            if (store.discountNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(store.discountNote, style: Nv.ui(12, color: Nv.gold300, weight: FontWeight.w600)),
            ],
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(Nv.rSm)),
            child: Text(
              'ลำดับการคิด: ① โปรโมชั่นอัตโนมัติที่ลดได้มากที่สุด 1 รายการ (ตามช่วงเวลา หมวด และยอดขั้นต่ำ) '
              '② คูปองที่กรอก ③ ส่วนลดสมาชิกตามระดับ คิดจากยอดหลังหัก ① และ ②',
              style: Nv.ui(12, color: Nv.onNight2, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          NvButton.gold('ไปหน้าขาย', icon: NvIcons.cashier, expand: true, size: NvButtonSize.sm, onPressed: () => context.go('/cashier')),
        ],
      ),
    );
  }
}

// ───────────────────────────── promo card ─────────────────────────────

class _PromoCard extends StatelessWidget {
  final Promotion promo;
  final Category? category;
  final bool liveNow;
  final bool applied;
  const _PromoCard({required this.promo, required this.category, required this.liveNow, required this.applied});

  @override
  Widget build(BuildContext context) {
    final p = promo;
    final missingCat = p.scope == PromoScope.category && category == null;
    final (stateLabel, stateTint) = !p.active
        ? ('ปิดอยู่', NvTint.neutral)
        : (missingCat ? ('หมวดถูกลบ', NvTint.lacquer) : (liveNow ? ('กำลังใช้อยู่ตอนนี้', NvTint.jade) : ('นอกช่วงเวลา', NvTint.amber)));
    return NvSheet(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      selected: applied,
      goldEdge: p.active,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: p.active ? Nv.btnGold : null, color: p.active ? null : Nv.ivoryDeep, shape: BoxShape.circle),
                child: Icon(p.kind == DiscountKind.percent ? NvIcons.percent : NvIcons.tags, size: 17, color: p.active ? const Color(0xFF1A1405) : Nv.ink3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(15.5, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(p.summary, style: Nv.ui(13, color: Nv.goldInk, weight: FontWeight.w700)),
                  ],
                ),
              ),
              Tooltip(
                message: p.active ? 'ปิดโปรโมชั่นนี้' : 'เปิดโปรโมชั่นนี้',
                child: Switch(
                  value: p.active,
                  onChanged: (v) {
                    AppScope.read(context).setPromotionActive(p, v);
                    nvToast(context, v ? 'เปิดโปรโมชั่น "${p.name}" แล้ว' : 'ปิดโปรโมชั่น "${p.name}" แล้ว');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              NvBadge(stateLabel, tint: stateTint),
              if (applied) const NvBadge('ใช้กับบิลปัจจุบัน', tint: NvTint.gold, icon: NvIcons.check),
              NvBadge(
                p.scope == PromoScope.all ? 'ทั้งบิล' : 'หมวด ${category?.name ?? '(ถูกลบ)'}',
                tint: NvTint.sapphire,
                icon: p.scope == PromoScope.all ? NvIcons.receipt : (category?.icon ?? NvIcons.tag),
              ),
              NvBadge(_windowText(p), tint: NvTint.neutral, icon: NvIcons.clock),
              if (p.minSpend > 0) NvBadge('ขั้นต่ำ ${baht(p.minSpend)}', tint: NvTint.neutral, icon: NvIcons.receipt),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NvButton.soft('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: () => _editPromo(context, p)),
              const SizedBox(width: 8),
              NvIconButton(NvIcons.trash, size: 36, tooltip: 'ลบ', color: Nv.lacquer, onPressed: () => _deletePromo(context, p)),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── actions ─────────────────────────────

Future<void> _editPromo(BuildContext context, Promotion? edit) async {
  final store = AppScope.read(context);
  final key = GlobalKey<_PromoFormState>();
  final id = edit?.id ?? store.newPromotionId();
  final res = await showNvDialog<Promotion>(
    context,
    title: edit == null ? 'สร้างโปรโมชั่นอัตโนมัติ' : 'แก้ไขโปรโมชั่น',
    art: 'discount',
    maxWidth: 560,
    body: _PromoForm(key: key, edit: edit, id: id),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold('บันทึก', icon: NvIcons.floppy, onPressed: () => key.currentState?._save()),
    ],
  );
  if (res == null || !context.mounted) return;
  AppScope.read(context).upsertPromotion(res);
  nvToast(context, edit == null ? 'สร้างโปรโมชั่น "${res.name}" แล้ว' : 'บันทึกโปรโมชั่น "${res.name}" แล้ว', kind: NvToastKind.success);
}

Future<void> _deletePromo(BuildContext context, Promotion p) async {
  final ok = await showNvConfirm(
    context,
    title: 'ลบโปรโมชั่น?',
    message: '"${p.name}" จะไม่ถูกใช้กับบิลใหม่อีก (บิลที่ชำระแล้วไม่เปลี่ยน)',
    confirmLabel: 'ลบโปรโมชั่น',
  );
  if (!ok || !context.mounted) return;
  AppScope.read(context).deletePromotion(p);
  nvToast(context, 'ลบโปรโมชั่น "${p.name}" แล้ว', kind: NvToastKind.success);
}

// ───────────────────────────── form ─────────────────────────────

class _PromoForm extends StatefulWidget {
  final Promotion? edit;
  final String id;
  const _PromoForm({super.key, this.edit, required this.id});

  @override
  State<_PromoForm> createState() => _PromoFormState();
}

class _PromoFormState extends State<_PromoForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _value = TextEditingController(text: widget.edit?.value.toString() ?? '');
  late final _min = TextEditingController(text: (widget.edit?.minSpend ?? 0) > 0 ? widget.edit!.minSpend.toString() : '');
  late DiscountKind _kind = widget.edit?.kind ?? DiscountKind.percent;
  late PromoScope _scope = widget.edit?.scope ?? PromoScope.all;
  late String? _categoryId = (widget.edit?.categoryId.isNotEmpty ?? false) ? widget.edit!.categoryId : null;
  late bool _allDay = widget.edit == null || widget.edit!.startHour == widget.edit!.endHour;
  late int _start = _allDay ? 11 : widget.edit!.startHour.clamp(0, 23);
  // endHour 0 (เที่ยงคืน) แสดงเป็น 24:00 — ความหมายเดียวกันใน Promotion.activeAt
  late int _end = _allDay ? 14 : (widget.edit!.endHour == 0 ? 24 : widget.edit!.endHour.clamp(1, 24));
  String? _extraError;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _min.dispose();
    super.dispose();
  }

  void _save() {
    final okForm = _form.currentState?.validate() ?? false;
    String? err;
    final cats = AppScope.read(context).categories;
    if (_scope == PromoScope.category && (_categoryId == null || !cats.any((c) => c.id == _categoryId))) {
      err = 'กรุณาเลือกหมวดสินค้า';
    } else if (!_allDay && _start == _end % 24) {
      err = 'เวลาเริ่มและสิ้นสุดต้องต่างกัน (หรือเลือก "ทั้งวัน")';
    }
    setState(() => _extraError = err);
    if (!okForm || err != null) return;
    _close(context, Promotion(
      id: widget.id,
      name: _name.text.trim(),
      kind: _kind,
      value: int.tryParse(_value.text) ?? 0,
      minSpend: int.tryParse(_min.text) ?? 0,
      scope: _scope,
      categoryId: _scope == PromoScope.category ? _categoryId! : '',
      startHour: _allDay ? 0 : _start,
      endHour: _allDay ? 0 : _end,
      active: widget.edit?.active ?? true,
    ));
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(t, style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
      );

  Widget _dropdown<T>({required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, String? hint}) {
    return InputDecorator(
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint == null ? null : Text(hint, style: Nv.ui(14, color: Nv.ink4)),
          items: items,
          onChanged: onChanged,
          style: Nv.ui(14.5),
          icon: const Icon(NvIcons.chevronDown, size: 12, color: Nv.ink3),
          borderRadius: BorderRadius.circular(Nv.rSm),
          dropdownColor: Nv.paper,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cats = store.sortedCategories;
    final percent = _kind == DiscountKind.percent;
    final catValue = cats.any((c) => c.id == _categoryId) ? _categoryId : null;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NvField(
            label: 'ชื่อโปรโมชั่น *',
            controller: _name,
            icon: NvIcons.bullhorn,
            hint: 'เช่น Happy Hour เครื่องดื่ม',
            autofocus: widget.edit == null,
            formatters: [LengthLimitingTextInputFormatter(60)],
            validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณาตั้งชื่อโปรโมชั่น' : null,
          ),
          const SizedBox(height: 14),
          _label('ประเภทส่วนลด'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: NvSegmented<DiscountKind>(
              options: const [(DiscountKind.percent, 'ลดเป็นเปอร์เซ็นต์'), (DiscountKind.amount, 'ลดเป็นบาท')],
              value: _kind,
              onChanged: (v) => setState(() => _kind = v),
            ),
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
                  label: 'ยอดบิลขั้นต่ำ',
                  controller: _min,
                  icon: NvIcons.receipt,
                  keyboard: TextInputType.number,
                  hint: '0 = ไม่มี',
                  suffixText: '฿',
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _label('ใช้กับ'),
          NvSegmented<PromoScope>(
            options: const [(PromoScope.all, 'ทั้งบิล'), (PromoScope.category, 'เฉพาะหมวด')],
            value: _scope,
            onChanged: (v) => setState(() {
              _scope = v;
              _extraError = null;
            }),
          ),
          if (_scope == PromoScope.category) ...[
            const SizedBox(height: 10),
            if (cats.isEmpty)
              Text('ยังไม่มีหมวดสินค้า — เพิ่มหมวดที่เมนู "เมนูและสินค้า" ก่อน', style: Nv.ui(12.5, color: Nv.lacquer))
            else
              _dropdown<String>(
                value: catValue,
                hint: 'เลือกหมวดสินค้า',
                items: [
                  for (final c in cats)
                    DropdownMenuItem(
                      value: c.id,
                      child: Row(children: [
                        Icon(c.icon, size: 13, color: Nv.goldInk),
                        const SizedBox(width: 10),
                        Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _categoryId = v;
                  _extraError = null;
                }),
              ),
            const SizedBox(height: 4),
            Text('ส่วนลดคิดจากยอดสินค้าในหมวดนี้เท่านั้น · ยอดขั้นต่ำคิดจากทั้งบิล', style: Nv.ui(12, color: Nv.ink3)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _label('ช่วงเวลา')),
              Text('ทั้งวัน', style: Nv.ui(13, color: Nv.ink2)),
              Switch(
                value: _allDay,
                onChanged: (v) => setState(() {
                  _allDay = v;
                  _extraError = null;
                }),
              ),
            ],
          ),
          if (!_allDay)
            Row(
              children: [
                Expanded(
                  child: _dropdown<int>(
                    value: _start,
                    items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('เริ่ม ${_hh(h)}'))],
                    onChanged: (v) => setState(() {
                      _start = v ?? _start;
                      _extraError = null;
                    }),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('ถึง')),
                Expanded(
                  child: _dropdown<int>(
                    value: _end,
                    items: [for (var h = 1; h <= 24; h++) DropdownMenuItem(value: h, child: Text('ถึง ${h == 24 ? '24:00' : _hh(h)}'))],
                    onChanged: (v) => setState(() {
                      _end = v ?? _end;
                      _extraError = null;
                    }),
                  ),
                ),
              ],
            ),
          if (!_allDay && _start > _end)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text('ช่วงเวลานี้ข้ามเที่ยงคืน (เช่น 22:00–02:00)', style: Nv.ui(12, color: Nv.ink3)),
            ),
          if (_extraError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(_extraError!, style: Nv.ui(12.5, color: Nv.lacquer, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          Text('ถ้ามีหลายโปรฯ เข้าเงื่อนไขพร้อมกัน ระบบเลือกโปรฯ ที่ลดได้มากที่สุดเพียงรายการเดียว',
              style: Nv.ui(12, color: Nv.ink3, height: 1.4)),
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

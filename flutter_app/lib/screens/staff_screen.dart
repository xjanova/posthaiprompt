// Thaiprompt POS — Staff (Nova): accounts, roles, PINs, time clock.
//
// Every card is a real staff record: role, phone, clock-in time, today's
// sales/bills from their own bills, lock status. Managers add staff (name,
// role, phone, PIN ×2 — 4–6 digits, not trivial, unique), edit them, reset a
// PIN (also clears a lockout), clock someone out, or delete an account.
// Owner accounts can only be changed with an owner's PIN, so a manager can't
// promote themselves or take over the owner login.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/security/pin.dart';
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

typedef _StaffInput = ({String name, StaffRole role, String phone, bool active, String pin});

/// Validates a new PIN; null = OK.
String? staffPinError(PosStore store, String pin, {Staff? except}) {
  if (!PinHasher.isValidPin(pin)) return 'PIN ต้องเป็นตัวเลข 4–6 หลัก';
  if (PinHasher.isWeak(pin)) return 'PIN เดาง่ายเกินไป (เช่น 1111 หรือ 1234)';
  if (store.pinInUse(pin, except: except)) return 'PIN นี้มีพนักงานคนอื่นใช้แล้ว';
  return null;
}

const _roleNotes = <StaffRole, String>{
  StaffRole.owner: 'เข้าได้ทุกหน้า · จัดการบัญชีเจ้าของร้าน · อนุมัติคืนเงิน/ยกเลิก/ลดสต็อกด้วย PIN',
  StaffRole.manager: 'เข้าได้ทุกหน้า (รายงาน บัญชี ตั้งค่า เมนู พนักงาน) · อนุมัติด้วย PIN · แก้บัญชีเจ้าของร้านไม่ได้',
  StaffRole.cashier: 'ขาย รับชำระ บิล กะ คลังสินค้า สมาชิก ใบกำกับ · คืนเงิน/ยกเลิก/ลดสต็อกต้องใช้ PIN ผู้จัดการ',
  StaffRole.waiter: 'ผังโต๊ะ รับออเดอร์ ส่งครัว และรับชำระได้ · เริ่มต้นที่หน้าผังโต๊ะ',
  StaffRole.kitchen: 'เฉพาะจอครัว หน้าหลัก และสถานะออเดอร์ · รับชำระเงินไม่ได้',
};

NvTint _roleTint(StaffRole r) => switch (r) {
      StaffRole.owner => NvTint.amethyst,
      StaffRole.manager => NvTint.navy,
      StaffRole.cashier => NvTint.gold,
      StaffRole.waiter => NvTint.sapphire,
      StaffRole.kitchen => NvTint.amber,
    };

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _query = '';
  StaffRole? _role;

  bool get _meIsOwner => AppScope.read(context).currentStaff?.role == StaffRole.owner;

  /// Approval for changing [target]. Owner accounts need an owner's PIN when
  /// the signed-in user isn't an owner. Returns the approver or null.
  Future<Staff?> _authorize(Staff target, String reason) async {
    if (target.role != StaffRole.owner || _meIsOwner) {
      return showManagerPin(context, reason: reason);
    }
    final appr = await showManagerPin(context, reason: '$reason · ต้องใช้ PIN เจ้าของร้าน', alwaysAsk: true);
    if (appr == null || !mounted) return null;
    if (appr.role != StaffRole.owner) {
      nvToast(context, 'บัญชีเจ้าของร้านแก้ได้ด้วย PIN ของเจ้าของร้านเท่านั้น', kind: NvToastKind.error);
      return null;
    }
    return appr;
  }

  Future<void> _add() async {
    final r = await showNvDialog<_StaffInput>(
      context,
      title: 'เพิ่มพนักงาน',
      subtitle: 'PIN ใช้เข้าระบบและลงเวลา — ห้ามซ้ำกับคนอื่น',
      art: 'staff',
      maxWidth: 520,
      body: _StaffForm(allowOwner: _meIsOwner),
    );
    if (r == null || !mounted) return;
    final s = AppScope.read(context).addStaff(name: r.name, role: r.role, pin: r.pin, phone: r.phone);
    nvToast(context, 'เพิ่ม ${s.name} (${s.role.label}) แล้ว', kind: NvToastKind.success);
  }

  Future<void> _edit(Staff s) async {
    final store = AppScope.read(context);
    final isSelf = store.currentStaff?.id == s.id;
    Staff? appr;
    if (s.role == StaffRole.owner && !_meIsOwner) {
      appr = await _authorize(s, 'แก้ไขบัญชีเจ้าของร้าน ${s.name}');
      if (appr == null || !mounted) return;
    }
    final r = await showNvDialog<_StaffInput>(
      context,
      title: 'แก้ไขพนักงาน',
      subtitle: s.name,
      art: 'staff',
      maxWidth: 520,
      body: _StaffForm(edit: s, allowOwner: _meIsOwner || appr?.role == StaffRole.owner, isSelf: isSelf),
    );
    if (r == null || !mounted) return;
    try {
      store.updateStaff(s, name: r.name, role: isSelf ? null : r.role, phone: r.phone, active: isSelf ? null : r.active);
      nvToast(context, 'บันทึกข้อมูล ${s.name} แล้ว', kind: NvToastKind.success);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
    }
  }

  Future<void> _resetPin(Staff s) async {
    final appr = await _authorize(s, 'ตั้ง PIN ใหม่ให้ ${s.name}');
    if (appr == null || !mounted) return;
    final pin = await showNvDialog<String>(
      context,
      title: 'ตั้ง PIN ใหม่',
      subtitle: '${s.name} · ${s.role.label}${s.isLocked ? ' · จะปลดล็อกบัญชีด้วย' : ''}',
      art: 'shield',
      maxWidth: 420,
      body: StaffPinForm(staff: s),
    );
    if (pin == null || !mounted) return;
    AppScope.read(context).setStaffPin(s, pin);
    nvToast(context, 'ตั้ง PIN ใหม่ให้ ${s.name} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _clockOut(Staff s) async {
    final isSelf = AppScope.read(context).currentStaff?.id == s.id;
    final ok = await showNvConfirm(
      context,
      title: 'ลงเวลาออกให้ ${s.name}?',
      message: isSelf
          ? 'บันทึกเวลาออกงานของคุณ (ยังอยู่ในระบบจนกว่าจะล็อกหน้าจอ)'
          : 'บันทึกเวลาออกงานของ ${s.name} — เข้างานตั้งแต่ ${s.clockedInAt == null ? '—' : hm(s.clockedInAt!)}',
      confirmLabel: 'ลงเวลาออก',
      danger: false,
      icon: NvIcons.userClock,
    );
    if (!ok || !mounted) return;
    AppScope.read(context).clockOut(s);
    nvToast(context, 'ลงเวลาออกให้ ${s.name} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _delete(Staff s) async {
    final store = AppScope.read(context);
    if (store.currentStaff?.id == s.id) {
      nvToast(context, 'ลบบัญชีที่กำลังใช้งานอยู่ไม่ได้', kind: NvToastKind.error);
      return;
    }
    final ok = await showNvConfirm(
      context,
      title: 'ลบพนักงาน ${s.name}?',
      message: 'บัญชีและ PIN จะถูกลบถาวร (บิลที่เคยขายยังอยู่ครบ) ถ้าแค่พักงานให้ใช้ "แก้ไข → ปิดใช้งาน" แทน',
      confirmLabel: 'ลบบัญชี',
    );
    if (!ok || !mounted) return;
    final appr = await _authorize(s, 'ลบบัญชี ${s.name}');
    if (appr == null || !mounted) return;
    try {
      store.removeStaff(s);
      nvToast(context, 'ลบ ${s.name} แล้ว', kind: NvToastKind.success);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentStaff;
    final q = _query.trim().toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    final list = store.staff.where((s) {
      if (_role != null && s.role != _role) return false;
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) || (digits.isNotEmpty && s.phone.replaceAll(RegExp(r'\D'), '').contains(digits));
    }).toList()
      ..sort((a, b) {
        if (a.active != b.active) return a.active ? -1 : 1;
        if (a.online != b.online) return a.online ? -1 : 1;
        final r = a.role.index.compareTo(b.role.index);
        return r != 0 ? r : a.name.compareTo(b.name);
      });
    final active = store.activeStaff;
    final online = active.where((s) => s.online).length;
    final locked = store.staff.where((s) => s.isLocked).length;
    final salesAll = active.fold<int>(0, (sum, s) => sum + store.salesTodayFor(s));

    return NvScaffold(
      title: 'พนักงาน',
      eyebrow: 'บทบาท · PIN · ลงเวลา',
      subtitle: '${store.shopName} · ${active.length} บัญชีที่ใช้งาน',
      art: 'staff',
      actions: [NvButton.gold('เพิ่มพนักงาน', icon: NvIcons.userPlus, size: NvButtonSize.sm, onPressed: _add)],
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final statCols = w >= 860 ? 4 : (w >= 520 ? 2 : 1);
        final statW = (w - (statCols - 1) * 12) / statCols;
        final cols = w >= 1300 ? 3 : (w >= 820 ? 2 : 1);
        final cardW = (w - (cols - 1) * 14) / cols;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: statW, child: NvStatTile(label: 'บัญชีที่ใช้งาน', value: '${active.length} คน', art: 'staff')),
                SizedBox(
                  width: statW,
                  child: NvStatTile(label: 'ลงเวลาเข้างานอยู่', value: '$online คน', art: 'shift', tint: NvTint.jade, caption: online == 0 ? 'ยังไม่มีใครเข้างาน' : null),
                ),
                SizedBox(
                  width: statW,
                  child: NvStatTile(
                    label: 'บัญชีถูกล็อก',
                    value: '$locked บัญชี',
                    art: 'shield',
                    tint: locked > 0 ? NvTint.lacquer : NvTint.neutral,
                    caption: locked > 0 ? 'ตั้ง PIN ใหม่เพื่อปลดล็อก' : 'ไม่มีบัญชีถูกล็อก',
                    onTap: () => context.go('/admin'),
                  ),
                ),
                SizedBox(width: statW, child: NvStatTile(label: 'ยอดขายวันนี้ (ทุกคน)', value: baht(salesAll), art: 'cash')),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: w < 560 ? w : 300,
                  child: NvSearchField(hint: 'ค้นหาชื่อหรือเบอร์โทร…', onChanged: (v) => setState(() => _query = v)),
                ),
                NvChip('ทั้งหมด', selected: _role == null, count: store.staff.length, onTap: () => setState(() => _role = null)),
                for (final r in StaffRole.values)
                  NvChip(r.label,
                      selected: _role == r,
                      count: store.staff.where((s) => s.role == r).length,
                      onTap: () => setState(() => _role = _role == r ? null : r)),
              ],
            ),
            const SizedBox(height: 16),
            if (store.staff.isEmpty)
              NvSheet(
                child: NvEmptyState(
                  mascot: 'welcome',
                  title: 'ยังไม่มีพนักงาน',
                  message: 'เพิ่มพนักงานพร้อม PIN เพื่อให้เข้าระบบ ลงเวลา และแยกยอดขายรายคน',
                  actionLabel: 'เพิ่มพนักงาน',
                  actionIcon: NvIcons.userPlus,
                  onAction: _add,
                ),
              )
            else if (list.isEmpty)
              NvSheet(
                child: NvEmptyState(
                  mascot: 'search',
                  title: 'ไม่พบพนักงาน',
                  message: 'ลองเปลี่ยนคำค้นหรือตัวกรองบทบาท',
                  actionLabel: 'ล้างตัวกรอง',
                  onAction: () => setState(() {
                    _role = null;
                    _query = '';
                  }),
                ),
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final s in list)
                    SizedBox(
                      width: cardW,
                      child: _StaffCard(
                        staff: s,
                        isMe: me?.id == s.id,
                        sales: store.salesTodayFor(s),
                        bills: store.ordersTodayFor(s),
                        onEdit: () => _edit(s),
                        onPin: () => _resetPin(s),
                        onClockOut: () => _clockOut(s),
                        onDelete: () => _delete(s),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 18),
            NvSheet(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NvSectionTitle('สิทธิ์ตามบทบาท', icon: NvIcons.shield),
                  for (final r in StaffRole.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 120, child: Align(alignment: Alignment.centerLeft, child: NvBadge(r.label, tint: _roleTint(r)))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_roleNotes[r]!, style: Nv.ui(13, color: Nv.ink2, height: 1.45))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text('รายละเอียดสิทธิ์ทุกหน้าดูได้ที่ ความปลอดภัย → ตารางสิทธิ์', style: Nv.ui(12, color: Nv.ink3)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final bool isMe;
  final int sales;
  final int bills;
  final VoidCallback onEdit;
  final VoidCallback onPin;
  final VoidCallback onClockOut;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.isMe,
    required this.sales,
    required this.bills,
    required this.onEdit,
    required this.onPin,
    required this.onClockOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = staff;
    return Opacity(
      opacity: s.active ? 1 : 0.62,
      child: NvSheet(
        selected: isMe,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                NvAvatar(s.initials, hue: s.hue, size: 50, ring: s.online),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(16, weight: FontWeight.w700)),
                          ),
                          if (isMe) ...[const SizedBox(width: 6), const NvBadge('คุณ', tint: NvTint.gold, dot: false)],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          NvBadge(s.role.label, tint: _roleTint(s.role), dot: false),
                          if (s.phone.isNotEmpty) Text(phoneFmt(s.phone), style: Nv.money(12, color: Nv.ink3, weight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (!s.active) const NvBadge('ปิดใช้งาน', tint: NvTint.neutral),
                if (s.online)
                  NvBadge(s.clockedInAt == null ? 'เข้างานอยู่' : 'เข้างาน ${hm(s.clockedInAt!)} · ${timeAgo(s.clockedInAt!)}', tint: NvTint.jade)
                else if (s.active)
                  const NvBadge('ยังไม่ลงเวลาเข้า', tint: NvTint.neutral),
                if (s.isLocked) NvBadge('ล็อกถึง ${hm(s.lockedUntil!)}', tint: NvTint.lacquer, icon: NvIcons.lock),
                if (!s.hasPin) const NvBadge('ยังไม่มี PIN', tint: NvTint.amber),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: Nv.paper, borderRadius: BorderRadius.circular(12), border: Border.all(color: Nv.lineSoft)),
              child: Row(
                children: [
                  Expanded(child: Text('ยอดขายวันนี้', style: Nv.ui(12.5, color: Nv.ink3))),
                  Text(baht(sales), style: Nv.money(15)),
                  const SizedBox(width: 10),
                  Text('$bills บิล', style: Nv.ui(12, color: Nv.ink3, weight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                NvButton.soft('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: onEdit),
                NvButton.soft(s.isLocked ? 'ตั้ง PIN ใหม่ / ปลดล็อก' : 'ตั้ง PIN ใหม่', icon: NvIcons.key, size: NvButtonSize.sm, onPressed: onPin),
                if (s.online) NvButton.ghost('ลงเวลาออก', icon: NvIcons.userClock, size: NvButtonSize.sm, onPressed: onClockOut),
                NvButton.danger('ลบ', icon: NvIcons.trash, size: NvButtonSize.sm, tooltip: isMe ? 'ลบบัญชีของตัวเองไม่ได้' : null, onPressed: isMe ? null : onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Add / edit staff form. Owns its controllers (disposed with the dialog).
class _StaffForm extends StatefulWidget {
  final Staff? edit;
  final bool allowOwner;
  final bool isSelf;
  const _StaffForm({this.edit, required this.allowOwner, this.isSelf = false});

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _phone = TextEditingController(text: widget.edit?.phone ?? '');
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  late StaffRole _role = widget.edit?.role ?? StaffRole.cashier;
  late bool _active = widget.edit?.active ?? true;
  bool _done = false; // a double-tap must not pop the page under the dialog

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  void _submit() {
    if (_done || !(_key.currentState?.validate() ?? false)) return;
    _done = true;
    Navigator.of(context).pop<_StaffInput>((
      name: _name.text.trim(),
      role: _role,
      phone: _phone.text.trim(),
      active: _active,
      pin: _pin.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.read(context);
    final isNew = widget.edit == null;
    final pinFormatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)];
    final lockRole = widget.isSelf || (!widget.allowOwner && widget.edit?.role == StaffRole.owner);
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvField(
            label: 'ชื่อพนักงาน *',
            controller: _name,
            icon: NvIcons.user,
            autofocus: isNew,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'กรุณาใส่ชื่อ';
              if (t.length > 40) return 'ชื่อยาวเกิน 40 ตัวอักษร';
              final dup = store.staff.any((s) => s.id != widget.edit?.id && s.active && s.name.trim().toLowerCase() == t.toLowerCase());
              return dup ? 'มีพนักงานชื่อนี้แล้ว (ชื่อใช้แยกคนตอนเข้าระบบ)' : null;
            },
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('บทบาท', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in StaffRole.values)
                if (r != StaffRole.owner || widget.allowOwner || _role == StaffRole.owner)
                  NvChip(
                    r.label,
                    selected: _role == r,
                    onTap: lockRole || (r == StaffRole.owner && !widget.allowOwner) ? null : () => setState(() => _role = r),
                  ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.isSelf ? 'เปลี่ยนบทบาทของตัวเองไม่ได้' : (_roleNotes[_role] ?? ''),
              style: Nv.ui(12, color: Nv.ink3, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          NvField(
            label: 'เบอร์โทร',
            controller: _phone,
            icon: NvIcons.phone,
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              return (t.length == 9 || t.length == 10) && t.startsWith('0') ? null : 'เบอร์โทร 9–10 หลัก ขึ้นต้นด้วย 0';
            },
          ),
          if (isNew) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NvField(
                    label: 'PIN 4–6 หลัก *',
                    controller: _pin,
                    icon: NvIcons.key,
                    obscure: true,
                    keyboard: TextInputType.number,
                    formatters: pinFormatters,
                    validator: (v) => staffPinError(store, v ?? ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NvField(
                    label: 'ยืนยัน PIN *',
                    controller: _pin2,
                    icon: NvIcons.key,
                    obscure: true,
                    keyboard: TextInputType.number,
                    formatters: pinFormatters,
                    validator: (v) => (v ?? '') == _pin.text ? null : 'PIN ไม่ตรงกัน',
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _active,
              onChanged: widget.isSelf ? null : (v) => setState(() => _active = v),
              title: Text('เปิดใช้งานบัญชี', style: Nv.ui(14, weight: FontWeight.w600)),
              subtitle: Text(
                widget.isSelf ? 'ปิดบัญชีของตัวเองไม่ได้' : 'ปิด = เข้าระบบไม่ได้ แต่ประวัติการขายยังอยู่',
                style: Nv.ui(12, color: Nv.ink3),
              ),
            ),
            Text('เปลี่ยน PIN ใช้ปุ่ม "ตั้ง PIN ใหม่" บนการ์ดพนักงาน', style: Nv.ui(12, color: Nv.ink3)),
          ],
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
              NvButton.gold(isNew ? 'เพิ่มพนักงาน' : 'บันทึก', icon: NvIcons.check, onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

/// New PIN ×2 for an existing staff member → pops the PIN string (also used by
/// the security screen to unlock accounts).
class StaffPinForm extends StatefulWidget {
  final Staff staff;
  const StaffPinForm({super.key, required this.staff});

  @override
  State<StaffPinForm> createState() => _StaffPinFormState();
}

class _StaffPinFormState extends State<StaffPinForm> {
  final _key = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  void _submit() {
    if (_done || !(_key.currentState?.validate() ?? false)) return;
    _done = true;
    Navigator.of(context).pop(_pin.text);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.read(context);
    final f = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)];
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvField(
            label: 'PIN ใหม่ 4–6 หลัก',
            controller: _pin,
            icon: NvIcons.key,
            obscure: true,
            autofocus: true,
            keyboard: TextInputType.number,
            formatters: f,
            validator: (v) => staffPinError(store, v ?? '', except: widget.staff),
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'ยืนยัน PIN ใหม่',
            controller: _pin2,
            icon: NvIcons.key,
            obscure: true,
            keyboard: TextInputType.number,
            formatters: f,
            validator: (v) => (v ?? '') == _pin.text ? null : 'PIN ไม่ตรงกัน',
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
              NvButton.gold('ตั้ง PIN', icon: NvIcons.check, onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

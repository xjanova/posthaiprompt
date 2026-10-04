// Thaiprompt POS — ระดับสมาชิก · /tiers
//
// Editable loyalty tiers (store.tiers): each card shows the threshold, the
// automatic member discount, the points rate and the live member count.
// Add / edit (name, ฿ threshold, discount 0–50 %, points per ฿100, card hue)
// → upsertTier; delete with confirmation (at least one tier is kept).
// The member discount is applied automatically at checkout by the store
// (PosStore.memberDiscount) whenever a member is linked to the bill.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

const _kHues = [215, 200, 42, 28, 268, 160, 350, 188];

Color _hsl(int hue, double s, double l) => HSLColor.fromAHSL(1, hue.toDouble() % 360, s, l).toColor();

LinearGradient _tierGradient(int hue) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_hsl(hue, 0.46, 0.40), _hsl(hue, 0.52, 0.22), Nv.navy950],
      stops: const [0.0, 0.62, 1.0],
    );

class MembershipTiersScreen extends StatelessWidget {
  const MembershipTiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final tiers = store.sortedTiers;
    final compact = MediaQuery.sizeOf(context).width < 760;
    return NvScaffold(
      title: 'ระดับสมาชิก',
      eyebrow: 'MEMBERSHIP TIERS',
      subtitle: 'ยอดซื้อสะสมที่ต้องถึง ส่วนลดอัตโนมัติ และอัตราแต้มของแต่ละระดับ',
      art: 'tiers',
      actions: [
        if (!compact) NvButton.ghost('รายชื่อสมาชิก', icon: NvIcons.members, onPressed: () => context.go('/crm')),
        NvButton.gold(compact ? '' : 'เพิ่มระดับ', icon: NvIcons.plus, tooltip: 'เพิ่มระดับ', onPressed: () => _editTier(context, null)),
      ],
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HowItWorks(store: store),
          if (tiers.isNotEmpty && tiers.first.minSpent > 0) ...[
            const SizedBox(height: 12),
            NvSheet(
              color: Nv.amberTint,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(NvIcons.warning, size: 16, color: Nv.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ระดับต่ำสุด (${tiers.first.name}) เริ่มที่ ${baht(tiers.first.minSpent)} — สมาชิกที่ยอดซื้อยังไม่ถึงจะถูกนับเป็นระดับนี้ด้วย แนะนำให้ระดับแรกเริ่มที่ ฿0',
                      style: Nv.ui(13, color: Nv.ink2, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          NvSectionTitle('ระดับทั้งหมด', icon: NvIcons.crown, trailing: '${tiers.length} ระดับ · เรียงตามยอดซื้อ'),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 1250 ? 4 : (c.maxWidth > 880 ? 3 : (c.maxWidth > 560 ? 2 : 1));
            final w = (c.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (var i = 0; i < tiers.length; i++)
                  SizedBox(
                    width: w,
                    child: _TierCard(
                      tier: tiers[i],
                      rank: i + 1,
                      members: store.membersInTier(tiers[i]),
                      canDelete: tiers.length > 1,
                      onEdit: () => _editTier(context, tiers[i]),
                      onDelete: () => _deleteTier(context, tiers[i]),
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

// ───────────────────────────── explainer ─────────────────────────────

class _HowItWorks extends StatelessWidget {
  final PosStore store;
  const _HowItWorks({required this.store});

  @override
  Widget build(BuildContext context) {
    final linked = store.linkedCustomer;
    Widget point(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(i, size: 13, color: Nv.gold300)),
              const SizedBox(width: 10),
              Expanded(child: Text(t, style: Nv.ui(13, color: Nv.onNight2, height: 1.45))),
            ],
          ),
        );
    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ทำงานอย่างไร', style: Nv.eyebrow(color: Nv.gold300)),
                const SizedBox(height: 8),
                point(NvIcons.percent,
                    'ส่วนลดสมาชิกคิดให้อัตโนมัติที่หน้าขายเมื่อผูกสมาชิกกับบิล — คิดจากยอดหลังหักโปรโมชั่นและคูปองแล้ว'),
                point(NvIcons.coins, 'แต้มสะสม = ยอดสุทธิของบิล ÷ 100 × อัตราแต้มของระดับ (ปัดเศษลง) ได้ทุกครั้งที่ชำระเงิน'),
                point(NvIcons.arrowTrendUp, 'ระดับปรับตามยอดซื้อสะสมของสมาชิกทันที ไม่ต้องอัปเกรดเอง · คืนเงินแล้วยอดสะสมลดลงตาม'),
                if (linked != null)
                  point(NvIcons.cashier,
                      'บิลปัจจุบันผูกกับ ${linked.name} (${store.tierFor(linked).name}) · ส่วนลดสมาชิกตอนนี้ ${baht(store.memberDiscount)}'),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 700) ...[
            const SizedBox(width: 16),
            NvArt.icon('tiers', size: 104),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── tier card ─────────────────────────────

class _TierCard extends StatelessWidget {
  final MembershipTier tier;
  final int rank;
  final int members;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TierCard({
    required this.tier,
    required this.rank,
    required this.members,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _TierFace(
      tier: tier,
      rank: rank,
      members: members,
      onTap: onEdit,
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          NvButton.ghost('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onNight: true, onPressed: onEdit),
          NvButton.ghost('ลบ', icon: NvIcons.trash, size: NvButtonSize.sm, onNight: true, onPressed: canDelete ? onDelete : null,
              tooltip: canDelete ? null : 'ต้องมีอย่างน้อย 1 ระดับ'),
        ],
      ),
    );
  }
}

/// The gradient tier face (also used as the live preview in the form).
class _TierFace extends StatelessWidget {
  final MembershipTier tier;
  final int? rank;
  final int? members;
  final Widget? footer;
  final VoidCallback? onTap;
  const _TierFace({required this.tier, this.rank, this.members, this.footer, this.onTap});

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(Nv.rPill),
          border: Border.all(color: Nv.lineNight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Nv.gold300),
            const SizedBox(width: 6),
            Text(text, style: Nv.ui(12, color: Nv.onNight, weight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(Nv.rXl);
    final card = Container(
      decoration: BoxDecoration(
        gradient: _tierGradient(tier.hue),
        borderRadius: br,
        border: Border.all(color: Nv.lineNightStrong),
        boxShadow: Nv.shadowLift,
      ),
      child: Stack(
        children: [
          Positioned(right: 4, top: 4, child: NvArt.icon('tiers', size: 84)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 78),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rank != null) Text('ระดับ $rank', style: Nv.eyebrow(color: Nv.gold300)),
                      const SizedBox(height: 2),
                      Text(tier.name.isEmpty ? 'ชื่อระดับ' : tier.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.display(22, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('ยอดซื้อสะสม ≥ ${baht(tier.minSpent)}', style: Nv.ui(13, color: Nv.onNight2, weight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _pill(NvIcons.percent, tier.discountPercent > 0 ? 'ส่วนลด ${tier.discountPercent}%' : 'ไม่มีส่วนลด'),
                    _pill(NvIcons.coins, '${tier.pointsPer100} แต้ม/฿100'),
                    if (members != null) _pill(NvIcons.users, '${groupDigits(members!)} คน'),
                  ],
                ),
                if (footer != null) ...[const SizedBox(height: 14), footer!],
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(borderRadius: br, onTap: onTap, child: card),
    );
  }
}

// ───────────────────────────── actions ─────────────────────────────

Future<void> _editTier(BuildContext context, MembershipTier? edit) async {
  final key = GlobalKey<_TierFormState>();
  final res = await showNvDialog<MembershipTier>(
    context,
    title: edit == null ? 'เพิ่มระดับสมาชิก' : 'แก้ไขระดับ ${edit.name}',
    art: 'tiers',
    maxWidth: 540,
    body: _TierForm(key: key, edit: edit),
    actions: (ctx) => [
      NvButton.soft('ยกเลิก', onPressed: () => _close(ctx)),
      NvButton.gold('บันทึก', icon: NvIcons.floppy, onPressed: () => key.currentState?._save()),
    ],
  );
  if (res == null || !context.mounted) return;
  AppScope.read(context).upsertTier(res);
  nvToast(context, edit == null ? 'เพิ่มระดับ ${res.name} แล้ว' : 'บันทึกระดับ ${res.name} แล้ว', kind: NvToastKind.success);
}

Future<void> _deleteTier(BuildContext context, MembershipTier t) async {
  final store = AppScope.read(context);
  if (store.tiers.length <= 1) {
    nvToast(context, 'ต้องมีระดับสมาชิกอย่างน้อย 1 ระดับ', kind: NvToastKind.warning);
    return;
  }
  final n = store.membersInTier(t);
  final ok = await showNvConfirm(
    context,
    title: 'ลบระดับ ${t.name}?',
    message: n > 0
        ? 'สมาชิก $n คนในระดับนี้จะถูกจัดระดับใหม่ตามยอดซื้อสะสมโดยอัตโนมัติ'
        : 'ยังไม่มีสมาชิกในระดับนี้',
    confirmLabel: 'ลบระดับ',
  );
  if (!ok || !context.mounted) return;
  store.deleteTier(t);
  nvToast(context, 'ลบระดับ ${t.name} แล้ว', kind: NvToastKind.success);
}

// ───────────────────────────── form ─────────────────────────────

class _TierForm extends StatefulWidget {
  final MembershipTier? edit;
  const _TierForm({super.key, this.edit});

  @override
  State<_TierForm> createState() => _TierFormState();
}

class _TierFormState extends State<_TierForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _min = TextEditingController(text: widget.edit?.minSpent.toString() ?? '');
  late final _disc = TextEditingController(text: widget.edit?.discountPercent.toString() ?? '0');
  late final _pts = TextEditingController(text: widget.edit?.pointsPer100.toString() ?? '10');
  late int _hue = widget.edit?.hue ?? 42;

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _disc.dispose();
    _pts.dispose();
    super.dispose();
  }

  MembershipTier _current(String id) => MembershipTier(
        id: id,
        name: _name.text.trim(),
        minSpent: int.tryParse(_min.text) ?? 0,
        discountPercent: (int.tryParse(_disc.text) ?? 0).clamp(0, 50),
        pointsPer100: (int.tryParse(_pts.text) ?? 0).clamp(0, 100),
        hue: _hue,
      );

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final id = widget.edit?.id ?? AppScope.read(context).newTierId();
    _close(context, _current(id));
  }

  List<MembershipTier> get _others => AppScope.read(context).tiers.where((t) => t.id != widget.edit?.id).toList();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TierFace(tier: _current(widget.edit?.id ?? 'preview')),
          const SizedBox(height: 16),
          NvField(
            label: 'ชื่อระดับ *',
            controller: _name,
            icon: NvIcons.crown,
            autofocus: widget.edit == null,
            hint: 'เช่น Silver · Gold · VIP',
            formatters: [LengthLimitingTextInputFormatter(30)],
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'กรุณาตั้งชื่อระดับ';
              if (_others.any((t) => t.name.trim().toLowerCase() == s.toLowerCase())) return 'มีระดับชื่อนี้แล้ว';
              return null;
            },
          ),
          const SizedBox(height: 12),
          NvField(
            label: 'ยอดซื้อสะสมขั้นต่ำ (บาท) *',
            controller: _min,
            icon: NvIcons.sackDollar,
            keyboard: TextInputType.number,
            hint: '0',
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'กรุณากรอกยอดขั้นต่ำ (ระดับแรกใช้ 0)';
              final n = int.tryParse(v!) ?? 0;
              final clash = _others.where((t) => t.minSpent == n);
              if (clash.isNotEmpty) return 'ระดับ ${clash.first.name} ใช้ยอด ${baht(n)} อยู่แล้ว';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NvField(
                  label: 'ส่วนลดอัตโนมัติ (%)',
                  controller: _disc,
                  icon: NvIcons.percent,
                  keyboard: TextInputType.number,
                  suffixText: '%',
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '') ?? 0;
                    return n > 50 ? 'สูงสุด 50%' : null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NvField(
                  label: 'แต้มต่อ ฿100',
                  controller: _pts,
                  icon: NvIcons.coins,
                  keyboard: TextInputType.number,
                  suffixText: 'แต้ม',
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '') ?? 0;
                    return n > 100 ? 'สูงสุด 100 แต้ม' : null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('สีบัตร', style: Nv.ui(12.5, color: Nv.ink2, weight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final h in _kHues)
                Tooltip(
                  message: 'เลือกสีนี้',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _hue = h),
                    child: AnimatedContainer(
                      duration: Nv.fast,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _tierGradient(h),
                        border: Border.all(color: _hue == h ? Nv.gold500 : Nv.line, width: _hue == h ? 3 : 1),
                        boxShadow: _hue == h ? Nv.goldGlow(0.6) : null,
                      ),
                      child: _hue == h ? const Icon(NvIcons.check, size: 14, color: Colors.white) : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('ส่วนลดสมาชิกคิดจากยอดหลังหักโปรโมชั่น/คูปอง และใช้อัตโนมัติเมื่อผูกสมาชิกกับบิล',
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

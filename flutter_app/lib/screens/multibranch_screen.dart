// Thaiprompt POS — Branches / HQ (Nova).
//
// The shop's branch list kept on this device: add / edit (name, area, phone),
// choose which branch THIS terminal belongs to (manager PIN + confirm), and
// delete branches that aren't in use. Live numbers are shown only for this
// device's branch (from its own bills) — other branches' sales live on the
// Thai Prompt server, and the card at the top says so honestly with the real
// sync status instead of inventing figures.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/sync/sync_service.dart';
import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';

typedef _BranchInput = ({String name, String area, String phone});

class MultiBranchScreen extends StatefulWidget {
  const MultiBranchScreen({super.key});

  @override
  State<MultiBranchScreen> createState() => _MultiBranchScreenState();
}

class _MultiBranchScreenState extends State<MultiBranchScreen> {
  Future<_BranchInput?> _form({Branch? edit}) => showNvDialog<_BranchInput>(
        context,
        title: edit == null ? 'เพิ่มสาขา' : 'แก้ไขสาขา',
        subtitle: edit == null ? 'สาขาใหม่จะยังไม่ถูกตั้งเป็นสาขาของเครื่องนี้' : edit.name,
        art: 'branch',
        body: _BranchForm(edit: edit),
      );

  Future<void> _add() async {
    final r = await _form();
    if (r == null || !mounted) return;
    final b = AppScope.read(context).addBranch(name: r.name, area: r.area, phone: r.phone);
    nvToast(context, 'เพิ่มสาขา ${b.name} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _edit(Branch b) async {
    final r = await _form(edit: b);
    if (r == null || !mounted) return;
    final store = AppScope.read(context);
    store.log('branch.edit', r.name == b.name ? b.name : '${b.name} → ${r.name}');
    store.updateBranch(b, name: r.name, area: r.area, phone: r.phone);
    nvToast(context, 'บันทึกสาขา ${b.name} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _makeCurrent(Branch b) async {
    final ok = await showNvConfirm(
      context,
      title: 'ใช้เครื่องนี้ที่ "${b.name}"?',
      message: 'ชื่อสาขาบนใบเสร็จ รายงาน และงบจะเปลี่ยนเป็น "${b.name}" ตั้งแต่บิลถัดไป (บิลเก่าไม่เปลี่ยน)',
      confirmLabel: 'ตั้งเป็นสาขาของเครื่องนี้',
      danger: false,
      art: 'branch',
    );
    if (!ok || !mounted) return;
    final mgr = await showManagerPin(context, reason: 'เปลี่ยนสาขาของเครื่องนี้เป็น ${b.name}');
    if (mgr == null || !mounted) return;
    AppScope.read(context).setCurrentBranch(b);
    nvToast(context, 'เครื่องนี้อยู่สาขา ${b.name} แล้ว', kind: NvToastKind.success);
  }

  Future<void> _delete(Branch b) async {
    if (b.isCurrent) {
      nvToast(context, 'ลบสาขาที่เครื่องนี้ใช้งานอยู่ไม่ได้ — ตั้งสาขาอื่นก่อน', kind: NvToastKind.error);
      return;
    }
    final ok = await showNvConfirm(
      context,
      title: 'ลบสาขา "${b.name}"?',
      message: 'ลบออกจากรายการสาขาในเครื่องนี้ (บิลที่บันทึกไว้แล้วไม่ถูกลบ)',
      confirmLabel: 'ลบสาขา',
    );
    if (!ok || !mounted) return;
    final store = AppScope.read(context);
    try {
      store.log('branch.remove', b.name);
      store.removeBranch(b);
      nvToast(context, 'ลบสาขา ${b.name} แล้ว', kind: NvToastKind.success);
    } on StateError catch (e) {
      nvToast(context, e.message, kind: NvToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final branches = store.branches;
    final current = store.currentBranch;
    final others = branches.where((b) => !b.isCurrent).toList();

    return NvScaffold(
      title: 'หลายสาขา',
      eyebrow: 'สำนักงานใหญ่',
      subtitle: '${store.shopName} · ${branches.length} สาขา',
      art: 'branch',
      actions: [NvButton.gold('เพิ่มสาขา', icon: NvIcons.plus, size: NvButtonSize.sm, onPressed: _add)],
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 3 : (w >= 760 ? 2 : 1);
        final cardW = (w - (cols - 1) * 14) / cols;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _SyncCard(store: store),
            const SizedBox(height: 16),
            if (current != null) ...[
              _CurrentBranch(store: store, branch: current, onEdit: () => _edit(current)),
              const SizedBox(height: 18),
            ],
            if (branches.isEmpty)
              NvSheet(
                child: NvEmptyState(
                  mascot: 'welcome',
                  title: 'ยังไม่มีข้อมูลสาขา',
                  message: 'เพิ่มสาขาแรกของร้าน แล้วตั้งให้เป็นสาขาของเครื่องนี้ เพื่อให้ชื่อสาขาแสดงบนใบเสร็จและรายงาน',
                  actionLabel: 'เพิ่มสาขา',
                  actionIcon: NvIcons.plus,
                  onAction: _add,
                ),
              )
            else ...[
              NvSectionTitle('สาขาอื่นของร้าน', trailing: '${others.length} สาขา', icon: NvIcons.store),
              if (others.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('ยังไม่มีสาขาอื่น — กด "เพิ่มสาขา" เพื่อบันทึกสาขาเพิ่ม', style: Nv.ui(13, color: Nv.ink3)),
                )
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final b in others)
                      SizedBox(
                        width: cardW,
                        child: _BranchCard(
                          branch: b,
                          onEdit: () => _edit(b),
                          onMakeCurrent: () => _makeCurrent(b),
                          onDelete: () => _delete(b),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _SyncCard extends StatelessWidget {
  final PosStore store;
  const _SyncCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final sync = store.sync;
    Widget body(SyncState? st) {
      final paired = store.auth?.isServerPaired ?? false;
      final tint = switch (st) {
        SyncState.idle => NvTint.jade,
        SyncState.syncing => NvTint.sapphire,
        SyncState.offline => NvTint.amber,
        SyncState.error => NvTint.lacquer,
        _ => NvTint.neutral,
      };
      return Stack(
        children: [
          NvNightCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: LayoutBuilder(builder: (context, c) {
              final narrow = c.maxWidth < 560;
              final text = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ภาพรวมทุกสาขาอยู่บนเซิร์ฟเวอร์ Thai Prompt', style: Nv.display(18, color: Nv.onNight)),
                  const SizedBox(height: 4),
                  Text(
                    'เครื่องนี้แสดงยอดขายจริงได้เฉพาะสาขาของตัวเอง และส่งบิลขึ้นเซิร์ฟเวอร์เมื่อจับคู่แล้ว '
                    'ยอดของสาขาอื่นดูได้ที่หลังบ้าน thaiprompt.online — แอปนี้จะไม่แสดงตัวเลขที่ไม่ได้มาจากบิลจริง',
                    style: Nv.ui(12.5, color: Nv.onNight2, height: 1.45),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      NvBadge(st == null ? 'ไม่มีระบบซิงก์' : st.label, tint: tint),
                      NvBadge(paired ? 'จับคู่แล้ว · ${store.auth?.session?.name ?? ''}' : 'ยังไม่จับคู่เซิร์ฟเวอร์',
                          tint: paired ? NvTint.jade : NvTint.amber),
                      if (sync != null && sync.pendingCount > 0) NvBadge('รอส่ง ${sync.pendingCount} บิล', tint: NvTint.amber),
                      if (sync?.lastSyncAt != null)
                        Text('ซิงก์ล่าสุด ${thaiDateTime(sync!.lastSyncAt!)}', style: Nv.ui(11.5, color: Nv.onNight3)),
                    ],
                  ),
                ],
              );
              final button = paired && sync != null
                  ? NvButton.gold('ซิงก์ตอนนี้', icon: NvIcons.sync, size: NvButtonSize.sm, loading: st == SyncState.syncing, onPressed: () => sync.syncNow())
                  : NvButton.ghost('ตั้งค่าเซิร์ฟเวอร์', icon: NvIcons.server, size: NvButtonSize.sm, onNight: true, onPressed: () => context.go('/settings'));
              if (narrow) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 12), button]);
              }
              return Row(
                children: [
                  NvArt.icon('sync', size: 60),
                  const SizedBox(width: 14),
                  Expanded(child: text),
                  const SizedBox(width: 14),
                  button,
                ],
              );
            }),
          ),
          const NvKanokCorners(size: 44, opacity: 0.45, inset: EdgeInsets.all(3), bottom: false),
        ],
      );
    }

    if (sync == null) return body(null);
    return ListenableBuilder(listenable: sync, builder: (context, _) => body(sync.state));
  }
}

class _CurrentBranch extends StatelessWidget {
  final PosStore store;
  final Branch branch;
  final VoidCallback onEdit;
  const _CurrentBranch({required this.store, required this.branch, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final sales = store.todaySales;
    final bills = store.todayOrderCount;
    final avg = bills == 0 ? 0 : (sales / bills).round();
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(branch.name, style: Nv.display(21)),
            const NvBadge('เครื่องนี้', tint: NvTint.gold, icon: NvIcons.mapPin),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          [if (branch.area.isNotEmpty) branch.area, if (branch.phone.isNotEmpty) 'โทร ${phoneFmt(branch.phone)}'].join(' · ').ifEmpty('ยังไม่ระบุพื้นที่/เบอร์โทร'),
          style: Nv.ui(12.5, color: Nv.ink3),
        ),
      ],
    );
    final stats = Wrap(
      spacing: 22,
      runSpacing: 10,
      children: [
        _stat('ยอดขายวันนี้', baht(sales)),
        _stat('บิลวันนี้', groupDigits(bills)),
        _stat('เฉลี่ย/บิล', baht(avg)),
        _stat('คิวครัว', groupDigits(store.kitchenQueueCount)),
      ],
    );
    return NvSheet(
      goldEdge: true,
      selected: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 720;
        final edit = NvButton.soft('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: onEdit);
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [NvArt.icon('branch', size: 54), const SizedBox(width: 12), Expanded(child: info)]),
              const SizedBox(height: 14),
              stats,
              const SizedBox(height: 12),
              edit,
            ],
          );
        }
        return Row(
          children: [
            NvArt.icon('branch', size: 72),
            const SizedBox(width: 14),
            Expanded(flex: 4, child: info),
            Expanded(flex: 5, child: stats),
            edit,
          ],
        );
      }),
    );
  }

  Widget _stat(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v, style: Nv.money(18)),
          Text(k, style: Nv.ui(11.5, color: Nv.ink3)),
        ],
      );
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

class _BranchCard extends StatelessWidget {
  final Branch branch;
  final VoidCallback onEdit;
  final VoidCallback onMakeCurrent;
  final VoidCallback onDelete;
  const _BranchCard({required this.branch, required this.onEdit, required this.onMakeCurrent, required this.onDelete});

  @override
  Widget build(BuildContext context) => NvSheet(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                NvArt.icon('branch', size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(15.5, weight: FontWeight.w700)),
                      Text(branch.area.ifEmpty('ไม่ระบุพื้นที่'), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12, color: Nv.ink3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(NvIcons.phone, size: 12, color: Nv.goldInk),
                const SizedBox(width: 8),
                Text(branch.phone.isEmpty ? 'ไม่มีเบอร์โทร' : phoneFmt(branch.phone), style: Nv.money(12.5, color: Nv.ink2, weight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(NvIcons.cloud, size: 12, color: Nv.ink4),
                const SizedBox(width: 8),
                Expanded(child: Text('ยอดขายของสาขานี้ดูได้จากเซิร์ฟเวอร์', style: Nv.ui(12, color: Nv.ink3))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                NvButton.soft('แก้ไข', icon: NvIcons.edit, size: NvButtonSize.sm, onPressed: onEdit),
                NvButton.ghost('ใช้กับเครื่องนี้', icon: NvIcons.mapPin, size: NvButtonSize.sm, onPressed: onMakeCurrent),
                NvButton.danger('ลบ', icon: NvIcons.trash, size: NvButtonSize.sm, onPressed: onDelete),
              ],
            ),
          ],
        ),
      );
}

/// Add/edit form — owns its controllers (disposed with the dialog body).
class _BranchForm extends StatefulWidget {
  final Branch? edit;
  const _BranchForm({this.edit});

  @override
  State<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends State<_BranchForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _area = TextEditingController(text: widget.edit?.area ?? '');
  late final _phone = TextEditingController(text: widget.edit?.phone ?? '');
  bool _done = false; // a double-tap must not pop the page under the dialog

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (_done || !(_key.currentState?.validate() ?? false)) return;
    _done = true;
    Navigator.of(context).pop<_BranchInput>((name: _name.text.trim(), area: _area.text.trim(), phone: _phone.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.read(context);
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NvField(
            label: 'ชื่อสาขา *',
            controller: _name,
            icon: NvIcons.store,
            autofocus: true,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'กรุณาใส่ชื่อสาขา';
              if (t.length > 60) return 'ชื่อยาวเกิน 60 ตัวอักษร';
              final dup = store.branches.any((b) => !identical(b, widget.edit) && b.name.trim().toLowerCase() == t.toLowerCase());
              return dup ? 'มีสาขาชื่อนี้แล้ว' : null;
            },
          ),
          const SizedBox(height: 12),
          NvField(label: 'พื้นที่ / ที่ตั้ง', controller: _area, icon: NvIcons.location, hint: 'เช่น สยาม · เชียงใหม่ นิมมาน'),
          const SizedBox(height: 12),
          NvField(
            label: 'เบอร์โทรสาขา',
            controller: _phone,
            icon: NvIcons.phone,
            keyboard: TextInputType.phone,
            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              return (t.length == 9 || t.length == 10) && t.startsWith('0') ? null : 'เบอร์โทร 9–10 หลัก ขึ้นต้นด้วย 0';
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(context).pop()),
              NvButton.gold(widget.edit == null ? 'เพิ่มสาขา' : 'บันทึก', icon: NvIcons.check, onPressed: _submit),
            ],
          ),
        ],
      ),
    );
  }
}

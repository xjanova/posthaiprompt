// Thaiprompt POS — Self-order landing (/self-order?table=7) · table kiosk.
//
// The table tablet's home: reads ?table= and points the kiosk at it (after
// the frame — never during build). Shows the real table (zone · seats), the
// table's open tickets and unpaid bill, and the customer actions:
//   เริ่มสั่งอาหาร → /cust/menu · ตะกร้าของฉัน → /cust/cart
//   เรียกพนักงาน / ยกเลิกการเรียก → store.setCallWaiter
//   ดูสถานะออเดอร์ → /order-status?table=…
// Without a table, a staff-only picker (manager PIN, always asked) chooses one
// from store.tables. Staff can also long-press the table badge to change it.
//
// by xman studio

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/extra_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'cust_menu_screen.dart';

class SelfOrderScreen extends StatefulWidget {
  const SelfOrderScreen({super.key});

  @override
  State<SelfOrderScreen> createState() => _SelfOrderScreenState();
}

class _SelfOrderScreenState extends State<SelfOrderScreen> {
  int? _scheduledTable;

  /// Apply ?table= to the store once per value, after this frame.
  void _syncTableParam(PosStore store, int? param) {
    if (param == null || param == _scheduledTable) return;
    _scheduledTable = param;
    if (store.selfTable == param) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).setSelfTable(param);
    });
  }

  /// Staff-only: choose (or clear) the table this kiosk orders for.
  Future<void> _pickTable() async {
    final approver = await showManagerPin(context, reason: 'ตั้งค่าโต๊ะสำหรับเครื่องสั่งอาหารนี้', alwaysAsk: true);
    if (approver == null || !mounted) return;
    final store = AppScope.read(context);
    final tables = List<TableInfo>.of(store.tables)..sort((a, b) => a.number.compareTo(b.number));
    final current = store.selfTable;
    final picked = await showNvDialog<int>(
      context,
      title: 'เลือกโต๊ะ',
      subtitle: 'ลูกค้าที่ใช้เครื่องนี้จะสั่งอาหารเข้าโต๊ะที่เลือก',
      art: 'table',
      maxWidth: 600,
      body: Builder(
        builder: (ctx) => tables.isEmpty
            ? Text(
                'ยังไม่มีโต๊ะในผังร้าน\nเพิ่มโต๊ะได้ที่เมนู โต๊ะ → ออกแบบผังโต๊ะ',
                textAlign: TextAlign.center,
                style: Nv.ui(14.5, color: Nv.ink2, height: 1.5),
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in tables)
                    SizedBox(
                      width: 116,
                      child: NvSheet(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        selected: t.number == current,
                        onTap: () => Navigator.of(ctx).pop(t.number),
                        child: Column(
                          children: [
                            Text('โต๊ะ', style: Nv.ui(12.5, color: Nv.ink3)),
                            Text('${t.number}', style: Nv.money(26)),
                            Text('${t.seats} ที่นั่ง · ${t.zone}',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(11.5, color: Nv.ink3)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      actions: (ctx) => [
        if (current != null)
          NvButton.ghost('ไม่ระบุโต๊ะ', icon: NvIcons.xmark, onPressed: () => Navigator.of(ctx).pop(0)),
        NvButton.soft('ยกเลิก', onPressed: () => Navigator.of(ctx).pop()),
      ],
    );
    if (picked == null || !mounted) return;
    final s = AppScope.read(context);
    if (picked == 0) {
      s.setSelfTable(null);
      _scheduledTable = null;
      context.go('/self-order');
      return;
    }
    s.setSelfTable(picked);
    s.log('self.table', 'ตั้งเครื่องสั่งอาหารเป็นโต๊ะ $picked · อนุมัติโดย ${approver.name}');
    context.go('/self-order?table=$picked');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final raw = int.tryParse(GoRouterState.of(context).uri.queryParameters['table'] ?? '');
    final param = (raw != null && raw > 0) ? raw : null;
    _syncTableParam(store, param);
    final table = param ?? store.selfTable;

    final header = CustTopBar(
      eyebrow: 'สั่งอาหารด้วยตนเอง',
      title: store.shopName,
      subtitle: store.branch,
      actions: [
        if (table != null && store.selfCartCount > 0)
          NvIconButton(
            NvIcons.cart,
            size: 56,
            onNight: true,
            badge: store.selfCartCount,
            tooltip: 'ตะกร้าของฉัน',
            onPressed: () => context.go('/cust/cart'),
          ),
      ],
    );

    if (table == null) {
      return NvKiosk(
        child: Column(
          children: [
            header,
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: NvNightCard(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NvArt.mascot('search', height: 170),
                          const SizedBox(height: 10),
                          NvFoilText('ยังไม่ได้ระบุโต๊ะ', style: Nv.display(28, weight: FontWeight.w700), align: TextAlign.center),
                          const SizedBox(height: 6),
                          Text(
                            'กรุณาสแกน QR ที่โต๊ะ หรือให้พนักงานตั้งค่าโต๊ะสำหรับเครื่องนี้',
                            textAlign: TextAlign.center,
                            style: Nv.ui(15.5, color: Nv.onNight2, height: 1.5),
                          ),
                          const SizedBox(height: 18),
                          NvButton.gold('ตั้งค่าโต๊ะ (สำหรับพนักงาน)',
                              icon: NvIcons.lock, size: NvButtonSize.xl, expand: true, onPressed: _pickTable),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return NvKiosk(
      child: Column(
        children: [
          header,
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final panel = _ActionsPanel(store: store, table: table, onChangeTable: _pickTable);
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 6, child: _Hero(store: store, table: table, wide: true)),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: SingleChildScrollView(child: panel)),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                children: [
                  SizedBox(height: math.min(280, c.maxWidth * 0.62), child: _Hero(store: store, table: table, wide: false)),
                  const SizedBox(height: 16),
                  panel,
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Food-banner hero with the table number in gold foil.
class _Hero extends StatelessWidget {
  final PosStore store;
  final int table;
  final bool wide;
  const _Hero({required this.store, required this.table, required this.wide});

  @override
  Widget build(BuildContext context) {
    return NvGoldRim(
      radius: Nv.rXl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            NvAssets.art('food-banner'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const DecoratedBox(decoration: BoxDecoration(gradient: Nv.night)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Nv.navy950.withValues(alpha: 0.92), Nv.navy950.withValues(alpha: 0.45), Colors.transparent],
                stops: const [0, 0.5, 0.9],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(wide ? 34 : 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ยินดีต้อนรับ', style: Nv.eyebrow(color: Nv.gold300).copyWith(fontSize: wide ? 16 : 13)),
                const SizedBox(height: 4),
                NvFoilText('โต๊ะ $table', style: Nv.display(wide ? 76 : 48, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 380 : 230),
                  child: Text(
                    'เลือกเมนู ส่งเข้าครัว และชำระเงินที่เคาน์เตอร์ได้ทันที',
                    style: Nv.ui(wide ? 18 : 14.5, color: Nv.onNight, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const NvKanokCorners(size: 72, opacity: 0.8, inset: EdgeInsets.all(4)),
        ],
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  final PosStore store;
  final int table;
  final VoidCallback onChangeTable;
  const _ActionsPanel({required this.store, required this.table, required this.onChangeTable});

  @override
  Widget build(BuildContext context) {
    final info = store.tableByNumber(table);
    final open = store.openTicketsForTable(table);
    final bill = store.tableBillTotal(table);
    final last = store.lastSelfTicket;
    final statusRoute = (last != null && last.tableNumber == table)
        ? '/order-status?ticket=${Uri.encodeQueryComponent(last.id)}&table=$table'
        : '/order-status?table=$table';

    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              NvArt.mascot('welcome', height: 130, width: 110),
              const SizedBox(width: 12),
              Expanded(
                child: Tooltip(
                  message: 'พนักงาน: กดค้างเพื่อเปลี่ยนโต๊ะ',
                  child: GestureDetector(
                    onLongPress: onChangeTable,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('โต๊ะของคุณ', style: Nv.eyebrow(color: Nv.gold300)),
                        NvFoilText('โต๊ะ $table', style: Nv.display(40, weight: FontWeight.w700)),
                        if (info != null)
                          Text('${info.zone} · ${info.seats} ที่นั่ง', style: Nv.ui(14.5, color: Nv.onNight2))
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: NvBadge('ยังไม่พบโต๊ะ $table ในผังร้าน', tint: NvTint.amber, icon: NvIcons.warning),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
          const SizedBox(height: 8),
          if (open.isNotEmpty) ...[
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(Nv.rMd),
              child: InkWell(
                borderRadius: BorderRadius.circular(Nv.rMd),
                onTap: () => context.go(statusRoute),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Nv.rMd),
                    border: Border.all(color: Nv.lineNight),
                  ),
                  child: Row(
                    children: [
                      const Icon(NvIcons.fire, size: 18, color: Nv.gold300),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('ส่งเข้าครัวแล้ว ${open.length} ออเดอร์', style: Nv.ui(15, color: Nv.onNight, weight: FontWeight.w600)),
                      ),
                      Text(baht(bill), style: Nv.money(18, color: Nv.gold200)),
                      const SizedBox(width: 6),
                      const Icon(NvIcons.chevronRight, size: 14, color: Nv.onNight3),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          NvButton.gold('เริ่มสั่งอาหาร',
              icon: NvIcons.utensils, size: NvButtonSize.xl, expand: true, onPressed: () => context.go('/cust/menu')),
          if (store.selfCartCount > 0) ...[
            const SizedBox(height: 10),
            NvButton.ghost(
              'ตะกร้าของฉัน · ${store.selfCartCount} รายการ · ${baht(store.selfCartTotal)}',
              onNight: true,
              icon: NvIcons.cart,
              size: NvButtonSize.xl,
              expand: true,
              onPressed: () => context.go('/cust/cart'),
            ),
          ],
          const SizedBox(height: 10),
          CustCallWaiterButton(table: table, expand: true),
          const SizedBox(height: 10),
          NvButton.ghost('ดูสถานะออเดอร์',
              onNight: true, icon: NvIcons.listCheck, size: NvButtonSize.xl, expand: true, onPressed: () => context.go(statusRoute)),
        ],
      ),
    );
  }
}

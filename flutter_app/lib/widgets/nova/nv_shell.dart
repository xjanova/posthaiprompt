// Thaiprompt POS — Nova app shell.
//
// NvScaffold — every staff-facing page: navy rail (brand mark, role-filtered
//   nav, staff menu) + top bar (page title, actions, shift chip, sync pill,
//   live clock, lock) over an ivory work surface. Collapses to a bottom nav
//   on narrow screens (phones / small tablets).
// NvKiosk — customer-facing pages (customer display, self-order, order
//   status): full-bleed night backdrop, no staff chrome; long-press the logo
//   for 1.5 s + manager PIN to leave kiosk mode.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/sync/sync_service.dart';
import '../../models/extra_models.dart';
import '../../state/app_scope.dart';
import '../../theme/nv_icons.dart';
import '../../theme/nv_tokens.dart';
import 'nv_art.dart';
import 'nv_backdrop.dart';
import 'nv_bits.dart';
import 'nv_buttons.dart';
import 'nv_dialogs.dart';

/// One destination in the rail.
class NvNavItem {
  final String route;
  final String label;
  final IconData icon;
  final bool managerOnly;
  final Set<StaffRole>? roles; // null = everyone except kitchen-only screens rule
  const NvNavItem(this.route, this.label, this.icon, {this.managerOnly = false, this.roles});
}

const List<NvNavItem> kRailItems = [
  NvNavItem('/home', 'หน้าหลัก', NvIcons.home),
  NvNavItem('/cashier', 'ขาย', NvIcons.cashier, roles: {StaffRole.owner, StaffRole.manager, StaffRole.cashier, StaffRole.waiter}),
  NvNavItem('/tablet/floor', 'โต๊ะ', NvIcons.chair, roles: {StaffRole.owner, StaffRole.manager, StaffRole.cashier, StaffRole.waiter}),
  NvNavItem('/display/kitchen', 'ครัว', NvIcons.fire),
  NvNavItem('/orders', 'บิล', NvIcons.receipt, roles: {StaffRole.owner, StaffRole.manager, StaffRole.cashier}),
  NvNavItem('/menu-editor', 'เมนู', NvIcons.menuBook, managerOnly: true),
  NvNavItem('/inventory', 'สต็อก', NvIcons.inventory, roles: {StaffRole.owner, StaffRole.manager, StaffRole.cashier}),
  NvNavItem('/crm', 'สมาชิก', NvIcons.members, roles: {StaffRole.owner, StaffRole.manager, StaffRole.cashier}),
  NvNavItem('/dashboard', 'รายงาน', NvIcons.chartLine, managerOnly: true),
  NvNavItem('/shift', 'กะ', NvIcons.clock, roles: {StaffRole.owner, StaffRole.manager, StaffRole.cashier}),
  NvNavItem('/settings', 'ตั้งค่า', NvIcons.settings, managerOnly: true),
];

bool nvCanSee(NvNavItem it, Staff? s) {
  if (s == null) return false;
  if (it.managerOnly) return s.role.isManager;
  if (it.roles != null) return it.roles!.contains(s.role);
  return true;
}

class NvScaffold extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? art; // 3D icon key next to the title
  final List<Widget> actions;
  final Widget body;
  final EdgeInsets padding;
  final bool showTopBar;
  final Widget? floating;
  final NvTone tone;

  const NvScaffold({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.subtitle,
    this.art,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(24, 6, 24, 22),
    this.showTopBar = true,
    this.floating,
    this.tone = NvTone.day,
  });

  @override
  Widget build(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    return NvPageFrame(
      route: route,
      child: Scaffold(
        backgroundColor: tone == NvTone.night ? Nv.navy900 : Nv.ivory,
        floatingActionButton: floating,
        body: LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 760;
            final content = Column(
              children: [
                if (showTopBar)
                  NvTopBar(
                    title: title,
                    eyebrow: eyebrow,
                    subtitle: subtitle,
                    art: art,
                    actions: actions,
                    compact: narrow,
                    night: tone == NvTone.night,
                  ),
                Expanded(
                  child: Padding(padding: narrow ? const EdgeInsets.fromLTRB(12, 4, 12, 12) : padding, child: body),
                ),
              ],
            );
            final surface = tone == NvTone.night ? NvBackdrop.night(kanok: false, child: content) : NvBackdrop.day(child: content);
            if (narrow) {
              return Column(
                children: [
                  Expanded(child: SafeArea(bottom: false, child: surface)),
                  NvBottomNav(current: route),
                ],
              );
            }
            return Row(
              children: [
                NvRail(current: route),
                // tablets in landscape: keep the top bar clear of the status bar / cut-outs
                Expanded(child: SafeArea(left: false, child: surface)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Navy side rail.
class NvRail extends StatelessWidget {
  final String current;
  const NvRail({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.currentStaff;
    final items = kRailItems.where((i) => nvCanSee(i, me)).toList();
    final kq = store.kitchenQueueCount;
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Nv.navy800, Nv.navy950]),
        border: Border(right: BorderSide(color: Nv.lineNight)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Tooltip(
              message: store.shopName,
              child: InkWell(
                onTap: () => context.go('/home'),
                borderRadius: BorderRadius.circular(40),
                child: Stack(
                  alignment: Alignment.center,
                  children: [NvArt(NvAssets.medallionWeb, width: 64, height: 64), NvArt(NvAssets.mark, width: 30, height: 30)],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('POS', style: Nv.eyebrowLatin(color: Nv.gold300).copyWith(fontSize: 10, letterSpacing: 3)),
            const SizedBox(height: 10),
            const NvKanokDivider(width: 70, thin: true, opacity: 0.7),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final it in items)
                      _RailButton(
                        item: it,
                        active: current == it.route || (it.route != '/home' && current.startsWith('${it.route}/')),
                        badge: it.route == '/display/kitchen' ? kq : (it.route == '/inventory' ? store.lowStockProducts.length : 0),
                      ),
                  ],
                ),
              ),
            ),
            if (me != null) _StaffMenu(staff: me),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  final NvNavItem item;
  final bool active;
  final int badge;
  const _RailButton({required this.item, required this.active, this.badge = 0});

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.active;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => context.go(widget.item.route),
          child: AnimatedContainer(
            duration: Nv.fast,
            height: 60,
            decoration: BoxDecoration(
              gradient: a ? Nv.btnGold : null,
              color: a ? null : (_hover ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              boxShadow: a ? Nv.goldGlow(0.8) : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.item.icon, size: 18, color: a ? const Color(0xFF1A1405) : (_hover ? Nv.gold200 : Nv.onNight2)),
                      const SizedBox(height: 5),
                      Text(
                        widget.item.label,
                        style: TextStyle(
                          fontFamily: Nv.fontUi,
                          fontSize: 11.5,
                          fontWeight: a ? FontWeight.w700 : FontWeight.w500,
                          color: a ? const Color(0xFF1A1405) : Nv.onNight2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.badge > 0)
                  Positioned(
                    top: 4,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: a ? Nv.navy800 : Nv.lacquer,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Nv.navy900, width: 1.5),
                      ),
                      child: Text(
                        '${widget.badge > 99 ? '99+' : widget.badge}',
                        style: const TextStyle(fontFamily: Nv.fontUi, fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Staff avatar → menu: lock screen · switch user · clock out & log out.
class _StaffMenu extends StatelessWidget {
  final Staff staff;
  const _StaffMenu({required this.staff});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '${staff.name} · ${staff.role.label}',
      offset: const Offset(80, -10),
      onSelected: (v) => nvStaffAction(context, v),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            '${staff.name}\n${staff.role.label}',
            style: Nv.ui(13, color: Nv.ink2, weight: FontWeight.w600),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'lock', child: _menuRow(NvIcons.lock, 'ล็อกหน้าจอ / สลับผู้ใช้')),
        PopupMenuItem(value: 'clockout', child: _menuRow(NvIcons.logout, 'ออกกะงาน (ลงเวลาออก)')),
      ],
      child: Column(
        children: [
          NvAvatar(staff.initials, hue: staff.hue, size: 44, ring: true),
          const SizedBox(height: 4),
          SizedBox(
            width: 84,
            child: Text(
              staff.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Nv.ui(11, color: Nv.onNight2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData i, String t) => Row(
    children: [
      Icon(i, size: 14, color: Nv.goldInk),
      const SizedBox(width: 10),
      Text(t),
    ],
  );
}

/// Shared staff-menu actions (rail + bottom nav + top bar).
Future<void> nvStaffAction(BuildContext context, String action) async {
  final store = AppScope.read(context);
  if (action == 'lock') {
    store.logout();
    if (context.mounted) context.go('/login');
  } else if (action == 'clockout') {
    final ok = await showNvConfirm(
      context,
      title: 'ออกกะงาน?',
      message: 'ลงเวลาออกงานของ ${store.currentStaff?.name ?? ''} และกลับไปหน้าเข้าสู่ระบบ',
      confirmLabel: 'ออกกะงาน',
      danger: false,
    );
    if (!ok || !context.mounted) return;
    store.logout(clockOut: true);
    context.go('/login');
  }
}

/// Bottom navigation for narrow layouts (first 4 allowed items + more).
class NvBottomNav extends StatelessWidget {
  final String current;
  const NvBottomNav({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = kRailItems.where((i) => nvCanSee(i, store.currentStaff)).take(4).toList();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Nv.navy800, Nv.navy900]),
        border: Border(top: BorderSide(color: Nv.lineNight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final it in items)
                Expanded(
                  child: _BottomItem(icon: it.icon, label: it.label, active: current == it.route, onTap: () => context.go(it.route)),
                ),
              Expanded(
                child: _BottomItem(icon: NvIcons.grid, label: 'เมนูทั้งหมด', active: false, onTap: () => context.go('/home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: Nv.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(gradient: active ? Nv.btnGold : null, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 17, color: active ? const Color(0xFF1A1405) : Nv.onNight2),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Nv.ui(10.5, color: active ? Nv.gold200 : Nv.onNight3, weight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Top bar: title block + actions + shift / sync / clock / lock.
class NvTopBar extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? art;
  final List<Widget> actions;
  final bool compact;
  final bool night;

  const NvTopBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.art,
    this.actions = const [],
    this.compact = false,
    this.night = false,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final lock = NvIconButton(
      NvIcons.lock,
      tooltip: 'ล็อกหน้าจอ',
      onNight: night,
      onPressed: store.currentStaff == null ? null : () => nvStaffAction(context, 'lock'),
    );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null && !compact) Text(eyebrow!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.eyebrow(color: night ? Nv.gold300 : Nv.goldInk)),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.display(compact ? 20 : 25, color: night ? Nv.onNight : Nv.ink)),
        if (subtitle != null && !compact)
          Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(13, color: night ? Nv.onNight3 : Nv.ink3)),
      ],
    );

    // Phones / narrow windows: title + lock on one row, actions on a second
    // row that scrolls sideways instead of overflowing.
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: titleBlock), const SizedBox(width: 8), lock]),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), actions[i]]]),
              ),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Row(
          children: [
            if (art != null && w >= 900) ...[NvArt.icon(art!, size: 54), const SizedBox(width: 12)],
            Expanded(child: titleBlock),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 10),
              // capped width: long action sets wrap onto a second line rather than overflow
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: w * (w >= 1200 ? 0.5 : 0.42)),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ),
            ],
            const SizedBox(width: 14),
            NvShiftChip(night: night),
            if (w >= 1050) ...[const SizedBox(width: 8), NvSyncPill(night: night)],
            if (w >= 900) ...[const SizedBox(width: 10), NvClock(night: night)],
            const SizedBox(width: 8),
            lock,
          ],
        ),
      );
    });
  }
}

/// Shift status chip → /shift.
class NvShiftChip extends StatelessWidget {
  final bool night;
  const NvShiftChip({super.key, this.night = false});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final open = store.hasOpenShift;
    return Tooltip(
      message: open ? 'เปิดกะตั้งแต่ ${hm(store.currentShift!.openedAt)}' : 'ยังไม่เปิดกะ — แตะเพื่อเปิดกะ',
      child: InkWell(
        borderRadius: BorderRadius.circular(Nv.rPill),
        onTap: () => context.go('/shift'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: open ? (night ? Nv.jade.withValues(alpha: 0.18) : Nv.jadeTint) : (night ? Nv.gold400.withValues(alpha: 0.14) : Nv.amberTint),
            borderRadius: BorderRadius.circular(Nv.rPill),
            border: Border.all(color: open ? Nv.jade.withValues(alpha: 0.4) : Nv.amber.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(NvIcons.clock, size: 13, color: open ? Nv.jade : Nv.amber),
              const SizedBox(width: 7),
              Text(
                open ? 'กะเปิด ${hm(store.currentShift!.openedAt)}' : 'ยังไม่เปิดกะ',
                style: Nv.ui(
                  12.5,
                  color: open ? (night ? Nv.jadeLight : const Color(0xFF1F6B44)) : (night ? Nv.gold300 : const Color(0xFF8A5A00)),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sync status pill (tap = sync now, or open settings when not paired).
class NvSyncPill extends StatelessWidget {
  final bool night;
  const NvSyncPill({super.key, this.night = false});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final sync = store.sync;
    if (sync == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final st = sync.state;
        final (color, icon) = switch (st) {
          SyncState.idle => (Nv.jade, NvIcons.cloud),
          SyncState.syncing => (Nv.sapphire, NvIcons.sync),
          SyncState.offline => (Nv.amber, NvIcons.plugX),
          SyncState.error => (Nv.lacquer, NvIcons.warning),
          SyncState.disabled => (Nv.ink4, NvIcons.cloud),
        };
        return Tooltip(
          message: st == SyncState.disabled ? 'ยังไม่จับคู่เครื่องกับเซิร์ฟเวอร์ — แตะเพื่อตั้งค่า' : '${st.label} · แตะเพื่อซิงก์ทันที',
          child: InkWell(
            borderRadius: BorderRadius.circular(Nv.rPill),
            onTap: () {
              if (st == SyncState.disabled) {
                if (store.isManager) context.go('/settings');
              } else {
                sync.syncNow();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: night ? Colors.white.withValues(alpha: 0.05) : Nv.paper,
                borderRadius: BorderRadius.circular(Nv.rPill),
                border: Border.all(color: night ? Nv.lineNight : Nv.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 6),
                  Text(
                    st == SyncState.disabled ? 'ออฟไลน์' : st.label,
                    style: Nv.ui(12, color: night ? Nv.onNight2 : Nv.ink2, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Live clock (HH:mm + Thai date), ticks once a minute aligned to the minute.
class NvClock extends StatefulWidget {
  final bool night;
  final bool large;
  const NvClock({super.key, this.night = false, this.large = false});

  @override
  State<NvClock> createState() => _NvClockState();
}

class _NvClockState extends State<NvClock> {
  Timer? _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final n = DateTime.now();
    _t = Timer(Duration(seconds: 60 - n.second), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.night;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(hm(_now), style: Nv.money(widget.large ? 34 : 17, color: n ? Nv.gold200 : Nv.ink)),
        Text(thaiDate(_now), style: Nv.ui(widget.large ? 14 : 11, color: n ? Nv.onNight3 : Nv.ink3)),
      ],
    );
  }
}

/// Customer-facing frame. [exitRoute] is where a manager lands after unlocking.
class NvKiosk extends StatelessWidget {
  final Widget child;
  final String exitRoute;
  final String? image;
  final double imageOpacity;
  final bool showLogo;

  const NvKiosk({super.key, required this.child, this.exitRoute = '/home', this.image, this.imageOpacity = 0.35, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return NvPageFrame(
      route: GoRouterState.of(context).matchedLocation,
      kiosk: true,
      child: Scaffold(
        backgroundColor: Nv.navy950,
        body: NvBackdrop.night(
          image: image,
          imageOpacity: imageOpacity,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: child),
                if (showLogo) Positioned(top: 10, left: 14, child: _KioskExit(exitRoute: exitRoute)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the Android back button / back gesture leads from each page.
/// Navigation uses `context.go` (no stack), so without this the system back
/// would close the app from any screen.
const Map<String, String> kBackTargets = {
  '/payment': '/cashier',
  '/payment/nfc': '/payment',
  '/receipt': '/cashier',
  '/bill/create': '/cashier',
  '/refund': '/orders',
  '/tax-invoice': '/orders',
  '/floor-designer': '/tablet/floor',
  '/stock': '/inventory',
  '/po': '/inventory',
  '/barcode': '/menu-editor',
  '/tiers': '/crm',
  '/shipping/labels': '/delivery',
  '/shipping/providers': '/delivery',
  '/staff': '/settings',
  '/admin': '/settings',
  // customer-facing kiosk: back stays inside the customer flow
  '/cust/item': '/cust/menu',
  '/cust/cart': '/cust/menu',
  '/cust/confirm': '/cust/menu',
  '/cust/menu': '/self-order',
  '/order-status': '/self-order',
};

/// Kiosk pages where back does nothing (customers can't leave kiosk mode).
const Set<String> kKioskRoots = {'/self-order', '/display/customer'};

DateTime? _lastBackAtHome;

/// Page wrapper shared by every Nova frame:
///  • Android back → parent page (see [kBackTargets]); at home, press twice to exit.
///  • kiosk pages never leave the customer flow via back.
///  • clamps the system font scale (1.0–1.15×) so phones with "large text"
///    don't break dense POS layouts.
class NvPageFrame extends StatelessWidget {
  final String route;
  final Widget child;
  final bool kiosk;
  const NvPageFrame({super.key, required this.route, required this.child, this.kiosk = false});

  void _onBack(BuildContext context) {
    final target = kBackTargets[route];
    if (target != null) {
      context.go(target);
      return;
    }
    if (kiosk) return; // stay — exit kiosk only via long-press logo + manager PIN
    if (route != '/home') {
      context.go('/home'); // the launcher reaches every module the role may open
      return;
    }
    final now = DateTime.now();
    if (_lastBackAtHome != null && now.difference(_lastBackAtHome!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackAtHome = now;
    nvToast(context, 'กดย้อนกลับอีกครั้งเพื่อออกจากแอป');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack(context);
      },
      child: MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, maxScaleFactor: 1.15, child: child),
    );
  }
}

class _KioskExit extends StatefulWidget {
  final String exitRoute;
  const _KioskExit({required this.exitRoute});

  @override
  State<_KioskExit> createState() => _KioskExitState();
}

class _KioskExitState extends State<_KioskExit> {
  Timer? _hold;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  Future<void> _unlock() async {
    final s = await showManagerPin(context, reason: 'ออกจากโหมดหน้าจอลูกค้า', alwaysAsk: true, kiosk: true);
    if (s != null && mounted) context.go(widget.exitRoute);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hold = Timer(const Duration(milliseconds: 1500), _unlock),
      onTapUp: (_) => _hold?.cancel(),
      onTapCancel: () => _hold?.cancel(),
      child: Opacity(opacity: 0.9, child: NvArt(NvAssets.logoOnDark, height: 34, width: 120)),
    );
  }
}

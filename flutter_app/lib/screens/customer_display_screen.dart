// Thaiprompt POS — Customer display (/display/customer) · counter 2nd screen.
//
// Mirrors the live COUNTER cart: lines with pictures, subtotal, discounts
// (with the store's discount note), VAT, the total in gold foil, the linked
// member (tier, points, points this bill earns) and — when a PromptPay id is
// set — a real EMVCo PromptPay QR for the exact amount.
// Empty cart → idle welcome (shop name, greeting, mascot, live clock and the
// promotions active right now, rotating). For 20 s after a checkout → a
// thank-you card with the total and, for cash, the change.
// A 5 s timer refreshes the time-based states (thank-you expiry, promotion
// windows, carousel).
//
// by xman studio

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/payments/promptpay.dart';
import '../models/catalog_models.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../state/pos_store.dart';
import '../widgets/nova/nova.dart';
import 'cust_menu_screen.dart';

const _kThanksFor = Duration(seconds: 20);

class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  Timer? _timer;
  int _tick = 0;
  final _scroll = ScrollController();
  int _lastLen = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Keep the newest line in view when the cashier adds items.
  void _followNewest(int len) {
    if (len > _lastLen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Nv.med, curve: Nv.ease);
      });
    }
    _lastLen = len;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    if (store.cart.isNotEmpty) {
      _followNewest(store.cart.length);
      return _live(store);
    }
    _lastLen = 0;
    final last = store.lastOrder;
    if (last != null) {
      final age = now.difference(last.createdAt);
      if (!age.isNegative && age < _kThanksFor) return _thanks(store, last);
    }
    return _idle(store, now);
  }

  // ─────────────────────────── live cart ───────────────────────────

  Widget _live(PosStore store) {
    final where = store.orderType == OrderType.dineIn && store.tableNumber != null
        ? 'โต๊ะ ${store.tableNumber}'
        : store.orderType.label;
    final header = CustTopBar(
      eyebrow: 'ตะกร้าของคุณ',
      title: store.shopName,
      subtitle: 'บิล ${store.openOrderId} · $where',
      actions: const [NvClock(night: true)],
    );
    return NvKiosk(
      child: Column(
        children: [
          header,
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final lines = _LinesCard(store: store, controller: _scroll);
              final right = <Widget>[
                if (store.linkedCustomer != null) ...[_MemberCard(store: store, customer: store.linkedCustomer!), const SizedBox(height: 14)],
                _TotalsCard(store: store, big: wide),
                ..._qr(store, wide ? 230 : 190),
              ];
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 11, child: lines),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 9,
                        child: SingleChildScrollView(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: lines),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: c.maxHeight * 0.58),
                      child: SingleChildScrollView(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Real PromptPay QR for the cart total (only with a valid shop id).
  List<Widget> _qr(PosStore store, double size) {
    final id = store.promptPayId.trim();
    if (id.isEmpty || !PromptPay.isValidId(id) || store.cartTotal <= 0) return const <Widget>[];
    final String payload;
    try {
      payload = PromptPay.payload(id, amountBaht: store.cartTotal.toDouble());
    } on ArgumentError {
      return const <Widget>[];
    }
    return [
      const SizedBox(height: 14),
      NvNightCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NvArt.icon('promptpay', size: 40),
                const SizedBox(width: 10),
                Flexible(child: Text('สแกนจ่ายด้วยพร้อมเพย์', style: Nv.ui(18, color: Nv.onNight, weight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Nv.rMd),
                border: Border.all(color: Nv.gold400, width: 2),
                boxShadow: Nv.goldGlow(0.6),
              ),
              child: QrImageView(
                data: payload,
                size: size,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                semanticsLabel: 'QR พร้อมเพย์ ${baht(store.cartTotal)}',
              ),
            ),
            const SizedBox(height: 10),
            Text(baht(store.cartTotal, decimals: true), style: Nv.money(22, color: Nv.gold200)),
            Text('บัญชีพร้อมเพย์ ${PromptPay.mask(id)}', style: Nv.ui(13, color: Nv.onNight3)),
          ],
        ),
      ),
    ];
  }

  // ─────────────────────────── thank you ───────────────────────────

  Widget _thanks(PosStore store, Order o) {
    final cash = o.method == PaymentMethod.cash && o.cashReceived > 0;
    final who = (o.customerName ?? '').trim();
    return NvKiosk(
      image: NvAssets.art('display-bg'),
      imageOpacity: 0.4,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 760;
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: Nv.navy950.withValues(alpha: 0.55))),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NvArt.mascot('cheer', height: math.min(wide ? 250 : 190, c.maxHeight * 0.34)),
                      const SizedBox(height: 6),
                      NvFoilText('ขอบคุณที่อุดหนุน', style: Nv.display(wide ? 48 : 34, weight: FontWeight.w700), align: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        who.isNotEmpty ? 'คุณ$who · บิล ${o.id}' : '${store.shopName} · บิล ${o.id}',
                        textAlign: TextAlign.center,
                        style: Nv.ui(17, color: Nv.onNight2),
                      ),
                      const SizedBox(height: 18),
                      Stack(
                        children: [
                          NvNightCard(
                            glow: true,
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                            child: Column(
                              children: [
                                Text('ยอดชำระ · ${o.method.receiptLabel}', style: Nv.ui(16, color: Nv.onNight2)),
                                FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(o.total), style: Nv.money(wide ? 56 : 44))),
                                if (cash) ...[
                                  const SizedBox(height: 8),
                                  const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _Figure(label: 'รับเงิน', value: baht(o.cashReceived))),
                                      Container(width: 1, height: 52, color: Nv.lineNight),
                                      Expanded(child: _Figure(label: 'เงินทอน', value: baht(o.change), gold: true)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const NvKanokCorners(size: 54, opacity: 0.7, inset: EdgeInsets.all(2)),
                        ],
                      ),
                      if (store.receiptFooter.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(store.receiptFooter.trim(), textAlign: TextAlign.center, style: Nv.ui(17, color: Nv.onNight2, height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ─────────────────────────── idle ───────────────────────────

  Widget _idle(PosStore store, DateTime now) {
    final promos = store.promotions.where((p) => p.activeAt(now)).toList();
    final greet = _greeting(now);
    return NvKiosk(
      image: NvAssets.art('display-bg'),
      imageOpacity: 0.6,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
        final textAlign = wide ? TextAlign.left : TextAlign.center;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: wide ? Alignment.centerLeft : Alignment.topCenter,
                    end: wide ? Alignment.centerRight : Alignment.bottomCenter,
                    colors: [Nv.navy950.withValues(alpha: 0.9), Nv.navy950.withValues(alpha: wide ? 0.25 : 0.7)],
                  ),
                ),
              ),
            ),
            const Positioned(top: 14, right: 22, child: NvClock(night: true, large: true)),
            if (wide)
              Positioned(
                right: 24,
                bottom: 0,
                child: NvArt.mascot('wai', height: c.maxHeight * 0.62),
              ),
            Align(
              alignment: wide ? const Alignment(-0.82, 0.15) : Alignment.center,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(wide ? 40 : 20, 80, wide ? 40 : 20, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? c.maxWidth * 0.55 : 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: align,
                    children: [
                      if (!wide) ...[NvArt.mascot('wai', height: math.min(190, c.maxHeight * 0.26)), const SizedBox(height: 8)],
                      Text(greet, textAlign: textAlign, style: Nv.ui(wide ? 22 : 18, color: Nv.gold300, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      NvFoilText(store.shopName, style: Nv.display(wide ? 64 : 40, weight: FontWeight.w700), align: textAlign),
                      if (store.branch.trim().isNotEmpty)
                        Text(store.branch, textAlign: textAlign, style: Nv.ui(wide ? 20 : 16, color: Nv.onNight2)),
                      const SizedBox(height: 10),
                      NvArt(NvAssets.kanokDivider, width: 300, height: 75, opacity: 0.9),
                      const SizedBox(height: 6),
                      Text(
                        'ยินดีต้อนรับ ขอให้มีความสุขกับมื้อนี้',
                        textAlign: textAlign,
                        style: Nv.ui(wide ? 20 : 16.5, color: Nv.onNight, height: 1.5),
                      ),
                      if (promos.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        _PromoCarousel(store: store, promos: promos, index: _tick % promos.length, center: !wide),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  static String _greeting(DateTime n) {
    final h = n.hour;
    if (h >= 5 && h < 12) return 'สวัสดีตอนเช้า';
    if (h >= 12 && h < 17) return 'สวัสดีตอนบ่าย';
    if (h >= 17 && h < 21) return 'สวัสดีตอนเย็น';
    return 'สวัสดีค่ะ';
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;
  const _Figure({required this.label, required this.value, this.gold = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label, style: Nv.ui(15, color: Nv.onNight2)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: gold ? NvFoilText(value, style: Nv.money(34)) : Text(value, style: Nv.money(26, color: Nv.onNight)),
          ),
        ],
      );
}

class _LinesCard extends StatelessWidget {
  final PosStore store;
  final ScrollController controller;
  const _LinesCard({required this.store, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cart = store.cart;
    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: NvSectionTitle('รายการสั่งซื้อ', trailing: '${store.cartItemCount} ชิ้น', onNight: true, icon: NvIcons.basket),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: cart.length,
              itemBuilder: (context, i) {
                final l = cart[i];
                final newest = i == cart.length - 1;
                final detail = custLineDetail(l);
                return AnimatedContainer(
                  duration: Nv.med,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: newest ? Nv.gold400.withValues(alpha: 0.09) : Colors.transparent,
                    borderRadius: BorderRadius.circular(Nv.rMd),
                    border: Border.all(color: newest ? Nv.lineNightStrong : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 62, height: 62, child: CustFoodPicture.product(l.product, icon: custCategoryIcon(store, l.product), soldOut: false)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.product.name,
                                maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(18, color: Nv.onNight, weight: FontWeight.w600)),
                            if (detail.isNotEmpty)
                              Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5, color: Nv.gold300)),
                            Text('${l.qty} × ${baht(l.unitPrice)}', style: Nv.money(14, color: Nv.onNight3, weight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(baht(l.lineTotal), style: Nv.money(21, color: Nv.gold200)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final PosStore store;
  final bool big;
  const _TotalsCard({required this.store, required this.big});

  @override
  Widget build(BuildContext context) {
    final vatPct = store.vatRate * 100;
    final vatText = (vatPct - vatPct.round()).abs() < 0.001 ? vatPct.round().toString() : vatPct.toStringAsFixed(1);
    final note = store.discountNote;
    return Stack(
      children: [
        NvNightCard(
          glow: true,
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NvKeyValue('รวม ${store.cartItemCount} ชิ้น', baht(store.cartSubtotal), onNight: true),
              if (store.cartDiscount > 0) ...[
                NvKeyValue('ส่วนลด', baht(-store.cartDiscount), onNight: true, valueColor: Nv.jadeLight),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(NvIcons.tags, size: 12, color: Nv.gold300),
                        const SizedBox(width: 6),
                        Expanded(child: Text(note, style: Nv.ui(13.5, color: Nv.gold300))),
                      ],
                    ),
                  ),
              ],
              if (store.vatEnabled && store.cartTax > 0)
                NvKeyValue(store.vatInclusive ? 'VAT $vatText% (รวมในราคาแล้ว)' : 'VAT $vatText%', baht(store.cartTax), onNight: true),
              const SizedBox(height: 6),
              const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
              const SizedBox(height: 4),
              Text('ยอดที่ต้องชำระ', style: Nv.ui(16, color: Nv.onNight2, weight: FontWeight.w600)),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(store.cartTotal), style: Nv.money(big ? 62 : 46))),
              ),
            ],
          ),
        ),
        const NvKanokCorners(size: 50, opacity: 0.65, inset: EdgeInsets.all(2)),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  final PosStore store;
  final Customer customer;
  const _MemberCard({required this.store, required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final tier = store.tierFor(c);
    final earn = (store.cartTotal * tier.pointsPer100 / 100).floor();
    final next = store.nextTierFor(c);
    return NvNightCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          NvAvatar(c.initials, hue: tier.hue, size: 54, ring: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('สมาชิก', style: Nv.eyebrow(color: Nv.gold300)),
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(19, color: Nv.onNight, weight: FontWeight.w700)),
                Text('แต้มสะสม ${groupDigits(c.points)} แต้ม', style: Nv.ui(14, color: Nv.onNight2)),
                if (next != null)
                  Text('อีก ${baht(next.remaining)} เลื่อนเป็น ${next.tier.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.onNight3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              NvBadge(tier.name, tint: NvTint.gold, icon: NvIcons.crown),
              if (earn > 0) ...[
                const SizedBox(height: 6),
                Text('+${groupDigits(earn)} แต้ม', style: Nv.money(15, color: Nv.gold200)),
                Text('จากบิลนี้', style: Nv.ui(11.5, color: Nv.onNight3)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Active promotions, one at a time (advances with the 5 s display tick).
class _PromoCarousel extends StatelessWidget {
  final PosStore store;
  final List<Promotion> promos;
  final int index;
  final bool center;
  const _PromoCarousel({required this.store, required this.promos, required this.index, required this.center});

  @override
  Widget build(BuildContext context) {
    final p = promos[index];
    final Category? cat = p.scope == PromoScope.category ? store.categoryById(p.categoryId) : null;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(NvIcons.bullhorn, size: 15, color: Nv.gold300),
            const SizedBox(width: 8),
            Text('โปรโมชันตอนนี้', style: Nv.eyebrow(color: Nv.gold300).copyWith(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: Nv.med,
          child: ConstrainedBox(
            key: ValueKey(p.id),
            constraints: const BoxConstraints(maxWidth: 560),
            child: NvNightCard(
              glow: true,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  NvArt.icon(p.kind == DiscountKind.percent ? 'discount' : 'coupon', size: 66),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.display(24, color: Nv.onNight, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(p.summary, style: Nv.ui(16.5, color: Nv.gold200, weight: FontWeight.w600)),
                        if (cat != null) Text('เฉพาะหมวด${cat.name}', style: Nv.ui(14, color: Nv.onNight3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (promos.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var j = 0; j < promos.length; j++) ...[
                if (j > 0) const SizedBox(width: 6),
                AnimatedContainer(
                  duration: Nv.med,
                  width: j == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: j == index ? Nv.btnGold : null,
                    color: j == index ? null : Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

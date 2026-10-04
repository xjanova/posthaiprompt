// Thaiprompt POS — Customer display view (pure: renders a DisplaySnapshot).
//
// The whole customer-facing display drawn from a [DisplaySnapshot] only — no
// AppScope / PosStore / GoRouter / plugins — so the same widget runs in the
// main app (/display/customer inside NvKiosk) and in a secondary Flutter
// engine on a physical second screen (CustomerDisplayApp).
//
//  • cart     → lines with pictures, subtotal, discounts (+ note), VAT, the
//               total in gold foil, the linked member and — when the snapshot
//               carries one — a real PromptPay QR for the exact amount;
//  • thank-you → for [DisplaySnapshot.thanksFor] after a checkout: total and,
//               for cash, received / change;
//  • idle     → greeting, shop name, mascot, live clock and the promotions
//               active at snapshot time, rotating every 5 s.
//
// Own timers (all cancelled in dispose): minute-aligned clock tick, 5 s
// promotion rotation (also a safety net for state changes) and a one-shot
// timer that drops the thank-you card exactly when it expires.
//
// by xman studio

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/format.dart';
import '../models/catalog_models.dart' show kCategoryIcons, kFoodArt;
import '../theme/nv_icons.dart';
import '../theme/nv_tokens.dart';
import '../widgets/nova/nv_art.dart';
import '../widgets/nova/nv_backdrop.dart';
import '../widgets/nova/nv_bits.dart';
import '../widgets/nova/nv_surfaces.dart';
import 'display_snapshot.dart';

enum _Mode { riderQr, cart, thanks, idle }

class CustomerDisplayView extends StatefulWidget {
  final DisplaySnapshot snap;
  const CustomerDisplayView({super.key, required this.snap});

  @override
  State<CustomerDisplayView> createState() => _CustomerDisplayViewState();
}

class _CustomerDisplayViewState extends State<CustomerDisplayView> {
  static const _rotateEvery = Duration(seconds: 5);

  final _scroll = ScrollController();
  Timer? _clockTimer;
  Timer? _rotateTimer;
  Timer? _thanksTimer;
  Timer? _secondTimer; // QR countdown, only while the rider QR is up
  int _tick = 0;
  int _lastLen = 0;
  _Mode? _shown;

  @override
  void initState() {
    super.initState();
    _scheduleClock();
    _rotateTimer = Timer.periodic(_rotateEvery, (_) => _onRotate());
    _scheduleThanksExpiry();
  }

  @override
  void didUpdateWidget(covariant CustomerDisplayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.snap, widget.snap)) _scheduleThanksExpiry();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _rotateTimer?.cancel();
    _thanksTimer?.cancel();
    _secondTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Rebuild right after every minute boundary (clock + greeting).
  void _scheduleClock() {
    final n = DateTime.now();
    _clockTimer = Timer(Duration(seconds: 60 - n.second), () {
      if (!mounted) return;
      setState(() {});
      _scheduleClock();
    });
  }

  _Mode _modeAt(DateTime now) {
    final s = widget.snap;
    if (s.riderQrActive(now)) return _Mode.riderQr;
    if (s.hasCart) return _Mode.cart;
    return s.thankYouActive(now) ? _Mode.thanks : _Mode.idle;
  }

  /// 5 s tick: advance the promotion carousel; rebuild if the state moved on
  /// (e.g. the thank-you window ran out while the timer below was skipped).
  void _onRotate() {
    if (!mounted) return;
    final mode = _modeAt(DateTime.now());
    if (mode != _shown) {
      setState(() {});
    } else if (mode == _Mode.idle && widget.snap.promos.length > 1) {
      setState(() => _tick++);
    }
  }

  /// Drop the thank-you card the moment its window closes.
  void _scheduleThanksExpiry() {
    _thanksTimer?.cancel();
    _thanksTimer = null;
    final s = widget.snap;
    final until = s.thanksUntil;
    if (s.hasCart || until == null) return;
    final left = until.difference(DateTime.now());
    if (left.isNegative) return;
    _thanksTimer = Timer(left + const Duration(milliseconds: 50), () {
      if (mounted) setState(() {});
    });
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
    final s = widget.snap;
    final now = DateTime.now();
    final mode = _modeAt(now);
    _shown = mode;
    if (mode == _Mode.riderQr) {
      _secondTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _secondTimer?.cancel();
      _secondTimer = null;
    }
    switch (mode) {
      case _Mode.riderQr:
        _lastLen = 0;
        return NvBackdrop.night(image: NvAssets.art('display-bg'), imageOpacity: 0.3, child: _riderQr(s, now));
      case _Mode.cart:
        _followNewest(s.lines.length);
        return NvBackdrop.night(imageOpacity: 0.35, child: _live(s, now));
      case _Mode.thanks:
        _lastLen = 0;
        return NvBackdrop.night(image: NvAssets.art('display-bg'), imageOpacity: 0.4, child: _thanks(s));
      case _Mode.idle:
        _lastLen = 0;
        return NvBackdrop.night(image: NvAssets.art('display-bg'), imageOpacity: 0.6, child: _idle(s, now));
    }
  }

  // ─────────────────────────── live cart ───────────────────────────

  Widget _live(DisplaySnapshot s, DateTime now) {
    final sub = [if (s.orderId.isNotEmpty) 'บิล ${s.orderId}', if (s.where.isNotEmpty) s.where].join(' · ');
    final header = _TopBar(
      eyebrow: 'ตะกร้าของคุณ',
      title: s.shopName,
      subtitle: sub.isEmpty ? null : sub,
      actions: [_ClockFace(now: now)],
    );
    return Column(
      children: [
        header,
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final lines = _LinesCard(snap: s, controller: _scroll);
            final right = <Widget>[
              if (s.memberName != null) ...[_MemberCard(snap: s), const SizedBox(height: 14)],
              _TotalsCard(snap: s, big: wide),
              ..._qr(s, wide ? 230 : 190),
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
    );
  }

  /// Real PromptPay QR for the cart total (only when the snapshot carries one).
  List<Widget> _qr(DisplaySnapshot s, double size) {
    final payload = s.promptPayPayload;
    if (payload == null || payload.isEmpty || s.total <= 0) return const <Widget>[];
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
                semanticsLabel: 'QR พร้อมเพย์ ${baht(s.total)}',
              ),
            ),
            const SizedBox(height: 10),
            Text(baht(s.total, decimals: true), style: Nv.money(22, color: Nv.gold200)),
            if (s.promptPayMasked.isNotEmpty)
              Text('บัญชีพร้อมเพย์ ${s.promptPayMasked}', style: Nv.ui(13, color: Nv.onNight3)),
          ],
        ),
      ),
    ];
  }

  // ─────────────────────────── Thai Prompt rider QR ───────────────────────────

  /// Customer scans with the Thai Prompt app → picks a pinned address → pays
  /// goods + delivery from their wallet; a rider then collects here.
  Widget _riderQr(DisplaySnapshot s, DateTime now) {
    final until = s.riderQrUntil;
    final left = until?.difference(now);
    String mmss(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    final header = _TopBar(
      eyebrow: 'ส่งด้วยไรเดอร์ Thai Prompt',
      title: s.shopName,
      subtitle: 'ชำระผ่านแอป Thai Prompt',
      actions: [_ClockFace(now: now)],
    );
    final count = s.riderQrLines.fold<int>(0, (a, l) => a + l.qty);
    const steps = [
      'เปิดแอป Thai Prompt แล้วกดสแกน',
      'เลือกที่อยู่ที่ปักหมุดไว้ ดูค่าส่ง',
      'ใส่ PIN ชำระจากกระเป๋าเงิน Thai Prompt',
      'ไรเดอร์มารับของที่ร้าน — สแกนรับของกับไรเดอร์เมื่อได้รับ',
    ];
    return Column(
      children: [
        header,
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            final qrSize = math.min(wide ? 300.0 : 230.0, c.maxHeight * (wide ? 0.52 : 0.34));
            final qrCard = NvNightCard(
              glow: true,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NvArt.icon('delivery', size: 44),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text('สแกนด้วยแอป Thai Prompt',
                            textAlign: TextAlign.center,
                            style: Nv.ui(wide ? 22 : 19, color: Nv.onNight, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Nv.rMd),
                      border: Border.all(color: Nv.gold400, width: 2),
                      boxShadow: Nv.goldGlow(0.6),
                    ),
                    child: QrImageView(
                      data: s.riderQrPayload!,
                      size: qrSize,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      semanticsLabel: 'QR สั่งส่งด้วยไรเดอร์ Thai Prompt',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('ค่าสินค้า', style: Nv.ui(15, color: Nv.onNight2)),
                  FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(s.riderQrTotal), style: Nv.money(wide ? 44 : 36))),
                  Text('+ ค่าส่งตามที่อยู่ของคุณ (แสดงในแอปก่อนยืนยัน)',
                      textAlign: TextAlign.center, style: Nv.ui(14, color: Nv.onNight3)),
                  if (left != null && !left.isNegative) ...[
                    const SizedBox(height: 8),
                    Text('QR ใช้ได้อีก ${mmss(left)}',
                        style: Nv.money(16, color: left.inSeconds < 60 ? Nv.lacquer : Nv.gold200)),
                  ],
                ],
              ),
            );
            final howTo = NvNightCard(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Nv.gold400),
                            child: Text('${i + 1}', style: Nv.money(14, color: Nv.navy950)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(steps[i], style: Nv.ui(16.5, color: Nv.onNight, height: 1.4))),
                        ],
                      ),
                    ),
                ],
              ),
            );
            final list = _LinesCard(snap: s, controller: _scroll, linesOverride: s.riderQrLines, countOverride: count);
            if (wide) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [Expanded(child: list), const SizedBox(height: 14), howTo],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 9, child: Center(child: SingleChildScrollView(child: qrCard))),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [qrCard, const SizedBox(height: 12), howTo],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─────────────────────────── thank you ───────────────────────────

  Widget _thanks(DisplaySnapshot s) {
    final cash = s.thanksCash > 0;
    final who = (s.thanksName ?? '').trim();
    final bill = (s.thanksOrderId ?? '').trim();
    final caption = [who.isNotEmpty ? 'คุณ$who' : s.shopName, if (bill.isNotEmpty) 'บิล $bill']
        .where((t) => t.trim().isNotEmpty)
        .join(' · ');
    final paidLabel = s.thanksMethod.isEmpty ? 'ยอดชำระ' : 'ยอดชำระ · ${s.thanksMethod}';
    final footer = s.receiptFooter.trim();
    return LayoutBuilder(builder: (context, c) {
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
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(caption, textAlign: TextAlign.center, style: Nv.ui(17, color: Nv.onNight2)),
                    ],
                    const SizedBox(height: 18),
                    Stack(
                      children: [
                        NvNightCard(
                          glow: true,
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                          child: Column(
                            children: [
                              Text(paidLabel, style: Nv.ui(16, color: Nv.onNight2)),
                              FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(s.thanksTotal), style: Nv.money(wide ? 56 : 44))),
                              if (cash) ...[
                                const SizedBox(height: 8),
                                const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _Figure(label: 'รับเงิน', value: baht(s.thanksCash))),
                                    Container(width: 1, height: 52, color: Nv.lineNight),
                                    Expanded(child: _Figure(label: 'เงินทอน', value: baht(s.thanksChange), gold: true)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const NvKanokCorners(size: 54, opacity: 0.7, inset: EdgeInsets.all(2)),
                      ],
                    ),
                    if (footer.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(footer, textAlign: TextAlign.center, style: Nv.ui(17, color: Nv.onNight2, height: 1.5)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ─────────────────────────── idle ───────────────────────────

  Widget _idle(DisplaySnapshot s, DateTime now) {
    final promos = s.promos;
    final greet = _greeting(now);
    final shop = s.shopName.trim();
    final branch = s.branch.trim();
    return LayoutBuilder(builder: (context, c) {
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
          Positioned(top: 14, right: 22, child: _ClockFace(now: now, large: true)),
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
                    if (shop.isNotEmpty) NvFoilText(shop, style: Nv.display(wide ? 64 : 40, weight: FontWeight.w700), align: textAlign),
                    if (branch.isNotEmpty) Text(branch, textAlign: textAlign, style: Nv.ui(wide ? 20 : 16, color: Nv.onNight2)),
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
                      _PromoCarousel(promos: promos, index: _tick % promos.length, center: !wide),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  static String _greeting(DateTime n) {
    final h = n.hour;
    if (h >= 5 && h < 12) return 'สวัสดีตอนเช้า';
    if (h >= 12 && h < 17) return 'สวัสดีตอนบ่าย';
    if (h >= 17 && h < 21) return 'สวัสดีตอนเย็น';
    return 'สวัสดีค่ะ';
  }
}

// ═════════════════════════════ pieces ═════════════════════════════

/// HH:mm + Thai date in the night style (same look as NvClock, but driven by
/// the view's own minute tick so it needs no shell / store code).
class _ClockFace extends StatelessWidget {
  final DateTime now;
  final bool large;
  const _ClockFace({required this.now, this.large = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hm(now), style: Nv.money(large ? 34 : 17, color: Nv.gold200)),
          Text(thaiDate(now), style: Nv.ui(large ? 14 : 11, color: Nv.onNight3)),
        ],
      );
}

/// Kiosk header (same layout as the self-order CustTopBar): leaves room
/// top-left for the kiosk logo; one row on tablets, two rows on phones.
class _TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> actions;

  const _TopBar({required this.title, this.subtitle, this.eyebrow, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      final titleBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (eyebrow != null)
            Text(eyebrow!.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.eyebrow(color: Nv.gold300)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: NvFoilText(title, style: Nv.display(wide ? 30 : 24, weight: FontWeight.w700)),
          ),
          if (subtitle != null)
            Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(wide ? 15 : 13.5, color: Nv.onNight2)),
        ],
      );
      final acts = <Widget>[
        for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 10), actions[i]],
      ];
      if (wide) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
          child: Row(
            children: [
              const SizedBox(width: 140, height: 56),
              Expanded(child: titleBlock),
              if (acts.isNotEmpty) const SizedBox(width: 12),
              ...acts,
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [const SizedBox(width: 136, height: 56), const Spacer(), ...acts]),
            const SizedBox(height: 6),
            Row(children: [Expanded(child: titleBlock)]),
          ],
        ),
      );
    });
  }
}

/// Line picture: food art → remote image → navy/gold tile with the category
/// glyph (same look as the self-order CustFoodPicture). Needs a bounded box.
class _FoodPicture extends StatelessWidget {
  final String? art;
  final String? imageUrl;
  final IconData icon;

  const _FoodPicture({this.art, this.imageUrl, this.icon = NvIcons.utensils});

  @override
  Widget build(BuildContext context) {
    final a = art;
    final url = imageUrl?.trim() ?? '';
    final br = BorderRadius.circular(Nv.rMd);
    return LayoutBuilder(builder: (context, c) {
      final s = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 120.0;
      Widget tile() => Center(
            child: Icon(icon, size: (s * 0.34).clamp(16.0, 120.0), color: Nv.gold300.withValues(alpha: 0.9)),
          );
      final Widget content;
      if (a != null && kFoodArt.contains(a)) {
        content = Center(child: NvArt.food(a, size: s * 0.88, fallbackIcon: icon));
      } else if (url.isNotEmpty) {
        content = Image.network(url, fit: BoxFit.cover, filterQuality: FilterQuality.medium, errorBuilder: (_, _, _) => tile());
      } else {
        content = tile();
      }
      return ClipRRect(
        borderRadius: br,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: const RadialGradient(
              center: Alignment(0, -0.2),
              radius: 0.95,
              colors: [Nv.navy600, Nv.navy800, Nv.navy950],
              stops: [0, 0.55, 1],
            ),
            border: Border.all(color: Nv.lineNight),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.15),
                    radius: 0.62,
                    colors: [Nv.gold500.withValues(alpha: 0.26), Colors.transparent],
                  ),
                ),
              ),
              content,
            ],
          ),
        ),
      );
    });
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
  final DisplaySnapshot snap;
  final ScrollController controller;
  final List<DisplayLine>? linesOverride; // e.g. the rider request's server-priced lines
  final int? countOverride;
  const _LinesCard({required this.snap, required this.controller, this.linesOverride, this.countOverride});

  /// Category glyph (no category → utensils; unknown key → tag, like Category.icon).
  static IconData _icon(DisplayLine l) {
    final key = l.iconKey;
    if (key == null) return NvIcons.utensils;
    return kCategoryIcons[key] ?? NvIcons.tag;
  }

  @override
  Widget build(BuildContext context) {
    final lines = linesOverride ?? snap.lines;
    return NvNightCard(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: NvSectionTitle('รายการสั่งซื้อ', trailing: '${countOverride ?? snap.itemCount} ชิ้น', onNight: true, icon: NvIcons.basket),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final l = lines[i];
                final newest = i == lines.length - 1;
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
                      SizedBox(width: 62, height: 62, child: _FoodPicture(art: l.art, imageUrl: l.imageUrl, icon: _icon(l))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(18, color: Nv.onNight, weight: FontWeight.w600)),
                            if (l.detail.isNotEmpty)
                              Text(l.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.ui(13.5, color: Nv.gold300)),
                            Text('${l.qty} × ${baht(l.unitPrice)}', style: Nv.money(14, color: Nv.onNight3, weight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(baht(l.total), style: Nv.money(21, color: Nv.gold200)),
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
  final DisplaySnapshot snap;
  final bool big;
  const _TotalsCard({required this.snap, required this.big});

  @override
  Widget build(BuildContext context) {
    final s = snap;
    final note = s.discountNote;
    return Stack(
      children: [
        NvNightCard(
          glow: true,
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NvKeyValue('รวม ${s.itemCount} ชิ้น', baht(s.subtotal), onNight: true),
              if (s.discount > 0) ...[
                NvKeyValue('ส่วนลด', baht(-s.discount), onNight: true, valueColor: Nv.jadeLight),
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
              if (s.taxLabel.isNotEmpty) NvKeyValue(s.taxLabel, baht(s.tax), onNight: true),
              const SizedBox(height: 6),
              const NvKanokDivider(width: 220, thin: true, opacity: 0.85),
              const SizedBox(height: 4),
              Text('ยอดที่ต้องชำระ', style: Nv.ui(16, color: Nv.onNight2, weight: FontWeight.w600)),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, child: NvFoilText(baht(s.total), style: Nv.money(big ? 62 : 46))),
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
  final DisplaySnapshot snap;
  const _MemberCard({required this.snap});

  @override
  Widget build(BuildContext context) {
    final s = snap;
    final name = s.memberName ?? '';
    final initials = (s.memberInitials ?? '').isNotEmpty
        ? s.memberInitials!
        : (name.isEmpty ? '?' : String.fromCharCode(name.runes.first));
    final tier = (s.memberTier ?? '').trim();
    final next = (s.memberNextHint ?? '').trim();
    return NvNightCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          NvAvatar(initials, hue: s.memberHue, size: 54, ring: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('สมาชิก', style: Nv.eyebrow(color: Nv.gold300)),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(19, color: Nv.onNight, weight: FontWeight.w700)),
                Text('แต้มสะสม ${groupDigits(s.memberPoints)} แต้ม', style: Nv.ui(14, color: Nv.onNight2)),
                if (next.isNotEmpty)
                  Text(next, maxLines: 1, overflow: TextOverflow.ellipsis, style: Nv.ui(12.5, color: Nv.onNight3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tier.isNotEmpty) NvBadge(tier, tint: NvTint.gold, icon: NvIcons.crown),
              if (s.memberEarn > 0) ...[
                const SizedBox(height: 6),
                Text('+${groupDigits(s.memberEarn)} แต้ม', style: Nv.money(15, color: Nv.gold200)),
                Text('จากบิลนี้', style: Nv.ui(11.5, color: Nv.onNight3)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Active promotions, one at a time (advances with the view's 5 s tick).
class _PromoCarousel extends StatelessWidget {
  final List<DisplayPromo> promos;
  final int index;
  final bool center;
  const _PromoCarousel({required this.promos, required this.index, required this.center});

  @override
  Widget build(BuildContext context) {
    final p = promos[index];
    final cat = (p.categoryName ?? '').trim();
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
            key: ValueKey('$index·${p.name}·${p.summary}'),
            constraints: const BoxConstraints(maxWidth: 560),
            child: NvNightCard(
              glow: true,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  NvArt.icon(p.art, size: 66),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Nv.display(24, color: Nv.onNight, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(p.summary, style: Nv.ui(16.5, color: Nv.gold200, weight: FontWeight.w600)),
                        if (cat.isNotEmpty) Text('เฉพาะหมวด$cat', style: Nv.ui(14, color: Nv.onNight3)),
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

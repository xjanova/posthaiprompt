// Thaiprompt POS — Customer-display snapshot (plain data, JSON-safe).
//
// Everything the customer display renders, flattened out of the live
// PosStore into strings and ints so it can cross an isolate / engine
// boundary: a secondary Flutter engine on Windows' second monitor or an
// Android Presentation display, where no PosStore exists. The in-app
// /display/customer screen renders the very same snapshot, so both screens
// always look identical.
//
// Rules mirrored from the original screen:
//  • cart lines with pictures (food art → remote image → category glyph);
//  • VAT line only when VAT is on and the cart carries tax;
//  • linked member: tier, points, points this bill earns, next-tier hint;
//  • PromptPay payload only for a valid shop id and a total above zero;
//  • thank-you window: 20 s after the last order, only while the cart is empty;
//  • promotions active at the snapshot time.
//
// fromJson tolerates missing / mistyped keys so an older sender and a newer
// display (or the other way round) never crash each other.
//
// by xman studio

import 'dart:convert';

import '../core/format.dart';
import '../core/payments/promptpay.dart';
import '../models/extra_models.dart';
import '../models/order_models.dart';
import '../state/pos_store.dart';

// ───────────────────────────── json helpers ─────────────────────────────

String _str(Object? v, [String d = '']) => v is String ? v : (v == null ? d : v.toString());

String? _strOrNull(Object? v) => v == null ? null : (v is String ? v : v.toString());

int _int(Object? v, [int d = 0]) {
  if (v is num) return v.isFinite ? v.toInt() : d;
  if (v is String) return int.tryParse(v.trim()) ?? d;
  return d;
}

DateTime? _time(Object? v) {
  if (v is num) return v.isFinite ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? v.map((k, e) => MapEntry(k.toString(), e)) : <String, dynamic>{};

List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) =>
    v is List ? [for (final e in v) if (e is Map) f(_map(e))] : <T>[];

String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s;

// ───────────────────────────── line ─────────────────────────────

/// One cart line as the customer sees it.
class DisplayLine {
  final String name;
  final String detail; // options + note, "ใหญ่ · หวานน้อย · ไม่ใส่น้ำแข็ง"
  final int qty;
  final int total; // baht, qty × unit price
  final String? art; // kFoodArt key (assets/nova/food/<art>.webp)
  final String? imageUrl; // remote product picture (fallback when no art)
  final String? iconKey; // category icon key (kCategoryIcons); null = no category

  const DisplayLine({
    required this.name,
    this.detail = '',
    required this.qty,
    required this.total,
    this.art,
    this.imageUrl,
    this.iconKey,
  });

  /// Unit price incl. options (lineTotal is always qty × unit).
  int get unitPrice => qty > 0 ? total ~/ qty : total;

  Map<String, dynamic> toJson() => {
        'name': name,
        'detail': detail,
        'qty': qty,
        'total': total,
        'art': art,
        'imageUrl': imageUrl,
        'iconKey': iconKey,
      };

  factory DisplayLine.fromJson(Map<String, dynamic> j) => DisplayLine(
        name: _str(j['name']),
        detail: _str(j['detail']),
        qty: _int(j['qty']),
        total: _int(j['total']),
        art: _strOrNull(j['art']),
        imageUrl: _strOrNull(j['imageUrl']),
        iconKey: _strOrNull(j['iconKey']),
      );

  @override
  bool operator ==(Object other) =>
      other is DisplayLine &&
      other.name == name &&
      other.detail == detail &&
      other.qty == qty &&
      other.total == total &&
      other.art == art &&
      other.imageUrl == imageUrl &&
      other.iconKey == iconKey;

  @override
  int get hashCode => Object.hash(name, detail, qty, total, art, imageUrl, iconKey);
}

// ───────────────────────────── promotion ─────────────────────────────

/// An automatic promotion active right now (idle carousel).
class DisplayPromo {
  final String name;
  final String summary; // "ลด 10% · ขั้นต่ำ ฿200 · 14:00–17:00"
  final String? categoryName; // only for category-scoped promotions
  final String art; // 3D icon key: 'discount' (percent) | 'coupon' (baht)

  const DisplayPromo({required this.name, required this.summary, this.categoryName, this.art = 'coupon'});

  Map<String, dynamic> toJson() => {
        'name': name,
        'summary': summary,
        'categoryName': categoryName,
        'art': art,
      };

  factory DisplayPromo.fromJson(Map<String, dynamic> j) {
    final art = _str(j['art']);
    return DisplayPromo(
      name: _str(j['name']),
      summary: _str(j['summary']),
      categoryName: _strOrNull(j['categoryName']),
      art: art.isEmpty ? 'coupon' : art,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DisplayPromo &&
      other.name == name &&
      other.summary == summary &&
      other.categoryName == categoryName &&
      other.art == art;

  @override
  int get hashCode => Object.hash(name, summary, categoryName, art);
}

// ───────────────────────────── snapshot ─────────────────────────────

/// Everything the customer display renders — all plain data.
class DisplaySnapshot {
  /// How long the thank-you card stays up after a checkout (cart empty).
  static const thanksFor = Duration(seconds: 20);

  /// JSON schema marker (bump when a field changes meaning).
  static const schema = 1;

  // shop / bill
  final String shopName;
  final String branch;
  final String receiptFooter;
  final String orderId; // next bill id, e.g. 'A1042'
  final String where; // 'โต๊ะ 7' / 'กลับบ้าน'

  // cart
  final List<DisplayLine> lines;
  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final String discountNote; // "คูปอง TP20 · Gold -5%"
  final String taxLabel; // 'VAT 7%' | 'VAT 7% (รวมในราคาแล้ว)' | '' = no VAT line

  // linked member
  final String? memberName;
  final String? memberTier;
  final int memberPoints;
  final int memberEarn; // points this bill earns
  final String? memberNextHint; // "อีก ฿1,200 เลื่อนเป็น Gold"
  final String? memberInitials; // avatar text
  final int memberHue; // tier color (avatar)

  // PromptPay
  final String? promptPayPayload; // EMVCo string, only when valid id && total > 0
  final String promptPayMasked; // "••••••4567"

  // Thai Prompt rider request — the customer scans with the Thai Prompt app
  // and pays goods + delivery from their wallet (takes over the screen)
  final String? riderQrPayload; // TPPOS1.<token>
  final int riderQrTotal; // goods total at the online store's prices
  final DateTime? riderQrUntil; // QR expiry
  final List<DisplayLine> riderQrLines;

  // thank-you (after checkout)
  final String? thanksName;
  final int thanksTotal;
  final int thanksCash; // cash tendered (0 = not a cash sale)
  final int thanksChange;
  final String? thanksOrderId;
  final DateTime? thanksUntil;
  final String thanksMethod; // 'เงินสด' / 'พร้อมเพย์' / 'บัตร' / 'อีวอลเล็ท'

  // idle
  final List<DisplayPromo> promos;

  final DateTime sentAt;

  const DisplaySnapshot({
    this.shopName = '',
    this.branch = '',
    this.receiptFooter = '',
    this.orderId = '',
    this.where = '',
    this.lines = const <DisplayLine>[],
    this.itemCount = 0,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.discountNote = '',
    this.taxLabel = '',
    this.memberName,
    this.memberTier,
    this.memberPoints = 0,
    this.memberEarn = 0,
    this.memberNextHint,
    this.memberInitials,
    this.memberHue = 40,
    this.promptPayPayload,
    this.promptPayMasked = '',
    this.riderQrPayload,
    this.riderQrTotal = 0,
    this.riderQrUntil,
    this.riderQrLines = const <DisplayLine>[],
    this.thanksName,
    this.thanksTotal = 0,
    this.thanksCash = 0,
    this.thanksChange = 0,
    this.thanksOrderId,
    this.thanksUntil,
    this.thanksMethod = '',
    this.promos = const <DisplayPromo>[],
    required this.sentAt,
  });

  bool get hasCart => lines.isNotEmpty;

  bool riderQrActive(DateTime now) =>
      riderQrPayload != null && riderQrPayload!.isNotEmpty && (riderQrUntil == null || now.isBefore(riderQrUntil!));

  bool thankYouActive(DateTime now) => !hasCart && thanksUntil != null && now.isBefore(thanksUntil!);

  /// Nothing to show yet (before the first snapshot arrives).
  static DisplaySnapshot empty() => DisplaySnapshot(sentAt: DateTime.fromMillisecondsSinceEpoch(0));

  /// Build from the live store with the same rules the in-app display used.
  factory DisplaySnapshot.fromStore(PosStore s, {DateTime? now}) {
    final at = now ?? DateTime.now();

    final lines = <DisplayLine>[
      for (final l in s.cart)
        DisplayLine(
          name: l.product.name,
          detail: [...l.options, if (l.note.isNotEmpty) l.note].join(' · '),
          qty: l.qty,
          total: l.lineTotal,
          art: l.product.art,
          imageUrl: _blankToNull(l.product.imageUrl),
          iconKey: s.categoryById(l.product.categoryId)?.iconKey,
        ),
    ];

    final where = s.orderType == OrderType.dineIn && s.tableNumber != null ? 'โต๊ะ ${s.tableNumber}' : s.orderType.label;

    final tax = s.cartTax;
    final total = s.cartTotal;
    var taxLabel = '';
    if (s.vatEnabled && tax > 0) {
      final pct = s.vatRate * 100;
      final txt = (pct - pct.round()).abs() < 0.001 ? pct.round().toString() : pct.toStringAsFixed(1);
      taxLabel = s.vatInclusive ? 'VAT $txt% (รวมในราคาแล้ว)' : 'VAT $txt%';
    }

    // linked member
    String? memberName, memberTier, memberNextHint, memberInitials;
    var memberPoints = 0, memberEarn = 0, memberHue = 40;
    final c = s.linkedCustomer;
    if (c != null) {
      final tier = s.tierFor(c);
      final next = s.nextTierFor(c);
      memberName = c.name;
      memberTier = tier.name;
      memberPoints = c.points;
      memberEarn = (total * tier.pointsPer100 / 100).floor();
      memberNextHint = next == null ? null : 'อีก ${baht(next.remaining)} เลื่อนเป็น ${next.tier.name}';
      memberInitials = c.initials;
      memberHue = tier.hue;
    }

    // PromptPay (real EMVCo payload for the exact amount)
    final id = s.promptPayId.trim();
    String? payload;
    var masked = '';
    if (id.isNotEmpty && PromptPay.isValidId(id)) {
      masked = PromptPay.mask(id);
      if (total > 0) {
        try {
          payload = PromptPay.payload(id, amountBaht: total.toDouble());
        } on ArgumentError {
          payload = null;
        }
      }
    }

    // thank-you window — 20 s after the last order while the cart is empty
    String? thanksName, thanksOrderId;
    DateTime? thanksUntil;
    var thanksTotal = 0, thanksCash = 0, thanksChange = 0;
    var thanksMethod = '';
    final last = s.lastOrder;
    if (s.cart.isEmpty && last != null) {
      final age = at.difference(last.createdAt);
      if (!age.isNegative && age < thanksFor) {
        final cash = last.method == PaymentMethod.cash && last.cashReceived > 0;
        final who = (last.customerName ?? '').trim();
        thanksName = who.isEmpty ? null : who;
        thanksTotal = last.total;
        thanksCash = cash ? last.cashReceived : 0;
        thanksChange = cash ? last.change : 0;
        thanksOrderId = last.id;
        thanksUntil = last.createdAt.add(thanksFor);
        thanksMethod = last.method.receiptLabel;
      }
    }

    // Thai Prompt rider QR (only while the request still waits for payment)
    final rq = s.riderQrJob;
    final riderLines = <DisplayLine>[
      if (rq != null)
        for (final l in rq.lines)
          DisplayLine(
            name: l.name,
            detail: [if (l.options.isNotEmpty) l.options, if (l.note.isNotEmpty) l.note].join(' · '),
            qty: l.qty,
            total: l.total,
            art: s.productByCode(l.code)?.art,
            imageUrl: _blankToNull(s.productByCode(l.code)?.imageUrl),
          ),
    ];

    final promos = <DisplayPromo>[
      for (final p in s.promotions)
        if (p.activeAt(at))
          DisplayPromo(
            name: p.name,
            summary: p.summary,
            categoryName: p.scope == PromoScope.category ? s.categoryById(p.categoryId)?.name : null,
            art: p.kind == DiscountKind.percent ? 'discount' : 'coupon',
          ),
    ];

    return DisplaySnapshot(
      shopName: s.shopName,
      branch: s.branch,
      receiptFooter: s.receiptFooter,
      orderId: s.openOrderId,
      where: where,
      lines: lines,
      itemCount: s.cartItemCount,
      subtotal: s.cartSubtotal,
      discount: s.cartDiscount,
      tax: tax,
      total: total,
      discountNote: s.discountNote,
      taxLabel: taxLabel,
      memberName: memberName,
      memberTier: memberTier,
      memberPoints: memberPoints,
      memberEarn: memberEarn,
      memberNextHint: memberNextHint,
      memberInitials: memberInitials,
      memberHue: memberHue,
      promptPayPayload: payload,
      promptPayMasked: masked,
      riderQrPayload: rq?.qrPayload,
      riderQrTotal: rq?.subtotal ?? 0,
      riderQrUntil: rq?.qrExpiresAt,
      riderQrLines: riderLines,
      thanksName: thanksName,
      thanksTotal: thanksTotal,
      thanksCash: thanksCash,
      thanksChange: thanksChange,
      thanksOrderId: thanksOrderId,
      thanksUntil: thanksUntil,
      thanksMethod: thanksMethod,
      promos: promos,
      sentAt: at,
    );
  }

  /// Times travel as epoch milliseconds (time-zone free).
  Map<String, dynamic> toJson() => {
        'v': schema,
        'shopName': shopName,
        'branch': branch,
        'receiptFooter': receiptFooter,
        'orderId': orderId,
        'where': where,
        'lines': lines.map((l) => l.toJson()).toList(),
        'itemCount': itemCount,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'discountNote': discountNote,
        'taxLabel': taxLabel,
        'memberName': memberName,
        'memberTier': memberTier,
        'memberPoints': memberPoints,
        'memberEarn': memberEarn,
        'memberNextHint': memberNextHint,
        'memberInitials': memberInitials,
        'memberHue': memberHue,
        'promptPayPayload': promptPayPayload,
        'promptPayMasked': promptPayMasked,
        'riderQrPayload': riderQrPayload,
        'riderQrTotal': riderQrTotal,
        'riderQrUntil': riderQrUntil?.millisecondsSinceEpoch,
        'riderQrLines': riderQrLines.map((l) => l.toJson()).toList(),
        'thanksName': thanksName,
        'thanksTotal': thanksTotal,
        'thanksCash': thanksCash,
        'thanksChange': thanksChange,
        'thanksOrderId': thanksOrderId,
        'thanksUntil': thanksUntil?.millisecondsSinceEpoch,
        'thanksMethod': thanksMethod,
        'promos': promos.map((p) => p.toJson()).toList(),
        'sentAt': sentAt.millisecondsSinceEpoch,
      };

  factory DisplaySnapshot.fromJson(Map<String, dynamic> j) => DisplaySnapshot(
        shopName: _str(j['shopName']),
        branch: _str(j['branch']),
        receiptFooter: _str(j['receiptFooter']),
        orderId: _str(j['orderId']),
        where: _str(j['where']),
        lines: _list(j['lines'], DisplayLine.fromJson),
        itemCount: _int(j['itemCount']),
        subtotal: _int(j['subtotal']),
        discount: _int(j['discount']),
        tax: _int(j['tax']),
        total: _int(j['total']),
        discountNote: _str(j['discountNote']),
        taxLabel: _str(j['taxLabel']),
        memberName: _strOrNull(j['memberName']),
        memberTier: _strOrNull(j['memberTier']),
        memberPoints: _int(j['memberPoints']),
        memberEarn: _int(j['memberEarn']),
        memberNextHint: _strOrNull(j['memberNextHint']),
        memberInitials: _strOrNull(j['memberInitials']),
        memberHue: _int(j['memberHue'], 40),
        promptPayPayload: _blankToNull(_strOrNull(j['promptPayPayload'])),
        promptPayMasked: _str(j['promptPayMasked']),
        riderQrPayload: _blankToNull(_strOrNull(j['riderQrPayload'])),
        riderQrTotal: _int(j['riderQrTotal']),
        riderQrUntil: _time(j['riderQrUntil']),
        riderQrLines: _list(j['riderQrLines'], DisplayLine.fromJson),
        thanksName: _strOrNull(j['thanksName']),
        thanksTotal: _int(j['thanksTotal']),
        thanksCash: _int(j['thanksCash']),
        thanksChange: _int(j['thanksChange']),
        thanksOrderId: _strOrNull(j['thanksOrderId']),
        thanksUntil: _time(j['thanksUntil']),
        thanksMethod: _str(j['thanksMethod']),
        promos: _list(j['promos'], DisplayPromo.fromJson),
        sentAt: _time(j['sentAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// JSON string for a platform / isolate message.
  String encode() => jsonEncode(toJson());

  /// Parse [encode]'s output. Throws [FormatException] for text that is not
  /// a JSON object (missing keys are fine — see [DisplaySnapshot.fromJson]).
  static DisplaySnapshot decode(String s) {
    final v = jsonDecode(s);
    if (v is! Map) throw const FormatException('DisplaySnapshot: expected a JSON object');
    return DisplaySnapshot.fromJson(_map(v));
  }
}

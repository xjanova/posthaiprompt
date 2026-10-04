// Thaiprompt POS — Order + cart domain models.
//
// CartLine = a live, mutable line in the open cart (qty/note/options edit in place).
// Ticket   = an unpaid order sent to the kitchen from a table / self-order kiosk;
//            settled later at the cashier.
// Order    = a payment snapshot recorded at checkout, persisted to disk and
//            replayed by receipts / reports / refunds / tax invoices.
//
// by xman studio

import 'catalog_models.dart';

/// [thaiprompt] = the customer paid from their Thai Prompt wallet in the app
/// (POS → Thai Prompt rider delivery). The shop is settled by Thai Prompt, so
/// the bill is not re-uploaded by the POS sync and never touches the drawer.
enum PaymentMethod { promptpay, card, cash, wallet, thaiprompt }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.promptpay => 'พร้อมเพย์ / QR',
        PaymentMethod.card => 'บัตรเครดิต / เดบิต',
        PaymentMethod.cash => 'เงินสด',
        PaymentMethod.wallet => 'อีวอลเล็ท',
        PaymentMethod.thaiprompt => 'Thai Prompt · ส่งไรเดอร์',
      };

  /// Short label for the receipt footer ("ชำระโดย …").
  String get receiptLabel => switch (this) {
        PaymentMethod.promptpay => 'พร้อมเพย์',
        PaymentMethod.card => 'บัตร',
        PaymentMethod.cash => 'เงินสด',
        PaymentMethod.wallet => 'อีวอลเล็ท',
        PaymentMethod.thaiprompt => 'Thai Prompt',
      };

  /// Nova 3D art key (`assets/nova/icons/<key>.webp`).
  String get art => switch (this) {
        PaymentMethod.promptpay => 'promptpay',
        PaymentMethod.card => 'card',
        PaymentMethod.cash => 'cash',
        PaymentMethod.wallet => 'wallet',
        PaymentMethod.thaiprompt => 'delivery',
      };
}

enum OrderType { dineIn, takeaway, delivery }

extension OrderTypeX on OrderType {
  String get label => switch (this) {
        OrderType.dineIn => 'ทานที่นี่',
        OrderType.takeaway => 'กลับบ้าน',
        OrderType.delivery => 'เดลิเวอรี่',
      };
}

/// Where an order was keyed in.
enum OrderSource { counter, table, self, mobile, delivery }

extension OrderSourceX on OrderSource {
  String get label => switch (this) {
        OrderSource.counter => 'หน้าร้าน',
        OrderSource.table => 'สั่งที่โต๊ะ',
        OrderSource.self => 'ลูกค้าสั่งเอง',
        OrderSource.mobile => 'มือถือพนักงาน',
        OrderSource.delivery => 'เดลิเวอรี่',
      };
}

enum OrderStatus { open, paid, voided, refunded }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.open => 'ค้างชำระ',
        OrderStatus.paid => 'ชำระแล้ว',
        OrderStatus.voided => 'ยกเลิก',
        OrderStatus.refunded => 'คืนเงินแล้ว',
      };
}

/// Kitchen lifecycle, independent of payment.
enum PrepStatus { queued, preparing, ready, served }

extension PrepStatusX on PrepStatus {
  String get label => switch (this) {
        PrepStatus.queued => 'รอทำ',
        PrepStatus.preparing => 'กำลังทำ',
        PrepStatus.ready => 'พร้อมเสิร์ฟ',
        PrepStatus.served => 'เสิร์ฟแล้ว',
      };

  /// Index on the 4-step customer timeline (รับออเดอร์→กำลังทำ→พร้อม→เสร็จ).
  int get step => index;

  PrepStatus get next => switch (this) {
        PrepStatus.queued => PrepStatus.preparing,
        PrepStatus.preparing => PrepStatus.ready,
        PrepStatus.ready => PrepStatus.served,
        PrepStatus.served => PrepStatus.served,
      };

  PrepStatus get previous => switch (this) {
        PrepStatus.queued => PrepStatus.queued,
        PrepStatus.preparing => PrepStatus.queued,
        PrepStatus.ready => PrepStatus.preparing,
        PrepStatus.served => PrepStatus.ready,
      };
}

/// An applied coupon on the live cart (amount resolved by the store from the
/// coupon definition each time the cart changes).
class Coupon {
  final String code;
  final int amountOff;
  const Coupon(this.code, this.amountOff);

  Map<String, dynamic> toJson() => {'code': code, 'amountOff': amountOff};
  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(j['code'] as String, (j['amountOff'] as num).toInt());
}

/// A live line in the open cart. Mutable on purpose — the qty stepper, note
/// editor and option picker mutate it through the store.
class CartLine {
  final Product product;
  int qty;
  String note;
  final List<String> options; // chosen option labels, e.g. ['ใหญ่', 'หวานน้อย']
  final int optionDelta; // baht added by the chosen options

  CartLine({required this.product, this.qty = 1, this.note = '', List<String>? options, this.optionDelta = 0})
      : options = options ?? <String>[];

  int get unitPrice => product.price + optionDelta;
  int get lineTotal => qty * unitPrice;

  /// Lines merge only when product, options and note all match.
  bool sameAs(Product p, List<String> opts, String n) =>
      product.id == p.id && note == n && _sameList(options, opts);

  OrderLine toOrderLine() => OrderLine(
        name: product.name,
        code: product.code,
        note: note,
        qty: qty,
        price: unitPrice,
        hue: product.hue,
        kind: product.kind,
        options: List.of(options),
        cost: product.cost,
        art: product.art,
      );

  Map<String, dynamic> toJson() => {
        'code': product.code,
        'qty': qty,
        'note': note,
        'options': options,
        'optionDelta': optionDelta,
      };

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// An immutable line inside a recorded [Order] / [Ticket] — decoupled from the
/// live catalog so a price/name change later never rewrites history.
class OrderLine {
  final String name;
  final String code;
  final String note;
  final int qty;
  final int price; // unit price incl. options
  final int hue;
  final String kind;
  final List<String> options;
  final int cost; // unit cost at time of sale (COGS)
  final String? art;
  int refundedQty; // partial refunds

  OrderLine({
    required this.name,
    required this.code,
    required this.note,
    required this.qty,
    required this.price,
    required this.hue,
    this.kind = 'rect',
    this.options = const [],
    this.cost = 0,
    this.art,
    this.refundedQty = 0,
  });

  int get lineTotal => qty * price;
  int get refundableQty => qty - refundedQty;

  /// Options + note in one line for receipts / KDS ("ใหญ่ · หวานน้อย · ไม่ใส่น้ำแข็ง").
  String get detail => [...options, if (note.isNotEmpty) note].join(' · ');

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'note': note,
        'qty': qty,
        'price': price,
        'hue': hue,
        'kind': kind,
        'options': options,
        'cost': cost,
        'art': art,
        'refundedQty': refundedQty,
      };

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        name: j['name'] as String,
        code: j['code'] as String,
        note: (j['note'] as String?) ?? '',
        qty: (j['qty'] as num).toInt(),
        price: (j['price'] as num).toInt(),
        hue: (j['hue'] as num?)?.toInt() ?? 40,
        kind: (j['kind'] as String?) ?? 'rect',
        options: ((j['options'] as List?) ?? const []).map((e) => e.toString()).toList(),
        cost: (j['cost'] as num?)?.toInt() ?? 0,
        art: j['art'] as String?,
        refundedQty: (j['refundedQty'] as num?)?.toInt() ?? 0,
      );
}

/// Buyer details for a full tax invoice (ใบกำกับภาษีเต็มรูป).
class TaxBuyer {
  final String name;
  final String taxId;
  final String address;
  final String branch; // 'สำนักงานใหญ่' or branch no.
  const TaxBuyer({required this.name, required this.taxId, this.address = '', this.branch = 'สำนักงานใหญ่'});

  Map<String, dynamic> toJson() => {'name': name, 'taxId': taxId, 'address': address, 'branch': branch};
  factory TaxBuyer.fromJson(Map<String, dynamic> j) => TaxBuyer(
        name: j['name'] as String,
        taxId: j['taxId'] as String,
        address: (j['address'] as String?) ?? '',
        branch: (j['branch'] as String?) ?? 'สำนักงานใหญ่',
      );
}

/// A completed sale.
class Order {
  final String id; // e.g. 'A1042'
  final DateTime createdAt;
  final List<OrderLine> lines;
  final int subtotal;
  final int discount; // coupon + promotion + member, total
  final int tax;
  final int total;
  final PaymentMethod method;
  final OrderType type;
  final int? tableNumber;
  final int guests;
  final String cashier;
  final String? couponCode;
  final String? customerName;
  final String? customerId;
  final String? staffId;
  final String? shiftId;
  final String? paymentRef; // EDC approval / transfer ref
  final int cashReceived; // cash tendered (0 for non-cash)
  final int change;
  final OrderSource source;
  final String? ticketId; // settled from a kitchen ticket
  final String discountNote; // "คูปอง TP50 · Gold -5%"
  OrderStatus status;
  PrepStatus prep;
  int refundAmount;
  String? refundReason;
  DateTime? refundedAt;
  String? refundedBy;
  String? taxInvoiceNo;
  TaxBuyer? taxBuyer;
  int printCount;

  Order({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.method,
    required this.type,
    required this.cashier,
    this.tableNumber,
    this.guests = 1,
    this.couponCode,
    this.customerName,
    this.customerId,
    this.staffId,
    this.shiftId,
    this.paymentRef,
    this.cashReceived = 0,
    this.change = 0,
    this.source = OrderSource.counter,
    this.ticketId,
    this.discountNote = '',
    this.status = OrderStatus.paid,
    this.prep = PrepStatus.queued,
    this.refundAmount = 0,
    this.refundReason,
    this.refundedAt,
    this.refundedBy,
    this.taxInvoiceNo,
    this.taxBuyer,
    this.printCount = 0,
  });

  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  int get netTotal => total - refundAmount;
  int get cogs => lines.fold(0, (s, l) => s + l.cost * (l.qty - l.refundedQty));
  bool get isPaid => status == OrderStatus.paid;
  bool get isPartiallyRefunded => status == OrderStatus.paid && refundAmount > 0;

  /// Customer-facing receipt reference, e.g. `TP-A1042-7218` — stable on every
  /// platform (FNV-1a, not `String.hashCode`).
  String get reference {
    final salt = (fnv1a('$id|${createdAt.millisecondsSinceEpoch}') % 10000).toString().padLeft(4, '0');
    return 'TP-$id-$salt';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((l) => l.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'method': method.name,
        'type': type.name,
        'tableNumber': tableNumber,
        'guests': guests,
        'cashier': cashier,
        'couponCode': couponCode,
        'customerName': customerName,
        'customerId': customerId,
        'staffId': staffId,
        'shiftId': shiftId,
        'paymentRef': paymentRef,
        'cashReceived': cashReceived,
        'change': change,
        'source': source.name,
        'ticketId': ticketId,
        'discountNote': discountNote,
        'status': status.name,
        'prep': prep.name,
        'refundAmount': refundAmount,
        'refundReason': refundReason,
        'refundedAt': refundedAt?.toIso8601String(),
        'refundedBy': refundedBy,
        'taxInvoiceNo': taxInvoiceNo,
        'taxBuyer': taxBuyer?.toJson(),
        'printCount': printCount,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        lines: (j['lines'] as List).map((e) => OrderLine.fromJson((e as Map).cast<String, dynamic>())).toList(),
        subtotal: (j['subtotal'] as num).toInt(),
        discount: (j['discount'] as num).toInt(),
        tax: (j['tax'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        method: PaymentMethod.values.firstWhere((m) => m.name == j['method'], orElse: () => PaymentMethod.cash),
        type: OrderType.values.firstWhere((t) => t.name == j['type'], orElse: () => OrderType.dineIn),
        tableNumber: (j['tableNumber'] as num?)?.toInt(),
        guests: (j['guests'] as num?)?.toInt() ?? 1,
        cashier: (j['cashier'] as String?) ?? '—',
        couponCode: j['couponCode'] as String?,
        customerName: j['customerName'] as String?,
        customerId: j['customerId'] as String?,
        staffId: j['staffId'] as String?,
        shiftId: j['shiftId'] as String?,
        paymentRef: j['paymentRef'] as String?,
        cashReceived: (j['cashReceived'] as num?)?.toInt() ?? 0,
        change: (j['change'] as num?)?.toInt() ?? 0,
        source: OrderSource.values.firstWhere((s) => s.name == j['source'], orElse: () => OrderSource.counter),
        ticketId: j['ticketId'] as String?,
        discountNote: (j['discountNote'] as String?) ?? '',
        status: OrderStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => OrderStatus.paid),
        prep: PrepStatus.values.firstWhere((s) => s.name == j['prep'], orElse: () => PrepStatus.queued),
        refundAmount: (j['refundAmount'] as num?)?.toInt() ?? 0,
        refundReason: j['refundReason'] as String?,
        refundedAt: j['refundedAt'] != null ? DateTime.parse(j['refundedAt'] as String) : null,
        refundedBy: j['refundedBy'] as String?,
        taxInvoiceNo: j['taxInvoiceNo'] as String?,
        taxBuyer: j['taxBuyer'] != null ? TaxBuyer.fromJson((j['taxBuyer'] as Map).cast<String, dynamic>()) : null,
        printCount: (j['printCount'] as num?)?.toInt() ?? 0,
      );
}

enum TicketStatus { open, settled, cancelled }

/// An unpaid order sent to the kitchen (table service / self-order kiosk /
/// waiter phone). Settled at the cashier into a paid [Order].
class Ticket {
  final String id; // 'T-0007'
  final DateTime createdAt;
  final OrderSource source;
  final int? tableNumber;
  final int guests;
  final String? customerName;
  final String? customerId; // linked member → discount + points follow to the bill
  final String staffName;
  final List<OrderLine> lines;
  String note;
  PrepStatus prep;
  TicketStatus status;
  String? settledOrderId;
  bool callWaiter; // customer pressed "เรียกพนักงาน"

  Ticket({
    required this.id,
    required this.createdAt,
    required this.source,
    required this.lines,
    this.tableNumber,
    this.guests = 1,
    this.customerName,
    this.customerId,
    this.staffName = '',
    this.note = '',
    this.prep = PrepStatus.queued,
    this.status = TicketStatus.open,
    this.settledOrderId,
    this.callWaiter = false,
  });

  int get total => lines.fold(0, (s, l) => s + l.lineTotal);
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  bool get isOpen => status == TicketStatus.open;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'source': source.name,
        'tableNumber': tableNumber,
        'guests': guests,
        'customerName': customerName,
        'customerId': customerId,
        'staffName': staffName,
        'lines': lines.map((l) => l.toJson()).toList(),
        'note': note,
        'prep': prep.name,
        'status': status.name,
        'settledOrderId': settledOrderId,
        'callWaiter': callWaiter,
      };

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        source: OrderSource.values.firstWhere((s) => s.name == j['source'], orElse: () => OrderSource.table),
        tableNumber: (j['tableNumber'] as num?)?.toInt(),
        guests: (j['guests'] as num?)?.toInt() ?? 1,
        customerName: j['customerName'] as String?,
        customerId: j['customerId'] as String?,
        staffName: (j['staffName'] as String?) ?? '',
        lines: (j['lines'] as List).map((e) => OrderLine.fromJson((e as Map).cast<String, dynamic>())).toList(),
        note: (j['note'] as String?) ?? '',
        prep: PrepStatus.values.firstWhere((s) => s.name == j['prep'], orElse: () => PrepStatus.queued),
        status: TicketStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => TicketStatus.open),
        settledOrderId: j['settledOrderId'] as String?,
        callWaiter: (j['callWaiter'] as bool?) ?? false,
      );
}

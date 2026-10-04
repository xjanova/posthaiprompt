// Thaiprompt POS — One-call print helpers used by screens.
//
//   await printReceipt(context, order);           // prints, toasts, counts reprints
//   await shareReceipt(context, order);           // PDF share/save
//
// by xman studio

import 'package:flutter/material.dart';

import '../core/print/print_service.dart';
import '../models/order_models.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nv_dialogs.dart';
import 'receipt_doc.dart';

PrintMedium rollMedium(int paperWidthMm) => paperWidthMm == 58 ? PrintMedium.roll58 : PrintMedium.roll80;

ReceiptDoc receiptDocFor(BuildContext context, Order order) {
  final store = AppScope.read(context);
  final c = order.customerId == null ? null : store.customerById(order.customerId!);
  return ReceiptDoc(
    order: order,
    shop: ShopInfo.of(store),
    reprint: order.printCount > 0,
    narrow: store.paperWidthMm == 58,
    memberPoints: c?.points,
  );
}

Future<bool> printReceipt(BuildContext context, Order order, {bool quiet = false}) async {
  final store = AppScope.read(context);
  final doc = receiptDocFor(context, order);
  final res = await PrintService.printDoc(
    context,
    doc,
    jobName: 'ใบเสร็จ ${order.id}',
    medium: rollMedium(store.paperWidthMm),
    printerName: store.printerName,
    precache: ReceiptDoc.precache,
  );
  if (res.ok) store.markPrinted(order);
  if (context.mounted && (!quiet || !res.ok)) {
    nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
  }
  return res.ok;
}

Future<void> shareReceipt(BuildContext context, Order order) async {
  final store = AppScope.read(context);
  final res = await PrintService.shareDoc(
    context,
    receiptDocFor(context, order),
    fileName: 'receipt-${order.id}',
    medium: rollMedium(store.paperWidthMm),
    precache: ReceiptDoc.precache,
  );
  if (context.mounted) nvToast(context, res.message, kind: res.ok ? NvToastKind.success : NvToastKind.warning);
}

# Thai Prompt POS — Nova UI & wiring guide

> The POS now wears the **Nova theme of thaiprompt.online**: royal navy night + polished gold + ivory sheets,
> Thai kanok ornaments, mascot **น้องพร้อม**, Anuphan (UI) / Trirong (display) / JetBrains Mono (money).
> This supersedes the old turquoise/coral mockup look (mockup/ stays as a *layout* reference only).
> Every button must do the real thing — no fake data, no "coming soon" snackbars.

## 1. Imports (one line for UI)

```dart
import 'package:go_router/go_router.dart';
import '../state/app_scope.dart';          // AppScope.of(context) in build, AppScope.read(context) in callbacks
import '../widgets/nova/nova.dart';        // Nv tokens, NvIcons, format helpers, every Nova widget
import '../models/catalog_models.dart';    // Product, Category, OptionGroup …   (as needed)
import '../models/order_models.dart';      // Order, CartLine, Ticket, PaymentMethod …
import '../models/extra_models.dart';      // Customer, Staff, TableInfo, Shift, CouponDef, Promotion …
import '../print/print_actions.dart';      // printReceipt / shareReceipt
import '../core/print/print_service.dart'; // PrintService.printDoc / shareDoc for other documents
```

Do **not** use `TpTokens`, `GlassCard`, `TpPrimaryButton`, `TpOrbBackdrop`, `TpScreenScale`, `google_fonts`, or Material `Icons.*`
in rewritten screens. Use `Nv.*` tokens and `NvIcons.*` (Font Awesome 6 — the same glyphs the website uses).

## 2. Page frames

| Screen kind | Frame |
|---|---|
| Staff pages (back office, cashier, KDS…) | `NvScaffold(title:, eyebrow:, subtitle:, art:, actions: [...], body: ...)` — navy rail + top bar (shift chip, sync pill, clock, lock) over an ivory surface. Responsive: rail → bottom nav under 760 px. Pass `tone: NvTone.night` for dark work screens (KDS). |
| Customer-facing (customer display, self-order, cust/*, order status) | `NvKiosk(child: ..., exitRoute: '/home', image: NvAssets.art('display-bg'))` — no staff chrome; long-press logo 1.5 s + manager PIN to exit. |
| Phone-first screens (/m/cashier, /mobile/order, /mobile/manager) | `NvScaffold` too; inside, center a `ConstrainedBox(maxWidth: 520)` column so it also looks right on desktop. |

Layouts are **responsive** (LayoutBuilder / Expanded / Wrap / GridView with computed columns). No fixed design canvas.
Long lists: `ListView.builder` / `GridView.builder`. Body must never overflow at 1024×700 or 1440×900; check narrow ≥ 400 px degrades gracefully.

## 3. Widget catalogue (`lib/widgets/nova/`)

- **Surfaces**: `NvSheet(child, padding, onTap, goldEdge, selected, color)` ivory card · `NvNightCard(child, onTap, glow, selected)` navy card · `NvGoldRim` · `NvFoilText(text, style:)`.
- **Buttons**: `NvButton.gold / .navy / .ghost(onNight:) / .danger / .success / .soft(label, icon:, trailing:, onPressed:, size: NvButtonSize.sm|md|lg|xl, expand:, loading:)` · `NvIconButton(icon, onPressed:, tooltip:, badge:, onNight:, active:)`.
- **Bits**: `NvBadge(label, tint: NvTint.gold|jade|amber|lacquer|sapphire|navy|neutral|amethyst, icon:)` · `NvChip(label, selected:, onTap:, icon:, count:)` · `NvSegmented<T>(options: [(v,'label')], value:, onChanged:)` · `NvStatTile(label:, value:, art:|icon:, caption:, night:)` · `NvPageHeader` · `NvSectionTitle(title, trailing:, action:, icon:)` · `NvEmptyState(mascot:, title:, message:, actionLabel:, onAction:)` · `NvSearchField(hint:, onChanged:, onSubmitted:, controller:)` · `NvField(label:, controller:, icon:, keyboard:, formatters: NvField.digits, validator:)` · `NvAvatar(initials, hue:)` · `NvMoney(amount, size:)` · `NvKeyValue(label, value, strong:)` · `NvStepper(value:, onMinus:, onPlus:)`.
- **Art**: `NvArt.icon(key, size:)` 3D icons · `NvArt.food(key)` · `NvArt.mascot(key, height:)` · `NvArt.deco(key)` · `NvArt(NvAssets.art('display-bg'))` · `NvKanokCorners()` (must be a direct child of a Stack) · `NvKanokDivider(width:, thin:)`.
  - icon keys: `pos payment receipt kitchen table display qr delivery refund dashboard inventory menu member staff shift po accounting tax branch coupon discount tiers affiliate barcode shipping nfc settings cash promptpay card wallet token printer drawer sync shield`
  - food keys (product pictures, `Product.art`): `thai_tea coffee rice noodle dessert snack bakery juice grocery`
  - mascot poses: `welcome present face cheer wai present_tab empty search sleepy chef gift clock`
  - deco: `lantern lotus coins bell garland elephant lamp umbrella gift crystal scroll bag` · scenes: `login-hero display-bg food-banner hero-temple`
- **Dialogs**: `showNvDialog(context, title:, subtitle:, art:|mascot:, body:, actions: (ctx) => [...])` · `showNvConfirm(context, title:, message:, confirmLabel:, danger:)` → `Future<bool>` · `showManagerPin(context, reason:)` → `Future<Staff?>` · `showNvAmountDialog` → `Future<int?>` · `showNvTextDialog` → `Future<String?>` · `nvToast(context, msg, kind: NvToastKind.success|info|warning|error)`.
- **Shell pieces**: `NvClock`, `NvShiftChip`, `NvSyncPill`.
- **Format** (`core/format.dart`, exported by nova.dart): `baht(int, decimals:)` → ฿1,335 · `groupDigits` · `thaiDate` (08 พ.ค. 2569) · `thaiDateTime` · `thaiDateFull` · `hm` · `timeAgo` · `elapsed(Duration)` · `phoneFmt` · `parseBaht`.
- **Product picture**: prefer `Product.art` → `NvArt.food(p.art!)`; else `p.imageUrl` (Image.network with errorBuilder); else a navy/gold tile with the category icon (`store.categoryById(p.categoryId)?.icon`).

### Look & feel rules
- Ivory work surface, navy for "power" panels (totals, KDS tickets, hero bands), gold for the single primary action per area.
- Titles in Trirong via `Nv.display(size)`; body `Nv.ui(size)`; every number/money `Nv.money(size)` (mono + tabular).
- Status colors: jade = paid/online/success · amber = warning/low stock/waiting · lacquer = danger/void/refund · sapphire = info.
- Use the 3D art generously but purposefully: page header `art:`, empty states (mascot), hero tiles, payment method tiles, module cards.
- Kanok ornaments: `NvKanokDivider` between hero and content, `NvKanokCorners` on hero/night panels and kiosk frames. Don't overdo it in dense tables.
- Hover/press feedback comes free with NvButton/NvSheet(onTap)/NvChip.
- Thai everywhere in UI; ฿ before amount, no space; dates พ.ศ.; 24-h time.

## 4. Store API (`lib/state/pos_store.dart` — read it; key members)

Session/staff: `currentStaff`, `isManager`, `activeStaff`, `login(id,pin)` → `LoginOk|LoginWrongPin|LoginLocked`, `logout(clockOut:)`, `addStaff(name:,role:,pin:,phone:)`, `updateStaff(s, name:,role:,phone:,active:)` (throws StateError with Thai message — catch and toast), `setStaffPin`, `removeStaff`, `pinInUse(pin, except:)`, `verifyManagerPin`, `salesTodayFor(s)`, `ordersTodayFor(s)`, `clockOut(s)`.
Catalog: `products`, `sortedCategories`, `categoryById`, `productByCode`, `productByScan`, `visibleProducts` (+ `setCategory`, `setSearch`, `activeCategoryId`, `searchQuery`), `upsertProduct(Product)` (use `p.copyWith(...)` or a new Product with `nextProductCode()`), `deleteProduct`, `setProductAvailable`, `addCategory(name, iconKey:)`, `updateCategory`, `deleteCategory`, `moveCategory`. `kCategoryIcons` map + `kFoodArt` list in catalog_models.
Cart: `cart`, `addProduct(p, options:, optionDelta:, note:, qty:)` → bool (false = sold out/unavailable), `addByScan(code)`, `incLine/decLine/setLineQty/removeLine/setLineNote/clearCart`, `setOrderType`, `setTable`, `setGuests`, `linkCustomer(c)`, `linkedCustomer`, `tryApplyCoupon(code)` → error String? , `removeCoupon`, `coupon`, totals `cartSubtotal/couponDiscount/promoDiscount/memberDiscount/cartDiscount/discountNote/cartTax/cartTotal/cartItemCount`, `openOrderId`, `checkoutBlockReason` ('' = OK), `holdCart(label:)`, `heldCarts`, `resumeHeld`, `deleteHeld`.
Checkout/orders: `checkout(method:, cashReceived:, paymentRef:)` → Order? (null if blocked/short cash), `lastOrder`, `orderById`, `orders` (newest first), `settledOrders`, `paidOrders`, `refundOrder(order, qtyByCode:, reason:, approvedBy:)` → baht, `markPrinted`, `issueTaxInvoice(order, TaxBuyer)` → running no.
Tickets/tables/kitchen: `sendCartToKitchen(source:, note:)`, `openTickets`, `openTicketsForTable(n)`, `tableBillTotal(n)`, `loadTableToCart(n)`, `loadTicketToCart(t)`, `cancelTicket(t, reason:, approvedBy:)`, `setCallWaiter(table, on)`, `tablesCallingWaiter`, `kitchenQueue` (List<KitchenEntry>), `advanceEntry/revertEntry/setEntryPrep`, tables: `tables`, `tableByNumber`, `addTable(...)`, `updateTable(...)`, `removeTable`, `setTableStatus`, `seatTable(t, guests)`, `nextTableNumber`.
Self-order kiosk: `selfCart`, `selfTable`, `setSelfTable`, `addToSelfCart`, `selfInc/selfDec/selfRemove`, `selfCartTotal/selfCartCount`, `submitSelfOrder(note:, guests:)` → Ticket, `lastSelfTicket`.
Shift: `currentShift`, `hasOpenShift`, `openShift(openingCash:)`, `addCashMovement(type, amount, reason:)`, `ordersInShift(s)`, `shiftSales`, `shiftRefunds`, `shiftByMethod`, `expectedCash(s)`, `closeShift(countedCash:, note:)` → Shift (Z snapshot: zNumber, byMethod, cashVariance…), `shiftHistory`.
CRM/loyalty: `customers`, `searchCustomers(q)`, `customerByPhone`, `addCustomer(name, phone:, email:, note:, birthday:)`, `updateCustomer`, `deleteCustomer`, `adjustPoints`, `tiers`, `sortedTiers`, `tierFor(c)`, `nextTierFor(c)`, `membersInTier(t)`, `upsertTier`, `deleteTier`, `newTierId()`.
Discounts: `couponDefs`, `couponByCode`, `upsertCoupon(CouponDef)`, `deleteCoupon`, `setCouponActive`, `promotions`, `upsertPromotion(Promotion)`, `deletePromotion`, `setPromotionActive`, `newPromotionId()`, `appliedPromotion`.
Stock & purchasing: `adjustStock(p, delta, type: StockMoveType.*, reason:)`, `countStock(p, counted)`, `stockMoves`, `movesFor(code)`, `lowStockProducts`, `suppliers`, `addSupplier/updateSupplier/removeSupplier/supplierById`, `purchaseOrders`, `createPurchaseOrder(supplier, [PoLine], note:)`, `markPoOrdered`, `receivePurchaseOrder(po)`, `cancelPurchaseOrder`.
Delivery: `deliveries`, `createDelivery(order, customerName:, phone:, address:, providerId:, fee:, cod:, weightGrams:, note:)`, `deliveryForOrder`, `updateDelivery`, `advanceDelivery`, `cancelDelivery`, `shippingProviders`, `enabledProviders`, `providerById`, `updateProvider`.
Branches/affiliate/audit: `branches`, `currentBranch`, `addBranch/updateBranch/setCurrentBranch/removeBranch`, `referralCode`, `referralLink`, `referredCustomers`, `auditLog`, `log(action, detail)`.
Reports: `todaySales`, `todayOrderCount`, `todayItemCount`, `todayRefunds`, `avgBasket`, `salesByDay(days:)`, `salesByHour(day)`, `salesByMethod(list)`, `salesByCategory(list)`, `topProducts(limit:, from:)`, `summarize(list)` → (gross, discounts, tax, refunds, net, cogs, profit), `ordersOn(day)`, `ordersBetween(from,to)`.
Settings: `shopName, branch, shopPhone, shopAddress, taxId, promptPayId, receiptFooter, vatRate, vatEnabled, vatInclusive, kitchenEnabled, requireShift, autoPrintReceipt, printerName, paperWidthMm, soundEnabled` → change via `updateSettings(shop:, branchName:, vat:, vatOn:, vatIncluded:, phone:, address:, taxNumber:, promptPay:, footer:, kitchen:, shiftRequired:, autoPrint:, printer:, paperWidth:, sound:)`; server via `updateServerConfig(...)`, `sync` (SyncService: `state`, `syncNow()`), `auth` (`pairTerminal(apiKey:)`, `signOut()`, `isServerPaired`).
Payments: `core/payments/promptpay.dart` → `PromptPay.payload(id, amountBaht:)` (real EMVCo string, render with `QrImageView` from `qr_flutter`), `PromptPay.isValidId`. Barcodes: `BarcodeWidget(barcode: Barcode.code128() | Barcode.ean13(), data:)` from `barcode_widget`.
Printing: `printReceipt(context, order)` / `shareReceipt`; other docs → build a pure black-on-white widget in `lib/print/<name>_doc.dart` and call `PrintService.printDoc(context, doc, jobName:, medium: PrintMedium.roll80|a4|label100x150|label50x30, printerName: store.printerName, precache: [...])` or `PrintService.shareDoc`.

## 5. Hard rules (each one came from a real bug)

1. **No fake data.** If a list is empty, show `NvEmptyState` with a mascot and a real action ("เพิ่ม…"). No hard-coded names, prices, riders, promos, charts.
2. **Every control works**: tap → real store mutation / navigation / print / dialog. Search fields filter. Filters filter. Toggles persist through the store.
3. **Destructive = confirm** (`showNvConfirm`). **Sensitive = manager PIN** (`showManagerPin`): refunds, cancelling kitchen tickets, voiding lines already sent to kitchen, stock decreases, cash pay-out, deleting staff/products, unpairing.
4. `AppScope.of(context)` only in `build`; `AppScope.read(context)` in callbacks. Never mutate the store inside `build`.
5. After any `await`: `if (!mounted) return;` (or `if (!context.mounted) return;`) before using context / setState.
6. Dispose every controller/timer/subscription. Dialog TextEditingControllers: create them in a StatefulWidget dialog body (dispose in its `dispose`) or dispose after the route closes (see `showNvTextDialog`).
7. Never `const [...]..add(...)`; never mutate a `const` list. Empty lists that grow must be `<T>[]`.
8. Catch `StateError` from store methods and show `e.message` in `nvToast(kind: error)`.
9. Navigation: `context.go(route)`; read query params with `GoRouterState.of(context).uri.queryParameters['id']`.
10. Thai UI text; ฿ via `baht()`; dates via `thaiDate*`; times via `hm`.

## 6. Verification each agent must do

- `flutter analyze lib/screens/<your files>` (and any new `lib/print/*_doc.dart`) → **No issues**.
- Don't run `flutter pub get`, `flutter build`, or edit files outside your assignment. Shared code (`lib/state`, `lib/models`, `lib/widgets/nova`, `lib/theme`, `lib/core`, `lib/routes`, `lib/print/print_service.dart`, `receipt_doc.dart`, `print_actions.dart`) is read-only for you — if something is truly missing, work around it locally and report it.

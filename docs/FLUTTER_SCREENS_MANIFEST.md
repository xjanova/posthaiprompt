# Flutter Screens Manifest — POS Thaiprompt

> **Architecture**: Flutter ทั้งหมด · Windows + Android + iOS · codebase เดียวที่ `flutter_app/`.
> **Windows native look**: Acrylic/Mica ผ่าน `flutter_acrylic` (init ใน `lib/main.dart`).
> **Canonical visual spec**: `mockup/index.html` (React+Babel, 39 screens).
> **Source of truth for colors / sizes**: `mockup/DESIGN_TOKENS.json`.
> **Anti-drift rules**: `mockup/CLAUDE.md` — sections 1–10.
>
> This manifest maps every mockup screen to its Flutter target file. Build
> screens in the priority order below; verify each against
> `mockup/screenshots/##-name.png` before merging.

## Status legend

| Symbol | Meaning |
|---|---|
| ✅ | Implemented in Flutter, parity verified against mockup |
| 🟡 | Implemented but pre-handoff (token values may drift — re-check) |
| ⬜ | Not yet started — scaffold below |

## 39-screen manifest

| # | Screen (TH / EN) | Canvas | Flutter route | Flutter file | Status |
|---|---|---|---|---|---|
| 01 | Cashier · จอขายหลัก | 1440×900 | `/cashier` | `lib/screens/cashier_screen.dart` | 🟡 |
| 02 | Payment · ชำระเงิน | 1100×800 | `/payment` | `lib/screens/payment_screen.dart` | 🟡 |
| 03 | Receipt · ใบเสร็จ | 360×640 | `/receipt` | `lib/screens/receipt_screen.dart` | 🟡 |
| 04 | Login · PIN | 1280×800 | `/login` | `lib/screens/login_screen.dart` | 🟡 |
| 05 | Customer Display | 1280×800 | `/display/customer` | `lib/screens/customer_display_screen.dart` | ⬜ |
| 06 | Kitchen Display (KDS) | 1440×900 | `/display/kitchen` | `lib/screens/kitchen_display_screen.dart` | ⬜ |
| 07 | Sales Dashboard | 1440×900 | `/dashboard` | `lib/screens/dashboard_screen.dart` | 🟡 |
| 08 | Inventory · คลังสินค้า | 1440×900 | `/inventory` | `lib/screens/inventory_screen.dart` | ⬜ |
| 09 | iPad · ผังโต๊ะ Waiter | 1024×768 | `/tablet/floor` | `lib/screens/tablet_waiter_screen.dart` | ⬜ |
| 10 | Mobile · รับออเดอร์ที่โต๊ะ | 390×844 | `/mobile/order` | `lib/screens/mobile_order_screen.dart` | ⬜ |
| 11 | Mobile · ผู้จัดการ | 390×844 | `/mobile/manager` | `lib/screens/mobile_manager_screen.dart` | ⬜ |
| 12 | การจัดการบัญชี | 1440×900 | `/accounting` | `lib/screens/accounting_screen.dart` | ⬜ |
| 13 | สร้างบิล | 1440×900 | `/bill/create` | `lib/screens/create_bill_screen.dart` | ⬜ |
| 14 | ใบกำกับภาษี / e-Tax | 1440×900 | `/tax-invoice` | `lib/screens/tax_invoice_screen.dart` | ⬜ |
| 15 | NFC Card Scan | 1280×800 | `/payment/nfc` | `lib/screens/nfc_scan_screen.dart` | ⬜ |
| 16 | เดลิเวอรี่ · ติดตามไรเดอร์ | 1440×900 | `/delivery` | `lib/screens/delivery_screen.dart` | ⬜ |
| 17 | จัดการสต็อก / Movements | 1440×900 | `/stock` | `lib/screens/stock_management_screen.dart` | ⬜ |
| 18 | ส่งของผ่านผู้ให้บริการ | 1440×900 | `/shipping/providers` | `lib/screens/shipping_providers_screen.dart` | ⬜ |
| 19 | ระบบคูปอง / โปรโมชั่น | 1440×900 | `/coupons` | `lib/screens/coupon_screen.dart` | ⬜ |
| 20 | ระบบพนักงาน | 1440×900 | `/staff` | `lib/screens/staff_screen.dart` | ⬜ |
| 21 | ระบบแอดมิน | 1440×900 | `/admin` | `lib/screens/admin_screen.dart` | ⬜ |
| 22 | จัดการบาร์โค้ด | 1440×900 | `/barcode` | `lib/screens/barcode_screen.dart` | ⬜ |
| 23 | พิมพ์ใบปะหน้าพัสดุ | 1440×900 | `/shipping/labels` | `lib/screens/shipping_label_screen.dart` | ⬜ |
| 24 | CRM · สมาชิก | 1440×900 | `/crm` | `lib/screens/crm_screen.dart` | ⬜ |
| 25 | ปิดกะ · Z-Report | 1440×900 | `/shift` | `lib/screens/shift_screen.dart` | ⬜ |
| 26 | คืนเงิน / Void | 1440×900 | `/refund` | `lib/screens/refund_screen.dart` | ⬜ |
| 27 | ใบสั่งซื้อ Supplier (PO) | 1440×900 | `/po` | `lib/screens/purchase_order_screen.dart` | ⬜ |
| 28 | แก้ไขเมนู + BOM | 1440×900 | `/menu-editor` | `lib/screens/menu_editor_screen.dart` | ⬜ |
| 29 | Multi-Branch HQ | 1440×900 | `/hq` | `lib/screens/multibranch_screen.dart` | ⬜ |
| 30 | ออกแบบผังโต๊ะ (เจ้าของ) | 1440×900 | `/floor-designer` | `lib/screens/floor_plan_designer_screen.dart` | ⬜ |
| 31 | สแกน QR สั่งจากโต๊ะ | 390×844 | `/self-order` | `lib/screens/self_order_screen.dart` | ⬜ |
| 32 | ติดตามสถานะออเดอร์ | 390×844 | `/order-status` | `lib/screens/order_status_screen.dart` | ⬜ |
| 33 | ระดับสมาชิก VIP/Gold/Premium | 1440×900 | `/tiers` | `lib/screens/membership_tiers_screen.dart` | ⬜ |
| 34 | ศูนย์ส่วนลด | 1440×900 | `/discount-center` | `lib/screens/discount_center_screen.dart` | ⬜ |
| 35 | Affiliate · แนะนำเพื่อน | 1440×900 | `/affiliate` | `lib/screens/affiliate_screen.dart` | ⬜ |
| 36 | Customer · เมนูกริด | 390×844 | `/cust/menu` | `lib/screens/cust_menu_screen.dart` | ⬜ |
| 37 | Customer · เลือกเมนู ปรับแต่ง | 390×844 | `/cust/item` | `lib/screens/cust_item_screen.dart` | ⬜ |
| 38 | Customer · ตะกร้า รีวิว | 390×844 | `/cust/cart` | `lib/screens/cust_cart_screen.dart` | ⬜ |
| 39 | Customer · ส่งครัวสำเร็จ | 390×844 | `/cust/confirm` | `lib/screens/cust_confirm_screen.dart` | ⬜ |

## Implementation order (per `mockup/CLAUDE.md`)

Build screens in this order — higher value first; each reuses widgets from the
previous step so the cumulative LOC drops sharply after the first 5–6.

### M2 — POS terminal foundation (mobile-first on Android, but layouts use desktop canvas size with `TpScreenScale` helper)
1. 01 Cashier — drives ~80% of usage
2. 02 Payment + 03 Receipt
3. 04 Login PIN

### M3 — Secondary displays + back office
4. 05 Customer Display, 06 KDS (separate Activities; subscribe to SignalR / WebSocket)
5. 25 Shift / Z-Report — required at end of every day
6. 08 Inventory, 07 Dashboard

### M4 — CRM, refund, mobile manager parity
7. 24 CRM, 26 Refund
8. 11 Mobile Manager (Android phone form factor)

### M5 — Self-order flow + table designer
9. 30 Floor designer, 31 Self-order, 32 Order status
10. 36–39 Customer order flow (mobile-only, no auth — QR token identifies table)

### M6 — Business / finance / e-Tax
11. 12 Accounting, 13 Bill, 14 Tax Invoice
12. 15 NFC, 16 Delivery, 27 PO

### M7 — Operations / loyalty / print
13. 17 Stock, 18 Shipping, 22 Barcode, 23 Shipping Labels
14. 33 Tiers, 34 Discounts, 35 Affiliate
15. 19 Coupons, 20 Staff, 21 Admin
16. 28 Menu/BOM, 29 Multi-Branch HQ

## Required new widgets (atoms / molecules)

Build in `lib/widgets/` before the screens that need them.

| Widget | Used by | Notes |
|---|---|---|
| `TpKpiCard` | 07, 08, 17, 19, 20, 24, 25, 26, 29 | Stat tile with delta indicator |
| `TpDataTable` | 08, 17, 18, 20, 22, 24, 26 | Striped, glass surface, sticky header |
| `TpChip` (active state) | 31, 36, all secondary navs | Pill, indigo gradient when selected |
| `TpProductTile` (3D) | 01, 10, 31, 36 | tp-prod CSS — image + name + price + add |
| `TpTierBadge` | 24, 33 | Gold / silver / premium gradient |
| `TpCouponTicket` | 19, 38 | Perforated edge, gold gradient body |
| `TpFloorPlan` (tile + designer) | 09, 30 | Drag-snap grid (designer only) |
| `TpThermalReceipt` | 03, 25 | 80mm mono font, zigzag bottom |
| `TpInvoiceDocument` | 14, 27 | A4 portrait, RD-compliant tax invoice format |
| `TpKdsTicket` | 06 | Color-coded by state (new/cook/ready) |
| `TpPhoneFrame` | 10, 11, 31, 32, 36, 37, 38, 39 | 390×844 viewport with notch + home indicator |
| `TpQrCodeCard` | 02, 05, 30 (per-table) | Square white card with QR + caption |
| `TpStepper` (progress) | 14 (e-Tax), 32, 39 | 5-state horizontal stepper |
| `TpStockBar` | 08, 17 | Progress bar tinted by stock level |
| `TpLabelSheet` | 22 | A4 24-up sticker preview |
| `TpShippingLabel` | 23 | 4×6 thermal label with QR + tracking |
| `TpStaffRow` | 20 | Avatar + name + online dot + shift |
| `TpTimeline` | 20 (shift), 25 (audit log), 32 | Vertical event timeline |
| `TpModifierSheet` | 37 | Size + spice + add-ons + qty + note |

## Backend service interfaces (stub in `lib/services/`)

Match the C# `Tp.Shared` interfaces listed in `mockup/CLAUDE.md`:

```dart
// lib/services/order_service.dart       — IOrderService
// lib/services/kitchen_hub.dart         — IKitchenHub (WebSocket/SignalR)
// lib/services/payment_service.dart     — IPaymentService (QR PromptPay, card, NFC, e-wallet)
// lib/services/inventory_service.dart   — IInventoryService
// lib/services/membership_service.dart  — IMembershipService
// lib/services/discount_engine.dart     — IDiscountEngine
// lib/services/tax_invoice_service.dart — ITaxInvoiceService (RD e-Tax)
// lib/services/shipping_service.dart    — IShippingService (Grab/LM/Flash/…)
// lib/services/affiliate_service.dart   — IAffiliateService
// lib/services/printer_service.dart     — IPrinterService (ESC/POS thermal, A4 PDF, label)
// lib/services/nfc_reader.dart          — INfcReader
```

All wrapped by a sync queue (SQLite local store) so the app keeps working
offline. Shift close (#25) reconciles against the local queue, not cloud.

## Implementation checklist for each screen

Before marking a screen as ✅:

- [ ] Pixel-checked against `mockup/screenshots/##-name.png` at 100% zoom
- [ ] All colors reference `TpTokens.*` — `grep "Color(0x"` in the file returns ZERO inline hex
- [ ] All radii reference `TpTokens.radSm/Md/Lg/Xl/Pill`
- [ ] All spacing references `TpTokens.sp*`
- [ ] Glass surfaces use `TpTokens.glassShadow()` not single-layer `BoxShadow`
- [ ] Money uses `฿` prefix + `JetBrainsMono` + tabular nums
- [ ] Dates formatted as พ.ศ. (`intl` package with `th_TH` locale)
- [ ] Layout uses explicit `Row`/`Column`/`Grid` matching CSS proportions — no naive `Wrap`
- [ ] `if (!mounted) return` guards every `setState` after an `await`
- [ ] Screen disposes its controllers/timers in `dispose()`

## Reference docs

- `mockup/CLAUDE.md` — anti-drift rules (sections 1–10)
- `mockup/SCREENS.md` — per-screen spec + sizes + source JSX
- `mockup/DESIGN_TOKENS.json` — canonical sRGB hex values
- `mockup/CSS_TO_XAML.md` — translation patterns (also applies to Flutter — read shadow + glass sections)
- `mockup/CUSTOMER_ORDER_FLOW.md` — detailed spec for screens 36–39
- `flutter_app/lib/theme/tp_tokens.dart` — Flutter mirror of DESIGN_TOKENS.json

# Screens Inventory · Thaiprompt POS

35 screens, 6 sections. Each row gives **size**, **purpose**, **source JSX
file** to read for the literal layout values.

| # | Screen | Size | Source | Purpose / key components |
|---|---|---|---|---|
| **— Cashier flow —** ||||
| 01 | Cashier · จอขายหลัก | 1440×900 | `screens-cashier.jsx` | Side rail (7 icons + logout) · Top bar (search + table chips + cashier badge) · Category strip (5 cards) · Product grid 4-col · Right cart panel with totals + ปุ่มชำระเงิน |
| 02 | Payment · ชำระเงิน | 1100×800 | `screens-payment.jsx` | 4 payment-method cards (QR/Card/Cash/eWallet) · Big amount · QR display 320px · CTA "ยืนยันการชำระ" |
| 03 | Receipt · ใบเสร็จ | 360×640 | `screens-payment.jsx` | Thermal 80mm preview · Mono font · Zigzag bottom · Barcode |
| 04 | Login · PIN | 1280×800 | `screens-payment.jsx` | Split: brand gradient left + user picker + 12-key PIN pad right |
| **— Secondary displays —** ||||
| 05 | Customer Display | 1280×800 | `screens-display.jsx` | 60/40 split — rotating promo carousel + live order list + QR pay |
| 06 | Kitchen Display KDS | 1440×900 | `screens-display.jsx` | Dark theme · 5-column ticket grid · 3 states (new/cook/ready) with color-coded borders + actions |
| **— Back office —** ||||
| 07 | Sales Dashboard | 1440×900 | `screens-back.jsx` | 4 KPI cards · Hourly line chart with peak callout · Top-5 menu bars · Donut (payment mix) · Recent-orders table |
| 08 | Inventory · คลังสินค้า | 1440×900 | `screens-back.jsx` | 4 summary cards · 10-row product table with stock % bar + status pill (ok/low/out) |
| **— iPad + Mobile —** ||||
| 09 | iPad · ผังโต๊ะ Waiter | 1024×768 | `screens-mobile.jsx` | 12-table floor plan · Active table panel right · Send-to-bill CTA |
| 10 | Mobile · รับออเดอร์ที่โต๊ะ | 390×844 | `screens-mobile.jsx` | Phone bezel · Category tabs · Menu cards · Sticky cart bar |
| 11 | Mobile · ผู้จัดการ | 390×844 | `screens-mobile.jsx` | Greeting · Sales hero with sparkline · 2×2 quick stats · 4 shortcuts · Alerts feed · Tab bar |
| **— Business / Finance —** ||||
| 12 | การจัดการบัญชี | 1440×900 | `screens-business.jsx` | Chart of accounts table · P&L summary · Recent journal entries |
| 13 | สร้างบิล | 1440×900 | `screens-business.jsx` | Customer block · Item editor · Doc-type radio · Totals |
| 14 | ใบกำกับภาษี / Tax Invoice | 1440×900 | `screens-business.jsx` | Print preview document · e-Tax status stepper |
| 15 | NFC · แตะบัตรเพื่อชำระ | 1280×800 | `screens-business.jsx` | Pulse rings · 3D NFC puck · Hovering card · Alternative methods |
| 16 | เดลิเวอรี่ · Track | 1440×900 | `screens-business.jsx` | Fake map with route lines + rider/customer pins · Order queue right |
| **— Operations —** ||||
| 17 | จัดการสต็อก · Movements | 1440×900 | `screens-ops.jsx` | 5 KPI strip · Stock-ledger table · Auto-reorder list · Warehouse-bay map |
| 18 | ส่งของผ่านผู้ให้บริการ | 1440×900 | `screens-ops.jsx` | 8 logistics partner cards (Grab/LM/Lalamove/Robinhood/EMS/Flash/Kerry/J&T) · Pending shipment table |
| 19 | ระบบคูปอง | 1440×900 | `screens-ops.jsx` | KPI · Ticket-style coupon cards · Top performers chart · Preview |
| 20 | ระบบพนักงาน | 1440×900 | `screens-ops.jsx` | 4 KPI · Staff table with online indicator · Shift timeline · Leaderboard |
| 21 | ระบบแอดมิน | 1440×900 | `screens-ops.jsx` | Settings sidebar · Roles & permissions cards · Toggle list · Audit log |
| **— Extras —** ||||
| 22 | จัดการบาร์โค้ด | 1440×900 | `screens-extras.jsx` | SKU table with mini-barcode · A4 24-up label sheet preview · Scanner status |
| 23 | พิมพ์ใบปะหน้าพัสดุ | 1440×900 | `screens-extras.jsx` | Queue · 4×6" label preview with tracking + QR · Printer status |
| **— Advanced —** ||||
| 24 | CRM · สมาชิก | 1440×900 | `screens-more.jsx` | 4 tier KPI · Member table with tier badges · VIP profile card |
| 25 | ปิดกะ · Z-Report | 1440×900 | `screens-more.jsx` | Sales breakdown by method · Cash drawer count grid · Hourly bars · Pay-ins/outs |
| 26 | คืนเงิน / Void | 1440×900 | `screens-more.jsx` | KPI · Refund log table · Approval form panel |
| 27 | Purchase Order | 1440×900 | `screens-more.jsx` | Supplier block · Line editor · Credit-term & VAT summary |
| 28 | แก้ไขเมนู + BOM | 1440×900 | `screens-more.jsx` | Menu list left · Modifier editor · Recipe BOM right with cost rollup |
| 29 | Multi-Branch HQ | 1440×900 | `screens-more.jsx` | 4 HQ KPI · 6 branch cards · Branch leaderboard · HQ alerts |
| **— Table ordering —** ||||
| 30 | ออกแบบผังโต๊ะ | 1440×900 | `screens-tableorder.jsx` | Left palette (tables + structures) · Snap-grid canvas with drag handles · Right property panel + per-table QR · Self-order toggles |
| 31 | ลูกค้าสแกน QR สั่งจากโต๊ะ | 390×844 | `screens-tableorder.jsx` | Gradient header (โต๊ะ T7) · Category chips · Promo banner · Menu cards · Call-waiter floating · Cart bar |
| 32 | ติดตามสถานะออเดอร์สด | 390×844 | `screens-tableorder.jsx` | Hero card + progress segments · 5-step timeline · Per-item status · Pay-at-table CTA |
| **— Customer Order Flow (Thai food restaurant) —** ||||
| 36 | เมนู · กริดรูปใหญ่ | 390×844 | `screens-customerorder.jsx` | Gradient table-badge header · Search · 7 category chips · Lunch-set hero banner · 2-col dish grid with 🌶 indicator · Avatar-stack cart bar |
| 37 | เลือกเมนู · ปรับแต่งจาน | 390×844 | `screens-customerorder.jsx` | Full-bleed dish hero (380px) · Bottom sheet with handle · Size/Spice/Add-ons selectors · Quick-meta tiles · Note-to-kitchen field · Qty stepper + Add-to-cart |
| 38 | ตะกร้า · รีวิว | 390×844 | `screens-customerorder.jsx` | Cart items with per-item options summary + note pill · Qty steppers · Coupon banner · Sticky summary card (Subtotal + Service Charge 10% + Total) · Send-to-kitchen CTA |
| 39 | ส่งครัวสำเร็จ | 390×844 | `screens-customerorder.jsx` | Big gradient hero · Animated check badge with ripple · Order #/Table/ETA triple-card · 4-step progress strip · Order-more + track-order CTAs |
| **— Loyalty —** ||||
| 33 | ระดับสมาชิก VIP/Gold/Premium | 1440×900 | `screens-loyalty.jsx` | 5 tier 3D cards · Tier editor · 8-benefit comparison matrix |
| 34 | ศูนย์ส่วนลด | 1440×900 | `screens-loyalty.jsx` | KPI · 8 rule-type discount table with toggles · Rule editor preview |
| 35 | Affiliate · ระบบแนะนำเพื่อน | 1440×900 | `screens-loyalty.jsx` | Hero "ค่าคอม 5%" · Partner table · 4 commission tiers · Referral link box |

---

## Build groups for the implementation phase

Group screens by domain when assigning work:

| Domain | Screens | Lead component |
|---|---|---|
| **Sales / POS Terminal** | 01, 02, 03, 04, 26 | `TpProductGrid`, `TpCart`, `TpPaymentMethod`, `TpReceipt` |
| **Secondary Displays** | 05, 06 | `TpKdsTicket`, `TpCustomerBoard` |
| **Customer / Loyalty** | 11, 24, 33, 34, 35 | `TpMemberCard`, `TpTierBadge`, `TpCouponTicket` |
| **Operations** | 08, 17, 18, 22, 23 | `TpDataGrid`, `TpStockBar`, `TpLabelSheet` |
| **Back-office reports** | 07, 12, 13, 14, 25, 29 | `TpKpi`, `TpChartLine`, `TpChartDonut`, `TpInvoiceDoc` |
| **People** | 20, 21 | `TpStaffRow`, `TpTimeline` |
| **Floor / Tables** | 09, 30 | `TpFloorPlan`, `TpTableTile` (designer drag), `TpQrCard` |
| **Mobile** | 10, 11, 31, 32, 36, 37, 38, 39 | `TpMobileShell`, `TpMobileTabBar`, `TpMobileMenu`, `TpDishCard`, `TpModifierSheet`, `TpCartRow` |
| **Vendor / Stock** | 27, 17 | `TpSupplierCard`, `TpPoLineEditor` |
| **Menu** | 28 | `TpModifierGroup`, `TpRecipeEditor` |

---

## Screen-size baselines

Always size containers to the **design canvas size**. Don't reflow.

- **Desktop POS terminal**: 1440 × 900 (most screens)
- **Customer / Kitchen display**: 1280 × 800 — slightly smaller, looser layout
- **iPad landscape**: 1024 × 768
- **iPhone / Android phone**: 390 × 844 (Pixel/iPhone 14 reference)
- **Thermal receipt**: 360 × 640 (80mm × 200mm preview)
- **Tax invoice document**: A4 portrait — render at 720 × 920 within preview frame

Build a `TpScreenScale` helper that scales the screen down for previews
in dev, but pins to native size at runtime.

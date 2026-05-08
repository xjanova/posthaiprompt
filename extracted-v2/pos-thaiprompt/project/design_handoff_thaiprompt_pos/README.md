# Handoff: Thaiprompt POS

## Overview
Thaiprompt POS เป็น Point-of-Sale สำหรับร้านอาหาร / ร้านค้าปลีกในประเทศไทย รองรับ
Windows desktop (จอแคชเชียร์ + Customer Display จอที่สอง + Kitchen Display), iPad
(พนักงานเสิร์ฟรับออเดอร์ที่โต๊ะ) และ iOS / Android phone (ผู้จัดการดูแดชบอร์ด).
ดีไซน์ออกมาเป็น 3D glassmorphism สดใส โทนเทอร์ควอยซ์ + ส้มประการัง + ทองสยาม.

This bundle covers the full UI surface of the product: 11 hi-fi screens across 4
form factors. The target stack is **C# (.NET) for Windows + cross-platform
mobile** — recommended choices below — but the screens themselves are
framework-agnostic.

## About the Design Files
ไฟล์ในชุดนี้เป็น **design reference ที่สร้างเป็น HTML/JSX prototypes** เพื่อแสดง
look-and-feel และพฤติกรรมที่ตั้งใจไว้ — **ไม่ใช่ production code ที่จะ copy
ตรงไปใช้**. งานของ developer คือ **ทำซ้ำดีไซน์เหล่านี้ใน target codebase** ตาม
แพทเทิร์นและไลบรารีที่ใช้อยู่เดิม. เนื่องจาก user ระบุชัดว่าต้องการ build ด้วย
**C# รันบน Windows + iOS + Android**, แนะนำสองทางเลือก:

- **.NET MAUI** (single C# codebase ครอบ Windows/iOS/Android) — ตรงสเปกที่สุด
- **Avalonia UI** (XAML แต่ cross-platform) — ถ้าต้องการ XAML-style binding
- **WinUI 3** สำหรับ Windows-only + **.NET MAUI** สำหรับ mobile (split, ถ้าทีมจะ
  เน้น performance บน Windows)

ในทุกกรณี: ใช้ HTML files ในนี้เป็น visual spec, สร้างใหม่ด้วย native controls
(`Border`, `Grid`, `CollectionView`, `Frame`) แทนที่จะ embed WebView.

## Fidelity
**High-fidelity (hi-fi)**. สี / ระยะห่าง / typography / shadow / blur / radius
เป็นค่าจริง. ขอ pixel-perfect recreate. Animations (slide-in, scale on press,
gradient sweep) เป็นแนวทาง — ปรับได้ตาม animation API ของ MAUI/Avalonia
(`VisualState`, `Storyboard`).

## Form Factors & Screen Inventory

| # | Screen | Form Factor | Size (design) | Source file |
|---|---|---|---|---|
| 1 | Login / PIN | Windows + Tablet | 1280 × 800 | `screens-display.jsx` (`LoginScreen`) |
| 2 | Cashier (main POS) | Windows | 1440 × 900 | `screens-cashier.jsx` (`CashierScreen`) |
| 3 | Payment | Windows modal | 1440 × 900 | `screens-payment.jsx` (`PaymentScreen`) |
| 4 | Receipt | Thermal 80mm | 380 × 720 | `screens-payment.jsx` (`ReceiptScreen`) |
| 5 | Customer Display | 2nd monitor | 1280 × 800 | `screens-display.jsx` (`CustomerDisplay`) |
| 6 | Kitchen Display (KDS) | 2nd monitor | 1280 × 800 | `screens-display.jsx` (`KitchenDisplay`) |
| 7 | Sales Dashboard | Windows | 1440 × 900 | `screens-back.jsx` (`DashboardScreen`) |
| 8 | Inventory | Windows | 1440 × 900 | `screens-back.jsx` (`InventoryScreen`) |
| 9 | iPad — Table service | iPad landscape | 1024 × 768 | `screens-mobile.jsx` (`TabletScreen`) |
| 10 | Mobile — Order at table | iOS / Android | 390 × 844 | `screens-mobile.jsx` (`MobileOrderScreen`) |
| 11 | Mobile — Manager dashboard | iOS / Android | 390 × 844 | `screens-mobile.jsx` (`MobileManagerScreen`) |

ดู layout และ component ของแต่ละหน้าจอจาก source file ที่ระบุ — ทุกหน้าเขียนเป็น
React component ที่ render ออกมาเป็น static markup ที่อ่าน-คัดลอกค่าได้ตรงๆ.

## Design Tokens

ทุก token ประกาศเป็น CSS custom properties ที่ `:root` ใน `styles.css` ส่วน
`@layer tokens`. คัดลอกค่าทั้งหมดเป็น `ResourceDictionary` (XAML) หรือ static
class ใน C#.

### Colors (light mode default)

| Token | Value (oklch) | Hex approx | Usage |
|---|---|---|---|
| `--tp-primary` | `oklch(0.66 0.13 var(--tp-primary-hue))` | `#0099B5` (hue 200) | Brand teal — buttons, headers, links |
| `--tp-primary-deep` | `oklch(0.42 0.12 var(--tp-primary-hue))` | `#055266` | Pressed / hover dark |
| `--tp-primary-soft` | `oklch(0.92 0.05 var(--tp-primary-hue))` | `#CFEAF2` | Tinted backgrounds, chips |
| `--tp-accent` | `oklch(0.72 0.17 var(--tp-accent-hue))` | `#FF7A6B` (hue 25) | CTA / coral accent |
| `--tp-gold` | `oklch(0.82 0.13 var(--tp-gold-hue))` | `#E8C66A` (hue 80) | Premium / highlights |
| `--tp-ink` | `oklch(0.22 0.04 250)` | `#1F2A3A` | Primary text |
| `--tp-ink-soft` | `oklch(0.45 0.04 250)` | `#5C6B7E` | Secondary text |
| `--tp-bg-1` | `oklch(0.98 0.01 220)` | `#F4F8FB` | Canvas background top |
| `--tp-bg-2` | `oklch(0.95 0.02 200)` | `#E5EFF3` | Canvas background bottom |
| `--tp-glass-fill` | `rgba(255,255,255,0.62)` | — | Glass surface fill |
| `--tp-glass-stroke` | `rgba(255,255,255,0.55)` | — | Glass border (top highlight) |
| `--tp-success` | `oklch(0.72 0.15 155)` | `#3CB371` | OK / paid |
| `--tp-warning` | `oklch(0.78 0.14 75)` | `#E8B14A` | Low stock |
| `--tp-danger` | `oklch(0.65 0.20 25)` | `#E8523C` | Out of stock / void |

Tweak panel hue defaults (user-adjusted in last session):
`primary_hue: 220`, `accent_hue: 25`, `gold_hue: 80`, `glass_blur: 32px`,
`background_warmth: cool`. **Implement these as live theme variables** so the
shopkeeper can re-tint the brand.

### Typography

- **UI font**: `"Prompt", "Inter", -apple-system, sans-serif` (ภาษาไทย+อังกฤษ คู่
  เดียวกัน — Google Font "Prompt" รองรับครบทั้งสองภาษา และเป็นที่มาของชื่อแบรนด์)
- **Numeric / receipt**: `"JetBrains Mono", "SF Mono", monospace`
- Weights ใช้: 400 (body), 500 (label), 600 (subtitle), 700 (title), 800
  (display number)

| Token | Size | Weight | Line height | Usage |
|---|---|---|---|---|
| `--type-display` | 64px | 800 | 1.05 | จำนวนเงิน, KPI |
| `--type-title` | 32px | 700 | 1.15 | Page title |
| `--type-subtitle` | 22px | 600 | 1.25 | Section header |
| `--type-body` | 16px | 400 | 1.45 | Body |
| `--type-label` | 13px | 500 | 1.3 | Tab, chip, table header (uppercase + 0.04em tracking) |
| `--type-mono` | 14px | 500 | 1.4 | Receipt, SKU, amounts in tables |

Mobile (390 wide) ใช้ scale `0.875×` ของค่าด้านบน.

### Spacing

`--space-1` 4px · `--space-2` 8px · `--space-3` 12px · `--space-4` 16px ·
`--space-5` 20px · `--space-6` 24px · `--space-8` 32px · `--space-10` 40px ·
`--space-12` 48px · `--space-16` 64px.

### Radius

`--radius-sm` 8px (chip) · `--radius-md` 14px (button) · `--radius-lg` 20px
(card) · `--radius-xl` 28px (panel) · `--radius-pill` 999px.

### Shadows / 3D

Glass surfaces ใช้ shadow stack 3 ชั้น — ห้าม flatten ลงเหลือชั้นเดียว, เป็น
key visual:

```
--shadow-glass:
  0 1px 0 rgba(255,255,255,0.85) inset,         /* top highlight */
  0 -1px 0 rgba(20,40,80,0.05) inset,           /* bottom shade  */
  0 14px 40px -12px rgba(20,40,80,0.18),        /* drop          */
  0 4px 12px -6px rgba(20,40,80,0.12);          /* contact       */

--shadow-pressed:
  0 1px 0 rgba(255,255,255,0.85) inset,
  0 2px 6px -2px rgba(20,40,80,0.18);

--shadow-float (for product tiles, FAB):
  0 24px 60px -18px rgba(20,40,80,0.22),
  0 8px 18px -8px rgba(20,40,80,0.12),
  0 1px 0 rgba(255,255,255,0.9) inset;
```

C# / XAML equivalent: `Shadow` element ซ้อน 2 ชั้น (XAML รองรับเดียว) — ใช้
`BoxView`/`Border` เป็น highlight strip ด้านบน 1px เพื่อจำลอง inset highlight.

### Glass surface recipe

```css
background: var(--tp-glass-fill);
backdrop-filter: blur(var(--tp-glass-blur, 24px)) saturate(1.4);
border: 1px solid var(--tp-glass-stroke);
border-radius: var(--radius-lg);
box-shadow: var(--shadow-glass);
```

ใน MAUI: ไม่มี backdrop-filter — ใช้ `Border` ที่ Background เป็น semi-transparent
white + ภาพพื้นหลังที่ blur ไว้แล้ว, หรือใช้ `Microsoft.Maui.Controls.SkiaSharp`
สำหรับ blur จริง. WinUI 3 มี `AcrylicBrush` (แนะนำ).

### Background

Canvas background = vertical linear gradient `--tp-bg-1` → `--tp-bg-2` +
**3 soft radial blobs** (turquoise top-left, coral top-right, gold bottom)
ที่ blur 120px และ opacity 0.35. ดู `.tp-canvas-bg` ใน `styles.css`.

## Screen-by-Screen Layout Notes

### 1. Login / PIN (1280 × 800)
- Centered glass card 480 × 560
- บนสุด: logo glyph (วงกลม gradient teal→navy, อักษร "ท" ตรงกลาง สีทอง) + ชื่อแบรนด์
- 6-digit PIN dots row, dynamic-island style
- 3×4 numpad keys (radius 20, glass, 80×80 each, 16px gap)
- Footer: branch name + role badge

### 2. Cashier (1440 × 900) — **screen หลักของระบบ**
3-column layout: `280px sidebar` · `1fr menu grid` · `420px cart`
- **Sidebar**: collapsible category list (icon + Thai label), staff avatar
  bottom, table-mode toggle
- **Menu grid**: filter chips ด้านบน (categories + "ขายดี" "เผ็ด" "ใหม่"), 4-col
  product tiles 200 × 220 each, glass พร้อม product image พื้นหลังเล่น parallax
  เบาๆ, ราคาตัวใหญ่มุมล่างขวา, badge "หมด" overlay เมื่อสต็อก = 0
- **Cart panel**: list items (qty stepper + line total), divider, ส่วนลด /
  หมายเหตุ, total breakdown (Sub / VAT 7% / Discount / **NET ตัวใหญ่**), CTA
  "ชำระเงิน" 100% width 64px high สีเทอร์ควอยซ์
- Top bar: order number, table number chip, cashier shift timer, sync
  status dot

### 3. Payment (1440 × 900) — modal style fullscreen
- Left 60%: payment method picker (Cash / QR PromptPay / Card / e-Wallet
  with Thai logos placeholder / Voucher) — large 280 × 180 cards
- Right 40%: order summary + numpad สำหรับรับเงินสด แสดง "เงินทอน" สดๆ
- เมื่อเลือก QR: render QR (placeholder) + countdown 90s + amount display
- Bottom: "ยกเลิก" + "ยืนยันการชำระเงิน" CTAs

### 4. Receipt (380 × 720) — thermal 80mm preview
- Mono font ทั้งใบ
- Logo + branch + tax ID
- Items: name | qty | price (right-aligned)
- Totals block + payment method + change
- QR ลูกค้าสมาชิก + thanks message
- Pixelated bottom edge mimic ใบเสร็จ

### 5. Customer Display (1280 × 800) — จอที่สองสำหรับลูกค้า
- Split: 60% order list (running total ตัวใหญ่ที่สุดในจอ — 96px), 40% rotating
  promo carousel (3 slots, auto-advance 6s)
- Top: ยินดีต้อนรับ + ชื่อลูกค้า (ถ้า login member) + วันที่/เวลา
- Bottom strip: branch QR สำหรับ feedback + ชวน follow social

### 6. Kitchen Display / KDS (1280 × 800)
- 5-column ticket grid (เลื่อนเพิ่มได้)
- แต่ละ ticket: header (โต๊ะ + เวลา + เลขออเดอร์) → list รายการ + qty + note
  (note สีส้ม) → footer "เริ่มทำ / เสร็จ" 2-state button
- Color-code ขอบบน ticket: เขียว < 5 นาที, เหลือง 5–10, แดง > 10
- Top bar: ตัวกรองสถานี (ครัวร้อน / ครัวเย็น / เครื่องดื่ม / ขนม) + เสียงแจ้ง
  เตือน toggle

### 7. Sales Dashboard (1440 × 900)
- 4 KPI cards บนสุด: ยอดขายวันนี้ / ออเดอร์ / ลูกค้าใหม่ / Avg basket — แต่ละ
  ใบมี delta % กับเมื่อวาน + sparkline 24 ชั่วโมง
- กราฟใหญ่ซ้าย 60%: ยอดขาย 7 วันล่าสุด area chart โทน teal-coral
- ขวา 40%: Top 5 เมนู (bar chart แนวนอน + thumbnail), staff leaderboard
- Bottom: heatmap ยอดขายรายชั่วโมง × วันในสัปดาห์
- Date range picker top-right (วันนี้ / 7 วัน / เดือน / Custom)

### 8. Inventory (1440 × 900)
- Table layout: SKU | ภาพ | ชื่อสินค้า | หมวด | คงเหลือ | min | ราคาทุน | ราคาขาย
  | สถานะ | actions
- เรียงตาม "ใกล้หมด" เป็นค่า default
- Status pill: เพียงพอ (เทอร์ควอยซ์) / ใกล้หมด (ทอง) / หมดแล้ว (ปะการัง)
- ฟิลเตอร์ chips ด้านบน + ปุ่ม "เพิ่มสินค้า" + "นำเข้า CSV" + "พิมพ์บาร์โค้ด"
- Right drawer (ปิดอยู่): edit form เมื่อคลิก row

### 9. iPad — Table service (1024 × 768 landscape)
- Floor plan view: ผัง 12 โต๊ะ ลากสลับได้
- Table tile: เลข + จำนวนคน + เวลานั่ง + สถานะสี (ว่าง / นั่ง / รอจ่าย / จองไว้)
- Bottom dock: shortcut "รับออเดอร์ใหม่" / "ย้ายโต๊ะ" / "รวมบิล"
- Tap โต๊ะ → push ไปหน้า cashier flow (ใช้ component เดียวกับจอ Windows scale
  ลง)

### 10. Mobile — Order at table (390 × 844)
- iOS-style status bar (ปล่อยให้ system render จริง — ใน mockup มี `IOSFrame`)
- Header: เลขโต๊ะ + จำนวนคน
- Quick category tabs (horizontal scroll)
- Menu list (full-width cards 100×100 image left + name/desc/price right)
- Sticky bottom: "ตะกร้า 4 รายการ · ฿ 580" CTA
- FAB: ค้นหา / สแกน QR เมนู

### 11. Mobile — Manager dashboard (390 × 844)
- Greeting + branch picker
- 2×2 KPI grid
- "วันนี้" sales line chart compact
- ลิสต์: รายการที่ต้องอนุมัติ (ส่วนลดเกินสิทธิ์, void, ปิดกะ) — swipe-to-act
- Bottom tab bar: Home / Orders / Inventory / Reports / More

## Interactions & Behavior

### Global
- **Press**: scale 0.97 + shadow ลดเหลือ `--shadow-pressed` (160ms cubic-bezier
  0.2, 0.8, 0.2, 1)
- **Hover** (desktop only): scale 1.02 + brighten 4%
- **Selection**: 2px ring ในสี `--tp-primary` + shadow ขยาย
- **Drawer slide-in**: 240ms ease-out, translateX 100% → 0
- **Modal**: backdrop fade 200ms + modal scale 0.96 → 1 (220ms)
- **Toast**: slide down from top, 3s auto-dismiss

### Cashier
- เพิ่มสินค้าเข้า cart → tile เด้ง bounce + cart row slide-in highlight 600ms
- Qty stepper: long-press = repeat (50ms interval หลัง 400ms hold)
- เคลียร์ cart มี confirm dialog
- รองรับ barcode scanner (USB HID keyboard wedge) — ฟัง global keypress + Enter

### Payment
- เลือก method → ขยาย card นั้น ลด opacity ของ card อื่นๆ (ไม่หายไป)
- QR payment: poll backend ทุก 2s, success → confetti 1s + auto-print receipt
- Cash: ปุ่ม preset 100/500/1000/พอดี + numpad — เงินทอนคำนวณ live

### Kitchen
- ออเดอร์ใหม่เข้า: slide-in from right + soft chime (default on)
- กดเสร็จ → ticket fade + slide out 300ms, ticket อื่น re-flow

### State management requirements
- **Order draft** (cart) ต้อง persistable / resumable หาก crash — local SQLite
- **Sync state**: online/offline/sync-pending dot ใน top bar; offline mode ต้อง
  enqueue ออเดอร์
- **Multi-screen**: cashier ↔ customer display ↔ KDS ใช้ same source of truth
  (recommend SignalR hub ในตัว app, หรือ named-pipe สำหรับ Customer Display
  เครื่องเดียวกัน)
- **Multi-branch**: ทุกหน้าจอผูก `branchId` + `terminalId`

## Assets Used in Mockups
- **Fonts**: Google Fonts "Prompt" (200–700) + "Inter" (400–700) + "JetBrains
  Mono" — ใน production embed ในแอป (license: SIL Open Font ทั้ง 3 ตัว, OK
  bundle)
- **Images**: ทุกภาพอาหาร / สินค้าใน mockup เป็น **monochrome SVG placeholder**
  ที่มี label monospace (เช่น `IMAGE: ผัดไทย`). ใช้รูปจริงของลูกค้าตอนติดตั้ง
- **Icons**: ใช้ Lucide-style stroke icons (1.5 stroke, 24px) — ใน MAUI ใช้
  `FontImageSource` กับ Material Symbols หรือ Phosphor

## Files in This Bundle

| File | Description |
|---|---|
| `index.html` | Top-level design canvas (รวม 11 หน้าจอใน DCArtboards) — เปิดในเบราเซอร์เพื่อ preview |
| `styles.css` | Design tokens + global glass styles + canvas background |
| `tp-shared.jsx` | Shared sub-components (`<TPGlassCard>`, `<TPButton>`, `<TPChip>`, `<TPLogo>`, etc.) — อ่านเพื่อรู้ component vocabulary |
| `screens-cashier.jsx` | Cashier (#2) |
| `screens-payment.jsx` | Payment (#3) + Receipt (#4) |
| `screens-display.jsx` | Login (#1) + Customer Display (#5) + Kitchen Display (#6) |
| `screens-back.jsx` | Dashboard (#7) + Inventory (#8) |
| `screens-mobile.jsx` | Tablet (#9) + Mobile order (#10) + Mobile manager (#11) |
| `design-canvas.jsx` | Pan/zoom canvas wrapper (ไม่ใช่ส่วนของ product UI — แค่ presentation shell) |
| `tweaks-panel.jsx` | Theme tweak panel (ไม่ใช่ส่วนของ product UI) |

## Implementation Priority (suggested)
1. Design tokens → `Resources/Styles/Tokens.xaml` (หรือ MAUI `App.xaml`)
2. Shared controls: GlassCard, TPButton, Chip, KPI, ProductTile
3. Cashier screen (highest value, สูงที่สุดของ product)
4. Payment + Receipt
5. Customer Display + KDS (แชร์ realtime hub)
6. Login
7. Dashboard + Inventory
8. Mobile + Tablet (cross-platform MAUI project)

## Notes
- ห้าม embed WebView เพื่อรัน HTML — recreate ด้วย native controls
- 3D glass effect บน Windows 10 อาจ fall back ไปเป็น flat semi-transparent
  (ตรวจ `IsAcrylicSupported`) — ออกแบบให้ degrade อย่างนุ่มนวล
- ทุก string ภาษาไทย วาง `Resx` ตั้งแต่ต้น เพื่อรองรับ EN ในอนาคต
- ราคาทั้งหมดใน mockup ใช้สมมติ — แทนที่ด้วย data จริงของลูกค้า

---
ออกแบบโดย: Designer (Anthropic Claude) · Handoff target: Claude Code

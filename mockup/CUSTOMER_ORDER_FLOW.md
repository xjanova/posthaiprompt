# Customer Order Flow — Screens 36–39

**Fidelity: HI-FI** — pixel-perfect mockups. Recreate exactly.

Customer-facing self-order flow for an in-restaurant Thai food shop ("ครัวคุณยาย").
Customer scans a QR at the table → these 4 screens are the whole experience.

> **About these files**: the bundled `screens-customerorder.jsx` + `index.html`
> are **design references created in HTML**. The task is to recreate them in the
> target environment (.NET MAUI / WinUI / Avalonia / SwiftUI / React Native /
> Flutter — match the rest of the app) using existing patterns. Do not ship
> the HTML directly.

All four screens use the **390 × 844** iPhone-Pro viewport. Inside the project
they are wrapped by the `PhoneFrame` helper that adds a notch (110×32) and home
indicator (134×5) — drop those in a native app and use the device chrome
instead.

---

## Shared building blocks

| Helper (JS name) | What it does | Native equivalent |
|---|---|---|
| `PhoneFrame` | 390×844 surface, ambient bg, notch + home indicator | Page root |
| `StatusBar({time, dark})` | iOS-style time + wifi + battery | OS status bar |
| `DishImg({hue, label})` | Procedural plate-on-gradient placeholder. `hue` is OKLCH hue (0–360) | Real photo from CMS — drop the placeholder |
| `TPLogo size={36}` | Multilayer SVG "TP" mark | Existing logo asset |
| `TPIcon name=...` | Stroke-based icon set (search, bell, fire, clock, leaf, …) | Existing icon set |

All tokens (`--tp-teal`, `--tp-coral`, `--tp-ink`, etc.) come from `App.xaml` /
`DESIGN_TOKENS.json` in the parent bundle. **Do not invent new values.**

The cart bar and CTA buttons in screens 36/37/38 use a **dark cinnamon gradient**
that's specific to this flow (not in the main token set):

```
background: linear-gradient(160deg, oklch(0.38 0.12 18) 0%, oklch(0.22 0.08 25) 100%);
```

Sampled in sRGB:
- top: `#6B3221` (rgb 107, 50, 33)
- bottom: `#3A1E18` (rgb 58, 30, 24)

Register as `Tp.Brush.Cinnamon` (LinearGradient 160°, two stops).

---

## 36 · Menu (grid)

**Purpose**: customer browses dishes, taps + to add directly, or taps card to customize.

### Layout (top → bottom, 390 wide)

| Y range | Block |
|---|---|
| 0–50 | iOS status bar (`19:24`) |
| 50–196 | **Header** — TPLogo 36 + greeting "สวัสดี · ยินดีต้อนรับสู่" + venue name "ครัวคุณยาย · สยาม สแควร์" + **Table badge T7** (right, gradient pill). Below: search input 44 high, white card, magnifier icon + placeholder "ค้นหาเมนู เช่น 'กะเพรา'" + 30×30 filter button (teal gradient). |
| 196–242 | **Category chips** — horizontal scroll, 36 high, 6px gap. Active chip = dark indigo gradient `oklch(.32 .08 265) → oklch(.20 .06 270)`; inactive = white-ish with `var(--tp-line)` border. 7 cats: แนะนำ ★, ข้าว 🔥, ก๋วยเตี๋ยว, ยำ/ส้มตำ, ทอด/ย่าง, เครื่องดื่ม ☕, ของหวาน ★. |
| 246–354 | **Lunch-set hero banner** — cinnamon-gradient card 108 high, radius 20. Round inset photo (80×80, white border 2px) top-right. "Set อาหารกลางวัน" gold pill. Headline "กะเพรา + น้ำดื่ม". Price: gold ฿89, strike-through ฿105, "· ถึง 14:00". |
| 372 | Section title "แนะนำสำหรับคุณ · 6 จาน · ดูทั้งหมด ›" |
| 402–742 | **Dish grid** — 2 columns, 12px gap. Each card: 120-high image + 12px padding label. Tag pill top-left (coral / gold / leaf / teal variants). 🌶 spice indicator top-right (black blur pill, repeat count = spice level). Card body: 13/600 name (2-line min-height 32), 10/400 desc clip-1, 15/800 price + 30×30 teal-gradient `+` button. |
| 742–760 | (overflow into cart bar shadow) |
| (floating) | **Call-waiter FAB** — 48×48 white square 16-radius, bell icon coral, label "เรียก", positioned `right: 16, bottom: 112`. |
| (sticky) | **Cart bar** — cinnamon gradient, 14px margin, 22-radius, 10/14 pad. **Avatar stack** 3 dish thumbs 36×36 overlapping -10px, 2px dark border. "ในตะกร้า · 3 จาน / ฿415". Gold pill button "ดูตะกร้า ›". |

### Sample dish data (use for placeholder content only)

```
ข้าวกะเพราหมูสับไข่ดาว   ฿75  hue 25  tag "ขายดี #1" coral  spice 2
ผัดไทยกุ้งสด            ฿120 hue 45  tag "Signature" gold
ต้มยำกุ้งน้ำข้น          ฿220 hue 18  tag "แนะนำ" teal       spice 3
ส้มตำไทยปูม้า           ฿95  hue 130                          spice 3
แกงเขียวหวานไก่          ฿110 hue 145
ข้าวเหนียวมะม่วง         ฿85  hue 90  tag "ตามฤดู" leaf
```

---

## 37 · Item Customize

**Purpose**: configure size / spice / add-ons / note before adding to cart.

### Layout

| Y range | Block |
|---|---|
| 0–380 | **Full-bleed dish hero** — `DishImg hue=25`. Top gradient overlay `rgba(0,0,0,.35) → transparent` for status-bar legibility. |
| 0–50 | Status bar (`dark`) — white text over image |
| 56–94 | Top nav row over image: 38×38 glass back button (left), pill "📍 โต๊ะ T7" (right). Both `rgba(0,0,0,.3)` + `backdropFilter: blur(10px)` + 1px white-25 border. |
| 320–844 | **Sheet** — `oklch(.985 .008 220)` cream, top corners 28-radius. 12/22 pad. 44×5 grab handle. |
| 320+ | Tags row — "ขายดี #1" coral + "🌶 เผ็ดกลาง" peach. Title 22/800 "ข้าวกะเพราหมูสับไข่ดาว". Desc 12/400 mute. Top-right rating chip "★ 4.9" (gold gradient). |
| (within sheet) | **Quick-meta** — 3 equal-flex tiles (white, 1px line, 12-radius): ⏰ ~12 นาที · 🔥 520 kcal · 🍃 ไม่มีถั่ว. |
| (within sheet, scrollable) | **Options**: |
| | **ขนาด \* จำเป็น · เลือก 1** — 3-col grid: ปกติ / **พิเศษ +15** (active = indigo gradient `oklch(.32 .08 265)`) / จัมโบ้ +30. |
| | **ระดับความเผ็ด** — 4-col: ไม่เผ็ด — / น้อย 🌶 / **กลาง 🌶🌶** (active = peach `oklch(.94 .10 28)` border `oklch(.65 .18 25)`) / เผ็ดมาก 🌶🌶🌶🌶. |
| | **เพิ่มเติม · เลือกได้หลายอย่าง** — vertical list with custom 22×7 checkbox (teal gradient when on). Items: "ไข่ดาวเพิ่ม 1 ฟอง +฿15" ✓, "ขอข้าวเพิ่ม +฿10", "พริกน้ำปลาเพิ่ม ฟรี" ✓, "ไม่ใส่กระเทียม ฟรี". |
| | **หมายเหตุถึงร้าน** — 60-min-height white text-area "ไม่ใส่ผักชี แพ้กลิ่น 🙏". |
| (sticky) | **Action row** — Qty stepper (white, 18-radius, padded; — / **2** / + with teal-gradient + button) + main CTA "เพิ่มลงตะกร้า | ฿180" (cinnamon gradient, 56-high, 18-radius, white text). |

### State variables

```
sizeId          enum  small | regular* | jumbo            (required)
spice           enum  none  | mild | medium* | hot
addons          set   "extra-egg" | "extra-rice" | …       (multi)
note            string
qty             int   ≥ 1
totalPrice      computed = base*qty + size.delta + addon.deltas (×qty)
```

Disable Add-to-cart if `sizeId` not chosen.

---

## 38 · Cart Review

**Purpose**: customer sees everything in cart, edits quantities / removes / applies coupon, then sends to kitchen.

### Layout

| Y range | Block |
|---|---|
| 0–50 | Status bar |
| 50–108 | Nav row — back button + "ตะกร้าของคุณ · 📍 โต๊ะ T7 · 2 ท่าน" + coral 🗑 trash-all button. |
| 108–540 | **Item list** (scrollable). Each row: 76×76 dish thumb · name 14/700 + 22×22 × delete · options 10/400 mute · note pill `oklch(.96 .04 80)` peach if present · row-total 15/800 teal + 26-high qty stepper. Border 1-px white-70, glass bg, 18-radius, 10px gap. |
| (end of list) | **"+ สั่งเพิ่มอีกจาน"** dashed teal CTA, full-width 14-pad. |
| (after) | **Coupon banner** — gold gradient `oklch(.96 .08 80) → oklch(.92 .10 70)`, tag icon, body "มีโค้ดส่วนลด? · สมาชิก Gold ใช้โค้ด TP-GOLD", "ใส่โค้ด" dark button right. |
| (sticky, bottom 24, left/right 14) | **Summary card** — glass, 24-radius, 18-pad. Rows "ค่าอาหาร (4 จาน) ฿730" + "Service Charge 10% ฿73" 12/400 mute. Divider line. "ยอดรวม" small uppercase label + **฿803** 26/800. Right column note "ชำระที่โต๊ะ / หลังเสิร์ฟครบ". CTA full-width 56-high "🔥 ส่งครัวเลย · เริ่มทำทันที →" cinnamon gradient with gold flame icon. |

### State

```
items[]   {dishId, options[], note, qty, unitPrice}
subtotal  = Σ items[i].lineTotal
service   = subtotal × 0.10   (configurable per branch)
total     = subtotal + service
couponCode optional
```

---

## 39 · Order Confirmation

**Purpose**: celebrate, give order number, expected wait, allow tracking.

### Layout

| Y range | Block |
|---|---|
| 0–50 | Status bar |
| 60–714 | **Hero card** (left/right 18 inset, bottom 130) — gradient `oklch(.78 .14 188) → oklch(.45 .14 250) → oklch(.30 .12 270)`, 28-radius. |
| (within hero) | **Decorative orbs** — gold orb 200×200 top-right (radial gold blur), coral orb 140×140 left mid. Both `filter: blur(8–10px)`. |
| (50 from top of card) | **Check badge** — 96×96 circle, gold-coral gradient `oklch(.85 .14 80) → oklch(.65 .14 60)`, 4px white-40 border. ✓ icon 48 white stroke-3. Two concentric "ripple" rings (-12 / -24 inset, 2px white-25 / white-12). |
| (180 from top) | **Headline** — "ส่งครัวเรียบร้อย ✨" 28/800 white, then 13/400 sub "ครัวรับออเดอร์แล้ว · เริ่มทำทันที / นั่งสบายๆ ได้เลยค่ะ". |
| (220 from top) | **Triple stat card** — glass `rgba(255,255,255,.14)` + backdrop-blur, 18-radius, 18-pad. 3 columns separated by 1×30 white-30 dividers: ORDER # `A1042` · TABLE `T7` · ETA `~14นาที`. All numbers tnum 22/800 mono. |
| (28 from bottom of hero) | **Progress strip** — 4 steps (ส่งครัว ✓ · **ครัวรับ** 🔥 active · กำลังทำ ☕ · เสิร์ฟ ★). Active step = gold-coral gradient circle with 0 0 0 4px gold-25 halo + box-shadow gold-65. Completed = white solid circle, indigo icon. Future = transparent 1px white-25 border. Below: 4px white-18 track with 42%-wide gradient fill (gold→coral) + glow. |
| (bottom 24, left/right 14) | **Action row** — 56-high · "+ สั่งเพิ่ม" white outline button (flex 1) · **📄 ติดตามออเดอร์** cinnamon gradient (flex 1.5). |

### State / behavior

- `orderId` (e.g. "A1042"), `tableId` (e.g. "T7"), `etaMinutes` (e.g. 14).
- Subscribe to live order updates via WebSocket/SignalR; transition progress
  strip as states arrive (ส่งครัว → ครัวรับ → กำลังทำ → เสิร์ฟ).
- "ติดตามออเดอร์" → screen 32 (`OrderStatusScreen`, already in bundle).

---

## End-to-end flow

```
[scan QR] → 36 Menu
            │  tap dish card → 37 Customize → "Add to cart" → back to 36
            │  tap + on card → adds default config straight to cart
            │  tap "ดูตะกร้า" → 38 Cart
            │                  edit qty / note / coupon
            │                  tap "ส่งครัวเลย" → POST /orders → 39 Confirmation
            │                                                     │ "ติดตามออเดอร์" → 32 Live status
            │                                                     │ "+ สั่งเพิ่ม" → back to 36
```

---

## Implementation notes

1. **Cinnamon gradient is the only new color in this flow** — register as a
   single named brush; never inline the hex.
2. **Bottom sheet in 37** is full-page in this design (no peek mode). On
   native, prefer a `Sheet` / `PresentationDetent(.large)` style. The
   draggable handle is decorative — sheet does not collapse.
3. **Spice level** uses literal `🌶` emoji repetition. If your icon set
   provides a chili glyph, swap it in for consistency with the rest of the
   app.
4. **Service Charge is hard-coded 10%** in the mockup. Real implementation
   reads `Branch.ServiceChargePercent` (already exists on branch settings).
5. **Coupon banner** is presentational only — the actual coupon flow lives
   in screen 34 (Discount Center). When user taps "ใส่โค้ด", show your
   existing modal/sheet from that flow.
6. **No login required** in this flow — the table session is identified by
   the QR token. If the owner has enabled "ต้องล็อกอินด้วยเบอร์โทร" in floor
   plan settings (screen 30 right panel), prepend a phone-OTP step.

---

*Screens 36–39 · added 2026-05-17 · 390×844 mobile*

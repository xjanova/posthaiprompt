# Thaiprompt POS — Mockup

**Created by xman studio** · Visual prototype for the cross-platform POS app to be built at
[github.com/xjanova/posthaiprompt](https://github.com/xjanova/posthaiprompt). Syncs with
[github.com/xjanova/Thaiprompt-Affiliate](https://github.com/xjanova/Thaiprompt-Affiliate).

> **23 screens + 2 docs** · Thai + English · standalone HTML · 51 clickable hot-links wiring screens together

---

## วิธีเปิดดู / How to view

เปิดไฟล์ `index.html` ในเบราเซอร์ใดก็ได้ — ไม่มี build step, ไม่มี server.

```
start E:\Code\POS Thaiprompt\mockup\index.html       (Windows)
open  mockup/index.html                              (Mac)
```

หรือใช้ Python http server:

```
python -m http.server 8080 --directory mockup
```

---

## โครงสร้างไฟล์ / Files

```
mockup/
├── index.html          ← entry point (open this in browser)
├── README.md
├── css/
│   ├── tokens.css      ← design tokens (oklch, radii, glass shadows)
│   └── styles.css      ← layout, components, screen frames
└── js/
    ├── i18n.js         ← Thai + English string dictionaries
    ├── icons.js        ← SVG icons + 3D brand mark + fake QR/barcode
    ├── screens.js      ← 23 screen renderers + 51 hot-link wires
    └── app.js          ← shell + nav rail + language toggle
```

---

## หน้าจอที่ครอบคลุม / 23 Screens

### 🏪 งานหน้าร้าน / Front of House
| #  | Screen                | Form factor       | Routes to                              |
|----|-----------------------|-------------------|----------------------------------------|
| 01 | Login / PIN           | 1280×800 Windows  | → Cashier                               |
| 02 | Cashier (main POS)    | 1440×900 Windows  | → Payment, Inventory, Dashboard, Tablet, Admin, Coupons, Staff, Login |
| 03 | Payment               | 1100×800 modal    | → Receipt, NFC Scan, Coupons, Cashier  |
| 15 | NFC Card Scan         | 1280×800          | → Payment, Cashier                      |
| 04 | Receipt               | 380×720 thermal   | → Cashier, Customer Display, KDS       |

### 📺 จอที่สอง / Secondary Displays
| #  | Screen                | Form factor       | Notes                                   |
|----|-----------------------|-------------------|-----------------------------------------|
| 05 | Customer Display      | 1280×800 2nd mon  | Promo carousel · running total          |
| 06 | Kitchen Display (KDS) | 1440×900          | 5-col tickets · color-coded by elapsed |

### 🗄️ งานหลังบ้าน / Back Office
| #  | Screen                | Form factor       | Routes to                              |
|----|-----------------------|-------------------|----------------------------------------|
| 07 | Sales Dashboard       | 1440×900          | → Inventory, Accounting, Staff, Coupons, Sync API |
| 08 | Inventory             | 1440×900          | → Barcode, Stock Mgmt, Admin           |
| 17 | Stock Movements       | 1440×900          | → Inventory, Barcode                    |
| 20 | Staff                 | 1440×900          | → Accounting (payroll)                  |

### 💰 บัญชี & เอกสาร / Accounting & Docs
| #  | Screen                | Form factor       | Routes to                              |
|----|-----------------------|-------------------|----------------------------------------|
| 12 | Accounting / CoA      | 1440×900          | → Create Bill                           |
| 13 | Create Bill           | 1440×900          | → Tax Invoice, Accounting              |
| 14 | Tax Invoice / e-Tax   | 1440×900          | (ready to send to RD)                  |
| 19 | Coupons / Promotions  | 1440×900          | → Dashboard (ROI)                       |

### 🚚 ระบบจัดการ / Operations
| #  | Screen                | Form factor       | Routes to                              |
|----|-----------------------|-------------------|----------------------------------------|
| 16 | Delivery / Riders     | 1440×900          | → Shipping Providers, Shipping Label   |
| 18 | Shipping Providers    | 1440×900          | → Shipping Label, Admin                 |
| 21 | Admin Settings        | 1440×900          | → Tax Invoice, Payment, Shipping, Sync |

### 🏷️ พิมพ์ฉลาก & พัสดุ / Labels & Shipping
| #  | Screen                | Form factor       | Routes to                              |
|----|-----------------------|-------------------|----------------------------------------|
| 22 | Barcode Manager       | 1440×900          | → Inventory                             |
| 23 | Shipping Labels       | 1440×900          | → Shipping Providers, Delivery          |

### 📱 iOS / Android
| #  | Screen                | Form factor       | Routes to                              |
|----|-----------------------|-------------------|----------------------------------------|
| 09 | iPad Floor Plan       | 1024×768          | → Cashier (new order), Create Bill      |
| 10 | Mobile · Order        | 390×844           | → Payment (cart), Cashier, Barcode      |
| 11 | Mobile · Manager      | 390×844           | → Cashier, Stock Mgmt, Staff, Dashboard, Admin, Inventory |

### 📚 Meta
- **Overview** — index of every screen, click any card to navigate
- **Architecture** — .NET MAUI stack, project structure, tech choices
- **Sync & API** — REST endpoints, outbox pattern, conflict resolution

---

## User flow diagram

```
                ┌──────────┐
                │  Login   │
                └─────┬────┘
                      ↓ (sign in)
       ┌──────────────────────────────────┐
       │           Cashier                │ ← top of every flow
       └─┬───┬───┬───┬───┬───┬───┬─────┬──┘
         │   │   │   │   │   │   │     │
         ↓   ↓   ↓   ↓   ↓   ↓   ↓     ↓
    Payment  Inv  Dash Tab Adm Coup  Staff  Logout
       │
       ↓ (confirm)
   ┌──────────┐
   │ Receipt  │ ─→ Customer Display, KDS, back to Cashier
   └──────────┘

   Card payment: Payment → NFC Scan → Receipt
   Cash payment: Payment (numpad) → Receipt
   QR PromptPay: Payment → NFC Scan (countdown) → Receipt

   Back office:
   Dashboard ⇄ Accounting ⇄ Create Bill → Tax Invoice (e-Tax)
                          ⇄ Coupons (ROI)
                          ⇄ Staff (payroll)

   Operations:
   Delivery ⇄ Shipping Providers → Shipping Label (4×6")
   Inventory ⇄ Stock Movements ⇄ Barcode Manager

   Mobile:
   Mobile Order ⇄ Cashier (table)
   Mobile Manager ⇄ Dashboard, Stock Mgmt, Staff, Inventory, Admin
```

---

## ภาษา / Languages

ทุก string ผ่าน `window.I18N.t(key, vars)` หรือ inline `tr("ไทย", "English")`. คลิกปุ่ม **ไทย / EN** ที่มุมขวาบนเพื่อสลับภาษาทันที — ทุกหน้า re-render พร้อม strings ใหม่.

ตำแหน่งคำแปล:
- **i18n.js** — strings ทั่วไปของ shell + nav
- **screens.js** — strings เฉพาะ screen ใช้ helper `tr(th, en)`

เพิ่มภาษาใหม่: เพิ่ม object ใหม่ใน `window.I18N` แล้วเพิ่มปุ่มใน `app.js`.

---

## Hot-link wiring (51 routes)

Mockup นี้ไม่ใช่แค่ static — ทุกปุ่มสำคัญกดได้ และนำไปยังหน้าที่เกี่ยวข้อง:

- ปุ่มทั้งหมดที่ navigate ใช้ `data-route="<screen-id>"` attribute
- `app.js` ทำ event delegation บน root element — จับ click event แล้ว navigate
- การ์ดใน Overview มี `data-nav` เช่นกัน — กด card ไปดู screen นั้น

ตัวอย่าง:
```html
<button class="tp-btn tp-btn-coral" data-route="payment">
  ชำระเงิน · ฿415
</button>
```

Click → `app.js` หา closest `[data-route]` → call `navigate("payment")` → render Payment screen.

---

## Design tokens

ทุกค่าอยู่ใน `css/tokens.css`:
- **สี**: teal `oklch(.72 .13 190)`, coral `oklch(.72 .18 25)`, gold `oklch(.82 .14 85)`, indigo `oklch(.30 .08 265)`
- **เรเดียส**: 10/16/22/30/999
- **Glass shadow**: 4-layer stack (top highlight inset + bottom shade inset + drop + contact)
- **Type**: Prompt (TH+EN, 200–800) + JetBrains Mono (numerics)

---

## ขั้นตอนต่อไป / Next steps

1. แสดง mockup นี้ให้ stakeholder ดูเพื่อ sign-off design
2. สร้าง .NET MAUI project ที่ `posthaiprompt/` ตามโครงสร้างใน `docs/ARCHITECTURE.md`
3. แปลง design tokens เป็น `Resources/Styles/Tokens.xaml`
4. สร้าง shared controls (`GlassCard`, `TPButton`, `Chip`, `KPI`, `ProductTile`)
5. ลำดับ implement (M1 → M8) ตาม `docs/ARCHITECTURE.md` Roadmap

---

## Credits

- **Design system**: based on `design_handoff_thaiprompt_pos` reference bundles (v1 + v2)
- **Mockup**: Claude Code · xman studio · 2026-05-08
- **Fonts**: Google Fonts "Prompt" + "JetBrains Mono" (SIL Open Font License)
- **Icons**: Lucide-inspired stroke set, hand-coded as inline SVG

---

Built with ❤ by **xman studio**

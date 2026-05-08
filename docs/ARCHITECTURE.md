# Architecture — Thaiprompt POS

> Cross-platform C# .NET MAUI · SQLite · Offline-first · Syncs with Thaiprompt-Affiliate

## เป้าหมาย

1. **โค้ดเดียว** ครอบ Windows / iOS / Android / macOS
2. **ออฟไลน์ได้เต็มรูปแบบ** — ตัดบิล / รับชำระ / พิมพ์ใบเสร็จ ไม่ต้องมีเน็ต
3. **สวยตามดีไซน์** — 3D glassmorphism, animation 60 fps
4. **ซิงก์อัตโนมัติ** กับ Thaiprompt-Affiliate API เมื่อ network กลับมา
5. **รองรับ multi-terminal** — cashier ↔ KDS ↔ customer display

---

## Solution structure

```
posthaiprompt/
├── src/
│   ├── PosThaiprompt.Core/          # Domain models, services, contracts (no UI)
│   │   ├── Entities/
│   │   │   ├── Product.cs
│   │   │   ├── Order.cs
│   │   │   ├── OrderLine.cs
│   │   │   ├── Payment.cs
│   │   │   ├── Branch.cs
│   │   │   ├── User.cs
│   │   │   ├── Promotion.cs
│   │   │   └── StockMovement.cs
│   │   ├── Services/
│   │   │   ├── IOrderService.cs
│   │   │   ├── IPaymentService.cs
│   │   │   ├── IPricingService.cs
│   │   │   ├── ICatalogService.cs
│   │   │   └── IInventoryService.cs
│   │   ├── Money.cs                 # ValueObject for THB amounts
│   │   └── DomainEvents.cs
│   │
│   ├── PosThaiprompt.Data/          # SQLite persistence (EF Core)
│   │   ├── PosDbContext.cs
│   │   ├── Configurations/
│   │   ├── Migrations/
│   │   └── Outbox/
│   │       ├── OutboxMessage.cs     # idempotency-key + payload
│   │       └── OutboxDispatcher.cs
│   │
│   ├── PosThaiprompt.Sync/          # Thaiprompt-Affiliate sync layer
│   │   ├── ITpAffiliateApi.cs       # Refit interface
│   │   ├── SyncWorker.cs            # BackgroundService — push/pull every 30s
│   │   ├── ConflictResolver.cs      # Last-Write-Wins on updatedAt
│   │   └── DeltaCursor.cs           # since-token bookkeeping
│   │
│   ├── PosThaiprompt.Hardware/      # Printers, scanners, cash drawer
│   │   ├── IThermalPrinter.cs
│   │   ├── EscPosPrinter.cs
│   │   ├── IBarcodeReader.cs
│   │   └── HidKeyboardWedgeReader.cs
│   │
│   ├── PosThaiprompt.App/           # MAUI app (UI)
│   │   ├── MauiProgram.cs
│   │   ├── App.xaml
│   │   ├── Resources/
│   │   │   ├── Styles/
│   │   │   │   ├── Tokens.xaml      # Colors, fonts, radii (mirror of mockup tokens.css)
│   │   │   │   └── Glass.xaml       # GlassCard, TPButton styles
│   │   │   ├── Strings/
│   │   │   │   ├── AppResources.resx     # default = th
│   │   │   │   └── AppResources.en.resx  # English
│   │   │   └── Fonts/
│   │   │       ├── Prompt-{200..700}.ttf
│   │   │       └── JetBrainsMono-{400,500,600}.ttf
│   │   ├── Controls/                # Reusable UI primitives
│   │   │   ├── GlassCard.cs
│   │   │   ├── TPButton.cs
│   │   │   ├── Chip.cs
│   │   │   ├── KpiCard.cs
│   │   │   └── ProductTile.cs
│   │   ├── Views/
│   │   │   ├── LoginPage.xaml
│   │   │   ├── CashierPage.xaml
│   │   │   ├── PaymentPage.xaml
│   │   │   ├── ReceiptPage.xaml
│   │   │   ├── CustomerDisplayPage.xaml
│   │   │   ├── KitchenDisplayPage.xaml
│   │   │   ├── DashboardPage.xaml
│   │   │   ├── InventoryPage.xaml
│   │   │   ├── TabletFloorPage.xaml
│   │   │   ├── MobileOrderPage.xaml
│   │   │   └── MobileManagerPage.xaml
│   │   ├── ViewModels/
│   │   │   ├── CashierViewModel.cs
│   │   │   ├── PaymentViewModel.cs
│   │   │   └── …
│   │   └── Platforms/
│   │       ├── Windows/             # MSIX manifest, AcrylicBrush
│   │       ├── Android/             # MainActivity, MainApplication
│   │       └── iOS/                 # AppDelegate, Info.plist
│   │
│   └── PosThaiprompt.Tests/         # xUnit + bUnit + Moq
│       ├── Domain/
│       ├── Sync/
│       └── Integration/
│
├── docs/
│   ├── ARCHITECTURE.md   ← this file
│   └── SYNC_API.md
└── posthaiprompt.sln
```

---

## เลเยอร์และความรับผิดชอบ

### 1. Core (PCL, ไม่มี UI)

- **Entities** — POCO ตรงกับ DB schema
- **Services** — interfaces ที่ ViewModels เรียกใช้ (ผ่าน DI)
- **Money** — value type สำหรับ THB เก็บเป็น `long` cents เพื่อหลีกเลี่ยง float drift
- **Domain events** — `OrderPaidEvent`, `StockDepletedEvent` ส่งผ่าน MediatR

### 2. Data (SQLite + EF Core)

- **PosDbContext** — main connection
- **Migrations** — `dotnet ef migrations add InitialCreate -p Data -s App`
- **Outbox** — ทุก write ที่ต้องส่งกลับ Affiliate ลง outbox table
  ก่อน. ถูก dispatch โดย `SyncWorker`
- **Encryption** — SQLCipher (`Microsoft.Data.Sqlite` + `SQLitePCLRaw.bundle_e_sqlcipher`)

### 3. Sync

- **Refit** สำหรับ HTTP client พร้อม Polly retry policy (exponential + jitter)
- **SyncWorker** เป็น `BackgroundService` ใน MAUI app — รัน loop ทุก 30s
- **DeltaCursor** เก็บ `lastSyncAt` ต่อ entity-type ใน `KeyValueStore` table
- **Idempotency** — ทุก outbox message มี GUID เป็น key, server ทำ dedup

### 4. UI (MAUI)

- **MVVM ผ่าน CommunityToolkit.MVVM** — `[ObservableProperty]` + `[RelayCommand]`
  ลด boilerplate
- **DI** ผ่าน `MauiProgram.CreateMauiApp().Services`
- **Styles** ใน `Tokens.xaml` ตรงกับ `mockup/css/tokens.css` 1:1
- **Glass effect** — Windows ใช้ `AcrylicBrush`, อื่นๆ ใช้ SkiaSharp render blur ให้
- **Animation** — `VisualState` + `Storyboard` (press 0.97 scale, etc.)
- **Routing** — Shell (`AppShell.xaml`) สำหรับ Windows desktop, `NavigationPage` สำหรับ mobile

### 5. Hardware

- **Printer** — ESC/POS via USB หรือ network · interface เดียว, implementation ต่อแพลตฟอร์ม
- **Barcode** — USB HID keyboard wedge: ฟัง `Window.KeyDown` global ใน MAUI
- **Cash drawer** — เปิดผ่าน printer (ESC `p` 0 50 50) ส่วนใหญ่

---

## Multi-screen sync

POS หลัก = source of truth. Cashier event ส่งไปที่ KDS + Customer Display ผ่าน:

```
                          ┌─────────────────────┐
                          │  Local SignalR Hub  │
                          │  (in-app, ws on     │
                          │   loopback :5099)   │
                          └─────┬───────────────┘
            ┌───────────────────┼─────────────────────┐
            │                   │                     │
   ┌────────▼─────┐   ┌─────────▼──────┐    ┌─────────▼─────┐
   │  Cashier     │   │  Customer      │    │  Kitchen      │
   │  (Windows)   │   │  Display       │    │  Display      │
   │              │   │  (2nd monitor) │    │  (KDS)        │
   └──────────────┘   └────────────────┘    └───────────────┘
```

- ถ้าเป็นเครื่องเดียวกัน — ใช้ named-pipe transport (เร็วกว่า)
- ถ้า KDS เป็นเครื่องแยก — SignalR over LAN
- คลื่น cashier → Hub: `OrderUpdated`, `OrderPaid`, `OrderVoided`
- คลื่น Hub → KDS: filter ตาม station ที่ KDS subscribe

---

## I18n

- ทุก UI string อยู่ใน `Resources/Strings/AppResources.resx` (default ภาษาไทย)
- `AppResources.en.resx` คือเวอร์ชันอังกฤษ
- ใช้ `xmlns:t="clr-namespace:..."` + `Text="{x:Static t:AppResources.cashier_pay_now}"`
- เปลี่ยนภาษา runtime: `Thread.CurrentThread.CurrentUICulture = new CultureInfo("en")`
  + raise event ให้ทุก ViewModel reload bindings

---

## Testing strategy

| Layer       | Tool         | Coverage target        |
|-------------|--------------|------------------------|
| Domain      | xUnit + FluentAssertions | 90% — เป็น core business logic |
| Data        | xUnit + SQLite in-memory | All migrations, outbox flow |
| Sync        | xUnit + WireMock.Net     | Happy path + 5xx + offline |
| ViewModels  | xUnit + Moq              | Cashier (cart math, discount, void) |
| UI smoke    | Manual + xharness         | Boot, login, sell, sync |

---

## Performance budget

- **App boot to login** < 1.5s บน mid-range Android (Helio G99)
- **Sell tap → cart row visible** < 80ms (no async)
- **Pay confirm → receipt printed** < 700ms (printer + write)
- **SQLite query 1000 rows** < 30ms
- **Sync push 100 outbox messages** < 4s on 4G

---

## Roadmap

| Milestone | Scope                                            | ETA |
|-----------|--------------------------------------------------|-----|
| M0        | Mockup sign-off                                  | now |
| M1        | Cashier + Payment + Receipt (Windows only)       | +2w |
| M2        | Customer Display + KDS                            | +2w |
| M3        | SQLite + Outbox + Sync layer                      | +2w |
| M4        | Dashboard + Inventory                             | +2w |
| M5        | Mobile + Tablet (MAUI Android)                   | +3w |
| M6        | iOS via TestFlight                                | +2w |
| M7        | Multi-branch + role-based access                  | +2w |
| M8        | Beta with 3 pilot stores                          | +4w |

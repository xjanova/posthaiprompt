# Thaiprompt POS

ระบบ Point of Sale แบบครบวงจรสำหรับร้านอาหาร / ร้านค้าปลีก ทำงานออฟไลน์ได้
และซิงก์ข้อมูลกับ [Thaiprompt-Affiliate](https://github.com/xjanova/Thaiprompt-Affiliate).

> **โปรเจคนี้จะถูก publish ที่:** [github.com/xjanova/posthaiprompt](https://github.com/xjanova/posthaiprompt)
> **สร้างโดย:** xman studio

---

## สถาปัตยกรรม — Two-arm split

```
                       ┌─ Thaiprompt POS ─┐
                       │                   │
              ┌────────┴──────┐    ┌──────┴───────────┐
              │   src/         │    │  flutter_android/ │
              │  .NET MAUI     │    │  Flutter 3.41    │
              │  (Windows)     │    │  (Android)       │
              └────────────────┘    └──────────────────┘
                      │                       │
                      └──── shared design ─────┘
                       (mockup/, design tokens)
```

**Windows** ใช้ MAUI · **Android** ใช้ Flutter (แยก codebase) — เพราะ MAUI Android workload
มีปัญหา manifest bug ใน .NET 10 preview SDK และ Flutter ให้ control ที่ดีกว่าสำหรับ
glassmorphism + auto-update flow.

---

## สถานะปัจจุบัน (M1 — 2026-05-09)

| Component                  | Tech                | Status                                              |
|----------------------------|---------------------|-----------------------------------------------------|
| 🎨 UI Mockup               | HTML/CSS/JS         | ✅ 23 หน้าจอ + TH/EN + 51 hot-links (`mockup/`)      |
| 🪟 Windows MAUI            | .NET 10 + MAUI      | ✅ M1 done — 6 หน้า: Login·Cashier·Payment·Receipt·Dashboard·Overview (`src/`) |
| 📱 Android Flutter         | Flutter 3.41 + Dart | ✅ M1 done — 7 หน้า + auto-updater + GitHub Actions (`flutter_android/`) |
| 🔄 Auto-update (Android)   | ota_update package  | ✅ ดาวน์โหลด APK จาก GitHub Releases + install ทับเดิม |
| 🤖 CI build APK            | GitHub Actions      | ✅ tag push → build signed APK + create release      |
| 📊 Dashboard + Inventory   | (M2)                | ⏳                                                   |
| 🍳 KDS + Customer Display  | (M2)                | ⏳                                                   |
| 🔌 SQLite + Sync layer     | (M3)                | ⏳                                                   |
| 🍎 iOS (TestFlight)        | (M5)                | ⏳                                                   |

---

## คุณลักษณะหลัก

- **Two-arm cross-platform** — Windows (MAUI) + Android (Flutter)
- **Auto-update** — Android จาก GitHub Releases + APK install ทับเดิมโดยใช้ signing key เดียว
- **Offline-first** — SQLite + outbox pattern · ทำงานได้แม้ไม่มีเน็ต
- **3D Glassmorphism UI** — โทนเทอร์ควอยซ์ · ปะการัง · ทองสยาม + decorative orbs
- **Bilingual** — ภาษาไทย + English (mockup), Thai-first (apps)
- **Multi-screen** — Cashier ↔ Customer Display ↔ KDS ผ่าน local SignalR hub (M2)
- **Hardware ready** — USB barcode · ESC/POS thermal printer · cash drawer · NFC reader
- **Accounting-grade** — Chart of Accounts, journal, P&L, e-Tax Invoice (RD-ready)
- **Logistics integration** — Grab · LINE MAN · Lalamove · Flash · Thailand Post · J&T · Kerry
- **Sync** — REST API กับ Thaiprompt-Affiliate (push outbox + pull delta)

---

## โครงสร้างไฟล์

```
POS Thaiprompt/
├── extracted/                  # Original design handoff (v1, JSX prototype)
├── extracted-v2/               # Design handoff (v2, +12 screens)
├── mockup/                     # ⭐ HTML mockup — open mockup/index.html
│   ├── index.html
│   ├── css/
│   └── js/
├── docs/                       # Architecture & API specs
│   ├── ARCHITECTURE.md
│   └── SYNC_API.md
├── src/                        # ⭐ .NET MAUI project (Windows)
│   ├── PosThaiprompt.sln
│   ├── PosThaiprompt.App/      # MAUI app — Windows-only target
│   ├── PosThaiprompt.Core/     # Domain models
│   ├── PosThaiprompt.Data/     # SQLite + EF Core
│   ├── PosThaiprompt.Sync/     # Refit + Polly
│   ├── PosThaiprompt.Hardware/ # Printer / barcode interfaces
│   └── PosThaiprompt.Tests/    # xUnit
├── flutter_android/            # ⭐ Flutter project (Android)
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme/      # tp_tokens.dart + tp_theme.dart
│   │   ├── widgets/    # GlassCard, TpOrb, TpButton, TpBrandMark
│   │   ├── screens/    # 7 screens (Overview/Login/Cashier/Payment/Receipt/Dashboard/Settings)
│   │   ├── routes/     # go_router
│   │   └── services/   # auto_updater.dart
│   └── android/        # AndroidManifest, build.gradle.kts, signing config
└── .github/
    └── workflows/
        └── android-build.yml   # CI: tag → build APK + create release
```

---

## Quick start

### ดู mockup

```bash
start mockup\index.html       # Windows
open  mockup/index.html       # Mac / Linux
```

### Run Windows MAUI

```powershell
cd src
dotnet build PosThaiprompt.App -c Debug -f net10.0-windows10.0.19041.0
Start-Process "src\PosThaiprompt.App\bin\Debug\net10.0-windows10.0.19041.0\win-x64\PosThaiprompt.App.exe"
```

### Run Android Flutter

```bash
cd flutter_android
flutter pub get
flutter run                   # debug, hot reload
flutter build apk --release   # signed APK at build/app/outputs/flutter-apk/
```

### Release Android APK ผ่าน GitHub Actions

```bash
# 1. bump version ใน flutter_android/pubspec.yaml
# 2. tag + push
git tag v1.2.3
git push origin main --tags
# 3. CI ทำต่อ — APK signed ปรากฏใน Releases page
```

ดู [`flutter_android/README.md`](flutter_android/README.md) สำหรับ release process รายละเอียด.

---

## License

MIT · 2026 · xman studio

# Thaiprompt POS

ระบบ Point of Sale แบบครบวงจรสำหรับร้านอาหาร / ร้านค้าปลีก ทำงานออฟไลน์ได้
และซิงก์ข้อมูลกับ [Thaiprompt-Affiliate](https://github.com/xjanova/Thaiprompt-Affiliate).

> **โปรเจคนี้จะถูก publish ที่:** [github.com/xjanova/posthaiprompt](https://github.com/xjanova/posthaiprompt)
> **สร้างโดย:** xman studio

---

## สถาปัตยกรรม — Flutter ทั้งหมด

```
                ┌─────── Thaiprompt POS ───────┐
                │      flutter_app/             │
                │   Flutter 3.41 · codebase เดียว│
                └────┬─────────┬─────────┬──────┘
                     │         │         │
                  Windows   Android     iOS
                  (Mica/    (auto-up   (TestFlight
                   Acrylic)  via OTA)   planned M5+)
                     │         │         │
                     └─── shared mockup/ ──┘
                        (39 screens · tokens)
```

ตัดสินใจรวมเป็น Flutter เดียว (2026-05-17) — เขียน 39 หน้าครั้งเดียว, design tokens
sync ตรงเป๊ะ ไม่เสี่ยง drift. Windows ได้ Acrylic/Mica แท้ผ่าน `flutter_acrylic`
(Win32 DwmExtendFrameIntoClientArea). MAUI code เดิมเก็บไว้ที่ `src-maui-legacy/`
สำหรับ reference เท่านั้น.

---

## สถานะปัจจุบัน (Flutter unified — 2026-05-17)

| Component                       | Tech                | Status                                              |
|---------------------------------|---------------------|-----------------------------------------------------|
| 🎨 UI Mockup (canonical)        | React + Babel (CDN) | ✅ **39 หน้าจอ hi-fi** + quick-jump HUD (`mockup/`)  |
| 📐 Design tokens                | OKLCH → sRGB hex    | ✅ pre-converted (`mockup/DESIGN_TOKENS.json` + `flutter_app/lib/theme/tp_tokens.dart`) |
| 📋 Anti-drift rules             | CLAUDE.md           | ✅ 10 mandatory rules + per-screen brief             |
| 📱 Flutter app (3 platforms)    | Flutter 3.41 + Dart | 🟡 M1 done — 7/39 หน้า · scaffold pending (`flutter_app/`) |
| 🪟 Windows · Acrylic/Mica       | flutter_acrylic     | ✅ wired ใน `main.dart` (Win32 DwmExtend…)            |
| 📊 Android · auto-update        | ota_update          | ✅ ดาวน์โหลด APK จาก Releases + install ทับเดิม      |
| 🍎 iOS · TestFlight             | (M5+)               | 🟡 platform scaffolded · ต้องการ Apple Dev account   |
| 🤖 CI · 3 workflows             | GitHub Actions      | ✅ android-build · windows-build · ios-build (unsigned) |
| 📚 Flutter screens manifest     | docs/               | ✅ 39 routes (`docs/FLUTTER_SCREENS_MANIFEST.md`)    |
| 🔌 SQLite + Sync layer          | (M3)                | ⏳                                                   |
| 🗄 MAUI legacy (reference only) | .NET 10 + MAUI      | 📦 archived (`src-maui-legacy/`)                     |

---

## คุณลักษณะหลัก

- **Flutter unified** — codebase เดียว · Windows + Android + iOS
- **Windows native look** — Acrylic/Mica จริงผ่าน flutter_acrylic (Win32 DwmExtendFrameIntoClientArea)
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
├── mockup/                          # ⭐ Canonical 39-screen design handoff
│   ├── index.html                   # open in browser — runnable React mockup
│   ├── nav.js                       # quick-jump nav HUD (top-left button)
│   ├── CLAUDE.md                    # anti-drift rules — READ FIRST
│   ├── SCREENS.md                   # per-screen brief (sizes, sources)
│   ├── DESIGN_TOKENS.json           # canonical sRGB hex (pre-converted oklch)
│   ├── CSS_TO_XAML.md               # translation patterns (XAML & Flutter)
│   ├── CUSTOMER_ORDER_FLOW.md       # spec for screens 36-39
│   ├── App.xaml                     # drop-in for MAUI/WPF/WinUI
│   ├── styles.css                   # source CSS
│   ├── tp-shared.jsx                # icons + logo + placeholder image
│   ├── design-canvas.jsx            # Figma-ish canvas wrapper
│   ├── tweaks-panel.jsx             # theme tweaker (presentational)
│   ├── screens-*.jsx                # 39 screens across 11 source files
│   └── screenshots/                 # one PNG per screen — pixel reference
├── mockup-legacy/                   # Old 23-screen vanilla-JS mockup (archived)
├── docs/                            # Architecture + manifests
│   ├── ARCHITECTURE.md
│   ├── SYNC_API.md
│   └── FLUTTER_SCREENS_MANIFEST.md  # ⭐ 39 routes + widget atoms + status
├── flutter_app/                     # ⭐ Flutter project (Windows · Android · iOS)
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart                # Acrylic init (Windows) + app shell
│   │   ├── theme/                   # tp_tokens.dart (mirrors DESIGN_TOKENS.json)
│   │   ├── widgets/                 # GlassCard, TpOrb, TpButton, TpBrandMark
│   │   ├── screens/                 # 7 of 39 — see FLUTTER_SCREENS_MANIFEST.md
│   │   ├── routes/                  # go_router
│   │   └── services/                # auto_updater.dart
│   ├── android/                     # AndroidManifest, gradle, signing
│   ├── windows/                     # Win32 runner (CMake)
│   └── ios/                         # Xcode runner
├── src-maui-legacy/                 # 📦 archived MAUI code (reference only)
└── .github/workflows/
    ├── android-build.yml            # CI: tag → signed APK + release
    ├── windows-build.yml            # CI: tag → Windows zip + release
    └── ios-build.yml                # CI: tag → unsigned iOS archive (TestFlight TBD)
```

---

## Quick start

### ดู mockup (39 หน้า canonical)

```powershell
# Windows
start mockup\index.html

# Mac / Linux
open mockup/index.html
```

เปิดแล้ว:
- กดปุ่ม **teal วงกลม** มุมซ้ายบน → quick-jump ไปหน้าไหนก็ได้ (39 หน้า)
- คลิก label ของ artboard แล้วกด **expand** → ดูเต็มจอ · ใช้ ←/→ เลื่อน · Esc ออก
- panel ขวาบน → ปรับ hue/blur/warmth realtime (presentational เท่านั้น)

### ตรวจ design tokens กับ Flutter ตรงกัน

```bash
# Flutter side — ต้องตรงกับ mockup/DESIGN_TOKENS.json เป๊ะ
cat flutter_android/lib/theme/tp_tokens.dart | grep "Color(0xFF"
# เช็คกับ canonical
cat mockup/DESIGN_TOKENS.json | jq '.color | to_entries | map({key, hex: .value.hex})'
```

### Run Flutter app

```bash
cd flutter_app
flutter pub get

# Android (hot reload)
flutter run -d emulator-5554

# Windows (ต้องเปิด Developer Mode ก่อน — start ms-settings:developers)
flutter run -d windows

# iOS (ต้องมี Mac + Xcode)
flutter run -d <iphone-uuid>
```

### Release builds ผ่าน GitHub Actions

```bash
# 1. bump version ใน flutter_app/pubspec.yaml
# 2. tag + push
git tag v1.2.3
git push origin main --tags
# 3. CI build ทั้ง 3 platforms — APK + Windows zip + iOS unsigned archive
#    APK signed (ถ้าตั้ง 4 secrets ครบ) ปรากฏใน Releases page
```

Secrets ที่ต้องการสำหรับ release:
- Android: `RELEASE_KEYSTORE_BASE64`, `RELEASE_STORE_PASSWORD`, `RELEASE_KEY_PASSWORD`, `RELEASE_KEY_ALIAS`
- Windows: ไม่ต้อง (unsigned zip — code-signing เพิ่มภายหลัง)
- iOS: TBD (Apple Developer account + provisioning profile + signing cert)

ดู [`flutter_app/README.md`](flutter_app/README.md) สำหรับ release process รายละเอียด.

---

## License

MIT · 2026 · xman studio

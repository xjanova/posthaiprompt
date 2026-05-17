# Claude Code — Implementation Rules

> **You are implementing the Thaiprompt POS designs in Flutter (Dart).**
> The bundled HTML/JSX files in this folder are the **canonical visual spec**.
> Your task is to **recreate them in Flutter widgets** — codebase at
> `flutter_app/lib/` targeting Windows · Android · iOS. **Not** to ship the HTML.
>
> **2026-05-17 architecture decision**: Project moved from MAUI(Windows) +
> Flutter(Android) two-arm split → Flutter-unified single codebase. Windows
> gets Acrylic/Mica via `flutter_acrylic` (Win32 DwmExtendFrameIntoClientArea).
> MAUI code preserved at `src-maui-legacy/` for reference only.

---

## 🚫 Anti-Drift Rules — DO NOT DEVIATE

These are non-negotiable. The user explicitly does not want pixel drift.

### 1. Use the tokens. Always.
- **All colors** must come from `DESIGN_TOKENS.json` or `App.xaml`.
  Never pick a "close enough" color. The hex values were converted from
  perceptual `oklch()` and look harmonious only as a set.
- **All radii / spacing / font sizes** must use the named tokens.
  No hand-typed magic numbers like `BorderRadius=12` if the token says `16`.
- If a value isn't in the tokens but appears in the HTML — add it to the
  tokens file first, then reference. Don't inline.

### 2. Re-create natively. Do NOT WebView.
- Don't drop a `WebView` and load the HTML. The whole point is native
  performance, accessibility, and offline reliability.
- Use the framework's primitives: `Border`, `Grid`, `CollectionView`,
  `Frame`, `BoxView`. The HTML is a spec for **layout + look**, not a
  rendering target.

### 3. Match dimensions exactly.
- Each screen has a **design canvas size** (see `SCREENS.md`).
  1440×900 → desktop · 1280×800 → secondary display · 1024×768 → iPad ·
  390×844 → mobile · 360×640 → thermal receipt.
- Use the same widths/heights for primary container sizing. Inner
  spacing values were hand-tuned at that size; don't reflow to fit a
  different baseline.

### 4. Preserve the 3 glass layers.
A glass card is **never** a flat semi-transparent rect. It is always:
  1. A 1px top-inside highlight (`#D9FFFFFF`, 85% white)
  2. A 1px bottom-inside shade (`#0A14284B`, 4% dark)
  3. A soft outer shadow (token `Tp.Shadow.Glass`)
  4. A 1px outer stroke at `#A6FFFFFF` (65% white)

In Flutter, use `TpTokens.glassShadow()` which returns all 4 layers in the
correct order (Flutter `BoxShadow` stacks unlimited; do not collapse to one).
Wrap the surface in `BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22))`
for the blur effect.

### 5. Acrylic / Backdrop blur
- **Windows**: `flutter_acrylic` package initialized in `main.dart` —
  `Window.setEffect(effect: WindowEffect.acrylic, color: ...)`.
  Sets `DwmExtendFrameIntoClientArea` → real Mica/Acrylic on Win10+.
- **Android / iOS**: `BackdropFilter(filter: ImageFilter.blur(...))` per glass
  card. This is GPU-cheap on mobile (Skia-backed) and matches the CSS look.
- **Web**: not a target.
- Never just delete the blur. Without a glass surface the design loses
  its identity.

### 6. Typography
- **Font**: bundle Google **Prompt** (`.ttf`, weights 300–700) — Thai +
  Latin in one family. Don't substitute Sarabun, Noto, or system.
- **Mono**: bundle **JetBrains Mono** for receipts, SKUs, prices in tables.
- Sizes per `DESIGN_TOKENS.json`. **24px is the absolute minimum
  desktop body**; mobile drops to ~13px floor.

### 7. Layouts
- The HTML uses absolute positioning for the outer chrome (header at
  top, sidebars, main, right panel) — recreate as `Grid` with explicit
  `RowDefinitions`/`ColumnDefinitions` in the same proportions, **not**
  with naive `StackLayout`.
- Cards inside scroll regions: use `CollectionView` (MAUI) /
  `ItemsControl` (WPF/WinUI). Never `<StackLayout>` over hundreds of items.

### 8. Match the 3D "shiny" buttons
- Linear gradient top→bottom (token `Tp.Gradient.PrimaryButton` or
  `…CoralButton` / `…GoldButton`).
- 1px white inner-top highlight + 2px black inner-bottom shade —
  fake with a 1px `Border` outline + a 2px-tall semi-transparent dark
  rectangle anchored to the bottom inside.
- Drop shadow tinted with the brand color, not pure black:
  `Brush="#3F008889"` for primary, `#3FC53637` for coral.

### 9. Numbers + receipts
- All money, counts, table numbers, SKUs use **monospace + tnum**
  (tabular numerals). In Flutter:
  `TextStyle(fontFamily: TpTokens.fontMono, fontFeatures: [FontFeature.tabularFigures()])`.
- Currency symbol is **`฿`** (Baht), placed **before** the amount,
  no space (e.g. `฿1,335`).

### 10. Thai-language correctness
- Number formatting: comma thousands, decimal point (e.g. `42,580.00`).
- Dates: **Buddhist Era (พ.ศ.)** in user-facing labels (`08 พ.ค. 2569`).
  Store as Gregorian, format for display only.
  In Flutter: `intl` with `th_TH` locale; for พ.ศ. year add `+543` manually
  before formatting (Dart's `intl` does not have a Buddhist calendar class).
- Time: 24-hour (`14:42`), never AM/PM in the UI.

---

## 🎯 Stack — Flutter unified (decided 2026-05-17)

One Flutter project at `flutter_app/` targeting Windows · Android · iOS.

| Concern | How it's handled |
|---|---|
| **Windows Acrylic/Mica** | `flutter_acrylic` package — init in `main.dart` when `Platform.isWindows` |
| **Mobile glass blur** | `BackdropFilter(filter: ImageFilter.blur(...))` on glass cards |
| **Glass 4-layer shadow** | `TpTokens.glassShadow()` returns 4 stacked `BoxShadow` (highlight + bottom inset + 2 outer) |
| **3D button shadow** | `TpTokens.btn3DShadow(tintColor: ...)` returns 4-layer stack |
| **Typography** | `google_fonts` (Prompt + JetBrains Mono) bootstrap, switch to bundled `.ttf` for offline |
| **Numbers + receipts** | `JetBrainsMono` family + `FontFeature.tabularFigures()` |
| **Thai dates (พ.ศ.)** | `intl` package with `th_TH` locale + manual +543 year offset |
| **Auto-update (Android)** | `ota_update` package + GitHub Releases API (existing, see `services/auto_updater.dart`) |
| **Code-signing Windows** | Wire later — Microsoft Store ID or self-signed |
| **TestFlight iOS** | M5+ — needs Apple Developer account |

Shared (within the single Flutter project):
- `flutter_app/lib/theme/tp_tokens.dart` — mirror of `DESIGN_TOKENS.json`
- `flutter_app/lib/theme/tp_theme.dart` — Material 3 wrapper
- `flutter_app/lib/widgets/` — atoms used across screens
- `flutter_app/assets/fonts/Prompt-*.ttf` + `JetBrainsMono-*.ttf` (TODO bundle)
- `flutter_app/assets/icons/` — extracted SVGs from `tp-shared.jsx` (TODO)

### Legacy / reference
- `mockup/App.xaml` + `mockup/CSS_TO_XAML.md` — kept as MAUI/WinUI reference
  for anyone needing to port back. Active development uses Flutter.
- `src-maui-legacy/` — old MAUI codebase, archived 2026-05-17.

---

## 🏗 Implementation Order (suggested)

Don't try to build everything at once. Build the design system first;
every screen falls out cheaply once tokens + components exist.

1. **Theme + tokens.** Drop `App.xaml`. Verify a "Hello" page picks up
   the gradient background.
2. **Atoms** — `TpButton` (primary/coral/gold/ghost/icon),
   `TpChip`, `TpInput`, `TpBadge`, `TpKpiCard`, `TpGlassCard`.
3. **Compositions** — `TpTopBar`, `TpSidebar`, `TpProductTile`,
   `TpReceiptRow`, `TpDataGrid` (using `CollectionView`).
4. **Screens** in this priority order (highest user value first):
   1. Cashier (#01) — drives 80% of usage
   2. Payment + Receipt (#02, #03)
   3. Login (#04)
   4. Customer Display + KDS (#05, #06) — these are server-screens,
      may be separate apps that subscribe to a SignalR hub.
   5. Shift / Z-Report (#25) — required at end of every day.
   6. Inventory (#08), Dashboard (#07).
   7. CRM (#24), Refund (#26).
   8. Floor plan designer (#30), Self-order + status (#31, #32).
   9. Everything else.

## 🔌 Backend / Architecture Contracts

The screens **imply** these services exist. Build them as interfaces in
`Tp.Shared` and stub them; wire to real backend later.

- `IOrderService`            — open/close/void; emits realtime updates
- `IKitchenHub` (SignalR)    — broadcasts to KDS + Customer Display
- `IPaymentService`          — QR PromptPay, card (with NFC), e-wallet
- `IInventoryService`        — stock movements, reorder points
- `IMembershipService`       — tiers, points, redemptions
- `IDiscountEngine`          — rule-based evaluation (the 8 rule types
  in screen #34)
- `ITaxInvoiceService`       — RD-compliant e-Tax submission
- `IShippingService`         — Grab/LM/Flash/Lalamove/EMS providers
- `IAffiliateService`        — referral codes, commission accrual
- `IPrinterService`          — thermal receipt, label, A4 invoice
- `INfcReader`                — listens for tag, returns card data

Run them all behind a sync queue so the app keeps working offline
(SQLite local store, replays when connection returns). The shift
close on screen #25 must reconcile against the local queue, not
the cloud.

---

## 📁 Files in this bundle

| File | Purpose |
|---|---|
| `README.md` | Overview + how to use this bundle |
| `CLAUDE.md` | This file — implementation rules |
| `DESIGN_TOKENS.json` | Tokens with both `oklch()` and pre-converted hex |
| `App.xaml` | XAML ResourceDictionary, drop-in for MAUI/WPF/WinUI |
| `CSS_TO_XAML.md` | Translation guide for every CSS pattern in the design |
| `SCREENS.md` | Per-screen brief (35 screens, sizes, purpose, key components) |
| `screenshots/` | One PNG per screen — your pixel reference |
| `index.html` + JSX files | Live runnable mockups. Open `index.html` in a browser to see them in motion. |
| `styles.css` | Source CSS — refer to it to resolve any ambiguity in tokens |

---

## When in doubt

1. Look at the matching screenshot (`screenshots/##-name.png`).
2. Open `index.html` and inspect the live element.
3. Find the source value in the JSX file named in `SCREENS.md`.
4. Pull the literal value into `App.xaml` as a new named token.
5. Reference it. Never inline.

**Do not change the design without checking with the user.**
If something looks "off" in your implementation, the bug is in your
implementation — not in the design. Re-read the screenshot.

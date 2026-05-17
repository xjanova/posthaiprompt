# Thaiprompt POS — Design Handoff Kit

**For Claude Code / any developer implementing this design in C#.**

This bundle contains everything needed to recreate **39 hi-fi screens** of
Thaiprompt POS in **C# / .NET MAUI / WPF / WinUI 3** with **no pixel drift**.

---

## 📖 Read in this order

1. **`CLAUDE.md`** — Strict implementation rules. **READ FIRST.**
2. **`SCREENS.md`** — Inventory of 35 screens, their sizes, source files, and key components.
3. **`DESIGN_TOKENS.json`** — Single source of truth for all colors / fonts / sizes / radii / shadows. **All `oklch()` values pre-converted to sRGB hex.**
4. **`App.xaml`** — Drop-in `ResourceDictionary` for MAUI / WPF / WinUI. Copy into your project's `App.xaml`.
5. **`CSS_TO_XAML.md`** — Conversion guide. Every CSS pattern in the design mapped to its closest XAML equivalent (glass cards, 3D buttons, gradients, shadows, animations, icons).
6. **`screenshots/`** — One PNG per screen. **Your pixel reference.** Open while implementing each screen.
7. **`index.html`** — Open in Chrome/Edge to see the live mockups at full fidelity (with real CSS blur). The screenshot PNGs are approximate; the live HTML is exact.

---

## ⚙️ Stack recommendation

User asked for **C# on Windows + iOS + Android**.

| Use case | Recommended | Notes |
|---|---|---|
| Single-codebase all platforms | **.NET MAUI** | Easiest, but glass blur fakes via SkiaSharp on mobile |
| Best Windows look | **WinUI 3** (POS terminal) + **MAUI** (mobile) | Real Acrylic on Windows · share `Tp.Shared` library |
| WPF-familiar team | **Avalonia UI** | XAML, near-WPF API, cross-platform |

Share between desktop & mobile projects:
- `Tp.Shared` (.NET Standard 2.1) — domain models, services, formatters
- `App.xaml` — tokens, brushes, styles (this folder)
- `Prompt-*.ttf` (Google Font) + `JetBrains Mono-*.ttf`
- SVG icons (extract from `tp-shared.jsx`)

---

## 🎯 35 screens

See `SCREENS.md` for the full table. Quick overview:

```
01-04  Cashier flow         (sales · payment · receipt · login)
05-06  Secondary displays   (customer board · kitchen KDS)
07-08  Back office          (dashboard · inventory)
09-11  iPad + Mobile        (floor plan · order · manager)
12-16  Business / Finance   (accounting · bill · tax invoice · NFC · delivery)
17-21  Operations           (stock · shipping · coupons · staff · admin)
22-23  Extras               (barcode · shipping label)
24-29  Advanced             (CRM · shift · refund · PO · menu+BOM · multi-branch)
30-32  Table ordering       (floor designer · self-order · live status)
33-35  Loyalty              (membership tiers · discount center · affiliate)
36-39  Customer Order Flow  (menu grid · item customize · cart review · confirmation)
```

---

## 🔒 The "ห้ามเพี้ยน" guarantee

Three things keep your C# implementation from drifting from the design:

### 1. The tokens are pre-converted
Modern CSS uses `oklch()` for harmonious color. XAML doesn't support
`oklch()`. The hex values in `DESIGN_TOKENS.json` / `App.xaml` were
computed via a real browser, not estimated — so the look stays identical.

### 2. The screenshots ARE the spec
If your C# implementation doesn't match the screenshot pixel-for-pixel,
the bug is in your implementation. Don't "improve" the design. If
something feels off, check the screenshot first.

### 3. The HTML is runnable
Open `index.html` in Chrome. Inspect any element. Read the literal CSS
value. Add it as a named token in `App.xaml`. Reference it. Never inline
a magic number.

---

## 📁 Files in this folder

```
README.md                    ← you are here
CLAUDE.md                    ← strict implementation rules
SCREENS.md                   ← per-screen specs
DESIGN_TOKENS.json           ← tokens (oklch + hex)
App.xaml                     ← drop-in XAML ResourceDictionary
CSS_TO_XAML.md               ← translation guide
screenshots/                 ← 35 PNG references
  01-cashier.png
  02-payment.png
  …
  35-affiliate.png
index.html                   ← live runnable mockup
styles.css                   ← canonical CSS source
tp-shared.jsx                ← icons, logo, image placeholder
screens-*.jsx                ← screen source code (read for layout values)
screens-customerorder.jsx    ← screens 36-39 (Thai food customer self-order flow)
CUSTOMER_ORDER_FLOW.md       ← detailed spec for screens 36-39
design-canvas.jsx            ← canvas wrapper (presentation only, not product)
tweaks-panel.jsx             ← theme tweaker (presentation only, not product)
```

---

## ❓ When you're stuck

1. Open the matching `screenshots/##-name.png` next to your editor.
2. Open `index.html` in a browser, find the screen, **right-click → Inspect**
   to read the literal CSS value.
3. Find the source JSX file named in `SCREENS.md` — search for the
   component's content (e.g. "ค่าคอม") to jump to its definition.
4. Pull the value into `App.xaml` as a new named token. Then reference
   `{StaticResource Tp.…}` from your C# code.

**Never invent values. Never deviate without checking.**

---

*Designed by Claude (Anthropic) · Handoff target: Claude Code · 2026*

# src-maui-legacy — DEPRECATED (2026-05-17)

This folder contains the **archived** MAUI (.NET 10) codebase from when the
project used a two-arm split (MAUI for Windows, Flutter for Android).

**Active development moved to Flutter unified** — see
[`../flutter_app/`](../flutter_app/) which targets Windows + Android + iOS
from a single Dart codebase.

## Why we moved away from MAUI

1. **.NET 10.0.300-preview Android workload bug** — `Pack 'Microsoft.Android.Ref.36.' was not present`
   blocked any Android MAUI build (the original reason we split off Flutter)
2. **Maintaining two codebases for 39 screens** — would double the screen
   implementation work for the M2+ phases
3. **Flutter `BackdropFilter` glassmorphism** is sharper than MAUI's
   single-layer `Shadow` workaround
4. **Windows Acrylic/Mica preserved** via `flutter_acrylic` (Win32 DwmExtend)
   so we don't lose the native Windows look

## What's preserved here for reference

- `PosThaiprompt.sln` — solution file
- `PosThaiprompt.App/` — MAUI app shell + 6 screens
- `PosThaiprompt.Core/` — domain models (may be useful when porting business logic)
- `PosThaiprompt.Data/` — SQLite + EF Core (schema design — port to Drift/sqflite)
- `PosThaiprompt.Sync/` — Refit + Polly (port to dio + retry interceptor)
- `PosThaiprompt.Hardware/` — Printer / barcode interfaces (port to Dart abstractions)
- `PosThaiprompt.Tests/` — xUnit tests

## When to delete

After the Flutter Windows build is verified working end-to-end (including
printer + barcode hardware), this folder can be deleted. Until then, treat
it as read-only reference material.

## Don't

- Don't add new features here — they won't ship.
- Don't refactor — it's frozen.
- Don't try to keep MAUI in sync with Flutter — pick one (we picked Flutter).

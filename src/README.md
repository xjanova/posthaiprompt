# PosThaiprompt — .NET MAUI source

โค้ดหลักของ Thaiprompt POS — multi-platform C# .NET MAUI app, ตามสเปกใน
[`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).

> **Created by xman studio** · Sister UI mockup ที่ `mockup/index.html`

---

## วิธีเปิดผ่าน Visual Studio

> .NET 10 ใช้ format `.slnx` (XML solution) แทน `.sln` แบบเก่า — VS 2022 17.10+ และ VS 2026 รองรับ.

```powershell
# Windows — เปิดผ่าน Solution Explorer
start "E:\Code\POS Thaiprompt\src\PosThaiprompt.slnx"

# หรือถ้ามี VS ใน PATH:
devenv "E:\Code\POS Thaiprompt\src\PosThaiprompt.slnx"
```

หรือคลิกขวาที่ `src/PosThaiprompt.slnx` → Open with → Visual Studio 2022/Insiders.

**ถ้า VS ไม่รู้จัก .slnx:** convert กลับเป็น .sln ได้ด้วย `dotnet sln migrate`.

---

## Solution layout

```
src/
├── PosThaiprompt.slnx
├── PosThaiprompt.Core/          # Domain models, services, contracts (no UI)
├── PosThaiprompt.Data/          # SQLite + EF Core 9
├── PosThaiprompt.Sync/          # Refit + Polly — sync with Affiliate API
├── PosThaiprompt.Hardware/      # Printer / barcode / cash drawer interfaces
├── PosThaiprompt.App/           # MAUI app — XAML views + ViewModels
└── PosThaiprompt.Tests/         # xUnit + FluentAssertions + Moq
```

Inter-project references:
```
Core ← Data, Sync, Hardware, App, Tests
Data ← Tests, App
Sync ← App
Hardware ← App
```

---

## Targets

ในการเริ่มต้นนี้ App project target **`net10.0-windows10.0.19041.0`** เท่านั้น
เพื่อให้ build/run บน Windows ได้ทันที ไม่ติด Android/iOS workload mismatch.

### เปิด Android target

> ⚠️ **ตอนนี้ยังเปิดไม่ได้** บน .NET 10.0.300-preview SDK — มี manifest bug
> `NETSDK1181: Pack 'Microsoft.Android.Ref.36.' was not present in workload manifests`
> (manifest มีช่อง version ว่างสำหรับ Android 36 API). ทดสอบแล้วยังเกิด
> แม้ทำ `dotnet workload restore` + `dotnet workload update` ทั้งคู่.

**Workaround ตามลำดับที่แนะนำ:**

1. **รอ .NET 10 stable** — bug นี้น่าจะถูกแก้ใน RTM ปลายปี 2569
2. **Pin SDK เป็น 10.0.200** ผ่าน `global.json` (ถ้า version นี้ workload สอดคล้องกัน):
   ```json
   { "sdk": { "version": "10.0.200" } }
   ```
3. **ติดตั้ง android workload band ใหม่** (advanced):
   ```powershell
   dotnet workload install android --skip-manifest-update --version 10.0.300
   ```

เมื่อใช้ได้ ให้แก้ไข `src/PosThaiprompt.App/PosThaiprompt.App.csproj` →
```xml
<TargetFrameworks>net10.0-windows10.0.19041.0;net10.0-android36.0</TargetFrameworks>
```

### เปิด iOS target (Mac only)

ต้องมี Xcode และ pair กับ Mac. แล้วเพิ่ม `net10.0-ios` ใน `<TargetFrameworks>`.

---

## Build / Run

```powershell
# Restore everything
dotnet restore src/PosThaiprompt.slnx

# Build
dotnet build src/PosThaiprompt.slnx

# Run Windows app — preferred way:
#   เปิดใน VS แล้วกด F5
# หรือ launch exe โดยตรง:
dotnet build src/PosThaiprompt.App -c Debug -f net10.0-windows10.0.19041.0
Start-Process "E:\Code\POS Thaiprompt\src\PosThaiprompt.App\bin\Debug\net10.0-windows10.0.19041.0\win-x64\PosThaiprompt.App.exe"

# Run unit tests
dotnet test src/PosThaiprompt.Tests
```

> ⚠️ `dotnet build -t:Run` จะ fail (exit 9009) เพราะ path มี space
> ("POS Thaiprompt") — MSBuild Exec task wrap ด้วย cmd ที่ escape ผิด.
> ใช้ F5 ใน VS หรือ `Start-Process` แทน.

---

## Packages installed

| Project       | Packages                                          |
|---------------|---------------------------------------------------|
| Core          | (none — pure domain)                              |
| Data          | EF Core SQLite 9.0 · EF Core Design 9.0           |
| Sync          | Refit 7.2.22 · Refit.HttpClientFactory · Polly    |
| Hardware      | (none — interfaces only)                          |
| App           | Microsoft.Maui.Controls · CommunityToolkit.MVVM 8.4 |
| Tests         | xUnit · FluentAssertions 6.12 · Moq 4.20          |

---

## Roadmap (per docs/ARCHITECTURE.md)

| Milestone | Scope                                            |
|-----------|--------------------------------------------------|
| M0        | ✅ Mockup sign-off + project scaffold (you are here) |
| M1        | Cashier + Payment + Receipt (Windows only)       |
| M2        | Customer Display + KDS                            |
| M3        | SQLite + Outbox + Sync layer                      |
| M4        | Dashboard + Inventory + Stock movements           |
| M5        | Mobile + Tablet (re-enable Android target)       |
| M6        | iOS via TestFlight                                |
| M7        | Multi-branch + role-based access                  |
| M8        | Beta with 3 pilot stores                          |

# CSS → XAML Translation Guide

The Thaiprompt POS HTML uses a small set of CSS patterns repeatedly.
This file maps every one of them to the closest XAML equivalent so the
visual remains intact when ported to C#.

---

## 1. Background gradients

### CSS
```css
background: linear-gradient(180deg, #5DE7DC 0%, #008889 100%);
background: linear-gradient(140deg, oklch(.30 .08 265), oklch(.20 .06 270));
```

### XAML — MAUI / WPF
```xml
<LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
  <GradientStop Offset="0" Color="#5DE7DC"/>
  <GradientStop Offset="1" Color="#008889"/>
</LinearGradientBrush>
```

For a **140° gradient** (which is not axis-aligned), compute the
endpoints: `140°` rotates ~50° clockwise from "top→bottom":
```xml
<LinearGradientBrush StartPoint="0.18,0" EndPoint="0.82,1">…</LinearGradientBrush>
```

For radial-gradient ambient orbs in the background:
```xml
<RadialGradientBrush Center="0.12,0.08" Radius="0.5">
  <GradientStop Offset="0" Color="#998EFAF9"/>  <!-- 60% alpha teal -->
  <GradientStop Offset="1" Color="#008EFAF9"/>
</RadialGradientBrush>
```

---

## 2. Glass surface

### CSS
```css
background: linear-gradient(140deg, rgba(255,255,255,0.78), rgba(255,255,255,0.48));
border: 1px solid rgba(255,255,255,0.65);
backdrop-filter: blur(22px) saturate(180%);
box-shadow:
  0 1px 0 rgba(255,255,255,0.90) inset,
  0 -1px 0 rgba(20,40,80,0.04) inset,
  0 10px 28px -12px rgba(20,40,80,0.22),
  0 30px 60px -30px rgba(20,40,80,0.28);
border-radius: 22px;
```

### XAML — recipe (two stacked Borders)
```xml
<Border StrokeShape="RoundRectangle 22"
        Stroke="#A6FFFFFF" StrokeThickness="1"
        Background="{StaticResource Tp.Gradient.GlassSurface}"
        Shadow="{StaticResource Tp.Shadow.Glass}">
  <!-- 1px inset highlight: a thin border anchored to the top -->
  <Grid>
    <BoxView HeightRequest="1" VerticalOptions="Start" Color="#D9FFFFFF"/>
    <ContentPresenter/>
  </Grid>
</Border>
```

### WinUI 3 — real acrylic
Set window-level `DesktopAcrylicController`, then:
```xml
<Border Background="{ThemeResource AcrylicInAppFillColorDefaultBrush}"
        BorderBrush="#A6FFFFFF" BorderThickness="1"
        CornerRadius="22">
  …
</Border>
```

---

## 3. 3D button

### CSS
```css
background: linear-gradient(180deg, #FF9A8A 0%, #C53637 100%);
border: 1px solid rgba(255,255,255,0.35);
box-shadow:
  0 1px 0 rgba(255,255,255,0.5) inset,
  0 -2px 0 rgba(0,0,0,0.15) inset,
  0 8px 18px -4px rgba(197,54,55,0.55),
  0 2px 4px rgba(20,40,80,0.18);
```

### XAML (MAUI)
```xml
<Border StrokeShape="RoundRectangle 16"
        Stroke="#59FFFFFF" StrokeThickness="1"
        Background="{StaticResource Tp.Gradient.CoralButton}"
        Shadow="{StaticResource Tp.Shadow.Button}">
  <Grid>
    <BoxView HeightRequest="1" VerticalOptions="Start" Color="#80FFFFFF"/>  <!-- top highlight -->
    <BoxView HeightRequest="2" VerticalOptions="End"   Color="#26000000"/>  <!-- bottom shade -->
    <Label  Text="ชำระเงิน · ฿1,335"
            TextColor="White" FontSize="15" FontAttributes="Bold"
            HorizontalOptions="Center" VerticalOptions="Center"/>
  </Grid>
</Border>
```

Wrap the Border in a `TapGestureRecognizer` or set `IsEnabled=True` and
use a `PointerOverEffect` for the hover lift (translate Y -1).

---

## 4. Soft tinted pill / chip

### CSS
```css
background: oklch(.94 .08 145); /* successBg */
color: oklch(.45 .14 150);     /* successDeep */
border-radius: 999px;
padding: 3px 10px;
font-size: 11px;
font-weight: 600;
```

### XAML
```xml
<Border Background="#CAFACB" Stroke="Transparent"
        StrokeShape="RoundRectangle 999" Padding="10,3"
        HorizontalOptions="Start">
  <Label Text="อนุมัติ" TextColor="#006925"
         FontSize="11" FontAttributes="Bold"/>
</Border>
```

---

## 5. Progress bar / gradient fill

### CSS
```css
background: linear-gradient(90deg, oklch(.78 .12 145), oklch(.55 .14 150));
height: 6px; border-radius: 999px;
```

### XAML
```xml
<Border Background="#0F14284B" StrokeShape="RoundRectangle 999" HeightRequest="6">
  <Border HorizontalOptions="Start" WidthRequest="{Binding ProgressWidth}"
          StrokeShape="RoundRectangle 999">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
        <GradientStop Offset="0" Color="#7EE6B0"/>
        <GradientStop Offset="1" Color="#1C8742"/>
      </LinearGradientBrush>
    </Border.Background>
  </Border>
</Border>
```

---

## 6. Donut / pie chart

CSS draws via `<circle stroke-dasharray>`. In XAML use SkiaSharp:

```csharp
canvas.DrawCircle(cx, cy, r, new SKPaint {
    Style = SKPaintStyle.Stroke,
    StrokeWidth = 24,
    Color = SKColor.Parse("#00BDBE"),
    PathEffect = SKPathEffect.CreateDash(new[] { 100f * 0.58f, 100f * 0.42f }, 0)
});
```

For 3D KPI dashboards prefer `LiveCharts2` (cross-platform), seeded
with the same brand colors.

---

## 7. Text emphasis (the "big number")

CSS uses `font-variant-numeric: tabular-nums` + `letter-spacing: -0.02em`
on display numbers. XAML equivalent:

```xml
<Label Text="฿42,580" FontFamily="JetBrains Mono"
       FontSize="32" FontAttributes="Bold"
       CharacterSpacing="-0.5"   <!-- approximates -0.02em at 32px -->
       TextColor="{StaticResource Tp.Color.Indigo}"/>
```

---

## 8. Outer drop shadow tinted with brand

CSS: `box-shadow: 0 8px 18px -4px rgba(197,54,55,0.55);`

MAUI:
```xml
<Border Shadow="{Tp.Shadow.Button}" …>
```

where the `Shadow` style sets `Brush="#3FC53637"` Offset="0,6" Radius="14".

WPF: use `DropShadowEffect`:
```xml
<Border.Effect>
  <DropShadowEffect Color="#C53637" Opacity="0.55"
                    BlurRadius="18" ShadowDepth="8"/>
</Border.Effect>
```

---

## 9. Dashed dividers

CSS: `border-bottom: 1px dashed rgba(20,40,80,0.06);`

XAML: use a `Path` with `StrokeDashArray` or a simple `BoxView` with
a repeating gradient:
```xml
<BoxView HeightRequest="1">
  <BoxView.Background>
    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
      <GradientStop Offset="0" Color="#0F14284B"/>
      <GradientStop Offset="0.5" Color="#0F14284B"/>
      <GradientStop Offset="0.5" Color="Transparent"/>
      <GradientStop Offset="1" Color="Transparent"/>
    </LinearGradientBrush>
  </BoxView.Background>
</BoxView>
```

Better: use `Shapes.Line` with `StrokeDashArray="3,3"`.

---

## 10. Pulse / breathing animations (NFC, KDS new-order)

CSS:
```css
@keyframes pulse {
  0%   { transform: scale(.8);  opacity: .55 }
  80%  { transform: scale(1.15); opacity: 0 }
  100% { transform: scale(1.15); opacity: 0 }
}
animation: pulse 2.6s ease-out infinite;
```

XAML (MAUI):
```csharp
async void StartPulse(Ellipse ring) {
    while (true) {
        ring.Scale = 0.8; ring.Opacity = 0.55;
        await ring.ScaleTo(1.15, 2080, Easing.SinOut);
        await ring.FadeTo(0,    2080, Easing.SinOut);
        ring.Scale = 0.8; ring.Opacity = 0.55;
        await Task.Delay(520);
    }
}
```

---

## 11. SVG icons → XAML

Every icon in `tp-shared.jsx` is hand-drawn from 24×24 SVG paths.
Convert them once into XAML `<Path>` resources and reuse with
`{StaticResource Tp.Icon.Cart}` etc.

Example (cart):
```xml
<Geometry x:Key="Tp.Icon.Cart.Geometry">
  M3 4h2l2.5 12.5a2 2 0 0 0 2 1.5h8a2 2 0 0 0 2-1.5L21 8H6
</Geometry>

<!-- usage -->
<Path Data="{StaticResource Tp.Icon.Cart.Geometry}"
      Stroke="{StaticResource Tp.Brush.Primary}"
      StrokeThickness="1.6" StrokeLineCap="Round" StrokeLineJoin="Round"
      Fill="Transparent" Aspect="Uniform"
      WidthRequest="22" HeightRequest="22"/>
```

In MAUI prefer `Microsoft.Maui.Controls.Shapes.Path`. In WinUI, the
inner `Data` syntax is similar (use `PathGeometry`).

---

## Quick lookup table

| HTML/CSS | XAML element |
|---|---|
| `div` (container) | `Grid` / `StackLayout` / `Border` |
| `position: absolute` | `Grid` with explicit row/column + `Margin` |
| `display: flex; gap: 12px` | `HorizontalStackLayout Spacing="12"` |
| `display: grid` | `Grid ColumnDefinitions="*,*,*"` |
| `border-radius: 16px` | `<Border StrokeShape="RoundRectangle 16"/>` |
| `box-shadow` | `Shadow` (MAUI) / `DropShadowEffect` (WPF) |
| `backdrop-filter: blur` | `AcrylicBrush` (WinUI) / pre-blurred bitmap (MAUI) |
| `<button>` | `Button` (use the `Tp.Style.*Button` styles) |
| `<input>` | `Entry` (MAUI) / `TextBox` (WPF/WinUI) |
| Scroll list | `CollectionView` (MAUI) / `ItemsControl` + `ScrollViewer` |
| SVG icon | `Path` with `Data="…"` |

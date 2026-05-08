// Thaiprompt POS Mockup — SVG icon factory + brand mark
// Style: 24x24 stroke icons (Lucide-inspired), 1.6 stroke width

window.Icon = function(name, opts) {
  opts = opts || {};
  const size = opts.size || 20;
  const color = opts.color || "currentColor";
  const stroke = opts.stroke || 1.6;
  const a = `stroke="${color}" stroke-width="${stroke}" fill="none" stroke-linecap="round" stroke-linejoin="round"`;

  const paths = {
    search:    `<circle cx="11" cy="11" r="7" ${a}/><path d="M20 20l-3.5-3.5" ${a}/>`,
    cart:      `<path d="M3 4h2l2.5 12.5a2 2 0 0 0 2 1.5h8a2 2 0 0 0 2-1.5L21 8H6" ${a}/><circle cx="10" cy="21" r="1.4" ${a}/><circle cx="18" cy="21" r="1.4" ${a}/>`,
    user:      `<circle cx="12" cy="8" r="4" ${a}/><path d="M4 21c1.5-4.5 5-6 8-6s6.5 1.5 8 6" ${a}/>`,
    users:     `<circle cx="9" cy="8" r="3.5" ${a}/><path d="M2 20c1-4 4-5.5 7-5.5s6 1.5 7 5.5" ${a}/><path d="M16 4a3.5 3.5 0 0 1 0 7" ${a}/><path d="M22 19c-.6-2.5-2.2-3.8-4.5-4.3" ${a}/>`,
    grid:      `<rect x="3" y="3" width="7" height="7" rx="1.5" ${a}/><rect x="14" y="3" width="7" height="7" rx="1.5" ${a}/><rect x="3" y="14" width="7" height="7" rx="1.5" ${a}/><rect x="14" y="14" width="7" height="7" rx="1.5" ${a}/>`,
    chart:     `<path d="M4 20V10M10 20V4M16 20v-7M22 20H2" ${a}/>`,
    box:       `<path d="M3 7l9-4 9 4-9 4-9-4z" ${a}/><path d="M3 7v10l9 4 9-4V7" ${a}/><path d="M12 11v10" ${a}/>`,
    settings:  `<circle cx="12" cy="12" r="3" ${a}/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1A2 2 0 1 1 7 4.3l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z" ${a}/>`,
    receipt:   `<path d="M5 3h14v18l-3-2-3 2-3-2-3 2-2-2V3z" ${a}/><path d="M9 8h6M9 12h6M9 16h4" ${a}/>`,
    card:      `<rect x="2" y="5" width="20" height="14" rx="2.5" ${a}/><path d="M2 10h20M6 15h4" ${a}/>`,
    qr:        `<rect x="3" y="3" width="7" height="7" rx="1" ${a}/><rect x="14" y="3" width="7" height="7" rx="1" ${a}/><rect x="3" y="14" width="7" height="7" rx="1" ${a}/><path d="M14 14h3v3h-3zM20 14v3M14 20h3M20 20v1" ${a}/>`,
    cash:      `<rect x="2" y="6" width="20" height="12" rx="2" ${a}/><circle cx="12" cy="12" r="3" ${a}/>`,
    plus:      `<path d="M12 5v14M5 12h14" ${a}/>`,
    minus:     `<path d="M5 12h14" ${a}/>`,
    trash:     `<path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13" ${a}/>`,
    x:         `<path d="M5 5l14 14M19 5L5 19" ${a}/>`,
    check:     `<path d="M5 13l4 4L19 7" ${a}/>`,
    bell:      `<path d="M6 8a6 6 0 1 1 12 0v5l1.5 3h-15L6 13V8z" ${a}/><path d="M10 19a2 2 0 0 0 4 0" ${a}/>`,
    clock:     `<circle cx="12" cy="12" r="9" ${a}/><path d="M12 7v5l3 2" ${a}/>`,
    wifi:      `<path d="M2 9a16 16 0 0 1 20 0M5 13a11 11 0 0 1 14 0M8.5 17a6 6 0 0 1 7 0" ${a}/><circle cx="12" cy="20" r="1" fill="${color}"/>`,
    printer:   `<path d="M7 9V3h10v6M7 18H4v-7a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v7h-3" ${a}/><rect x="7" y="14" width="10" height="7" rx="1" ${a}/>`,
    tag:       `<path d="M3 12V3h9l9 9-9 9-9-9z" ${a}/><circle cx="8" cy="8" r="1.5" ${a}/>`,
    star:      `<path d="M12 3l2.7 6 6.3.5-4.8 4.2 1.5 6.3L12 16.8 6.3 20l1.5-6.3L3 9.5 9.3 9z" ${a}/>`,
    fire:      `<path d="M12 3c1 4 5 5 5 10a5 5 0 1 1-10 0c0-2 1-3 1-4 1.5 1 2-1 1-3 2 0 3-1 3-3z" ${a}/>`,
    leaf:      `<path d="M5 19c0-9 7-15 16-15-1 9-7 15-16 15z" ${a}/><path d="M5 19l7-7" ${a}/>`,
    coffee:    `<path d="M4 8h13v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V8z" ${a}/><path d="M17 10h2a3 3 0 0 1 0 6h-2" ${a}/><path d="M7 4v2M11 4v2" ${a}/>`,
    pin:       `<path d="M12 21s7-7 7-12a7 7 0 1 0-14 0c0 5 7 12 7 12z" ${a}/><circle cx="12" cy="9" r="2.5" ${a}/>`,
    table:     `<rect x="3" y="6" width="18" height="4" rx="1" ${a}/><path d="M6 10v10M18 10v10M3 14h18" ${a}/>`,
    phone:     `<path d="M5 4h4l2 5-3 2a11 11 0 0 0 5 5l2-3 5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z" ${a}/>`,
    monitor:   `<rect x="2" y="4" width="20" height="13" rx="2" ${a}/><path d="M8 21h8M12 17v4" ${a}/>`,
    logout:    `<path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4M9 16l-4-4 4-4M5 12h11" ${a}/>`,
    filter:    `<path d="M4 5h16l-6 8v6l-4-2v-4z" ${a}/>`,
    arrow_up:  `<path d="M7 11l5-5 5 5M12 6v14" ${a}/>`,
    arrow_down:`<path d="M7 13l5 5 5-5M12 4v14" ${a}/>`,
    arrow_right:`<path d="M5 12h14M13 5l7 7-7 7" ${a}/>`,
    more:      `<circle cx="5" cy="12" r="1.4" fill="${color}"/><circle cx="12" cy="12" r="1.4" fill="${color}"/><circle cx="19" cy="12" r="1.4" fill="${color}"/>`,
    split:     `<path d="M14 4h6v6M20 4l-7 7M10 20H4v-6M4 20l7-7" ${a}/>`,
    cloud:     `<path d="M7 18h10a4 4 0 0 0 .5-7.97A6 6 0 0 0 6.5 11 4 4 0 0 0 7 18z" ${a}/>`,
    cloud_off: `<path d="M3 3l18 18M16 16H7a4 4 0 0 1-.5-8 6 6 0 0 1 9.5-3.5M19 17.5a4 4 0 0 0 1-2.5 4 4 0 0 0-3-3.87" ${a}/>`,
    download:  `<path d="M12 4v12M7 11l5 5 5-5M5 20h14" ${a}/>`,
    upload:    `<path d="M12 20V8M7 13l5-5 5 5M5 4h14" ${a}/>`,
    home:      `<path d="M3 11l9-7 9 7v9a2 2 0 0 1-2 2h-4v-7H9v7H5a2 2 0 0 1-2-2v-9z" ${a}/>`,
    refresh:   `<path d="M4 12a8 8 0 0 1 14-5.3M20 4v5h-5M20 12a8 8 0 0 1-14 5.3M4 20v-5h5" ${a}/>`,
    layers:    `<path d="M12 2l10 5-10 5L2 7l10-5z" ${a}/><path d="M2 17l10 5 10-5M2 12l10 5 10-5" ${a}/>`,
    eye:       `<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z" ${a}/><circle cx="12" cy="12" r="3" ${a}/>`,
    arrow_left:`<path d="M19 12H5M12 19l-7-7 7-7" ${a}/>`
  };
  const body = paths[name] || "";
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" style="display:inline-block;vertical-align:middle">${body}</svg>`;
};

// 3D Thai-themed brand mark — a glassy gradient orb with the letter "ท" centered + coral accent
window.BrandMark = function(size) {
  size = size || 44;
  return `
    <svg viewBox="0 0 100 100" width="${size}" height="${size}" style="filter:drop-shadow(0 6px 16px oklch(.55 .13 195 / .45))">
      <defs>
        <linearGradient id="bm-g-${size}" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="oklch(.85 .12 188)"/>
          <stop offset="55%" stop-color="oklch(.62 .14 195)"/>
          <stop offset="100%" stop-color="oklch(.45 .14 250)"/>
        </linearGradient>
        <linearGradient id="bm-h-${size}" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="rgba(255,255,255,.85)"/>
          <stop offset="40%" stop-color="rgba(255,255,255,0)"/>
        </linearGradient>
        <linearGradient id="bm-c-${size}" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="oklch(.85 .18 28)"/>
          <stop offset="100%" stop-color="oklch(.62 .18 25)"/>
        </linearGradient>
      </defs>
      <path d="M50 6 C 78 6 94 22 94 50 C 94 78 78 94 50 94 C 22 94 6 78 6 50 C 6 22 22 6 50 6 Z" fill="url(#bm-g-${size})"/>
      <path d="M50 6 C 78 6 94 22 94 50 C 94 60 90 68 88 70 C 80 50 60 38 36 38 C 22 38 12 44 8 48 C 10 26 26 6 50 6 Z" fill="url(#bm-h-${size})" opacity=".9"/>
      <path d="M28 35 h44 a4 4 0 0 1 4 4 v6 a4 4 0 0 1 -4 4 h-15 v22 a4 4 0 0 1 -4 4 h-6 a4 4 0 0 1 -4 -4 v-22 h-15 a4 4 0 0 1 -4 -4 v-6 a4 4 0 0 1 4 -4 z" fill="white" opacity=".95"/>
      <circle cx="74" cy="72" r="10" fill="url(#bm-c-${size})"/>
      <circle cx="71" cy="69" r="3" fill="rgba(255,255,255,.7)"/>
    </svg>`;
};

// Decorative product image placeholder — gradient swatch with monogram label
window.ProductImg = function(opts) {
  opts = opts || {};
  const hue = opts.hue ?? 195;
  const label = opts.label ?? "P";
  const kind = opts.kind || "rect";
  const r = kind === "circle" ? "50%" : "12px";
  return `
    <div style="height:100%;width:100%;
      background:linear-gradient(160deg, oklch(.92 .08 ${hue}) 0%, oklch(.82 .12 ${hue}) 60%, oklch(.65 .14 ${hue}) 100%);
      position:relative;display:flex;align-items:center;justify-content:center;overflow:hidden;color:white">
      <div style="position:absolute;inset:0;opacity:.35;
        background-image:linear-gradient(135deg, rgba(255,255,255,.12) 25%, transparent 25%, transparent 50%, rgba(255,255,255,.12) 50%, rgba(255,255,255,.12) 75%, transparent 75%, transparent);
        background-size:16px 16px"></div>
      <div style="position:absolute;inset:auto 0 0 0;height:40%;
        background:linear-gradient(180deg, transparent, rgba(0,0,0,.2))"></div>
      <div style="width:${kind === "circle" ? 64 : 70}px;height:${kind === "circle" ? 64 : 50}px;
        border-radius:${r};background:rgba(255,255,255,.35);backdrop-filter:blur(8px);
        border:1px solid rgba(255,255,255,.5);
        box-shadow:0 8px 20px -6px rgba(0,0,0,.25), 0 1px 0 rgba(255,255,255,.7) inset"></div>
      <div style="position:absolute;left:10px;bottom:8px;font-size:10px;
        font-family:var(--tp-font-mono);color:rgba(255,255,255,.85);letter-spacing:.05em;text-transform:uppercase">${label}</div>
    </div>`;
};

// Decorative QR code placeholder (random matrix that *looks* like a QR — not scannable)
window.FakeQR = function(size, color) {
  size = size || 180;
  color = color || "var(--tp-ink)";
  const cells = 21;
  const cellSize = size / cells;
  let dots = "";
  // PRNG seeded by position so it stays stable visually
  function bit(x, y) {
    const v = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
    return (v - Math.floor(v)) > 0.5 ? 1 : 0;
  }
  for (let y = 0; y < cells; y++) {
    for (let x = 0; x < cells; x++) {
      // skip finder squares (corners)
      const corner =
        (x < 7 && y < 7) ||
        (x >= cells - 7 && y < 7) ||
        (x < 7 && y >= cells - 7);
      if (corner) continue;
      if (bit(x, y)) {
        dots += `<rect x="${x * cellSize}" y="${y * cellSize}" width="${cellSize}" height="${cellSize}" fill="${color}"/>`;
      }
    }
  }
  // finder squares
  function finder(cx, cy) {
    return `
      <rect x="${cx}" y="${cy}" width="${cellSize * 7}" height="${cellSize * 7}" fill="${color}"/>
      <rect x="${cx + cellSize}" y="${cy + cellSize}" width="${cellSize * 5}" height="${cellSize * 5}" fill="white"/>
      <rect x="${cx + cellSize * 2}" y="${cy + cellSize * 2}" width="${cellSize * 3}" height="${cellSize * 3}" fill="${color}"/>`;
  }
  return `
    <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" style="background:white;border-radius:8px">
      ${dots}
      ${finder(0, 0)}
      ${finder((cells - 7) * cellSize, 0)}
      ${finder(0, (cells - 7) * cellSize)}
    </svg>`;
};

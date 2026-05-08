// Thaiprompt POS — shared building blocks (icons, primitives)

const TPIcon = ({ name, size = 20, stroke = 1.6, color = "currentColor", style = {} }) => {
  const s = { width: size, height: size, ...style };
  const p = { stroke: color, strokeWidth: stroke, fill: "none", strokeLinecap: "round", strokeLinejoin: "round" };
  switch (name) {
    case "search": return <svg style={s} viewBox="0 0 24 24"><circle cx="11" cy="11" r="7" {...p}/><path d="M20 20l-3.5-3.5" {...p}/></svg>;
    case "cart": return <svg style={s} viewBox="0 0 24 24"><path d="M3 4h2l2.5 12.5a2 2 0 0 0 2 1.5h8a2 2 0 0 0 2-1.5L21 8H6" {...p}/><circle cx="10" cy="21" r="1.4" {...p}/><circle cx="18" cy="21" r="1.4" {...p}/></svg>;
    case "user": return <svg style={s} viewBox="0 0 24 24"><circle cx="12" cy="8" r="4" {...p}/><path d="M4 21c1.5-4.5 5-6 8-6s6.5 1.5 8 6" {...p}/></svg>;
    case "menu": return <svg style={s} viewBox="0 0 24 24"><path d="M4 6h16M4 12h16M4 18h16" {...p}/></svg>;
    case "grid": return <svg style={s} viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1.5" {...p}/><rect x="14" y="3" width="7" height="7" rx="1.5" {...p}/><rect x="3" y="14" width="7" height="7" rx="1.5" {...p}/><rect x="14" y="14" width="7" height="7" rx="1.5" {...p}/></svg>;
    case "chart": return <svg style={s} viewBox="0 0 24 24"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" {...p}/></svg>;
    case "box": return <svg style={s} viewBox="0 0 24 24"><path d="M3 7l9-4 9 4-9 4-9-4z" {...p}/><path d="M3 7v10l9 4 9-4V7" {...p}/><path d="M12 11v10" {...p}/></svg>;
    case "settings": return <svg style={s} viewBox="0 0 24 24"><circle cx="12" cy="12" r="3" {...p}/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.3-1.8l-.1-.1A2 2 0 1 1 7 4.3l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z" {...p}/></svg>;
    case "users": return <svg style={s} viewBox="0 0 24 24"><circle cx="9" cy="8" r="3.5" {...p}/><path d="M2 20c1-4 4-5.5 7-5.5s6 1.5 7 5.5" {...p}/><path d="M16 4a3.5 3.5 0 0 1 0 7" {...p}/><path d="M22 19c-.6-2.5-2.2-3.8-4.5-4.3" {...p}/></svg>;
    case "receipt": return <svg style={s} viewBox="0 0 24 24"><path d="M5 3h14v18l-3-2-3 2-3-2-3 2-2-2V3z" {...p}/><path d="M9 8h6M9 12h6M9 16h4" {...p}/></svg>;
    case "card": return <svg style={s} viewBox="0 0 24 24"><rect x="2" y="5" width="20" height="14" rx="2.5" {...p}/><path d="M2 10h20M6 15h4" {...p}/></svg>;
    case "qr": return <svg style={s} viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="7" rx="1" {...p}/><rect x="14" y="3" width="7" height="7" rx="1" {...p}/><rect x="3" y="14" width="7" height="7" rx="1" {...p}/><path d="M14 14h3v3h-3zM20 14v3M14 20h3M20 20v1" {...p}/></svg>;
    case "cash": return <svg style={s} viewBox="0 0 24 24"><rect x="2" y="6" width="20" height="12" rx="2" {...p}/><circle cx="12" cy="12" r="3" {...p}/><path d="M5 9v0M19 15v0" {...p}/></svg>;
    case "plus": return <svg style={s} viewBox="0 0 24 24"><path d="M12 5v14M5 12h14" {...p}/></svg>;
    case "minus": return <svg style={s} viewBox="0 0 24 24"><path d="M5 12h14" {...p}/></svg>;
    case "trash": return <svg style={s} viewBox="0 0 24 24"><path d="M4 7h16M9 7V4h6v3M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13" {...p}/></svg>;
    case "x": return <svg style={s} viewBox="0 0 24 24"><path d="M5 5l14 14M19 5L5 19" {...p}/></svg>;
    case "check": return <svg style={s} viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" {...p}/></svg>;
    case "bell": return <svg style={s} viewBox="0 0 24 24"><path d="M6 8a6 6 0 1 1 12 0v5l1.5 3h-15L6 13V8z" {...p}/><path d="M10 19a2 2 0 0 0 4 0" {...p}/></svg>;
    case "clock": return <svg style={s} viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" {...p}/><path d="M12 7v5l3 2" {...p}/></svg>;
    case "wifi": return <svg style={s} viewBox="0 0 24 24"><path d="M2 9a16 16 0 0 1 20 0M5 13a11 11 0 0 1 14 0M8.5 17a6 6 0 0 1 7 0" {...p}/><circle cx="12" cy="20" r="1" fill={color}/></svg>;
    case "printer": return <svg style={s} viewBox="0 0 24 24"><path d="M7 9V3h10v6M7 18H4v-7a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v7h-3" {...p}/><rect x="7" y="14" width="10" height="7" rx="1" {...p}/></svg>;
    case "tag": return <svg style={s} viewBox="0 0 24 24"><path d="M3 12V3h9l9 9-9 9-9-9z" {...p}/><circle cx="8" cy="8" r="1.5" {...p}/></svg>;
    case "star": return <svg style={s} viewBox="0 0 24 24"><path d="M12 3l2.7 6 6.3.5-4.8 4.2 1.5 6.3L12 16.8 6.3 20l1.5-6.3L3 9.5 9.3 9z" {...p}/></svg>;
    case "fire": return <svg style={s} viewBox="0 0 24 24"><path d="M12 3c1 4 5 5 5 10a5 5 0 1 1-10 0c0-2 1-3 1-4 1.5 1 2-1 1-3 2 0 3-1 3-3z" {...p}/></svg>;
    case "leaf": return <svg style={s} viewBox="0 0 24 24"><path d="M5 19c0-9 7-15 16-15-1 9-7 15-16 15z" {...p}/><path d="M5 19l7-7" {...p}/></svg>;
    case "coffee": return <svg style={s} viewBox="0 0 24 24"><path d="M4 8h13v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V8z" {...p}/><path d="M17 10h2a3 3 0 0 1 0 6h-2" {...p}/><path d="M7 4v2M11 4v2" {...p}/></svg>;
    case "pin": return <svg style={s} viewBox="0 0 24 24"><path d="M12 21s7-7 7-12a7 7 0 1 0-14 0c0 5 7 12 7 12z" {...p}/><circle cx="12" cy="9" r="2.5" {...p}/></svg>;
    case "table": return <svg style={s} viewBox="0 0 24 24"><rect x="3" y="6" width="18" height="4" rx="1" {...p}/><path d="M6 10v10M18 10v10M3 14h18" {...p}/></svg>;
    case "phone": return <svg style={s} viewBox="0 0 24 24"><path d="M5 4h4l2 5-3 2a11 11 0 0 0 5 5l2-3 5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z" {...p}/></svg>;
    case "monitor": return <svg style={s} viewBox="0 0 24 24"><rect x="2" y="4" width="20" height="13" rx="2" {...p}/><path d="M8 21h8M12 17v4" {...p}/></svg>;
    case "logout": return <svg style={s} viewBox="0 0 24 24"><path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4M9 16l-4-4 4-4M5 12h11" {...p}/></svg>;
    case "filter": return <svg style={s} viewBox="0 0 24 24"><path d="M4 5h16l-6 8v6l-4-2v-4z" {...p}/></svg>;
    case "arrow-up": return <svg style={s} viewBox="0 0 24 24"><path d="M7 11l5-5 5 5M12 6v14" {...p}/></svg>;
    case "arrow-down": return <svg style={s} viewBox="0 0 24 24"><path d="M7 13l5 5 5-5M12 4v14" {...p}/></svg>;
    case "arrow-right": return <svg style={s} viewBox="0 0 24 24"><path d="M5 12h14M13 5l7 7-7 7" {...p}/></svg>;
    case "more": return <svg style={s} viewBox="0 0 24 24"><circle cx="5" cy="12" r="1.4" fill={color}/><circle cx="12" cy="12" r="1.4" fill={color}/><circle cx="19" cy="12" r="1.4" fill={color}/></svg>;
    case "split": return <svg style={s} viewBox="0 0 24 24"><path d="M14 4h6v6M20 4l-7 7M10 20H4v-6M4 20l7-7" {...p}/></svg>;
    default: return null;
  }
};

// 3D thai-themed logo mark
const TPLogo = ({ size = 40, glow = true }) => (
  <div style={{ width: size, height: size, position: "relative", display: "inline-block" }}>
    <svg viewBox="0 0 100 100" style={{ width: "100%", height: "100%", filter: glow ? "drop-shadow(0 6px 16px oklch(.55 .13 195 / .45))" : "none" }}>
      <defs>
        <linearGradient id="tplogo-g" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="oklch(.85 .12 188)"/>
          <stop offset="55%" stopColor="oklch(.62 .14 195)"/>
          <stop offset="100%" stopColor="oklch(.45 .14 250)"/>
        </linearGradient>
        <linearGradient id="tplogo-h" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="rgba(255,255,255,.85)"/>
          <stop offset="40%" stopColor="rgba(255,255,255,0)"/>
        </linearGradient>
        <linearGradient id="tplogo-c" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="oklch(.85 .18 28)"/>
          <stop offset="100%" stopColor="oklch(.62 .18 25)"/>
        </linearGradient>
      </defs>
      <path d="M50 6 C 78 6 94 22 94 50 C 94 78 78 94 50 94 C 22 94 6 78 6 50 C 6 22 22 6 50 6 Z" fill="url(#tplogo-g)"/>
      <path d="M50 6 C 78 6 94 22 94 50 C 94 60 90 68 88 70 C 80 50 60 38 36 38 C 22 38 12 44 8 48 C 10 26 26 6 50 6 Z" fill="url(#tplogo-h)" opacity=".9"/>
      <path d="M28 35 h44 a4 4 0 0 1 4 4 v6 a4 4 0 0 1 -4 4 h-15 v22 a4 4 0 0 1 -4 4 h-6 a4 4 0 0 1 -4 -4 v-22 h-15 a4 4 0 0 1 -4 -4 v-6 a4 4 0 0 1 4 -4 z" fill="white" opacity=".95"/>
      <circle cx="74" cy="72" r="10" fill="url(#tplogo-c)"/>
      <circle cx="71" cy="69" r="3" fill="rgba(255,255,255,.7)"/>
    </svg>
  </div>
);

// rich placeholder image with category-based color and label
const TPProductImg = ({ label = "ผลิตภัณฑ์", hue = 195, kind = "rect" }) => (
  <div style={{
    height: "100%",
    width: "100%",
    background: `linear-gradient(160deg, oklch(.92 .08 ${hue}) 0%, oklch(.82 .12 ${hue}) 60%, oklch(.65 .14 ${hue}) 100%)`,
    position: "relative",
    display: "flex", alignItems: "center", justifyContent: "center",
    overflow: "hidden",
    color: "white"
  }}>
    <div className="tp-img-ph" style={{ position: "absolute", inset: 0, opacity: .35 }}/>
    <div style={{
      position: "absolute", inset: "auto 0 0 0", height: "40%",
      background: "linear-gradient(180deg, transparent, rgba(0,0,0,.2))"
    }}/>
    <div style={{
      width: kind === "circle" ? 64 : 70,
      height: kind === "circle" ? 64 : 50,
      borderRadius: kind === "circle" ? "50%" : 12,
      background: "rgba(255,255,255,.35)",
      backdropFilter: "blur(8px)",
      border: "1px solid rgba(255,255,255,.5)",
      boxShadow: "0 8px 20px -6px rgba(0,0,0,.25), 0 1px 0 rgba(255,255,255,.7) inset"
    }}/>
    <div style={{
      position: "absolute", left: 10, bottom: 8,
      fontSize: 10, fontFamily: "var(--tp-font-mono)",
      color: "rgba(255,255,255,.85)", letterSpacing: ".05em",
      textTransform: "uppercase"
    }}>{label}</div>
  </div>
);

window.TPIcon = TPIcon;
window.TPLogo = TPLogo;
window.TPProductImg = TPProductImg;

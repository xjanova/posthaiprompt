// Thaiprompt POS Mockup — All 11 screen renderers
// Each function returns an HTML string to be injected into .canvas-inner.
// Strings are wrapped through window.I18N.t so language toggle works live.

(function() {
  const t  = (k, v) => window.I18N.t(k, v);
  const ic = (n, o) => window.Icon(n, o);
  const bm = (s) => window.BrandMark(s);
  const pi = (o) => window.ProductImg(o);
  const qr = (s, c) => window.FakeQR(s, c);

  function frameWrap(klass, contentHTML) {
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">${arguments[2] || ""}</span>
        <span class="screen-meta-size">${arguments[3] || ""}</span>
      </div>
      <div class="screen-frame ${klass}">
        <div class="screen-bg"></div>
        ${contentHTML}
      </div>`;
  }

  /* ────────────────────────────────────────────────
     OVERVIEW (welcome / index)
     ────────────────────────────────────────────────*/
  function renderOverview() {
    const cards = [
      { icon: "user",    color: "80",  title: "login", desc: tr("PIN เข้าระบบ · เลือกผู้ใช้", "PIN sign-in · pick user") },
      { icon: "grid",    color: "188", title: "cashier", desc: tr("จอขายหลัก · ตัดบิล · รับชำระ", "Main POS · sell · pay") },
      { icon: "qr",      color: "25",  title: "payment", desc: tr("เงินสด · QR · บัตร · e-Wallet", "Cash · QR · card · e-Wallet") },
      { icon: "card",    color: "188", title: "nfc_scan", desc: tr("แตะบัตร / มือถือเพื่อชำระ", "Tap card or phone to pay") },
      { icon: "receipt", color: "270", title: "receipt", desc: tr("ใบเสร็จย่อ · พิมพ์ thermal 80mm", "Abbreviated receipt · 80mm thermal") },
      { icon: "monitor", color: "270", title: "customer_display", desc: tr("จอที่ 2 ลูกค้า · โปรโมชัน", "2nd display for guests · promo") },
      { icon: "fire",    color: "25",  title: "kds", desc: tr("จอครัว · ออเดอร์เรียลไทม์", "Kitchen · realtime tickets") },
      { icon: "chart",   color: "80",  title: "dashboard", desc: tr("KPI · กราฟ · เมนูขายดี", "KPIs · charts · top items") },
      { icon: "box",     color: "265", title: "inventory", desc: tr("สต็อก · ราคา · บาร์โค้ด · CSV", "Stock · pricing · barcode · CSV") },
      { icon: "layers",  color: "270", title: "stock_mgmt", desc: tr("Stock movements · รับเข้า/เบิก/โอน", "Stock movements · receive/issue/transfer") },
      { icon: "users",   color: "188", title: "staff", desc: tr("ตารางกะ · ยอดขายต่อคน · เงินเดือน", "Schedule · per-staff sales · payroll") },
      { icon: "chart",   color: "188", title: "accounting", desc: tr("ผังบัญชี · งบกำไรขาดทุน · งบทดลอง", "CoA · P&L · trial balance") },
      { icon: "receipt", color: "145", title: "create_bill", desc: tr("ออกใบกำกับ · ใบเสร็จ · ใบแจ้งหนี้", "Tax invoice · receipt · invoice") },
      { icon: "receipt", color: "270", title: "tax_invoice", desc: tr("e-Tax Invoice พร้อมส่งกรมสรรพากร", "e-Tax invoice · ready to send to RD") },
      { icon: "tag",     color: "25",  title: "coupons", desc: tr("คูปอง · 1+1 · ROI ของแคมเปญ", "Coupons · 1+1 · campaign ROI") },
      { icon: "phone",   color: "270", title: "delivery", desc: tr("ติดตามไรเดอร์ · แผนที่สด", "Track riders · live map") },
      { icon: "split",   color: "145", title: "shipping_providers", desc: tr("Grab · LINE MAN · Flash · ไปรษณีย์", "Grab · LINE MAN · Flash · TH Post") },
      { icon: "qr",      color: "188", title: "barcode", desc: tr("จัดการ EAN-13 / Code 128 · พิมพ์ฉลาก", "EAN-13 / Code 128 · sticker print") },
      { icon: "printer", color: "80",  title: "shipping_label", desc: tr("ใบปะหน้า 4×6\" · Manifest", "4×6\" labels · manifest") },
      { icon: "settings", color: "265", title: "admin", desc: tr("ผู้ใช้ · บทบาท · สิทธิ์ · audit log", "Users · roles · perms · audit") },
      { icon: "table",   color: "188", title: "tablet", desc: tr("iPad ผังโต๊ะ · พนักงานเสิร์ฟ", "iPad floor plan · waiters") },
      { icon: "phone",   color: "25",  title: "mobile_order", desc: tr("ลูกค้าสแกน QR สั่งจากโต๊ะ", "Guests scan QR to order") },
      { icon: "user",    color: "80",  title: "mobile_mgr", desc: tr("ผู้จัดการดูยอด · อนุมัติ", "Manager dashboard · approvals") }
    ];
    return `
      <div class="welcome-hero">
        <div style="position:absolute;width:280px;height:280px;right:-60px;top:-80px;border-radius:50%;
          background:linear-gradient(135deg, oklch(.85 .18 28 / .55), transparent);"></div>
        <div style="position:absolute;width:160px;height:160px;right:160px;bottom:-60px;border-radius:50%;
          background:oklch(.82 .14 80 / .35);filter:blur(30px)"></div>
        <div style="position:relative">
          <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35);margin-bottom:14px">
            ${ic("star", { size: 12 })} ${t("brand_subtitle")} · MOCKUP PREVIEW
          </span>
          <h1>${t("brand_title")}</h1>
          <p>${t("arch_desc")}</p>
          <div style="display:flex;gap:8px;margin-top:18px;flex-wrap:wrap">
            <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35)">
              ${ic("monitor", { size: 13 })} Windows
            </span>
            <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35)">
              ${ic("phone", { size: 13 })} iOS · Android
            </span>
            <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35)">
              ${ic("box", { size: 13 })} SQLite Offline
            </span>
            <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35)">
              ${ic("cloud", { size: 13 })} Sync API
            </span>
          </div>
        </div>
      </div>

      <div class="overview-grid">
        ${cards.map(c => `
          <div class="overview-card" data-nav="${c.title}" style="cursor:pointer">
            <div class="ico-wrap" style="background:linear-gradient(160deg, oklch(.82 .12 ${c.color}), oklch(.55 .14 ${c.color}))">
              ${ic(c.icon, { size: 24, color: "white" })}
            </div>
            <h3>${t(c.title)}</h3>
            <p>${c.desc}</p>
          </div>
        `).join("")}
      </div>

      <div style="margin-top:26px" class="tp-glass" >
        <div style="padding:24px 26px">
          <div style="display:flex;align-items:center;gap:10px;margin-bottom:8px">
            ${ic("layers", { size: 18, color: "var(--tp-teal-deep)" })}
            <h3 style="margin:0;font-size:18px;font-weight:600">${t("arch_title")}</h3>
          </div>
          <p style="margin:0 0 16px;color:var(--tp-ink-soft);font-size:14px;line-height:1.55">
            ${t("arch_desc")}
          </p>
          <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px">
            ${[
              ["UI Layer", ".NET MAUI XAML · cross-platform"],
              ["Data Layer", "SQLite + EF Core · offline-first"],
              ["Sync Layer", "REST · Thaiprompt-Affiliate API"],
              ["Hardware", "USB barcode · ESC/POS printer · cash drawer"]
            ].map(([h, d]) => `
              <div style="padding:14px 16px;border-radius:14px;background:rgba(255,255,255,.6);border:1px solid rgba(255,255,255,.7)">
                <div style="font-size:13px;font-weight:600;margin-bottom:3px">${h}</div>
                <div style="font-size:12px;color:var(--tp-ink-mute)">${d}</div>
              </div>
            `).join("")}
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     LOGIN
     ────────────────────────────────────────────────*/
  function renderLogin() {
    const users = [
      { n: "ปริม", c: "oklch(.82 .14 80)", on: true },
      { n: "ธนา", c: "oklch(.72 .14 188)" },
      { n: "นิด", c: "oklch(.72 .18 25)" },
      { n: "เม", c: "oklch(.55 .14 280)" }
    ];
    const numpadKeys = [1, 2, 3, 4, 5, 6, 7, 8, 9, "·", 0, "⌫"];

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">01 · ${t("login")}</span>
        <span class="screen-meta-size">1280 × 800 · Windows / Tablet</span>
      </div>
      <div class="screen-frame win-1280">
        <div class="screen-bg"></div>
        <div class="tp-orb" style="width:360px;height:360px;left:-80px;top:-80px;background:oklch(.78 .14 188)"></div>
        <div class="tp-orb" style="width:280px;height:280px;right:-60px;bottom:-60px;background:oklch(.72 .18 25)"></div>
        <div class="tp-orb" style="width:200px;height:200px;right:220px;top:80px;background:oklch(.82 .14 80);opacity:.4"></div>

        <div class="login-card">
          <div class="login-brand-side">
            <div style="position:absolute;inset:0;opacity:.3;background:radial-gradient(circle at 80% 0%, oklch(.85 .18 28 / .8), transparent 50%)"></div>
            <div style="position:absolute;width:220px;height:220px;right:-60px;bottom:-60px;border-radius:50%;
              background:linear-gradient(135deg, rgba(255,255,255,.25), rgba(255,255,255,.05));
              border:1px solid rgba(255,255,255,.3);backdrop-filter:blur(20px)"></div>

            <div style="position:relative;display:flex;align-items:center;gap:14px">
              ${bm(56)}
              <div>
                <div style="font-size:22px;font-weight:600;letter-spacing:-.02em">${t("brand_title")}</div>
                <div style="font-size:13px;opacity:.85;letter-spacing:.05em">${t("brand_subtitle")}</div>
              </div>
            </div>
            <div style="flex:1"></div>
            <div style="position:relative">
              <div style="font-size:32px;font-weight:600;line-height:1.15;letter-spacing:-.02em">${t("welcome")}</div>
              <div style="font-size:14px;opacity:.85;margin-top:14px;line-height:1.5;max-width:280px">${t("welcome_sub")}</div>
            </div>
            <div style="position:relative;display:flex;gap:10px;margin-top:32px;font-size:11px;opacity:.8">
              <span class="tp-mono">${t("version")}</span>
              <span>·</span>
              <span>${t("branch")}</span>
            </div>
          </div>

          <div class="login-pin-side">
            <span style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("sign_in")}</span>
            <h1 style="margin:6px 0 0;font-size:28px;font-weight:600;letter-spacing:-.02em">${t("enter_pin")}</h1>

            <div style="display:flex;gap:8px;margin-top:20px;margin-bottom:24px">
              ${users.map(u => `
                <div style="text-align:center">
                  <div style="width:44px;height:44px;border-radius:50%;
                    background:linear-gradient(135deg, ${u.c}, oklch(.50 .12 30));
                    border:${u.on ? "2px solid oklch(.55 .13 195)" : "2px solid white"};
                    display:flex;align-items:center;justify-content:center;color:white;font-size:14px;font-weight:600;
                    box-shadow:${u.on ? "0 0 0 3px oklch(.55 .13 195 / .25)" : "0 4px 10px -3px rgba(20,40,80,.2)"};
                    cursor:pointer">${u.n}</div>
                </div>
              `).join("")}
              <div style="text-align:center">
                <div style="width:44px;height:44px;border-radius:50%;border:1.5px dashed var(--tp-line);
                  display:flex;align-items:center;justify-content:center;color:var(--tp-ink-mute);font-size:18px;cursor:pointer">+</div>
              </div>
            </div>

            <div class="pin-display">
              ${[1, 1, 0, 0].map(d => `
                <div class="pin-cell">${d ? '<div class="pin-dot"></div>' : ""}</div>
              `).join("")}
            </div>

            <div class="numpad" style="margin-top:8px">
              ${numpadKeys.map(k => `<button class="tp-key">${k}</button>`).join("")}
            </div>

            <div style="display:flex;align-items:center;margin-top:18px;gap:12px">
              <button class="tp-btn tp-btn-ghost" style="flex:1">${t("forgot_pin")}</button>
              <button class="tp-btn tp-btn-primary" data-route="cashier" style="flex:1">${t("sign_in")} ${ic("arrow_right", { size: 16, color: "white" })}</button>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     CASHIER (main POS)
     ────────────────────────────────────────────────*/
  function renderCashier() {
    const cats = [
      { id: "hot", name: t("cat_hot"), icon: "fire", count: 18, hue: 25 },
      { id: "cold", name: t("cat_cold"), icon: "leaf", count: 22, hue: 188 },
      { id: "coffee", name: t("cat_coffee"), icon: "coffee", count: 14, hue: 60 },
      { id: "bakery", name: t("cat_bakery"), icon: "tag", count: 11, hue: 35 },
      { id: "set", name: t("cat_set"), icon: "star", count: 6, hue: 280 }
    ];
    const products = [
      { name: window.I18N.lang === "th" ? "ชาไทยเย็น" : "Iced Thai Tea", price: 65, hue: 25, tag: t("bestseller"), kind: "rect", code: "TT-01" },
      { name: window.I18N.lang === "th" ? "ชาเขียวมัทฉะลาเต้" : "Matcha Latte", price: 85, hue: 145, kind: "circle", code: "MT-02" },
      { name: window.I18N.lang === "th" ? "อเมริกาโน่เย็น" : "Iced Americano", price: 70, hue: 35, kind: "rect", code: "AM-03" },
      { name: window.I18N.lang === "th" ? "ลาเต้ร้อน" : "Hot Latte", price: 75, hue: 50, kind: "circle", code: "LT-04" },
      { name: window.I18N.lang === "th" ? "โกโก้ปั่น" : "Choco Frappe", price: 80, hue: 28, tag: window.I18N.lang === "th" ? "ใหม่" : "New", kind: "rect", code: "CC-05" },
      { name: window.I18N.lang === "th" ? "ชามะนาวโซดา" : "Lemon Tea Soda", price: 55, hue: 105, kind: "circle", code: "LM-06" },
      { name: window.I18N.lang === "th" ? "เอสเปรสโซ่" : "Espresso", price: 60, hue: 40, kind: "rect", code: "ES-07" },
      { name: window.I18N.lang === "th" ? "นมสดน้ำผึ้ง" : "Honey Milk", price: 65, hue: 70, kind: "rect", code: "HM-08" }
    ];
    const cart = [
      { name: window.I18N.lang === "th" ? "ชาไทยเย็น" : "Iced Thai Tea", note: window.I18N.lang === "th" ? "หวานน้อย ไม่เพิ่มไข่มุก" : "Less sweet, no boba", qty: 2, price: 65, hue: 25, kind: "rect" },
      { name: window.I18N.lang === "th" ? "ชาเขียวมัทฉะลาเต้" : "Matcha Latte", note: window.I18N.lang === "th" ? "ขนาดใหญ่ +10" : "Large +10", qty: 1, price: 95, hue: 145, kind: "circle" },
      { name: window.I18N.lang === "th" ? "ครัวซองต์อัลมอนด์" : "Almond Croissant", note: window.I18N.lang === "th" ? "อุ่น" : "Warmed", qty: 1, price: 55, hue: 35, kind: "rect" }
    ];
    const subtotal = cart.reduce((s, i) => s + i.qty * i.price, 0);
    const discount = 30;
    const tax = Math.round((subtotal - discount) * 0.07);
    const total = subtotal - discount + tax;

    const railItems = [
      { i: "grid", on: true, l: window.I18N.lang === "th" ? "ขาย" : "Sell", route: null },
      { i: "receipt", l: window.I18N.lang === "th" ? "บิล" : "Bills", route: "create_bill" },
      { i: "users", l: window.I18N.lang === "th" ? "ลูกค้า" : "Guests", route: "staff" },
      { i: "box", l: window.I18N.lang === "th" ? "สต็อก" : "Stock", route: "inventory" },
      { i: "chart", l: window.I18N.lang === "th" ? "รายงาน" : "Reports", route: "dashboard" },
      { i: "table", l: window.I18N.lang === "th" ? "โต๊ะ" : "Tables", route: "tablet" },
      { i: "settings", l: window.I18N.lang === "th" ? "ตั้งค่า" : "Settings", route: "admin" }
    ];

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">02 · ${t("cashier")}</span>
        <span class="screen-meta-size">1440 × 900 · Windows</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>
        <div class="cashier-wrap">

          <aside class="cashier-rail">
            ${bm(48)}
            <div style="font-size:9px;font-weight:600;letter-spacing:.15em;margin-top:2px;color:var(--tp-ink-soft)">POS</div>
            <div style="height:1px;width:36px;background:var(--tp-line);margin:12px 0"></div>
            ${railItems.map(it => `
              <button class="nav-btn ${it.on ? "active" : ""}" ${it.route ? `data-route="${it.route}"` : ""}>
                ${ic(it.i, { size: 22, color: it.on ? "white" : "var(--tp-ink-soft)" })}
                <span>${it.l}</span>
              </button>
            `).join("")}
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-icon" data-route="login" style="width:56px;height:56px;border-radius:16px">${ic("logout", { size: 22 })}</button>
          </aside>

          <header class="cashier-top tp-glass" style="border-radius:22px">
            <div class="cashier-search">
              ${ic("search", { size: 18, color: "var(--tp-ink-soft)" })}
              <input placeholder="${t("search_ph")}"/>
              <span class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute);padding:3px 8px;border-radius:6px;background:rgba(20,40,80,.06)">F2</span>
            </div>

            <div style="display:flex;gap:8px">
              <span class="tp-chip tp-chip-active">${ic("table", { size: 13, color: "white" })} ${t("table_n", { n: 7, seats: 4 })}</span>
              <span class="tp-chip">${t("dine_in")}</span>
              <span class="tp-chip">${t("take_out")}</span>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;align-items:center;gap:8px">
              <span class="tp-chip"><span class="tp-dot"></span> ${t("online")}</span>
              <span class="tp-chip">${ic("printer", { size: 13 })} ${t("ready")}</span>
              <span class="tp-chip tp-mono">14:32</span>
            </div>
            <div style="width:1px;height:36px;background:var(--tp-line)"></div>
            <button class="tp-btn tp-btn-ghost" style="height:44px;padding:0 14px;gap:10px">
              <div style="width:30px;height:30px;border-radius:50%;
                background:linear-gradient(135deg, oklch(.82 .14 80), oklch(.65 .14 50));
                display:flex;align-items:center;justify-content:center;color:white;font-size:13px;font-weight:600;
                box-shadow:0 4px 10px -3px rgba(20,40,80,.3)">ป</div>
              <div style="display:flex;flex-direction:column;align-items:flex-start;line-height:1.15">
                <span style="font-size:13px;font-weight:600">ปริม สุข</span>
                <span style="font-size:11px;color:var(--tp-ink-mute)">${t("cashier_role")}</span>
              </div>
            </button>
          </header>

          <main class="cashier-main">
            <div style="display:flex;gap:12px;margin-bottom:14px;overflow:hidden">
              ${cats.map((c, i) => `
                <button class="cat-btn" style="${i === 0 ? `background:linear-gradient(160deg, oklch(.82 .12 ${c.hue}), oklch(.55 .14 ${c.hue}));color:white;border:1px solid rgba(255,255,255,.4);box-shadow:0 1px 0 rgba(255,255,255,.5) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 12px 24px -10px oklch(.55 .14 ${c.hue} / .5)` : ""}">
                  <div class="cat-ico" style="background:${i === 0 ? "rgba(255,255,255,.25)" : `linear-gradient(160deg, oklch(.92 .08 ${c.hue}), oklch(.78 .13 ${c.hue}))`};
                    box-shadow:${i === 0 ? "0 1px 0 rgba(255,255,255,.4) inset" : `0 6px 14px -4px oklch(.65 .14 ${c.hue} / .5)`}">
                    ${ic(c.icon, { size: 22, color: "white" })}
                  </div>
                  <div class="cat-text">
                    <span class="cat-name">${c.name}</span>
                    <span class="cat-count">${t("items_count", { n: c.count })}</span>
                  </div>
                </button>
              `).join("")}
            </div>

            <div class="tp-glass" style="height:calc(100% - 100px);padding:18px;overflow:hidden">
              <div style="display:flex;align-items:center;margin-bottom:14px">
                <h3 style="margin:0;font-size:18px;font-weight:600;letter-spacing:-.01em">
                  ${t("cat_hot")} <span style="color:var(--tp-ink-mute);font-weight:400;font-size:14px">· ${t("items_count", { n: 18 })}</span>
                </h3>
                <div style="flex:1"></div>
                <div style="display:flex;gap:6px">
                  <span class="tp-chip">${t("all")}</span>
                  <span class="tp-chip">${t("bestseller")}</span>
                  <span class="tp-chip">${t("promo")}</span>
                  <button class="tp-btn tp-btn-ghost" style="height:30px;padding:0 12px;font-size:13px">
                    ${ic("filter", { size: 14 })} ${t("filter")}
                  </button>
                </div>
              </div>
              <div class="product-grid">
                ${products.map(p => `
                  <div class="tp-prod" style="height:200px">
                    <div class="tp-prod-img">${pi({ label: p.code, hue: p.hue, kind: p.kind })}</div>
                    ${p.tag ? `<div style="position:absolute;top:18px;left:18px;padding:4px 10px;border-radius:999px;font-size:11px;font-weight:600;
                      background:${p.tag === t("bestseller") ? "linear-gradient(180deg, oklch(.78 .18 28), oklch(.60 .18 25))" : "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))"};
                      color:white;box-shadow:0 4px 10px -3px rgba(20,40,80,.3)">${p.tag}</div>` : ""}
                    <div style="padding:0 14px 12px">
                      <div style="font-size:14px;font-weight:500;margin-bottom:4px">${p.name}</div>
                      <div style="display:flex;align-items:baseline;gap:4px">
                        <span class="tp-tnum" style="font-size:19px;font-weight:600;color:var(--tp-teal-deep)">฿${p.price}</span>
                        <span style="font-size:11px;color:var(--tp-ink-mute)">/${window.I18N.lang === "th" ? "แก้ว" : "cup"}</span>
                        <div style="flex:1"></div>
                        <button class="tp-btn tp-btn-primary" style="width:30px;height:30px;padding:0;border-radius:10px">
                          ${ic("plus", { size: 16, color: "white" })}
                        </button>
                      </div>
                    </div>
                  </div>
                `).join("")}
              </div>
            </div>
          </main>

          <aside class="cashier-cart tp-glass">
            <div style="padding:20px 22px 14px;border-bottom:1px solid rgba(20,40,80,.08)">
              <div style="display:flex;align-items:center">
                <div>
                  <div style="display:flex;align-items:center;gap:8px">
                    <h2 style="margin:0;font-size:20px;font-weight:600">${t("order_no", { no: "A1042" })}</h2>
                    <span class="tp-chip tp-chip-success">${t("status_open")}</span>
                  </div>
                  <div style="font-size:12px;color:var(--tp-ink-mute);margin-top:3px">
                    ${t("table_n", { n: 7, seats: 4 })} · ${t("customer_count", { n: 2 })} · ${t("started_at", { time: "14:18" })}
                  </div>
                </div>
                <div style="flex:1"></div>
                <button class="tp-btn tp-btn-ghost tp-btn-icon" style="width:38px;height:38px">${ic("more", { size: 18 })}</button>
              </div>
            </div>

            <div class="tp-scroll" style="flex:1;overflow:auto;padding:10px 14px">
              ${cart.map(it => `
                <div class="cart-row">
                  <div style="width:56px;height:56px;border-radius:12px;overflow:hidden;flex-shrink:0">
                    ${pi({ hue: it.hue, kind: it.kind })}
                  </div>
                  <div style="flex:1;min-width:0">
                    <div style="display:flex;justify-content:space-between;gap:8px">
                      <span style="font-size:14px;font-weight:500;line-height:1.2">${it.name}</span>
                      <span class="tp-tnum" style="font-size:14px;font-weight:600">฿${it.qty * it.price}</span>
                    </div>
                    <div style="font-size:12px;color:var(--tp-ink-mute);margin-top:3px">${it.note}</div>
                    <div style="display:flex;align-items:center;margin-top:8px;gap:8px">
                      <div class="qty-stepper">
                        <button class="step minus">${ic("minus", { size: 12 })}</button>
                        <span class="num tp-tnum">${it.qty}</span>
                        <button class="step plus">${ic("plus", { size: 12, color: "white" })}</button>
                      </div>
                      <button style="height:26px;padding:0 10px;border-radius:999px;border:1px solid var(--tp-line);background:white;font-size:11px;font-family:inherit;color:var(--tp-ink-soft);cursor:pointer">${t("note")}</button>
                      <div style="flex:1"></div>
                      <button style="width:26px;height:26px;border:none;background:transparent;cursor:pointer;color:var(--tp-coral-deep)">${ic("trash", { size: 15 })}</button>
                    </div>
                  </div>
                </div>
              `).join("")}

              <div style="display:flex;align-items:center;gap:10px;padding:10px 14px;margin:8px 4px;border-radius:12px;
                background:linear-gradient(160deg, oklch(.95 .08 80), oklch(.92 .10 65));border:1px solid oklch(.85 .10 75)">
                ${ic("tag", { size: 16, color: "oklch(.55 .14 70)" })}
                <span style="font-size:13px;font-weight:500;color:oklch(.35 .08 70)">${t("coupon", { code: "TP-MAY30" })}</span>
                <div style="flex:1"></div>
                <span class="tp-tnum" style="font-size:13px;font-weight:600;color:oklch(.45 .14 70)">−฿${discount}</span>
              </div>
            </div>

            <div style="padding:16px 22px 18px;border-top:1px solid rgba(20,40,80,.08)">
              <div style="display:grid;gap:6px;font-size:13px;margin-bottom:10px">
                <div style="display:flex;justify-content:space-between;color:var(--tp-ink-soft)">
                  <span>${t("subtotal")}</span><span class="tp-tnum">฿${subtotal}</span>
                </div>
                <div style="display:flex;justify-content:space-between;color:oklch(.55 .14 70)">
                  <span>${t("discount")}</span><span class="tp-tnum">−฿${discount}</span>
                </div>
                <div style="display:flex;justify-content:space-between;color:var(--tp-ink-soft)">
                  <span>${t("vat")}</span><span class="tp-tnum">฿${tax}</span>
                </div>
              </div>

              <div class="cart-total-card">
                <span style="font-size:15px;font-weight:500">${t("total")}</span>
                <span class="tp-tnum" style="font-size:30px;font-weight:600;letter-spacing:-.02em">฿${total}</span>
              </div>

              <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:10px">
                <button class="tp-btn tp-btn-ghost" style="height:42px;font-size:13px">${ic("split", { size: 15 })} ${t("split_bill")}</button>
                <button class="tp-btn tp-btn-ghost" data-route="coupons" style="height:42px;font-size:13px">${ic("tag", { size: 15 })} ${t("apply_coupon")}</button>
                <button class="tp-btn tp-btn-ghost" data-route="staff" style="height:42px;font-size:13px">${ic("user", { size: 15 })} ${t("member")}</button>
              </div>

              <button class="tp-btn tp-btn-coral" data-route="payment" style="width:100%;height:60px;font-size:18px;font-weight:600;border-radius:18px">
                ${t("pay_now")} · ฿${total} ${ic("arrow_right", { size: 20, color: "white" })}
              </button>
            </div>
          </aside>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     PAYMENT
     ────────────────────────────────────────────────*/
  function renderPayment() {
    const methods = [
      { id: "cash", label: t("cash"), icon: "cash", color: "145", on: true, route: null },
      { id: "qr",   label: t("qr"),   icon: "qr",   color: "188", route: "nfc_scan" },
      { id: "card", label: t("card"), icon: "card", color: "265", route: "nfc_scan" },
      { id: "ewallet", label: t("ewallet"), icon: "phone", color: "25", route: null },
      { id: "voucher", label: t("voucher"), icon: "tag", color: "80", route: "coupons" }
    ];
    const numpad = [1, 2, 3, 4, 5, 6, 7, 8, 9, ".", 0, "⌫"];
    const total = 415;
    const received = 500;
    const change = received - total;

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">03 · ${t("payment")}</span>
        <span class="screen-meta-size">1100 × 800 · Modal</span>
      </div>
      <div class="screen-frame payment">
        <div class="screen-bg"></div>
        <div style="position:absolute;inset:0;display:grid;grid-template-columns:60% 40%;gap:20px;padding:28px">
          <div class="tp-glass" style="padding:26px 28px">
            <div style="display:flex;align-items:center;margin-bottom:18px">
              <div>
                <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("pay_method")}</div>
                <h2 style="margin:4px 0 0;font-size:24px;font-weight:600">${t("order_no", { no: "A1042" })}</h2>
              </div>
              <div style="flex:1"></div>
              <button class="tp-btn tp-btn-ghost tp-btn-icon" data-route="cashier">${ic("x", { size: 20 })}</button>
            </div>

            <div style="display:grid;grid-template-columns:repeat(3, 1fr);gap:14px">
              ${methods.map(m => `
                <button ${m.route ? `data-route="${m.route}"` : ""} style="height:140px;border-radius:22px;border:none;cursor:pointer;text-align:left;padding:18px;
                  background:${m.on ? `linear-gradient(160deg, oklch(.82 .12 ${m.color}), oklch(.55 .14 ${m.color}))` : "linear-gradient(160deg, rgba(255,255,255,.92), rgba(255,255,255,.62))"};
                  color:${m.on ? "white" : "var(--tp-ink)"};
                  border:1px solid ${m.on ? "rgba(255,255,255,.4)" : "rgba(255,255,255,.7)"};
                  box-shadow:${m.on ? `0 1px 0 rgba(255,255,255,.5) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 14px 28px -10px oklch(.55 .14 ${m.color} / .5)` : "0 1px 0 rgba(255,255,255,.9) inset, 0 8px 18px -10px rgba(20,40,80,.18)"}">
                  <div style="width:48px;height:48px;border-radius:14px;
                    background:${m.on ? "rgba(255,255,255,.25)" : `linear-gradient(160deg, oklch(.92 .08 ${m.color}), oklch(.78 .14 ${m.color}))`};
                    display:flex;align-items:center;justify-content:center;color:white;margin-bottom:18px">
                    ${ic(m.icon, { size: 24, color: "white" })}
                  </div>
                  <div style="font-size:18px;font-weight:600;letter-spacing:-.01em">${m.label}</div>
                </button>
              `).join("")}
            </div>

            <div style="margin-top:24px;padding:20px;border-radius:18px;background:rgba(255,255,255,.7);border:1px solid rgba(255,255,255,.7)">
              <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
                <span style="font-size:13px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("cash")} · ${t("received")}</span>
                <div style="display:flex;gap:6px">
                  ${[100, 500, 1000, "พอดี"].map(v => `
                    <button class="tp-chip" style="height:30px;cursor:pointer">${typeof v === "number" ? "฿" + v : t("quick_amounts")}</button>
                  `).join("")}
                </div>
              </div>

              <div style="display:flex;align-items:baseline;justify-content:space-between;padding:14px 18px;border-radius:14px;background:white;border:1px solid var(--tp-line);margin-bottom:12px">
                <span style="font-size:14px;color:var(--tp-ink-mute)">${t("received")}</span>
                <span class="tp-tnum" style="font-size:32px;font-weight:700;color:var(--tp-ink)">฿${received}</span>
              </div>

              <div style="display:grid;grid-template-columns:repeat(3, 1fr);gap:10px">
                ${numpad.map(n => `<button class="tp-key" style="height:54px;font-size:22px">${n}</button>`).join("")}
              </div>
            </div>
          </div>

          <div style="display:flex;flex-direction:column;gap:14px">
            <div class="tp-glass" style="padding:22px 24px;flex:1">
              <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em;margin-bottom:6px">${t("total")}</div>
              <div class="tp-tnum" style="font-size:48px;font-weight:700;letter-spacing:-.03em;color:var(--tp-indigo)">฿${total}</div>
              <div style="margin-top:18px;padding-top:18px;border-top:1px dashed rgba(20,40,80,.15);display:grid;gap:8px;font-size:13px">
                <div style="display:flex;justify-content:space-between;color:var(--tp-ink-soft)">
                  <span>${t("subtotal")}</span><span class="tp-tnum">฿415</span>
                </div>
                <div style="display:flex;justify-content:space-between;color:oklch(.55 .14 70)">
                  <span>${t("discount")}</span><span class="tp-tnum">−฿30</span>
                </div>
                <div style="display:flex;justify-content:space-between;color:var(--tp-ink-soft)">
                  <span>${t("vat")}</span><span class="tp-tnum">฿27</span>
                </div>
              </div>

              <div style="margin-top:18px;padding:16px 18px;border-radius:16px;background:linear-gradient(160deg, oklch(.78 .14 145), oklch(.45 .14 150));color:white">
                <div style="font-size:11px;opacity:.85;text-transform:uppercase;letter-spacing:.1em">${t("change")}</div>
                <div class="tp-tnum" style="font-size:36px;font-weight:700;letter-spacing:-.02em">฿${change}</div>
              </div>
            </div>

            <button class="tp-btn tp-btn-ghost" data-route="cashier" style="height:54px">${ic("x", { size: 16 })} ${t("cancel")}</button>
            <button class="tp-btn tp-btn-coral" data-route="receipt" style="height:64px;font-size:17px;font-weight:600">
              ${ic("check", { size: 20, color: "white" })} ${t("confirm_pay")}
            </button>
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     RECEIPT (thermal 80mm)
     ────────────────────────────────────────────────*/
  function renderReceipt() {
    const items = [
      { n: window.I18N.lang === "th" ? "ชาไทยเย็น" : "Iced Thai Tea", q: 2, p: 65 },
      { n: window.I18N.lang === "th" ? "ชาเขียวมัทฉะ (L)" : "Matcha Latte (L)", q: 1, p: 95 },
      { n: window.I18N.lang === "th" ? "ครัวซองต์อัลมอนด์" : "Almond Croissant", q: 1, p: 55 },
      { n: window.I18N.lang === "th" ? "อเมริกาโน่ร้อน" : "Hot Americano", q: 1, p: 60 }
    ];
    const total = 415;
    const change = 85;
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">04 · ${t("receipt")}</span>
        <span class="screen-meta-size">380 × 720 · Thermal 80mm</span>
        <div style="flex:1"></div>
        <button class="tp-btn tp-btn-ghost" data-route="cashier" style="height:32px;font-size:12px">${ic("arrow_left", { size: 14 })} ${tr("กลับสู่หน้าขาย", "Back to cashier")}</button>
        <button class="tp-btn tp-btn-ghost" data-route="customer_display" style="height:32px;font-size:12px">${ic("monitor", { size: 14 })} ${tr("จอลูกค้า", "Customer display")}</button>
        <button class="tp-btn tp-btn-ghost" data-route="kds" style="height:32px;font-size:12px">${ic("fire", { size: 14 })} KDS</button>
      </div>
      <div class="screen-frame receipt">
        <div class="receipt-wrap">
          <div style="text-align:center;margin-bottom:14px">
            <div style="display:inline-block;margin-bottom:6px">${bm(48)}</div>
            <div style="font-family:var(--tp-font);font-size:16px;font-weight:600;color:var(--tp-ink)">${window.I18N.lang === "th" ? "ไทยพร้อม คาเฟ่" : "Thaiprompt Café"}</div>
            <div style="font-size:11px;margin-top:2px">${t("branch")}</div>
            <div style="font-size:11px;margin-top:2px">${t("tax_id")} 0125567891234</div>
          </div>
          <div class="receipt-divider"></div>

          <div class="receipt-line"><span>${t("receipt_no")}</span><span>A1042</span></div>
          <div class="receipt-line"><span>${t("cashier_label")}</span><span>ปริม สุข</span></div>
          <div class="receipt-line"><span>${window.I18N.lang === "th" ? "วันที่" : "Date"}</span><span>2026-05-08 14:32</span></div>
          <div class="receipt-line"><span>${window.I18N.lang === "th" ? "โต๊ะ" : "Table"}</span><span>7 / 4 ${window.I18N.lang === "th" ? "ที่" : "seats"}</span></div>
          <div class="receipt-divider"></div>

          ${items.map(it => `
            <div class="receipt-line">
              <span>${it.n}</span>
              <span>${it.q} × ฿${it.p}</span>
            </div>
            <div class="receipt-line" style="color:var(--tp-ink-mute);font-size:11px"><span>&nbsp;</span><span>฿${it.q * it.p}</span></div>
          `).join("")}

          <div class="receipt-divider"></div>
          <div class="receipt-line"><span>${t("subtotal")}</span><span>฿415</span></div>
          <div class="receipt-line"><span>${t("discount")} TP-MAY30</span><span>−฿30</span></div>
          <div class="receipt-line"><span>${t("vat")}</span><span>฿27</span></div>
          <div class="receipt-divider"></div>
          <div class="receipt-line" style="font-size:16px;font-weight:700;color:var(--tp-ink);font-family:var(--tp-font)">
            <span>${t("total")}</span><span>฿${total}</span>
          </div>
          <div class="receipt-line"><span>${t("cash")}</span><span>฿500</span></div>
          <div class="receipt-line"><span>${t("change")}</span><span>฿${change}</span></div>

          <div class="receipt-divider"></div>
          <div style="text-align:center;margin:10px 0 12px">
            ${qr(110, "var(--tp-ink)")}
            <div style="font-size:10px;margin-top:6px;color:var(--tp-ink-mute)">${t("join_member")}</div>
          </div>

          <div style="text-align:center;font-family:var(--tp-font);font-size:13px;font-weight:500;margin-bottom:6px">${t("thank_you")}</div>
          <div style="text-align:center;font-size:10px;color:var(--tp-ink-mute)">${t("receipt_simple")}</div>
        </div>
        <div class="receipt-edge"></div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     CUSTOMER DISPLAY (2nd monitor)
     ────────────────────────────────────────────────*/
  function renderCustomerDisplay() {
    const items = [
      { n: (window.I18N.lang === "th" ? "ชาไทยเย็น" : "Iced Thai Tea") + " × 2", p: 130 },
      { n: window.I18N.lang === "th" ? "ชาเขียวมัทฉะลาเต้ (L)" : "Matcha Latte (L)", p: 95 },
      { n: window.I18N.lang === "th" ? "ครัวซองต์อัลมอนด์" : "Almond Croissant", p: 55 },
      { n: window.I18N.lang === "th" ? "อเมริกาโน่ร้อน" : "Hot Americano", p: 60 }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">05 · ${t("customer_display")}</span>
        <span class="screen-meta-size">1280 × 800 · Second monitor</span>
      </div>
      <div class="screen-frame win-1280">
        <div class="screen-bg"></div>
        <div class="tp-orb" style="width:380px;height:380px;right:-100px;top:-120px;background:oklch(.85 .18 28)"></div>
        <div class="tp-orb" style="width:320px;height:320px;left:-80px;bottom:-100px;background:oklch(.78 .14 188)"></div>

        <div class="customer-wrap">
          <div style="position:absolute;top:30px;left:30px;display:flex;align-items:center;gap:14px">
            ${bm(48)}
            <div>
              <div style="font-size:18px;font-weight:600;letter-spacing:-.01em">${window.I18N.lang === "th" ? "ไทยพร้อม คาเฟ่" : "Thaiprompt Café"}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${t("branch")} · ${t("welcome_customer")}</div>
            </div>
          </div>
          <div style="position:absolute;top:30px;right:30px;display:flex;gap:10px">
            <span class="tp-chip"><span class="tp-dot"></span> ${t("branch_open")}</span>
            <span class="tp-chip tp-mono">14:42 · 8 ${window.I18N.lang === "th" ? "พ.ค." : "May"}</span>
          </div>

          <div class="customer-grid">
            <div style="border-radius:32px;position:relative;overflow:hidden;
              background:linear-gradient(160deg, oklch(.78 .14 188) 0%, oklch(.40 .15 280) 100%);
              box-shadow:0 1px 0 rgba(255,255,255,.3) inset, 0 30px 60px -30px rgba(20,40,80,.4)">
              <div style="position:absolute;width:260px;height:260px;right:-40px;bottom:-40px;border-radius:50%;
                background:linear-gradient(135deg, rgba(255,255,255,.30), rgba(255,255,255,.06));backdrop-filter:blur(20px);border:1px solid rgba(255,255,255,.3)"></div>
              <div style="position:absolute;width:130px;height:130px;right:220px;bottom:80px;border-radius:50%;background:oklch(.85 .18 28 / .6);filter:blur(8px)"></div>
              <div style="position:absolute;width:90px;height:90px;right:160px;bottom:280px;border-radius:50%;
                background:linear-gradient(135deg, oklch(.95 .14 80 / .8), oklch(.78 .14 80 / .5));backdrop-filter:blur(8px);border:1px solid rgba(255,255,255,.4)"></div>

              <div style="position:relative;padding:50px;color:white;height:100%;display:flex;flex-direction:column">
                <span style="align-self:flex-start;padding:6px 14px;border-radius:999px;
                  background:rgba(255,255,255,.2);border:1px solid rgba(255,255,255,.35);
                  font-size:12px;font-weight:600;letter-spacing:.05em;backdrop-filter:blur(10px)">${t("promo_title")}</span>
                <div style="flex:1"></div>
                <div style="font-size:64px;font-weight:700;line-height:1;letter-spacing:-.03em">
                  ${t("promo_buy_2")}<br/>
                  <span style="background:linear-gradient(180deg, oklch(.95 .14 80), oklch(.78 .14 80));-webkit-background-clip:text;-webkit-text-fill-color:transparent">${t("promo_save_30")}</span>
                </div>
                <div style="font-size:18px;opacity:.9;margin-top:14px;max-width:480px;line-height:1.45">
                  ${t("promo_desc")} <span class="tp-mono" style="background:rgba(255,255,255,.22);padding:2px 8px;border-radius:6px">TP-MAY30</span>
                </div>
                <div style="display:flex;gap:6px;margin-top:30px">
                  <div style="width:36px;height:5px;border-radius:999px;background:white"></div>
                  <div style="width:12px;height:5px;border-radius:999px;background:rgba(255,255,255,.4)"></div>
                  <div style="width:12px;height:5px;border-radius:999px;background:rgba(255,255,255,.4)"></div>
                  <div style="width:12px;height:5px;border-radius:999px;background:rgba(255,255,255,.4)"></div>
                </div>
              </div>
            </div>

            <div class="tp-glass" style="padding:26px 28px;display:flex;flex-direction:column">
              <div style="display:flex;align-items:center;margin-bottom:14px">
                <div>
                  <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("current_order")}</div>
                  <div style="font-size:22px;font-weight:600;margin-top:2px">${t("order_no", { no: "A1042" })} · ${t("table_n", { n: 7, seats: 4 })}</div>
                </div>
                <div style="flex:1"></div>
                <div class="tp-chip tp-chip-success">${t("preparing")}</div>
              </div>

              <div style="flex:1;overflow:auto;margin:8px -8px">
                ${items.map((it, i) => `
                  <div style="display:flex;align-items:center;padding:12px 8px;border-bottom:1px dashed rgba(20,40,80,.1)">
                    <div style="width:38px;height:38px;border-radius:12px;
                      background:linear-gradient(160deg, oklch(.92 .08 ${20 + i * 50}), oklch(.78 .12 ${20 + i * 50}));
                      border:1px solid rgba(255,255,255,.7);display:flex;align-items:center;justify-content:center;
                      color:white;font-size:13px;font-weight:600;box-shadow:0 4px 10px -3px rgba(20,40,80,.18)">${i + 1}</div>
                    <div style="flex:1;margin-left:14px;font-size:16px;font-weight:500">${it.n}</div>
                    <div class="tp-tnum" style="font-size:17px;font-weight:600">฿${it.p}</div>
                  </div>
                `).join("")}
              </div>

              <div style="margin-top:14px;padding-top:14px;border-top:1px solid rgba(20,40,80,.1)">
                <div style="display:flex;justify-content:space-between;color:var(--tp-ink-soft);font-size:13px;margin-bottom:4px">
                  <span>${t("subtotal")}</span><span class="tp-tnum">฿415</span>
                </div>
                <div style="display:flex;justify-content:space-between;color:oklch(.55 .14 70);font-size:13px;margin-bottom:4px">
                  <span>${t("coupon", { code: "TP-MAY30" })}</span><span class="tp-tnum">−฿30</span>
                </div>
                <div style="display:flex;justify-content:space-between;align-items:baseline;margin-top:10px">
                  <span style="font-size:14px;color:var(--tp-ink-soft)">${t("total")}</span>
                  <span class="tp-tnum" style="font-size:48px;font-weight:700;letter-spacing:-.02em;color:var(--tp-indigo)">฿415</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     KITCHEN DISPLAY
     ────────────────────────────────────────────────*/
  function renderKDS() {
    const tickets = [
      { table: 5, time: "2", color: "green", items: [
        { n: window.I18N.lang === "th" ? "ผัดไทยกุ้งสด" : "Pad Thai Shrimp", q: 1, note: window.I18N.lang === "th" ? "ไม่ใส่ถั่ว" : "No peanuts" },
        { n: window.I18N.lang === "th" ? "ต้มยำกุ้ง" : "Tom Yum Goong", q: 1 }
      ]},
      { table: 7, time: "4", color: "green", items: [
        { n: window.I18N.lang === "th" ? "ข้าวกะเพราหมูสับ" : "Krapao Pork", q: 2, note: window.I18N.lang === "th" ? "เผ็ดมาก ไข่ดาว" : "Extra spicy, fried egg" },
        { n: window.I18N.lang === "th" ? "ชาไทยเย็น" : "Iced Thai Tea", q: 2 }
      ]},
      { table: 12, time: "7", color: "yellow", items: [
        { n: window.I18N.lang === "th" ? "สเต็กปลาแซลมอน" : "Salmon Steak", q: 1, note: window.I18N.lang === "th" ? "Medium" : "Medium" },
        { n: window.I18N.lang === "th" ? "ซุปเห็ดทรัฟเฟิล" : "Truffle Mushroom Soup", q: 2 }
      ]},
      { table: 3, time: "11", color: "red", items: [
        { n: window.I18N.lang === "th" ? "ส้มตำไทย" : "Som Tum Thai", q: 1, note: window.I18N.lang === "th" ? "เผ็ดน้อย" : "Mild" },
        { n: window.I18N.lang === "th" ? "ไก่ย่าง" : "Grilled Chicken", q: 1 },
        { n: window.I18N.lang === "th" ? "ข้าวเหนียว" : "Sticky rice", q: 2 }
      ]},
      { table: 8, time: "1", color: "green", items: [
        { n: window.I18N.lang === "th" ? "ลาเต้ร้อน" : "Hot Latte", q: 2 },
        { n: window.I18N.lang === "th" ? "ครัวซองต์" : "Croissant", q: 1 }
      ]}
    ];

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">06 · ${t("kds")}</span>
        <span class="screen-meta-size">1440 × 900 · Kitchen</span>
      </div>
      <div class="screen-frame kds">
        <div class="screen-bg"></div>
        <div class="kds-wrap">
          <div style="display:flex;align-items:center;gap:14px">
            ${bm(48)}
            <div>
              <div style="font-size:22px;font-weight:600;letter-spacing:-.01em">${t("kds_title")}</div>
              <div style="font-size:13px;color:var(--tp-ink-mute)">${t("branch")} · 14:42</div>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;gap:8px">
              <span class="tp-chip tp-chip-active">${t("station_all")}</span>
              <span class="tp-chip">${ic("fire", { size: 13 })} ${t("station_hot")}</span>
              <span class="tp-chip">${ic("leaf", { size: 13 })} ${t("station_cold")}</span>
              <span class="tp-chip">${ic("coffee", { size: 13 })} ${t("station_drink")}</span>
              <span class="tp-chip">${ic("star", { size: 13 })} ${t("station_dessert")}</span>
            </div>
            <div style="width:1px;height:32px;background:var(--tp-line)"></div>
            <button class="tp-btn tp-btn-ghost" style="height:40px;padding:0 14px">${ic("bell", { size: 16 })} ${t("sound_alert")}</button>
          </div>

          <div class="kds-grid">
            ${tickets.map(t1 => `
              <div class="kds-ticket ${t1.color}">
                <div class="kds-ticket-header">
                  <span>${t("table_label", { n: t1.table })}</span>
                  <span class="tp-mono">${t("elapsed_min", { m: t1.time })}</span>
                </div>
                <div style="padding:12px 14px;flex:1">
                  ${t1.items.map(it => `
                    <div style="padding:6px 0;border-bottom:1px dashed rgba(20,40,80,.08)">
                      <div style="display:flex;justify-content:space-between;align-items:baseline">
                        <span style="font-size:14px;font-weight:500">${it.n}</span>
                        <span class="tp-tnum" style="font-size:13px;font-weight:600;color:var(--tp-ink-mute)">×${it.q}</span>
                      </div>
                      ${it.note ? `<div style="font-size:11px;color:var(--tp-coral-deep);margin-top:2px;font-style:italic">${it.note}</div>` : ""}
                    </div>
                  `).join("")}
                </div>
                <div style="padding:10px 12px;display:flex;gap:8px">
                  <button class="tp-btn tp-btn-ghost" data-route="cashier" style="flex:1;height:36px;font-size:12px">${t("start_cooking")}</button>
                  <button class="tp-btn tp-btn-primary" data-route="customer_display" style="flex:1;height:36px;font-size:12px">${ic("check", { size: 14, color: "white" })} ${t("mark_ready")}</button>
                </div>
              </div>
            `).join("")}
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     DASHBOARD
     ────────────────────────────────────────────────*/
  function renderDashboard() {
    const kpis = [
      { l: t("sales_today"), v: "฿42,580", d: "+12.4%", up: true, hue: "188" },
      { l: t("orders"),      v: "248",     d: "+8.1%",  up: true, hue: "270" },
      { l: t("new_customers"), v: "32",   d: "+22%",   up: true, hue: "80" },
      { l: t("avg_basket"),  v: "฿172",    d: "−3.2%",  up: false, hue: "25" }
    ];
    const top = [
      { n: window.I18N.lang === "th" ? "ชาไทยเย็น" : "Iced Thai Tea", c: 86, hue: 25 },
      { n: window.I18N.lang === "th" ? "ลาเต้ร้อน" : "Hot Latte", c: 72, hue: 50 },
      { n: window.I18N.lang === "th" ? "มัทฉะลาเต้" : "Matcha Latte", c: 64, hue: 145 },
      { n: window.I18N.lang === "th" ? "อเมริกาโน่" : "Americano", c: 58, hue: 35 },
      { n: window.I18N.lang === "th" ? "โกโก้ปั่น" : "Choco Frappe", c: 47, hue: 28 }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">07 · ${t("dashboard")}</span>
        <span class="screen-meta-size">1440 × 900 · Back office</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>
        <div style="position:absolute;inset:24px">
          <div style="display:flex;align-items:center;margin-bottom:18px">
            <div>
              <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("dashboard_title")}</div>
              <h1 style="margin:4px 0 0;font-size:28px;font-weight:700;letter-spacing:-.02em">${t("branch")}</h1>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;gap:8px">
              <span class="tp-chip tp-chip-active">${t("range_today")}</span>
              <span class="tp-chip">${t("range_7d")}</span>
              <span class="tp-chip">${t("range_month")}</span>
              <span class="tp-chip">${t("range_custom")}</span>
            </div>
            <div style="width:1px;height:30px;background:var(--tp-line);margin:0 8px"></div>
            <button class="tp-btn tp-btn-ghost" data-route="accounting" style="height:34px;font-size:12px">${ic("chart", { size: 14 })} ${tr("บัญชี", "Accounting")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="staff" style="height:34px;font-size:12px">${ic("users", { size: 14 })} ${t("staff")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="coupons" style="height:34px;font-size:12px">${ic("tag", { size: 14 })} ${tr("คูปอง", "Coupons")}</button>
            <span class="sync-banner" data-route="sync_api" style="cursor:pointer">${ic("cloud", { size: 14 })} ${t("online")}</span>
          </div>

          <div class="kpi-grid">
            ${kpis.map(k => `
              <div class="kpi-card">
                <div style="display:flex;align-items:flex-start">
                  <div>
                    <div class="kpi-label">${k.l}</div>
                    <div class="kpi-value tp-tnum">${k.v}</div>
                    <div class="kpi-delta" style="color:${k.up ? "var(--tp-success)" : "var(--tp-coral-deep)"}">
                      ${ic(k.up ? "arrow_up" : "arrow_down", { size: 12, color: k.up ? "var(--tp-success)" : "var(--tp-coral-deep)" })}
                      ${k.d} ${t("vs_yesterday")}
                    </div>
                  </div>
                  <div style="flex:1"></div>
                  <svg width="80" height="36" viewBox="0 0 80 36">
                    <path d="M0 30 L15 24 L30 26 L45 18 L60 12 L80 8" fill="none" stroke="oklch(.55 .14 ${k.hue})" stroke-width="2" stroke-linecap="round"/>
                    <path d="M0 30 L15 24 L30 26 L45 18 L60 12 L80 8 L80 36 L0 36 Z" fill="oklch(.85 .12 ${k.hue})" opacity=".25"/>
                  </svg>
                </div>
              </div>
            `).join("")}
          </div>

          <div style="display:grid;grid-template-columns:1.6fr 1fr;gap:18px;height:calc(100% - 220px)">
            <div class="tp-glass" style="padding:22px 26px;overflow:hidden">
              <div style="display:flex;align-items:center;margin-bottom:14px">
                <h3 style="margin:0;font-size:18px;font-weight:600">${t("sales_chart_title")}</h3>
                <div style="flex:1"></div>
                <span class="tp-chip">${t("range_today")}</span>
              </div>
              <svg viewBox="0 0 800 280" style="width:100%;height:calc(100% - 40px)">
                <defs>
                  <linearGradient id="d-fill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="oklch(.72 .13 190)" stop-opacity="0.6"/>
                    <stop offset="100%" stop-color="oklch(.72 .13 190)" stop-opacity="0"/>
                  </linearGradient>
                  <linearGradient id="d-fill-c" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="oklch(.72 .18 25)" stop-opacity="0.4"/>
                    <stop offset="100%" stop-color="oklch(.72 .18 25)" stop-opacity="0"/>
                  </linearGradient>
                </defs>
                <g stroke="rgba(20,40,80,0.06)">
                  ${[0, 70, 140, 210, 280].map(y => `<line x1="40" x2="800" y1="${y}" y2="${y}"/>`).join("")}
                </g>
                <path d="M40,200 L150,160 L260,180 L370,120 L480,100 L590,80 L800,60 L800,280 L40,280 Z" fill="url(#d-fill)"/>
                <path d="M40,200 L150,160 L260,180 L370,120 L480,100 L590,80 L800,60" fill="none" stroke="oklch(.55 .13 195)" stroke-width="3" stroke-linecap="round"/>
                <path d="M40,230 L150,220 L260,200 L370,180 L480,160 L590,140 L800,120 L800,280 L40,280 Z" fill="url(#d-fill-c)"/>
                <path d="M40,230 L150,220 L260,200 L370,180 L480,160 L590,140 L800,120" fill="none" stroke="oklch(.60 .18 25)" stroke-width="2.5" stroke-dasharray="4 4" stroke-linecap="round"/>
                ${[40, 150, 260, 370, 480, 590, 800].map((x, i) => `
                  <text x="${x}" y="270" font-size="11" fill="oklch(.62 .015 250)" text-anchor="middle" font-family="var(--tp-font)">
                    ${["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][i]}
                  </text>
                `).join("")}
              </svg>
            </div>

            <div class="tp-glass" style="padding:22px 24px;overflow:hidden">
              <div style="display:flex;align-items:center;margin-bottom:14px">
                <h3 style="margin:0;font-size:18px;font-weight:600">${t("top_items")}</h3>
                <div style="flex:1"></div>
                <button class="tp-btn tp-btn-ghost" data-route="inventory" style="height:28px;padding:0 10px;font-size:11px">${ic("box", { size: 12 })} ${t("inventory")}</button>
              </div>
              ${top.map(it => `
                <div data-route="inventory" style="display:flex;align-items:center;gap:12px;padding:8px 0;border-bottom:1px dashed rgba(20,40,80,.08);cursor:pointer">
                  <div style="width:38px;height:38px;border-radius:12px;overflow:hidden">${pi({ hue: it.hue, kind: "rect" })}</div>
                  <div style="flex:1">
                    <div style="font-size:13px;font-weight:500">${it.n}</div>
                    <div style="height:6px;background:rgba(20,40,80,.06);border-radius:999px;margin-top:6px;overflow:hidden">
                      <div style="height:100%;width:${(it.c / 86) * 100}%;background:linear-gradient(90deg, oklch(.72 .13 ${it.hue}), oklch(.55 .13 ${it.hue}));border-radius:999px"></div>
                    </div>
                  </div>
                  <div class="tp-tnum" style="font-size:14px;font-weight:600">${it.c}</div>
                </div>
              `).join("")}
            </div>
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     INVENTORY
     ────────────────────────────────────────────────*/
  function renderInventory() {
    const rows = [
      { sku: "TT-01", name: window.I18N.lang === "th" ? "ชาไทยเย็น (ผงชา)" : "Thai Tea Mix", cat: t("cat_hot"), stock: 3, min: 5, cost: 220, price: 65, status: "low", hue: 25 },
      { sku: "MT-02", name: window.I18N.lang === "th" ? "ผงมัทฉะ" : "Matcha Powder", cat: t("cat_hot"), stock: 12, min: 4, cost: 850, price: 85, status: "ok", hue: 145 },
      { sku: "AM-03", name: window.I18N.lang === "th" ? "เมล็ดกาแฟ Arabica" : "Arabica Beans", cat: t("cat_coffee"), stock: 0, min: 3, cost: 1200, price: 70, status: "out", hue: 35 },
      { sku: "CC-05", name: window.I18N.lang === "th" ? "ผงโกโก้" : "Cocoa Powder", cat: t("cat_hot"), stock: 7, min: 4, cost: 320, price: 80, status: "ok", hue: 28 },
      { sku: "CR-12", name: window.I18N.lang === "th" ? "ครัวซองต์อัลมอนด์" : "Almond Croissant", cat: t("cat_bakery"), stock: 2, min: 6, cost: 22, price: 55, status: "low", hue: 35 },
      { sku: "ML-08", name: window.I18N.lang === "th" ? "นมสด" : "Fresh Milk 1L", cat: t("cat_coffee"), stock: 18, min: 8, cost: 65, price: 0, status: "ok", hue: 70 },
      { sku: "BT-09", name: window.I18N.lang === "th" ? "ใบชาดำ" : "Black Tea Leaves", cat: t("cat_hot"), stock: 1, min: 4, cost: 480, price: 50, status: "low", hue: 30 },
      { sku: "SB-11", name: window.I18N.lang === "th" ? "สตรอเบอร์รี่แช่แข็ง" : "Frozen Strawberry", cat: t("cat_cold"), stock: 14, min: 5, cost: 280, price: 90, status: "ok", hue: 18 }
    ];
    function statusChip(s) {
      const map = {
        ok:  { l: t("inv_status_ok"),  bg: "linear-gradient(180deg, oklch(.92 .10 145), oklch(.85 .14 145))", c: "oklch(.32 .12 150)", b: "oklch(.85 .10 145)" },
        low: { l: t("inv_status_low"), bg: "linear-gradient(180deg, oklch(.95 .12 80),  oklch(.85 .14 75))",  c: "oklch(.40 .14 70)",  b: "oklch(.85 .10 75)" },
        out: { l: t("inv_status_out"), bg: "linear-gradient(180deg, oklch(.92 .10 25),  oklch(.78 .16 25))",  c: "oklch(.40 .18 25)",  b: "oklch(.85 .14 25)" }
      }[s];
      return `<span class="tp-chip" style="background:${map.bg};color:${map.c};border-color:${map.b}">${map.l}</span>`;
    }
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">08 · ${t("inventory")}</span>
        <span class="screen-meta-size">1440 × 900 · Back office</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>
        <div style="position:absolute;inset:24px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:18px">
            <div>
              <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("inventory_title")}</div>
              <h1 style="margin:4px 0 0;font-size:28px;font-weight:700;letter-spacing:-.02em">${t("branch")}</h1>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;gap:8px">
              <button class="tp-btn tp-btn-ghost" data-route="admin">${ic("upload", { size: 16 })} ${t("import_csv")}</button>
              <button class="tp-btn tp-btn-ghost" data-route="barcode">${ic("printer", { size: 16 })} ${t("print_barcode")}</button>
              <button class="tp-btn tp-btn-ghost" data-route="stock_mgmt">${ic("layers", { size: 16 })} ${tr("เคลื่อนไหว", "Movements")}</button>
              <button class="tp-btn tp-btn-primary" data-route="barcode">${ic("plus", { size: 16, color: "white" })} ${t("add_product")}</button>
            </div>
          </div>

          <div style="display:flex;gap:8px;margin-bottom:14px">
            <div class="cashier-search" style="flex:0 0 320px">
              ${ic("search", { size: 18, color: "var(--tp-ink-soft)" })}
              <input placeholder="${window.I18N.lang === "th" ? "ค้นหา SKU / ชื่อ" : "Search SKU / name"}"/>
            </div>
            <span class="tp-chip tp-chip-active">${t("all")}</span>
            <span class="tp-chip">${t("cat_hot")}</span>
            <span class="tp-chip">${t("cat_cold")}</span>
            <span class="tp-chip">${t("cat_coffee")}</span>
            <span class="tp-chip">${t("cat_bakery")}</span>
            <span class="tp-chip">${t("inv_status_low")}</span>
            <div style="flex:1"></div>
            <span class="sync-banner">${ic("refresh", { size: 14 })} ${window.I18N.lang === "th" ? "ซิงก์ล่าสุด 14:31" : "Synced 14:31"}</span>
          </div>

          <div class="tp-glass" style="flex:1;overflow:auto;padding:8px 12px">
            <table class="inv-table">
              <thead>
                <tr>
                  <th>${t("inv_sku")}</th>
                  <th>${t("inv_image")}</th>
                  <th>${t("inv_name")}</th>
                  <th>${t("inv_cat")}</th>
                  <th style="text-align:right">${t("inv_stock")}</th>
                  <th style="text-align:right">${t("inv_min")}</th>
                  <th style="text-align:right">${t("inv_cost")}</th>
                  <th style="text-align:right">${t("inv_price")}</th>
                  <th>${t("inv_status")}</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                ${rows.map(r => `
                  <tr>
                    <td class="tp-mono" style="font-size:13px;color:var(--tp-ink-mute)">${r.sku}</td>
                    <td><div style="width:42px;height:42px;border-radius:10px;overflow:hidden">${pi({ hue: r.hue, kind: "rect" })}</div></td>
                    <td style="font-weight:500">${r.name}</td>
                    <td><span class="tp-chip">${r.cat}</span></td>
                    <td class="tp-tnum" style="text-align:right;font-weight:600;color:${r.status === "out" ? "var(--tp-coral-deep)" : r.status === "low" ? "oklch(.50 .14 70)" : "var(--tp-ink)"}">${r.stock}</td>
                    <td class="tp-tnum" style="text-align:right;color:var(--tp-ink-mute)">${r.min}</td>
                    <td class="tp-tnum" style="text-align:right">฿${r.cost}</td>
                    <td class="tp-tnum" style="text-align:right;font-weight:600">${r.price ? "฿" + r.price : "—"}</td>
                    <td>${statusChip(r.status)}</td>
                    <td>
                      <button class="tp-btn tp-btn-ghost tp-btn-icon" style="width:32px;height:32px">${ic("more", { size: 16 })}</button>
                    </td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     iPad floor plan
     ────────────────────────────────────────────────*/
  function renderTablet() {
    const tables = [
      { n: 1, status: "empty", seats: 2 },
      { n: 2, status: "occupied", seats: 4, time: "32 min", total: 580 },
      { n: 3, status: "waiting", seats: 4, time: "1h 12 min", total: 1240 },
      { n: 4, status: "empty", seats: 2 },
      { n: 5, status: "occupied", seats: 6, time: "18 min", total: 920 },
      { n: 6, status: "reserved", seats: 4, name: "K.Niran 19:00" },
      { n: 7, status: "occupied", seats: 4, time: "24 min", total: 415 },
      { n: 8, status: "empty", seats: 2 },
      { n: 9, status: "reserved", seats: 8, name: "K.Som · 19:30" },
      { n: 10, status: "occupied", seats: 2, time: "8 min", total: 180 },
      { n: 11, status: "empty", seats: 4 },
      { n: 12, status: "waiting", seats: 4, time: "55 min", total: 1100 }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">09 · ${t("tablet")}</span>
        <span class="screen-meta-size">1024 × 768 · iPad landscape</span>
      </div>
      <div class="screen-frame tablet">
        <div class="screen-bg"></div>
        <div style="position:absolute;inset:24px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;gap:14px;margin-bottom:18px">
            ${bm(40)}
            <div>
              <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${t("floor_title")}</div>
              <h1 style="margin:2px 0 0;font-size:22px;font-weight:600;letter-spacing:-.01em">${t("branch")}</h1>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;gap:8px;align-items:center">
              <span class="tp-chip"><span class="tp-dot"></span> 9 ${window.I18N.lang === "th" ? "นั่ง" : "seated"}</span>
              <span class="tp-chip"><span class="tp-dot" style="background:oklch(.78 .14 75);box-shadow:0 0 0 3px oklch(.78 .14 75 / .25)"></span> 2 ${window.I18N.lang === "th" ? "รอจ่าย" : "waiting"}</span>
              <span class="tp-chip"><span class="tp-dot" style="background:oklch(.55 .14 280);box-shadow:0 0 0 3px oklch(.55 .14 280 / .25)"></span> 2 ${window.I18N.lang === "th" ? "จองไว้" : "reserved"}</span>
            </div>
          </div>

          <div class="floor-grid" style="flex:1">
            ${tables.map(tt => {
              const stKey = `table_status_${tt.status}`;
              return `
                <div class="table-tile ${tt.status}">
                  <div style="display:flex;justify-content:space-between;align-items:flex-start">
                    <div style="font-size:36px;font-weight:700;letter-spacing:-.03em">${tt.n}</div>
                    <span style="font-size:11px;font-weight:600;padding:3px 8px;border-radius:999px;background:rgba(255,255,255,.5);">${t(stKey)}</span>
                  </div>
                  <div style="font-size:12px;margin-top:6px;opacity:.85">${tt.seats} ${window.I18N.lang === "th" ? "ที่นั่ง" : "seats"}</div>
                  ${tt.time ? `<div style="margin-top:auto;display:flex;justify-content:space-between;align-items:baseline">
                    <span style="font-size:11px;opacity:.85">${tt.time}</span>
                    <span class="tp-tnum" style="font-size:18px;font-weight:700">฿${tt.total}</span>
                  </div>` : ""}
                  ${tt.name ? `<div style="margin-top:auto;font-size:12px;font-weight:500">${tt.name}</div>` : ""}
                  ${!tt.time && !tt.name ? `<div style="margin-top:auto;font-size:11px;opacity:.85">${window.I18N.lang === "th" ? "พร้อมรับลูกค้า" : "Ready for guests"}</div>` : ""}
                </div>
              `;
            }).join("")}
          </div>

          <div style="margin-top:18px;display:flex;gap:10px;justify-content:center">
            <button class="tp-btn tp-btn-primary" data-route="cashier" style="flex:0 0 240px;height:48px">${ic("plus", { size: 16, color: "white" })} ${t("new_order")}</button>
            <button class="tp-btn tp-btn-ghost" style="flex:0 0 200px;height:48px">${ic("split", { size: 16 })} ${t("move_table")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="create_bill" style="flex:0 0 200px;height:48px">${ic("layers", { size: 16 })} ${t("merge_bill")}</button>
          </div>
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     MOBILE — Order at table
     ────────────────────────────────────────────────*/
  function renderMobileOrder() {
    const items = [
      { n: window.I18N.lang === "th" ? "ผัดไทยกุ้งสด" : "Pad Thai Shrimp", desc: window.I18N.lang === "th" ? "เส้นจันท์ผัดเข้มข้น" : "Classic with peanuts", price: 120, hue: 30 },
      { n: window.I18N.lang === "th" ? "ต้มยำกุ้ง" : "Tom Yum Goong", desc: window.I18N.lang === "th" ? "ซุปต้มยำหอมเครื่อง" : "Spicy & sour soup", price: 180, hue: 25 },
      { n: window.I18N.lang === "th" ? "กะเพราหมูสับ" : "Krapao Pork", desc: window.I18N.lang === "th" ? "ราดข้าวไข่ดาว" : "With fried egg", price: 95, hue: 80 },
      { n: window.I18N.lang === "th" ? "ส้มตำไทย" : "Som Tum Thai", desc: window.I18N.lang === "th" ? "เผ็ดเด็ดถูกใจ" : "Spicy papaya salad", price: 80, hue: 145 }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">10 · ${t("mobile_order")}</span>
        <span class="screen-meta-size">390 × 844 · iOS / Android</span>
      </div>
      <div class="screen-frame mobile">
        <div class="screen-bg" style="border-radius:44px"></div>
        <div class="notch"></div>
        <div class="mobile-status">
          <span class="tp-mono">14:42</span>
          <div style="display:flex;gap:6px;align-items:center">${ic("wifi", { size: 14 })}
            <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" stroke-width="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/><rect x="19" y="4" width="2" height="3" rx="1" fill="currentColor"/></svg>
          </div>
        </div>

        <div style="position:absolute;inset:50px 18px 84px;overflow:auto">
          <div style="padding:12px 4px 14px;display:flex;align-items:center;gap:10px">
            ${bm(34)}
            <div style="flex:1">
              <div style="font-size:11px;color:var(--tp-ink-mute)">${t("table_n", { n: 7, seats: 4 })}</div>
              <div style="font-size:17px;font-weight:600">${window.I18N.lang === "th" ? "ไทยพร้อม คาเฟ่" : "Thaiprompt Café"}</div>
            </div>
            <button class="tp-btn tp-btn-ghost tp-btn-icon" style="width:38px;height:38px">${ic("search", { size: 16 })}</button>
          </div>

          <div style="display:flex;gap:8px;overflow:auto;padding:4px 0 14px;margin:0 -4px">
            ${[t("all"), t("bestseller"), t("cat_hot"), t("cat_cold"), t("cat_coffee"), t("cat_bakery")].map((l, i) => `
              <span class="tp-chip ${i === 0 ? "tp-chip-active" : ""}" style="flex-shrink:0">${l}</span>
            `).join("")}
          </div>

          <div style="display:flex;flex-direction:column;gap:10px">
            ${items.map(it => `
              <div class="tp-prod" style="display:flex;height:100px;padding:8px">
                <div style="width:84px;height:84px;border-radius:14px;overflow:hidden;flex-shrink:0">${pi({ hue: it.hue, kind: "rect" })}</div>
                <div style="flex:1;padding:4px 12px;display:flex;flex-direction:column">
                  <div style="font-size:14px;font-weight:600">${it.n}</div>
                  <div style="font-size:11px;color:var(--tp-ink-mute);margin-top:2px;line-height:1.35">${it.desc}</div>
                  <div style="margin-top:auto;display:flex;justify-content:space-between;align-items:center">
                    <span class="tp-tnum" style="font-size:16px;font-weight:600;color:var(--tp-teal-deep)">฿${it.price}</span>
                    <button class="tp-btn tp-btn-primary" style="width:30px;height:30px;padding:0;border-radius:10px">${ic("plus", { size: 14, color: "white" })}</button>
                  </div>
                </div>
              </div>
            `).join("")}
          </div>
        </div>

        <div style="position:absolute;left:14px;right:14px;bottom:96px">
          <button class="tp-btn tp-btn-coral" data-route="payment" style="width:100%;height:54px;font-size:15px;font-weight:600;border-radius:18px">
            ${ic("cart", { size: 18, color: "white" })} ${t("cart_summary", { n: 4, total: 580 })}
          </button>
        </div>

        <div class="mobile-tabbar">
          ${[
            { i: "home", l: t("home_tab"), on: true, route: "mobile_order" },
            { i: "grid", l: window.I18N.lang === "th" ? "เมนู" : "Menu", route: "cashier" },
            { i: "qr", l: window.I18N.lang === "th" ? "สแกน" : "Scan", route: "barcode" },
            { i: "user", l: window.I18N.lang === "th" ? "บัญชี" : "Profile", route: "mobile_mgr" }
          ].map(x => `
            <button class="tab-item ${x.on ? "active" : ""}" data-route="${x.route}">
              ${ic(x.i, { size: 22, color: x.on ? "var(--tp-teal-deep)" : "var(--tp-ink-mute)" })}
              <span>${x.l}</span>
            </button>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     MOBILE — Manager
     ────────────────────────────────────────────────*/
  function renderMobileManager() {
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">11 · ${t("mobile_mgr")}</span>
        <span class="screen-meta-size">390 × 844 · iOS / Android</span>
      </div>
      <div class="screen-frame mobile">
        <div class="screen-bg" style="border-radius:44px"></div>
        <div class="notch"></div>
        <div class="mobile-status">
          <span class="tp-mono">14:42</span>
          <div style="display:flex;gap:6px;align-items:center">${ic("wifi", { size: 14 })}
            <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" stroke-width="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/><rect x="19" y="4" width="2" height="3" rx="1" fill="currentColor"/></svg>
          </div>
        </div>

        <div style="position:absolute;inset:50px 0 84px;padding:10px 18px;overflow:auto">
          <div style="display:flex;align-items:center;gap:12px;padding:6px 4px 18px">
            <div style="width:44px;height:44px;border-radius:50%;
              background:linear-gradient(135deg, oklch(.82 .14 80), oklch(.65 .14 50));
              color:white;display:flex;align-items:center;justify-content:center;font-size:16px;font-weight:600;
              box-shadow:0 6px 14px -4px rgba(20,40,80,.3)">ป</div>
            <div style="flex:1">
              <div style="font-size:12px;color:var(--tp-ink-mute)">${t("greeting_mgr")}</div>
              <div style="font-size:16px;font-weight:600">ปริม สุข</div>
            </div>
            <button class="tp-btn tp-btn-ghost tp-btn-icon" style="width:40px;height:40px;position:relative">
              ${ic("bell", { size: 18 })}
              <span style="position:absolute;top:6px;right:6px;width:8px;height:8px;border-radius:50%;background:oklch(.65 .18 25);box-shadow:0 0 0 2px white"></span>
            </button>
          </div>

          <div style="padding:20px 22px;border-radius:26px;
            background:linear-gradient(160deg, oklch(.40 .14 250) 0%, oklch(.20 .08 270) 100%);
            color:white;position:relative;overflow:hidden;
            box-shadow:0 1px 0 rgba(255,255,255,.15) inset, 0 20px 40px -20px oklch(.25 .08 270 / .6)">
            <div style="position:absolute;width:180px;height:180px;right:-50px;top:-50px;border-radius:50%;
              background:linear-gradient(135deg, oklch(.78 .14 188 / .6), transparent)"></div>
            <div style="position:absolute;width:110px;height:110px;right:30px;bottom:-40px;border-radius:50%;background:oklch(.78 .18 28 / .35);filter:blur(20px)"></div>

            <div style="position:relative">
              <div style="font-size:11px;opacity:.8;letter-spacing:.1em;text-transform:uppercase">${t("sales_today")}</div>
              <div class="tp-tnum" style="font-size:38px;font-weight:600;letter-spacing:-.02em;margin-top:4px">฿42,580</div>
              <div style="display:flex;align-items:center;gap:6px;margin-top:4px;font-size:12px">
                <span style="display:inline-flex;align-items:center;gap:3px;padding:2px 8px;border-radius:999px;
                  background:oklch(.78 .14 145 / .35);border:1px solid oklch(.78 .14 145 / .5)">
                  ${ic("arrow_up", { size: 12, color: "white" })} 12.4%
                </span>
                <span style="opacity:.85">${t("vs_yesterday")}</span>
              </div>

              <svg viewBox="0 0 200 50" style="width:100%;height:50px;margin-top:14px">
                <defs>
                  <linearGradient id="m-fill-${Math.random().toString(36).slice(2)}" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="oklch(.85 .14 80)" stop-opacity=".6"/>
                    <stop offset="100%" stop-color="oklch(.85 .14 80)" stop-opacity="0"/>
                  </linearGradient>
                </defs>
                <path d="M0,40 L15,30 L30,35 L45,22 L60,28 L75,18 L90,15 L105,22 L120,12 L135,16 L150,8 L165,14 L180,5 L200,10 L200,50 L0,50 Z" fill="oklch(.85 .14 80 / .35)"/>
                <path d="M0,40 L15,30 L30,35 L45,22 L60,28 L75,18 L90,15 L105,22 L120,12 L135,16 L150,8 L165,14 L180,5 L200,10" fill="none" stroke="oklch(.85 .14 80)" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </div>
          </div>

          <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:14px">
            ${[
              { l: t("orders"), v: "248", c: "188", icon: "receipt" },
              { l: t("new_customers"), v: "32", c: "80", icon: "users" }
            ].map(k => `
              <div class="tp-glass" style="padding:14px 16px;border-radius:18px">
                <div style="display:flex;align-items:center;gap:8px">
                  <div style="width:30px;height:30px;border-radius:9px;background:linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}));color:white;display:flex;align-items:center;justify-content:center">${ic(k.icon, { size: 16, color: "white" })}</div>
                  <span style="font-size:12px;color:var(--tp-ink-mute)">${k.l}</span>
                </div>
                <div class="tp-tnum" style="font-size:24px;font-weight:600;margin-top:6px">${k.v}</div>
              </div>
            `).join("")}
          </div>

          <div style="margin-top:22px;display:flex;align-items:center">
            <h3 style="margin:0;font-size:16px;font-weight:600">${t("quick_actions")}</h3>
          </div>
          <div style="display:grid;grid-template-columns:repeat(4, 1fr);gap:10px;margin-top:10px">
            ${[
              { i: "grid", l: window.I18N.lang === "th" ? "ขาย" : "Sell", c: "188", route: "cashier" },
              { i: "box", l: window.I18N.lang === "th" ? "สต็อก" : "Stock", c: "270", route: "stock_mgmt" },
              { i: "users", l: window.I18N.lang === "th" ? "พนักงาน" : "Staff", c: "25", route: "staff" },
              { i: "chart", l: window.I18N.lang === "th" ? "รายงาน" : "Report", c: "80", route: "dashboard" }
            ].map(it => `
              <button data-route="${it.route}" style="background:rgba(255,255,255,.65);border:1px solid rgba(255,255,255,.7);
                border-radius:18px;padding:14px 6px;cursor:pointer;font-family:inherit;
                display:flex;flex-direction:column;align-items:center;gap:6px;
                box-shadow:0 1px 0 rgba(255,255,255,.7) inset, 0 6px 14px -6px rgba(20,40,80,.18)">
                <div style="width:36px;height:36px;border-radius:11px;background:linear-gradient(160deg, oklch(.85 .12 ${it.c}), oklch(.62 .14 ${it.c}));color:white;display:flex;align-items:center;justify-content:center">${ic(it.i, { size: 18, color: "white" })}</div>
                <span style="font-size:12px;font-weight:500">${it.l}</span>
              </button>
            `).join("")}
          </div>

          <div style="margin-top:22px;display:flex;align-items:center">
            <h3 style="margin:0;font-size:16px;font-weight:600">${t("pending_approvals")}</h3>
            <div style="flex:1"></div>
            <span style="font-size:11px;color:var(--tp-coral-deep);font-weight:600">3</span>
          </div>
          ${[
            { l: window.I18N.lang === "th" ? "ส่วนลด 200฿ เกินสิทธิ์" : "Discount 200฿ over limit", who: "นิด · Cashier #3", time: "5m" },
            { l: window.I18N.lang === "th" ? "Void ออเดอร์ #A1038" : "Void order #A1038", who: "ธนา · Cashier #1", time: "12m" }
          ].map(p => `
            <div class="tp-glass" style="margin-top:8px;padding:12px 14px;display:flex;align-items:center;gap:10px;border-radius:14px">
              <div style="width:36px;height:36px;border-radius:11px;background:linear-gradient(160deg, oklch(.92 .10 25), oklch(.78 .16 25));color:white;display:flex;align-items:center;justify-content:center">${ic("bell", { size: 16, color: "white" })}</div>
              <div style="flex:1">
                <div style="font-size:13px;font-weight:500">${p.l}</div>
                <div style="font-size:11px;color:var(--tp-ink-mute);margin-top:2px">${p.who} · ${p.time}</div>
              </div>
              <button class="tp-btn tp-btn-primary" style="height:30px;padding:0 12px;font-size:12px">${t("confirm")}</button>
            </div>
          `).join("")}
        </div>

        <div class="mobile-tabbar">
          ${[
            { i: "home", l: t("home_tab"), on: true, route: "mobile_mgr" },
            { i: "receipt", l: t("orders_tab"), route: "create_bill" },
            { i: "box", l: t("inventory_tab"), route: "inventory" },
            { i: "chart", l: t("reports_tab"), route: "dashboard" },
            { i: "more", l: t("more_tab"), route: "admin" }
          ].map(x => `
            <button class="tab-item ${x.on ? "active" : ""}" data-route="${x.route}">
              ${ic(x.i, { size: 22, color: x.on ? "var(--tp-teal-deep)" : "var(--tp-ink-mute)" })}
              <span>${x.l}</span>
            </button>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     ARCHITECTURE
     ────────────────────────────────────────────────*/
  function renderArchitecture() {
    return `
      <div class="welcome-hero">
        <div style="position:relative">
          <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35);margin-bottom:14px">
            ${ic("layers", { size: 12 })} ${t("architecture")}
          </span>
          <h1>${t("arch_title")}</h1>
          <p>${t("arch_desc")}</p>
        </div>
      </div>

      <div style="display:grid;grid-template-columns:1.2fr 1fr;gap:20px;margin-top:20px">
        <div class="tp-glass" style="padding:24px 26px">
          <h3 style="margin:0 0 12px;font-size:18px;font-weight:600">${window.I18N.lang === "th" ? "Stack ที่ใช้" : "Tech stack"}</h3>
          ${[
            { name: ".NET MAUI 9", desc: window.I18N.lang === "th" ? "C# โค้ดเดียว · Windows / iOS / Android / macOS" : "Single C# codebase · Windows / iOS / Android / macOS", icon: "monitor" },
            { name: "SQLite + EF Core", desc: window.I18N.lang === "th" ? "Local DB ทำงานออฟไลน์ได้เต็มที่" : "Local DB · full offline operation", icon: "box" },
            { name: "CommunityToolkit.MVVM", desc: window.I18N.lang === "th" ? "Source-gen MVVM ลด boilerplate" : "Source-gen MVVM, less boilerplate", icon: "grid" },
            { name: "SkiaSharp", desc: window.I18N.lang === "th" ? "Render glass blur + shadow บนทุกแพลตฟอร์ม" : "Cross-platform glass blur + shadow", icon: "layers" },
            { name: "Refit + Polly", desc: window.I18N.lang === "th" ? "Sync HTTP client พร้อม retry/jitter" : "HTTP client with retry/jitter", icon: "cloud" },
            { name: "Serilog → Sqlite sink", desc: window.I18N.lang === "th" ? "Local log + ส่งกลับเมื่อออนไลน์" : "Local log → upload when online", icon: "receipt" }
          ].map(it => `
            <div style="display:flex;gap:12px;padding:12px 0;border-bottom:1px dashed rgba(20,40,80,.08)">
              <div style="width:38px;height:38px;border-radius:11px;background:linear-gradient(160deg, oklch(.85 .12 188), oklch(.55 .13 195));color:white;display:flex;align-items:center;justify-content:center;flex-shrink:0">${ic(it.icon, { size: 18, color: "white" })}</div>
              <div style="flex:1">
                <div style="font-weight:600;font-size:14px">${it.name}</div>
                <div style="font-size:12px;color:var(--tp-ink-mute);margin-top:2px">${it.desc}</div>
              </div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="padding:24px 26px">
          <h3 style="margin:0 0 12px;font-size:18px;font-weight:600">${window.I18N.lang === "th" ? "โครงสร้างโปรเจค" : "Project structure"}</h3>
          <pre style="font-family:var(--tp-font-mono);font-size:12px;line-height:1.6;color:var(--tp-ink);margin:0;white-space:pre-wrap">posthaiprompt/
├── src/
│   ├── PosThaiprompt.Core/        ${window.I18N.lang === "th" ? "# โดเมน + บริการแชร์" : "# Domain + shared services"}
│   ├── PosThaiprompt.Data/        ${window.I18N.lang === "th" ? "# EF Core + SQLite" : "# EF Core + SQLite"}
│   ├── PosThaiprompt.Sync/        ${window.I18N.lang === "th" ? "# Sync API กับ Affiliate" : "# Sync with Affiliate"}
│   ├── PosThaiprompt.App/         ${window.I18N.lang === "th" ? "# MAUI app (UI)" : "# MAUI app (UI)"}
│   │   ├── Resources/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Platforms/
│   │       ├── Windows/
│   │       ├── Android/
│   │       └── iOS/
│   └── PosThaiprompt.Tests/
├── Resources/Strings/{th,en}.resx
├── README.md
└── posthaiprompt.sln</pre>
        </div>
      </div>

      <div class="tp-glass" style="margin-top:18px;padding:24px 26px">
        <h3 style="margin:0 0 12px;font-size:18px;font-weight:600">${window.I18N.lang === "th" ? "พื้นฐาน Offline-first" : "Offline-first design"}</h3>
        <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px">
          ${[
            { ic: "cloud_off", t: window.I18N.lang === "th" ? "ตัดบิลได้แม้ไม่มีเน็ต" : "Sell without network", d: window.I18N.lang === "th" ? "เก็บลง SQLite + outbox" : "SQLite + outbox queue" },
            { ic: "refresh", t: window.I18N.lang === "th" ? "ซิงก์อัตโนมัติเมื่อต่อเน็ต" : "Auto-sync on reconnect", d: window.I18N.lang === "th" ? "Outbox flush ผ่าน Refit" : "Flush outbox via Refit" },
            { ic: "layers", t: window.I18N.lang === "th" ? "Conflict resolution" : "Conflict resolution", d: window.I18N.lang === "th" ? "LWW + version vector" : "LWW + version vector" },
            { ic: "monitor", t: window.I18N.lang === "th" ? "Local SignalR hub" : "Local SignalR hub", d: window.I18N.lang === "th" ? "Cashier ↔ KDS ↔ Customer" : "Cashier ↔ KDS ↔ Customer" }
          ].map(c => `
            <div style="padding:14px 16px;border-radius:14px;background:rgba(255,255,255,.6);border:1px solid rgba(255,255,255,.7)">
              <div style="width:34px;height:34px;border-radius:10px;background:linear-gradient(160deg, oklch(.85 .12 188), oklch(.55 .13 195));color:white;display:flex;align-items:center;justify-content:center;margin-bottom:10px">${ic(c.ic, { size: 16, color: "white" })}</div>
              <div style="font-weight:600;font-size:13px">${c.t}</div>
              <div style="font-size:11px;color:var(--tp-ink-mute);margin-top:3px">${c.d}</div>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     SYNC / API
     ────────────────────────────────────────────────*/
  function renderSync() {
    return `
      <div class="welcome-hero" style="background:linear-gradient(160deg, oklch(.55 .14 250) 0%, oklch(.30 .10 280) 100%)">
        <div style="position:relative">
          <span class="tp-chip" style="background:rgba(255,255,255,.22);color:white;border-color:rgba(255,255,255,.35);margin-bottom:14px">
            ${ic("cloud", { size: 12 })} ${t("sync_api")}
          </span>
          <h1>${t("sync_title")}</h1>
          <p>${t("sync_desc")} · github.com/xjanova/Thaiprompt-Affiliate</p>
        </div>
      </div>

      <div class="tp-glass" style="margin-top:20px;padding:24px 26px">
        <h3 style="margin:0 0 14px;font-size:18px;font-weight:600">${window.I18N.lang === "th" ? "Endpoint ที่จะใช้" : "API endpoints"}</h3>
        <table style="width:100%;font-size:13px;border-collapse:collapse">
          <thead>
            <tr style="text-align:left;color:var(--tp-ink-mute);font-size:11px;letter-spacing:.1em;text-transform:uppercase">
              <th style="padding:8px 12px;border-bottom:1px solid var(--tp-line)">Method</th>
              <th style="padding:8px 12px;border-bottom:1px solid var(--tp-line)">Path</th>
              <th style="padding:8px 12px;border-bottom:1px solid var(--tp-line)">${window.I18N.lang === "th" ? "วัตถุประสงค์" : "Purpose"}</th>
            </tr>
          </thead>
          <tbody>
            ${[
              ["POST", "/api/pos/auth/pin", window.I18N.lang === "th" ? "เข้าสู่ระบบ ด้วย PIN + branchId" : "Sign in with PIN + branchId"],
              ["GET",  "/api/pos/products?branchId=X&since=…", window.I18N.lang === "th" ? "ดึง catalog (delta)" : "Pull catalog (delta)"],
              ["POST", "/api/pos/orders/sync", window.I18N.lang === "th" ? "ส่ง orders ที่อยู่ใน outbox" : "Push outbox orders"],
              ["POST", "/api/pos/payments/sync", window.I18N.lang === "th" ? "ส่ง payments ที่ออฟไลน์" : "Push offline payments"],
              ["GET",  "/api/pos/inventory/stock?branchId=X", window.I18N.lang === "th" ? "ดึงสต็อกล่าสุด" : "Get latest stock"],
              ["POST", "/api/pos/promotions/redeem", window.I18N.lang === "th" ? "ตรวจ + ใช้คูปอง" : "Validate + redeem coupon"],
              ["GET",  "/api/pos/reports/daily?date=YYYY-MM-DD", window.I18N.lang === "th" ? "Daily summary" : "Daily summary"]
            ].map(([m, p, d]) => `
              <tr>
                <td style="padding:10px 12px;border-bottom:1px dashed rgba(20,40,80,.06)">
                  <span class="tp-chip ${m === "POST" ? "tp-chip-coral" : ""}" style="font-family:var(--tp-font-mono);font-size:11px">${m}</span>
                </td>
                <td style="padding:10px 12px;border-bottom:1px dashed rgba(20,40,80,.06);font-family:var(--tp-font-mono);font-size:12px">${p}</td>
                <td style="padding:10px 12px;border-bottom:1px dashed rgba(20,40,80,.06);color:var(--tp-ink-soft)">${d}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>

      <div class="tp-glass" style="margin-top:18px;padding:24px 26px">
        <h3 style="margin:0 0 14px;font-size:18px;font-weight:600">${window.I18N.lang === "th" ? "ลำดับการซิงก์" : "Sync sequence"}</h3>
        <ol style="margin:0;padding-left:18px;font-size:13px;line-height:1.85;color:var(--tp-ink-soft)">
          <li>${window.I18N.lang === "th" ? "บูตเครื่อง POS → load จาก SQLite (cashier เริ่มขายได้ทันทีแม้ออฟไลน์)" : "POS boots → load from SQLite (cashier can sell immediately even offline)"}</li>
          <li>${window.I18N.lang === "th" ? "ทุก 30 วินาที + ทุกครั้งที่ network state กลับมา → SyncWorker ทำงาน" : "Every 30s + on network-up → SyncWorker runs"}</li>
          <li>${window.I18N.lang === "th" ? "Push outbox: orders, payments, void, stock-mutation (idempotency-key)" : "Push outbox: orders, payments, voids, stock mutations (idempotency-key)"}</li>
          <li>${window.I18N.lang === "th" ? "Pull delta: products, stock, prices, promos (since=lastSync)" : "Pull delta: products, stock, prices, promos (since=lastSync)"}</li>
          <li>${window.I18N.lang === "th" ? "Conflict → Last-Write-Wins ตาม updatedAt + log audit ใน admin panel" : "Conflicts → Last-Write-Wins on updatedAt + audit log in admin panel"}</li>
        </ol>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-top:18px">
        <div class="tp-glass" style="padding:22px 24px">
          <h3 style="margin:0 0 8px;font-size:17px;font-weight:600">${window.I18N.lang === "th" ? "ความปลอดภัย" : "Security"}</h3>
          <ul style="margin:0;padding-left:18px;font-size:13px;line-height:1.8;color:var(--tp-ink-soft)">
            <li>${window.I18N.lang === "th" ? "PIN เก็บแบบ Argon2id + salt ต่อ device" : "PIN stored with Argon2id + per-device salt"}</li>
            <li>${window.I18N.lang === "th" ? "JWT short-lived + refresh token แบบ rotating" : "Short-lived JWT + rotating refresh token"}</li>
            <li>${window.I18N.lang === "th" ? "TLS 1.2+ + cert pinning ในมือถือ" : "TLS 1.2+ with cert pinning on mobile"}</li>
            <li>${window.I18N.lang === "th" ? "SQLite encrypted (SQLCipher)" : "SQLite encrypted (SQLCipher)"}</li>
            <li>${window.I18N.lang === "th" ? "Hardware secure storage สำหรับ token" : "Hardware secure storage for tokens"}</li>
          </ul>
        </div>
        <div class="tp-glass" style="padding:22px 24px">
          <h3 style="margin:0 0 8px;font-size:17px;font-weight:600">${window.I18N.lang === "th" ? "Repo & การ deploy" : "Repo & deployment"}</h3>
          <div style="font-family:var(--tp-font-mono);font-size:12px;background:rgba(20,40,80,.05);padding:12px 14px;border-radius:10px;line-height:1.6">
git clone https://github.com/xjanova/posthaiprompt<br/>
cd posthaiprompt<br/>
dotnet workload install maui<br/>
dotnet build -t:Run -f net9.0-windows10.0.19041.0
          </div>
          <ul style="margin:14px 0 0;padding-left:18px;font-size:13px;line-height:1.8;color:var(--tp-ink-soft)">
            <li>${window.I18N.lang === "th" ? "Windows: MSIX installer + auto-update" : "Windows: MSIX installer + auto-update"}</li>
            <li>${window.I18N.lang === "th" ? "Android: APK + Play internal" : "Android: APK + Play internal"}</li>
            <li>${window.I18N.lang === "th" ? "iOS: TestFlight" : "iOS: TestFlight"}</li>
          </ul>
        </div>
      </div>
    `;
  }

  /* ════════════════════════════════════════════════
     PHASE 2 — Business / Operations / Print screens
     ════════════════════════════════════════════════*/

  const isTh = () => window.I18N.lang === "th";
  const tr = (th, en) => isTh() ? th : en;

  /* 12 · ACCOUNTING ─────────────────────────────── */
  function renderAccounting() {
    const accounts = [
      { code: "1101", name: tr("เงินสดในมือ", "Cash on hand"), type: tr("สินทรัพย์", "Asset"), balance: 184250, dir: "Dr", c: "188" },
      { code: "1102", name: tr("เงินฝากธนาคาร — ไทยพาณิชย์", "Bank — SCB"), type: tr("สินทรัพย์", "Asset"), balance: 1245680, dir: "Dr", c: "188" },
      { code: "1103", name: tr("เงินฝากธนาคาร — กสิกรไทย", "Bank — KBank"), type: tr("สินทรัพย์", "Asset"), balance: 482350, dir: "Dr", c: "188" },
      { code: "1201", name: tr("ลูกหนี้การค้า", "Trade receivables"), type: tr("สินทรัพย์", "Asset"), balance: 38420, dir: "Dr", c: "188" },
      { code: "2101", name: tr("เจ้าหนี้การค้า", "Trade payables"), type: tr("หนี้สิน", "Liability"), balance: 96420, dir: "Cr", c: "25" },
      { code: "2103", name: tr("ภาษีขายค้างจ่าย (VAT 7%)", "VAT payable 7%"), type: tr("หนี้สิน", "Liability"), balance: 28940, dir: "Cr", c: "25" },
      { code: "4101", name: tr("รายได้จากการขาย", "Sales revenue"), type: tr("รายได้", "Revenue"), balance: 1284500, dir: "Cr", c: "145" },
      { code: "5101", name: tr("ต้นทุนขาย", "Cost of goods sold"), type: tr("ค่าใช้จ่าย", "Expense"), balance: 542180, dir: "Dr", c: "80" },
      { code: "5201", name: tr("เงินเดือนพนักงาน", "Salaries"), type: tr("ค่าใช้จ่าย", "Expense"), balance: 184000, dir: "Dr", c: "80" },
      { code: "5301", name: tr("ค่าเช่าสถานที่", "Rent"), type: tr("ค่าใช้จ่าย", "Expense"), balance: 65000, dir: "Dr", c: "80" }
    ];
    const tabs = [tr("ผังบัญชี", "Accounts"), tr("สมุดรายวัน", "Journal"), tr("งบทดลอง", "Trial balance"), tr("งบกำไรขาดทุน", "P&L"), tr("งบดุล", "Balance sheet")];

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">12 · ${t("accounting")}</span>
        <span class="screen-meta-size">1440 × 900 · Back office</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>
        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("accounting")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("ผังบัญชี · งบทดลอง · พฤษภาคม 2568", "Chart of accounts · Trial balance · May 2026")}</div>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;background:rgba(255,255,255,.5);border-radius:12px;padding:4px;gap:2px;border:1px solid rgba(255,255,255,.6)">
              ${tabs.map((tab, i) => `
                <button style="padding:8px 16px;border-radius:9px;border:none;cursor:pointer;font-family:inherit;font-size:13px;font-weight:500;
                  background:${i === 0 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent"};
                  color:${i === 0 ? "white" : "var(--tp-ink-soft)"}">${tab}</button>
              `).join("")}
            </div>
            <button class="tp-btn tp-btn-primary" data-route="create_bill" style="height:42px">${ic("plus", { size: 16, color: "white" })} ${t("create_bill")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:24px;top:116px;display:grid;grid-template-columns:repeat(4, 1fr);gap:16px">
          ${[
            { l: tr("สินทรัพย์รวม", "Total assets"), v: "฿1,950,700", d: "+8.2%", up: true, c: "188" },
            { l: tr("หนี้สินรวม", "Total liabilities"), v: "฿125,360", d: "−3.1%", up: false, c: "25" },
            { l: tr("ส่วนของเจ้าของ", "Equity"), v: "฿1,825,340", d: "+10.4%", up: true, c: "270" },
            { l: tr("กำไรสุทธิเดือนนี้", "Net profit this month"), v: "฿493,320", d: "+15.8%", up: true, c: "145" }
          ].map(k => `
            <div class="tp-glass" style="padding:18px 22px;position:relative;overflow:hidden">
              <div style="font-size:12px;color:var(--tp-ink-mute)">${k.l}</div>
              <div class="tp-tnum" style="font-size:28px;font-weight:600;letter-spacing:-.02em;margin-top:4px;color:var(--tp-indigo-deep)">${k.v}</div>
              <div style="display:inline-flex;align-items:center;gap:4px;margin-top:6px;padding:2px 8px;border-radius:999px;font-size:11px;font-weight:600;
                background:${k.up ? "oklch(.94 .08 145)" : "oklch(.94 .08 25)"};color:${k.up ? "oklch(.45 .14 150)" : "oklch(.55 .15 25)"}">
                ${ic(k.up ? "arrow_up" : "arrow_down", { size: 11, color: k.up ? "oklch(.45 .14 150)" : "oklch(.55 .15 25)" })} ${k.d}
              </div>
              <div style="position:absolute;right:-10px;top:-10px;width:80px;height:80px;border-radius:50%;background:radial-gradient(circle, oklch(.85 .12 ${k.c} / .35), transparent 70%);filter:blur(8px)"></div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:240px;width:920px;bottom:24px;padding:20px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:14px">
            <div>
              <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">Chart of Accounts</div>
              <div style="font-size:18px;font-weight:600;margin-top:2px">${tr("ผังบัญชี", "Chart of Accounts")}</div>
            </div>
            <div style="flex:1"></div>
            <div style="display:flex;gap:6px">
              ${[t("all"), tr("สินทรัพย์", "Assets"), tr("หนี้สิน", "Liabilities"), tr("รายได้", "Revenue"), tr("ค่าใช้จ่าย", "Expenses")].map((tt, i) => `
                <span class="tp-chip ${i === 0 ? "tp-chip-active" : ""}">${tt}</span>
              `).join("")}
            </div>
          </div>
          <div style="display:grid;grid-template-columns:100px 2.4fr 1fr 1fr 140px;gap:14px;padding:10px 14px;font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.05em;border-bottom:1px solid rgba(20,40,80,.08)">
            <span>${tr("เลขบัญชี", "Account #")}</span><span>${tr("ชื่อบัญชี", "Name")}</span><span>${tr("ประเภท", "Type")}</span><span style="text-align:right">${tr("ยอดคงเหลือ", "Balance")}</span><span style="text-align:right">Dr / Cr</span>
          </div>
          <div style="flex:1;overflow:auto">
            ${accounts.map((a, i) => `
              <div style="display:grid;grid-template-columns:100px 2.4fr 1fr 1fr 140px;gap:14px;padding:12px 14px;align-items:center;border-bottom:1px dashed rgba(20,40,80,.06);font-size:13px;background:${i % 2 ? "rgba(255,255,255,.25)" : "transparent"};border-radius:8px">
                <span class="tp-mono" style="font-weight:600;color:var(--tp-ink-soft)">${a.code}</span>
                <span style="font-weight:500">${a.name}</span>
                <span class="tp-chip" style="height:24px;font-size:11px;padding:0 10px">${a.type}</span>
                <span class="tp-tnum" style="text-align:right;font-weight:600">฿${a.balance.toLocaleString()}</span>
                <div style="text-align:right">
                  <span style="font-size:11px;font-weight:600;padding:3px 10px;border-radius:999px;background:oklch(.94 .08 ${a.c});color:oklch(.45 .14 ${a.c});font-family:var(--tp-font-mono)">${a.dir === "Dr" ? tr("เดบิต", "DEBIT") : tr("เครดิต", "CREDIT")}</span>
                </div>
              </div>
            `).join("")}
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:240px;width:460px;height:320px;padding:22px 26px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("กำไร / ขาดทุน", "Profit & Loss")}</div>
          <div style="font-size:18px;font-weight:600;margin-top:2px;margin-bottom:16px">${tr("เดือนพฤษภาคม", "May 2026")}</div>
          ${[
            { l: tr("รายได้จากการขาย", "Sales revenue"), v: 1284500, c: "145" },
            { l: tr("หัก: ส่วนลด", "Less: discounts"), v: -42300, c: "25" },
            { l: tr("หัก: ต้นทุนขาย", "Less: COGS"), v: -542180, c: "80" },
            { l: tr("กำไรขั้นต้น", "Gross profit"), v: 700020, c: "270", bold: true },
            { l: tr("หัก: ค่าใช้จ่ายในการขาย", "Less: selling exp."), v: -84500, c: "80" },
            { l: tr("หัก: ค่าใช้จ่ายบริหาร", "Less: admin exp."), v: -122200, c: "80" },
            { l: tr("กำไรสุทธิ", "Net profit"), v: 493320, c: "188", bold: true, big: true }
          ].map(r => `
            <div style="display:flex;padding:8px 0;border-bottom:${r.bold ? "1px solid rgba(20,40,80,.15)" : "1px dashed rgba(20,40,80,.06)"};font-weight:${r.bold ? 600 : 400};font-size:${r.big ? 16 : 13}px">
              <span style="flex:1">${r.l}</span>
              <span class="tp-tnum" style="color:${r.v < 0 ? "oklch(.55 .15 25)" : (r.bold ? "oklch(.45 .14 " + r.c + ")" : "var(--tp-ink)")}">
                ${r.v < 0 ? "(" : ""}฿${Math.abs(r.v).toLocaleString()}${r.v < 0 ? ")" : ""}
              </span>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:580px;width:460px;bottom:24px;padding:18px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("สมุดรายวันล่าสุด", "Recent journal")}</div>
          <div style="font-size:16px;font-weight:600;margin-top:2px;margin-bottom:12px">Journal Entries</div>
          ${[
            { d: tr("08 พ.ค.", "08 May"), n: "JV-0428", desc: tr("รับชำระบิล A1042", "Payment A1042"), v: "฿331" },
            { d: tr("08 พ.ค.", "08 May"), n: "JV-0427", desc: tr("ซื้อเมล็ดกาแฟ", "Buy coffee beans"), v: "฿8,460" },
            { d: tr("07 พ.ค.", "07 May"), n: "JV-0426", desc: tr("จ่ายค่าเช่า", "Rent paid"), v: "฿65,000" }
          ].map(j => `
            <div style="display:flex;align-items:center;padding:10px 0;border-bottom:1px dashed rgba(20,40,80,.06);gap:10px">
              <div style="width:38px;height:38px;border-radius:10px;background:linear-gradient(160deg, oklch(.92 .05 220), oklch(.85 .06 230));display:flex;align-items:center;justify-content:center;color:oklch(.45 .12 250)">${ic("receipt", { size: 16, color: "oklch(.45 .12 250)" })}</div>
              <div style="flex:1">
                <div style="font-size:13px;font-weight:500">${j.desc}</div>
                <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute)">${j.n} · ${j.d}</div>
              </div>
              <span class="tp-tnum" style="font-weight:600;font-size:13px">${j.v}</span>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* 13 · CREATE BILL ─────────────────────────────── */
  function renderCreateBill() {
    const items = [
      { name: tr("ชาไทยเย็น", "Iced Thai Tea"), qty: 4, price: 65, note: tr("หวานน้อย", "Less sweet") },
      { name: tr("ชาเขียวมัทฉะลาเต้", "Matcha Latte"), qty: 2, price: 85, note: "" },
      { name: tr("ครัวซองต์อัลมอนด์", "Almond Croissant"), qty: 3, price: 55, note: tr("อุ่นก่อนเสิร์ฟ", "Warm up") },
      { name: tr("เค้กส้ม", "Orange Cake"), qty: 1, price: 95, note: "" }
    ];
    const sub = items.reduce((s, it) => s + it.qty * it.price, 0);
    const disc = 30;
    const vat = Math.round(((sub - disc) * 7) / 107);
    const net = sub - disc;

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">13 · ${t("create_bill")}</span>
        <span class="screen-meta-size">1440 × 900 · Back office</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("create_bill")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("เลขที่", "No.")}: <span class="tp-mono">INV-2568-0428</span></div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" data-route="accounting" style="height:42px">${ic("x", { size: 16 })} ${t("cancel")}</button>
            <button class="tp-btn tp-btn-ghost" style="height:42px">${ic("receipt", { size: 16 })} ${tr("บันทึกร่าง", "Save draft")}</button>
            <button class="tp-btn tp-btn-primary" data-route="tax_invoice" style="height:42px">${ic("check", { size: 16, color: "white" })} ${tr("ออกบิล", "Issue bill")}</button>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:116px;width:880px;bottom:24px;padding:24px;display:flex;flex-direction:column;gap:18px">
          <div>
            <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em;margin-bottom:8px">${tr("ข้อมูลลูกค้า", "Customer info")}</div>
            <div style="display:grid;grid-template-columns:1.4fr 1fr 1fr;gap:12px">
              <div style="background:white;border:1px solid var(--tp-line);border-radius:12px;padding:10px 14px">
                <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("ชื่อ / บริษัท", "Name / Company")}</div>
                <div style="font-size:15px;font-weight:500;margin-top:2px">${tr("บริษัท สยาม คอฟฟี่ จำกัด", "Siam Coffee Co., Ltd.")}</div>
              </div>
              <div style="background:white;border:1px solid var(--tp-line);border-radius:12px;padding:10px 14px">
                <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("เบอร์โทร", "Phone")}</div>
                <div class="tp-mono" style="font-size:15px;font-weight:500;margin-top:2px">02-218-5400</div>
              </div>
              <div style="background:white;border:1px solid var(--tp-line);border-radius:12px;padding:10px 14px">
                <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("เลขผู้เสียภาษี", "Tax ID")}</div>
                <div class="tp-mono" style="font-size:15px;font-weight:500;margin-top:2px">0105563012345</div>
              </div>
            </div>
            <div style="margin-top:10px;background:white;border:1px solid var(--tp-line);border-radius:12px;padding:10px 14px">
              <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("ที่อยู่จัดส่ง", "Shipping address")}</div>
              <div style="font-size:14px;margin-top:2px">${tr("989 อาคารสยามพิวรรธน์ ทาวเวอร์ ชั้น 14 ถ.พระราม 1 แขวงปทุมวัน เขตปทุมวัน กรุงเทพฯ 10330", "989 Siam Piwat Tower, 14th floor, Rama 1 Rd., Pathumwan, Bangkok 10330")}</div>
            </div>
          </div>

          <div style="flex:1;display:flex;flex-direction:column">
            <div style="display:flex;align-items:center;margin-bottom:8px">
              <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("รายการสินค้า", "Line items")}</div>
              <div style="flex:1"></div>
              <button class="tp-btn tp-btn-ghost" style="height:34px;font-size:12px">${ic("plus", { size: 14 })} ${tr("เพิ่มรายการ", "Add line")}</button>
            </div>
            <div style="display:grid;grid-template-columns:44px 2.6fr 80px 100px 110px 40px;gap:10px;padding:10px 14px;font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.05em;border-bottom:1px solid rgba(20,40,80,.08)">
              <span>#</span><span>${tr("สินค้า", "Item")}</span><span style="text-align:right">${tr("จำนวน", "Qty")}</span><span style="text-align:right">${tr("ราคา", "Price")}</span><span style="text-align:right">${tr("รวม", "Amount")}</span><span></span>
            </div>
            <div style="flex:1;overflow:auto">
              ${items.map((it, i) => `
                <div style="display:grid;grid-template-columns:44px 2.6fr 80px 100px 110px 40px;gap:10px;padding:12px 14px;align-items:center;border-bottom:1px dashed rgba(20,40,80,.06);font-size:13px">
                  <span class="tp-mono" style="color:var(--tp-ink-mute)">${i + 1}</span>
                  <div>
                    <div style="font-weight:500">${it.name}</div>
                    ${it.note ? `<div style="font-size:11px;color:oklch(.55 .15 25);margin-top:2px">* ${it.note}</div>` : ""}
                  </div>
                  <span class="tp-tnum" style="text-align:right">${it.qty}</span>
                  <span class="tp-tnum" style="text-align:right">฿${it.price}</span>
                  <span class="tp-tnum" style="text-align:right;font-weight:600">฿${(it.qty * it.price).toLocaleString()}</span>
                  <button style="width:28px;height:28px;border-radius:8px;border:1px solid var(--tp-line);background:white;cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--tp-ink-mute)">${ic("trash", { size: 14 })}</button>
                </div>
              `).join("")}
            </div>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:116px;width:488px;bottom:24px;padding:24px;display:flex;flex-direction:column">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ตั้งค่าเอกสาร", "Document settings")}</div>
          <div style="margin-top:14px;display:grid;grid-template-columns:1fr 1fr;gap:10px">
            <div style="background:white;border:1px solid var(--tp-line);border-radius:12px;padding:10px 14px">
              <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("วันที่ออก", "Issue date")}</div>
              <div class="tp-mono" style="font-size:14px;font-weight:500;margin-top:2px">${tr("08 พ.ค. 2568", "08 May 2026")}</div>
            </div>
            <div style="background:white;border:1px solid var(--tp-line);border-radius:12px;padding:10px 14px">
              <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("ครบกำหนด", "Due date")}</div>
              <div class="tp-mono" style="font-size:14px;font-weight:500;margin-top:2px">${tr("22 พ.ค. 2568", "22 May 2026")}</div>
            </div>
          </div>
          <div style="margin-top:14px;font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ประเภทเอกสาร", "Document type")}</div>
          <div style="margin-top:8px;display:grid;grid-template-columns:repeat(2, 1fr);gap:8px">
            ${[
              { l: tr("ใบกำกับภาษี", "Tax invoice"), on: true },
              { l: tr("ใบเสร็จรับเงิน", "Receipt"), on: false },
              { l: tr("ใบแจ้งหนี้", "Invoice"), on: false },
              { l: tr("ใบเสนอราคา", "Quotation"), on: false }
            ].map(d => `
              <button style="padding:10px 12px;border-radius:12px;font-family:inherit;font-size:13px;font-weight:500;cursor:pointer;
                border:${d.on ? "1.5px solid oklch(.62 .14 195)" : "1px solid var(--tp-line)"};
                background:${d.on ? "oklch(.96 .04 195)" : "white"};
                color:${d.on ? "oklch(.40 .14 200)" : "var(--tp-ink-soft)"};
                display:flex;align-items:center;justify-content:center;gap:6px">
                ${d.on ? ic("check", { size: 14, color: "oklch(.40 .14 200)" }) : ""} ${d.l}
              </button>
            `).join("")}
          </div>
          <div style="flex:1"></div>
          <div style="border-top:1px dashed var(--tp-line);padding-top:16px;font-size:14px">
            <div style="display:flex;padding:6px 0"><span style="flex:1;color:var(--tp-ink-mute)">${tr("ยอดรวมก่อนหักส่วนลด", "Subtotal")}</span><span class="tp-tnum">฿${sub.toLocaleString()}</span></div>
            <div style="display:flex;padding:6px 0"><span style="flex:1;color:var(--tp-ink-mute)">${t("discount")}</span><span class="tp-tnum" style="color:oklch(.55 .15 25)">−฿${disc}</span></div>
            <div style="display:flex;padding:6px 0"><span style="flex:1;color:var(--tp-ink-mute)">${tr("ภาษีมูลค่าเพิ่ม 7% (รวมแล้ว)", "VAT 7% (incl.)")}</span><span class="tp-tnum">฿${vat}</span></div>
            <div style="display:flex;padding:14px 16px;margin-top:10px;border-radius:14px;background:linear-gradient(140deg, oklch(.30 .08 265), oklch(.20 .06 270));color:white;align-items:baseline;
              box-shadow:0 8px 22px -10px oklch(.25 .07 265 / .55), 0 1px 0 rgba(255,255,255,.12) inset">
              <span style="flex:1;font-size:14px;opacity:.85">${tr("ยอดสุทธิที่ต้องชำระ", "Total due")}</span>
              <span class="tp-tnum" style="font-size:28px;font-weight:700;letter-spacing:-.01em">฿${net.toLocaleString()}.00</span>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  /* 14 · TAX INVOICE ─────────────────────────────── */
  function renderTaxInvoice() {
    const items = [
      { name: tr("ชาไทยเย็น (สูตรพิเศษ)", "Iced Thai Tea (special)"), qty: 4, price: 65 },
      { name: tr("ชาเขียวมัทฉะลาเต้", "Matcha Latte"), qty: 2, price: 85 },
      { name: tr("ครัวซองต์อัลมอนด์", "Almond Croissant"), qty: 3, price: 55 },
      { name: tr("เค้กส้ม", "Orange Cake"), qty: 1, price: 95 }
    ];
    const sub = items.reduce((s, it) => s + it.qty * it.price, 0) - 30;
    const beforeVat = Math.round((sub * 100) / 107);
    const vat = Math.round((sub * 7) / 107);

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">14 · ${t("tax_invoice")}</span>
        <span class="screen-meta-size">1440 × 900 · Back office</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("tax_invoice")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("ตัวอย่างก่อนพิมพ์", "Print preview")} · <span class="tp-mono">TAX-2568-001428</span></div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" style="height:42px">${ic("download", { size: 16 })} ${tr("ดาวน์โหลด PDF", "Download PDF")}</button>
            <button class="tp-btn tp-btn-ghost" style="height:42px">${ic("printer", { size: 16 })} ${tr("พิมพ์", "Print")}</button>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("check", { size: 16, color: "white" })} ${tr("ส่ง e-Tax", "Send e-Tax")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:360px;top:116px;bottom:24px;display:flex;justify-content:center;align-items:flex-start;overflow:auto;padding:20px 0">
          <div style="width:720px;min-height:920px;background:white;border-radius:12px;
            box-shadow:0 30px 70px -25px rgba(20,40,80,.25), 0 8px 22px -10px rgba(20,40,80,.15);
            padding:44px 56px;font-family:var(--tp-font);color:var(--tp-ink);position:relative;overflow:hidden">
            <div style="position:absolute;left:0;top:0;right:0;height:6px;background:linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 250))"></div>
            <div style="position:absolute;right:-40px;top:120px;opacity:.04;transform:rotate(-22deg);font-size:140px;font-weight:700;pointer-events:none">TAX INVOICE</div>

            <div style="display:flex;align-items:flex-start">
              ${bm(56)}
              <div style="margin-left:14px">
                <div style="font-size:20px;font-weight:700;letter-spacing:-.01em">Thaiprompt Coffee Co., Ltd.</div>
                <div style="font-size:11px;color:var(--tp-ink-mute);margin-top:2px">${tr("444 อาคารสยามสแควร์วัน ชั้น 8, ถ.พระราม 1, ปทุมวัน กรุงเทพฯ 10330", "444 Siam Square One, 8F, Rama 1, Pathumwan, Bangkok 10330")}</div>
                <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute)">${tr("เลขประจำตัวผู้เสียภาษี", "Tax ID")}: 0107555000123 · ${tr("สำนักงานใหญ่", "Head office")}</div>
                <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute)">${tr("โทร", "Tel")} 02-555-0123 · contact@thaiprompt.co.th</div>
              </div>
              <div style="flex:1"></div>
              <div style="text-align:right">
                <div style="font-size:18px;font-weight:700;letter-spacing:-.01em">${tr("ใบกำกับภาษี / ใบเสร็จรับเงิน", "Tax Invoice / Receipt")}</div>
                <div style="font-size:11px;color:var(--tp-ink-mute)">TAX INVOICE / RECEIPT</div>
                <div style="margin-top:8px;font-size:11px;color:var(--tp-ink-mute)">${tr("ต้นฉบับ", "ORIGINAL")}</div>
              </div>
            </div>

            <div style="display:grid;grid-template-columns:1.4fr 1fr;gap:14px;margin-top:26px">
              <div style="border:1px solid var(--tp-line);border-radius:10px;padding:12px 16px">
                <div style="font-size:10px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.08em">${tr("ลูกค้า", "Customer")}</div>
                <div style="font-size:14px;font-weight:600;margin-top:4px">${tr("บริษัท สยาม คอฟฟี่ จำกัด", "Siam Coffee Co., Ltd.")}</div>
                <div style="font-size:11px;margin-top:2px;color:var(--tp-ink-soft)">${tr("989 อาคารสยามพิวรรธน์ ทาวเวอร์ ชั้น 14 ถ.พระราม 1 แขวงปทุมวัน เขตปทุมวัน กรุงเทพฯ 10330", "989 Siam Piwat Tower, 14F, Rama 1, Pathumwan, Bangkok 10330")}</div>
                <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute);margin-top:4px">TAX ID: 0105563012345</div>
              </div>
              <div style="border:1px solid var(--tp-line);border-radius:10px;padding:12px 16px">
                <div style="display:grid;grid-template-columns:auto 1fr;gap:6px 12px;font-size:12px">
                  <span style="color:var(--tp-ink-mute)">${tr("เลขที่", "No.")}:</span><span class="tp-mono" style="font-weight:600">TAX-2568-001428</span>
                  <span style="color:var(--tp-ink-mute)">${tr("วันที่", "Date")}:</span><span class="tp-mono">${tr("08 พ.ค. 2568", "08 May 2026")}</span>
                  <span style="color:var(--tp-ink-mute)">${tr("ครบกำหนด", "Due")}:</span><span class="tp-mono">${tr("22 พ.ค. 2568", "22 May 2026")}</span>
                  <span style="color:var(--tp-ink-mute)">${tr("ผู้ขาย", "Issued by")}:</span><span>${tr("คุณนัทธมน", "K.Nattamon")}</span>
                </div>
              </div>
            </div>

            <table style="width:100%;border-collapse:collapse;margin-top:22px;font-size:12px">
              <thead>
                <tr style="background:oklch(.96 .02 220);text-align:left">
                  <th style="padding:10px 12px;font-weight:600;font-size:11px;color:var(--tp-ink-soft);text-transform:uppercase;letter-spacing:.05em">#</th>
                  <th style="padding:10px 12px;font-weight:600;font-size:11px;color:var(--tp-ink-soft);text-transform:uppercase;letter-spacing:.05em">${tr("รายการ", "Description")}</th>
                  <th style="padding:10px 12px;font-weight:600;font-size:11px;color:var(--tp-ink-soft);text-transform:uppercase;letter-spacing:.05em;text-align:right">${tr("จำนวน", "Qty")}</th>
                  <th style="padding:10px 12px;font-weight:600;font-size:11px;color:var(--tp-ink-soft);text-transform:uppercase;letter-spacing:.05em;text-align:right">${tr("ราคา/หน่วย", "Unit price")}</th>
                  <th style="padding:10px 12px;font-weight:600;font-size:11px;color:var(--tp-ink-soft);text-transform:uppercase;letter-spacing:.05em;text-align:right">${tr("จำนวนเงิน", "Amount")}</th>
                </tr>
              </thead>
              <tbody>
                ${items.map((it, i) => `
                  <tr style="border-bottom:1px dashed var(--tp-line)">
                    <td class="tp-mono" style="padding:12px;color:var(--tp-ink-mute)">${i + 1}</td>
                    <td style="padding:12px;font-weight:500">${it.name}</td>
                    <td class="tp-tnum" style="padding:12px;text-align:right">${it.qty}</td>
                    <td class="tp-tnum" style="padding:12px;text-align:right">${it.price.toFixed(2)}</td>
                    <td class="tp-tnum" style="padding:12px;text-align:right;font-weight:500">${(it.qty * it.price).toFixed(2)}</td>
                  </tr>
                `).join("")}
              </tbody>
            </table>

            <div style="display:flex;margin-top:20px">
              <div style="flex:1;padding:14px 16px;border:1px dashed var(--tp-line);border-radius:10px;font-size:11px;color:var(--tp-ink-soft)">
                <div style="font-weight:600;color:var(--tp-ink);margin-bottom:4px">${tr("หมายเหตุ", "Note")}</div>
                <div>${tr("ชำระโดยโอนเข้าบัญชี ไทยพาณิชย์ เลขที่ 123-4-56789-0", "Pay via SCB account 123-4-56789-0")}</div>
              </div>
              <div style="width:280px;margin-left:16px;font-size:12px">
                <div style="display:flex;padding:6px 0;border-bottom:1px dashed var(--tp-line)">
                  <span style="flex:1;color:var(--tp-ink-mute)">${tr("มูลค่าก่อน VAT", "Pre-VAT")}</span><span class="tp-tnum">${beforeVat.toLocaleString()}.00</span>
                </div>
                <div style="display:flex;padding:6px 0;border-bottom:1px dashed var(--tp-line)">
                  <span style="flex:1;color:var(--tp-ink-mute)">${tr("ภาษีมูลค่าเพิ่ม 7%", "VAT 7%")}</span><span class="tp-tnum">${vat.toLocaleString()}.00</span>
                </div>
                <div style="display:flex;padding:12px 14px;margin-top:8px;border-radius:10px;background:linear-gradient(140deg, oklch(.30 .08 265), oklch(.20 .06 270));color:white">
                  <span style="flex:1;font-weight:500">${t("total")}</span><span class="tp-tnum" style="font-weight:700;font-size:16px">฿${Math.round(sub).toLocaleString()}.00</span>
                </div>
              </div>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:32px;margin-top:64px;font-size:11px;color:var(--tp-ink-soft)">
              <div style="border-top:1px solid var(--tp-line);padding-top:8px;text-align:center">${tr("ผู้รับเงิน", "Received by")}</div>
              <div style="border-top:1px solid var(--tp-line);padding-top:8px;text-align:center">${tr("ผู้รับสินค้า", "Received goods")}</div>
            </div>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:116px;width:312px;bottom:24px;padding:22px 24px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("สถานะ e-Tax Invoice", "e-Tax status")}</div>
          ${[
            { l: tr("บันทึกร่าง", "Draft saved"), t: "08/05 14:32", done: true },
            { l: tr("ออกเลขที่เอกสาร", "Number assigned"), t: "08/05 14:33", done: true },
            { l: tr("ลงลายเซ็นดิจิทัล", "Digital signature"), t: "08/05 14:33", done: true },
            { l: tr("ส่งให้กรมสรรพากร", "Send to RD"), t: tr("รอดำเนินการ", "Pending"), done: false, current: true },
            { l: tr("ส่งให้ลูกค้าทาง Email", "Email to customer"), t: "—", done: false }
          ].map((s, i, arr) => `
            <div style="display:flex;gap:12px;margin-top:${i === 0 ? 16 : 0}px">
              <div style="display:flex;flex-direction:column;align-items:center">
                <div style="width:26px;height:26px;border-radius:50%;
                  background:${s.done ? "linear-gradient(160deg, oklch(.78 .14 145), oklch(.55 .14 150))" : (s.current ? "white" : "oklch(.96 .01 220)")};
                  border:${s.current ? "2px solid oklch(.62 .14 195)" : "none"};
                  display:flex;align-items:center;justify-content:center;color:${s.done ? "white" : "var(--tp-ink-mute)"}">
                  ${s.done ? ic("check", { size: 14, color: "white" }) : `<span style="font-size:12px;font-weight:600">${i + 1}</span>`}
                </div>
                ${i < arr.length - 1 ? `<div style="width:2px;flex:1;background:${s.done ? "oklch(.78 .14 145)" : "var(--tp-line)"};margin:4px 0"></div>` : ""}
              </div>
              <div style="padding-bottom:18px;flex:1">
                <div style="font-size:13px;font-weight:500">${s.l}</div>
                <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute);margin-top:2px">${s.t}</div>
              </div>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* 15 · NFC SCAN ─────────────────────────────── */
  function renderNFCScan() {
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">15 · ${t("nfc_scan")}</span>
        <span class="screen-meta-size">1280 × 800 · Payment device</span>
      </div>
      <div class="screen-frame win-1280">
        <div class="screen-bg"></div>
        <div style="position:absolute;inset:0;background:radial-gradient(circle at 50% 45%, oklch(.85 .14 195 / .35), transparent 60%)"></div>

        <div class="tp-glass" style="position:absolute;left:24px;right:24px;top:24px;height:64px">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(36)}
            <div style="font-size:15px;font-weight:600">${tr("แตะบัตรเพื่อชำระ", "Tap card to pay")}</div>
            <div style="flex:1"></div>
            <span class="tp-chip">${ic("receipt", { size: 13 })} ${tr("บิล A1042", "Bill A1042")}</span>
            <button class="tp-btn tp-btn-ghost" data-route="payment" style="height:36px">${tr("วิธีอื่น", "Other methods")}</button>
          </div>
        </div>

        <div style="position:absolute;left:0;right:360px;top:100px;bottom:24px;display:flex;flex-direction:column;align-items:center;justify-content:center">
          <div style="position:relative;width:460px;height:460px;display:flex;align-items:center;justify-content:center">
            ${[1, 2, 3].map(r => `
              <div style="position:absolute;width:${460 - r * 30}px;height:${460 - r * 30}px;border-radius:50%;
                border:2px solid oklch(.62 .14 195);opacity:${0.5 - r * 0.12};
                animation:nfcpulse 2.6s ease-out ${r * 0.3}s infinite"></div>
            `).join("")}
            <style>@keyframes nfcpulse { 0% { transform: scale(.8); opacity: .55 } 80% { transform: scale(1.15); opacity: 0 } 100% { transform: scale(1.15); opacity: 0 } }</style>

            <div style="width:240px;height:240px;border-radius:50%;
              background:linear-gradient(160deg, oklch(.85 .12 188), oklch(.55 .14 200) 70%, oklch(.40 .14 250));
              box-shadow:0 30px 80px -20px oklch(.45 .14 230 / .55), 0 8px 22px -8px oklch(.50 .14 250 / .45), inset 0 2px 0 rgba(255,255,255,.5), inset 0 -3px 0 rgba(20,40,80,.15);
              display:flex;align-items:center;justify-content:center;position:relative">
              <svg width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="1.6" stroke-linecap="round" style="filter:drop-shadow(0 4px 8px rgba(20,40,80,.3))">
                <path d="M5 8a10 10 0 0 1 14 0"/><path d="M8 11a6 6 0 0 1 8 0"/><path d="M11 14a2 2 0 0 1 2 0"/><circle cx="12" cy="17" r="1" fill="white"/>
              </svg>
            </div>

            <div style="position:absolute;right:30px;top:80px;width:220px;height:138px;border-radius:16px;
              background:linear-gradient(140deg, oklch(.50 .15 270 / .85), oklch(.30 .12 290 / .85));backdrop-filter:blur(8px);
              border:1px solid rgba(255,255,255,.35);
              box-shadow:0 24px 50px -16px rgba(20,40,80,.45), inset 0 1px 0 rgba(255,255,255,.55);
              transform:rotate(-12deg);padding:16px 18px;color:white;overflow:hidden">
              <div style="position:absolute;left:-20px;bottom:-20px;width:120px;height:120px;border-radius:50%;background:radial-gradient(circle, oklch(.78 .14 28 / .6), transparent 70%);filter:blur(8px)"></div>
              <div style="display:flex;align-items:center;gap:10px">
                <div style="width:32px;height:24px;border-radius:4px;background:linear-gradient(135deg, oklch(.85 .14 80), oklch(.65 .12 80));box-shadow:inset 0 1px 0 rgba(255,255,255,.5)"></div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="1.8" opacity=".8"><path d="M5 8a10 10 0 0 1 14 0"/><path d="M8 11a6 6 0 0 1 8 0"/></svg>
              </div>
              <div class="tp-mono" style="font-size:16px;letter-spacing:.15em;margin-top:28px;opacity:.9">•••• 4827</div>
              <div style="display:flex;margin-top:6px;font-size:9px;opacity:.7;text-transform:uppercase;letter-spacing:.15em">
                <span>VISA Platinum</span><div style="flex:1"></div><span>05/29</span>
              </div>
            </div>
          </div>

          <div style="margin-top:20px;font-size:26px;font-weight:600;letter-spacing:-.01em">${tr("กรุณาแตะบัตรหรือมือถือ", "Please tap card or phone")}</div>
          <div style="font-size:14px;color:var(--tp-ink-mute);margin-top:6px">${tr("รองรับ Visa · Master · JCB · Apple Pay · Google Pay · พร้อมเพย์ Tag", "Visa · Master · JCB · Apple Pay · Google Pay · PromptPay")}</div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:100px;width:312px;bottom:24px;padding:22px 26px;display:flex;flex-direction:column">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ยอดที่ต้องชำระ", "Amount due")}</div>
          <div class="tp-tnum" style="font-size:56px;font-weight:700;letter-spacing:-.03em;line-height:1;margin-top:6px;color:var(--tp-indigo-deep)">฿1,335</div>
          <div style="font-size:12px;color:var(--tp-ink-mute);margin-top:4px">17 ${tr("รายการ", "items")} · ${tr("บิล A1042", "Bill A1042")}</div>

          <div style="margin-top:22px;padding:14px;border-radius:14px;background:oklch(.96 .03 195);border:1px solid oklch(.85 .05 195)">
            <div style="display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;color:oklch(.40 .14 200)">
              <span style="width:8px;height:8px;border-radius:50%;background:oklch(.62 .14 195);box-shadow:0 0 0 4px oklch(.62 .14 195 / .25)"></span>
              ${tr("กำลังรอบัตร...", "Waiting for card...")}
            </div>
            <div style="font-size:11px;color:var(--tp-ink-mute);margin-top:4px">${tr("วางบัตรใกล้เครื่องอ่าน 2-3 ซม.", "Tap card 2–3 cm from reader")}</div>
          </div>

          <div style="flex:1"></div>

          <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em;margin-bottom:8px">${tr("หรือชำระแบบอื่น", "Or pay another way")}</div>
          ${[
            { i: "qr", l: tr("พร้อมเพย์ QR", "QR PromptPay"), route: "payment" },
            { i: "cash", l: t("cash"), route: "payment" },
            { i: "card", l: tr("รูดบัตรในเครื่อง", "Insert card"), route: "payment" }
          ].map(m => `
            <button data-route="${m.route}" style="display:flex;align-items:center;gap:10px;width:100%;padding:12px 14px;margin-bottom:8px;border-radius:12px;
              border:1px solid var(--tp-line);background:white;cursor:pointer;font-family:inherit;font-size:13px;font-weight:500;text-align:left">
              <div style="width:32px;height:32px;border-radius:8px;background:oklch(.95 .03 220);display:flex;align-items:center;justify-content:center;color:oklch(.45 .12 250)">${ic(m.i, { size: 16, color: "oklch(.45 .12 250)" })}</div>
              <span style="flex:1">${m.l}</span>
              ${ic("arrow_right", { size: 14, color: "var(--tp-ink-mute)" })}
            </button>
          `).join("")}

          <button class="tp-btn tp-btn-ghost" data-route="cashier" style="margin-top:4px;height:44px">${ic("x", { size: 14 })} ${tr("ยกเลิกธุรกรรม", "Cancel transaction")}</button>
        </div>
      </div>
    `;
  }

  /* 16 · DELIVERY (rider tracker) ─────────────────────────────── */
  function renderDelivery() {
    const orders = [
      { id: "DLV-1042", cust: tr("คุณสมชาย ม.", "K.Somchai"), addr: tr("สุขุมวิท 39 ซ.5", "Sukhumvit 39"), items: 4, amount: 420, status: "preparing", rider: "—", eta: "—", km: 2.4, c: "80" },
      { id: "DLV-1041", cust: tr("คุณนภา ส.", "K.Napa"), addr: tr("พญาไท One City", "Phaya Thai"), items: 2, amount: 180, status: "ready", rider: "—", eta: tr("พร้อมส่ง", "Ready"), km: 0.9, c: "188" },
      { id: "DLV-1040", cust: tr("คุณกานต์ ว.", "K.Karn"), addr: tr("ทองหล่อ ซ.10", "Thonglor 10"), items: 6, amount: 695, status: "delivering", rider: tr("พี่โต้ง", "Tong"), eta: tr("8 นาที", "8 min"), km: 3.1, c: "270" },
      { id: "DLV-1039", cust: "บจก. ไอแซค", addr: tr("อโศก ดิเอ็มดิสทริค", "Asoke EmDistrict"), items: 12, amount: 1840, status: "delivering", rider: tr("พี่นัท", "Nut"), eta: tr("12 นาที", "12 min"), km: 4.2, c: "270" },
      { id: "DLV-1038", cust: tr("คุณมินตรา ก.", "K.Mintra"), addr: tr("เอกมัย ซ.5", "Ekkamai 5"), items: 3, amount: 285, status: "delivered", rider: tr("พี่โต้ง", "Tong"), eta: tr("ส่งแล้ว 14:02", "Done 14:02"), km: 1.8, c: "145" }
    ];
    const statusLabel = {
      preparing: tr("กำลังเตรียม", "Preparing"),
      ready: tr("พร้อมส่ง", "Ready"),
      delivering: tr("กำลังส่ง", "On the way"),
      delivered: tr("ส่งแล้ว", "Delivered")
    };
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">16 · ${t("delivery")}</span>
        <span class="screen-meta-size">1440 × 900 · Operations</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("delivery")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("5 ออเดอร์ · ไรเดอร์ 3 คน", "5 orders · 3 riders")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" data-route="shipping_providers" style="height:42px">${ic("split", { size: 16 })} ${t("shipping_providers")}</button>
            <button class="tp-btn tp-btn-primary" data-route="cashier" style="height:42px">${ic("plus", { size: 16, color: "white" })} ${tr("ออเดอร์ใหม่", "New order")}</button>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:116px;width:880px;bottom:24px;padding:0;overflow:hidden">
          <div style="position:absolute;inset:0;background:linear-gradient(180deg, oklch(.92 .04 200), oklch(.96 .02 220))"></div>
          <svg viewBox="0 0 880 760" style="position:absolute;inset:0;width:100%;height:100%">
            <defs>
              <pattern id="map-grid-${Math.random().toString(36).slice(2)}" width="60" height="60" patternUnits="userSpaceOnUse">
                <path d="M 60 0 L 0 0 0 60" fill="none" stroke="oklch(.85 .03 200)" stroke-width="1"/>
              </pattern>
            </defs>
            <rect width="880" height="760" fill="white"/>
            <path d="M 0 380 L 880 380" stroke="white" stroke-width="22" stroke-linecap="round"/>
            <path d="M 200 0 L 200 760" stroke="white" stroke-width="16" stroke-linecap="round"/>
            <path d="M 580 0 L 580 760" stroke="white" stroke-width="18" stroke-linecap="round"/>
            <path d="M 0 180 Q 300 220 460 100 T 880 240" stroke="white" stroke-width="14" fill="none" stroke-linecap="round"/>
            <path d="M 100 760 Q 250 600 460 580 T 880 540" stroke="white" stroke-width="12" fill="none" stroke-linecap="round"/>
            <circle cx="700" cy="180" r="80" fill="oklch(.92 .07 145)" opacity=".7"/>
            <rect x="60" y="500" width="140" height="100" rx="14" fill="oklch(.92 .07 145)" opacity=".7"/>
            <path d="M 0 660 Q 200 620 460 700 T 880 680" stroke="oklch(.85 .07 220)" stroke-width="34" fill="none" stroke-linecap="round" opacity=".6"/>
            <path d="M 440 380 Q 540 320 580 240 T 720 160" stroke="oklch(.50 .14 250)" stroke-width="4" fill="none" stroke-dasharray="8 6" stroke-linecap="round"/>
            <path d="M 440 380 Q 360 440 280 480 T 160 540" stroke="oklch(.62 .14 195)" stroke-width="4" fill="none" stroke-dasharray="8 6" stroke-linecap="round"/>
            <g transform="translate(440 380)">
              <circle r="22" fill="oklch(.62 .14 195 / .3)"/>
              <circle r="14" fill="oklch(.50 .14 250)" stroke="white" stroke-width="3"/>
              <text y="5" font-size="14" fill="white" text-anchor="middle" font-weight="700">T</text>
            </g>
            ${[
              { x: 720, y: 160, c: "270" }, { x: 160, y: 540, c: "270" }, { x: 280, y: 240, c: "80" }, { x: 600, y: 540, c: "188" }, { x: 760, y: 480, c: "145" }
            ].map(p => `
              <g transform="translate(${p.x} ${p.y})">
                <circle r="20" fill="oklch(.78 .14 ${p.c} / .35)"/>
                <path d="M 0 -16 C 9 -16 14 -8 14 -2 C 14 6 0 18 0 18 C 0 18 -14 6 -14 -2 C -14 -8 -9 -16 0 -16 Z" fill="oklch(.55 .14 ${p.c})" stroke="white" stroke-width="2.5"/>
                <circle cy="-3" r="5" fill="white"/>
              </g>
            `).join("")}
            ${[{ x: 540, y: 280 }, { x: 360, y: 460 }].map(r => `
              <g transform="translate(${r.x} ${r.y})">
                <circle r="22" fill="oklch(.85 .14 80 / .4)"/>
                <circle r="15" fill="oklch(.65 .15 50)" stroke="white" stroke-width="3"/>
              </g>
            `).join("")}
          </svg>

          <div class="tp-glass" style="position:absolute;left:16px;top:16px;padding:10px 14px;display:flex;gap:14px;font-size:12px;align-items:center">
            <span style="display:flex;align-items:center;gap:6px"><span style="width:10px;height:10px;border-radius:50%;background:oklch(.50 .14 250)"></span> ${tr("ร้าน", "Shop")}</span>
            <span style="display:flex;align-items:center;gap:6px"><span style="width:10px;height:10px;border-radius:50%;background:oklch(.65 .15 50)"></span> ${tr("ไรเดอร์", "Rider")}</span>
            <span style="display:flex;align-items:center;gap:6px"><span style="width:10px;height:10px;border-radius:50%;background:oklch(.55 .14 270)"></span> ${tr("ลูกค้า", "Customer")}</span>
          </div>

          <div class="tp-glass" style="position:absolute;left:16px;bottom:16px;width:360px;padding:16px">
            <div style="display:flex;align-items:center;gap:10px">
              <div style="width:44px;height:44px;border-radius:12px;background:linear-gradient(160deg, oklch(.85 .12 270), oklch(.55 .14 280));display:flex;align-items:center;justify-content:center;color:white">${ic("phone", { size: 18, color: "white" })}</div>
              <div style="flex:1">
                <div style="font-size:14px;font-weight:600">DLV-1040 — ${statusLabel.delivering}</div>
                <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("คุณกานต์ · ทองหล่อ ซ.10", "K.Karn · Thonglor 10")}</div>
              </div>
              <span class="tp-tnum" style="font-size:16px;font-weight:600">฿695</span>
            </div>
            <button class="tp-btn tp-btn-primary" data-route="shipping_label" style="width:100%;margin-top:10px;height:38px;font-size:12px">${ic("printer", { size: 14, color: "white" })} ${tr("พิมพ์ใบปะหน้า", "Print label")}</button>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:116px;width:488px;bottom:24px;padding:18px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:12px">
            <div>
              <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("คิวออเดอร์", "Order queue")}</div>
              <div style="font-size:18px;font-weight:600;margin-top:2px">${tr("วันนี้", "Today")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" style="height:34px;font-size:12px">${ic("filter", { size: 14 })} ${t("filter")}</button>
          </div>
          <div style="flex:1;overflow:auto;padding-right:4px">
            ${orders.map(o => `
              <div style="padding:14px;margin-bottom:10px;border-radius:14px;background:white;border:1px solid var(--tp-line);
                box-shadow:0 4px 10px -6px rgba(20,40,80,.08);border-left:4px solid oklch(.65 .14 ${o.c})">
                <div style="display:flex;align-items:center;gap:8px">
                  <span class="tp-mono" style="font-size:13px;font-weight:600">${o.id}</span>
                  <span style="font-size:10px;font-weight:600;padding:3px 9px;border-radius:999px;background:oklch(.94 .08 ${o.c});color:oklch(.45 .14 ${o.c})">${statusLabel[o.status]}</span>
                  <div style="flex:1"></div>
                  <span class="tp-tnum" style="font-size:14px;font-weight:600">฿${o.amount}</span>
                </div>
                <div style="margin-top:8px;font-size:13px;font-weight:500">${o.cust}</div>
                <div style="font-size:12px;color:var(--tp-ink-mute);display:flex;align-items:center;gap:4px;margin-top:2px">
                  ${ic("pin", { size: 12, color: "var(--tp-ink-mute)" })} ${o.addr} · ${o.km} ${tr("กม.", "km")}
                </div>
                <div style="display:flex;align-items:center;margin-top:10px;padding-top:8px;border-top:1px dashed var(--tp-line);font-size:11px;color:var(--tp-ink-mute)">
                  ${ic("cart", { size: 12, color: "var(--tp-ink-mute)" })} ${o.items} ${tr("รายการ", "items")}
                  <span style="margin:0 8px">·</span>
                  ${ic("user", { size: 12, color: "var(--tp-ink-mute)" })} ${o.rider}
                  <div style="flex:1"></div>
                  <span class="tp-mono">${o.eta}</span>
                </div>
              </div>
            `).join("")}
          </div>
        </div>
      </div>
    `;
  }

  /* 17 · STOCK MGMT ─────────────────────────────── */
  function renderStockMgmt() {
    const moves = [
      { id: "MV-2841", t: tr("รับเข้า", "Receive"), item: tr("เมล็ดกาแฟ Arabica", "Arabica beans"), from: "Hillkoff Supply", to: tr("คลังสยาม", "Siam WH"), qty: "+50", unit: tr("ก.ก.", "kg"), val: "฿46,000", time: "08/05 10:24", c: "145", icon: "arrow_down" },
      { id: "MV-2840", t: tr("เบิกผลิต", "Issue"), item: tr("ผงมัทฉะ", "Matcha powder"), from: tr("คลังสยาม", "Siam WH"), to: tr("ครัวร้อน", "Hot kitchen"), qty: "−2.5", unit: tr("ก.ก.", "kg"), val: "฿3,625", time: "08/05 09:12", c: "80", icon: "arrow_up" },
      { id: "MV-2839", t: tr("โอนระหว่างสาขา", "Transfer"), item: tr("นมสด", "Fresh milk"), from: tr("คลังสยาม", "Siam WH"), to: tr("สาขาอโศก", "Asoke branch"), qty: "−12", unit: tr("ลัง", "case"), val: "฿6,960", time: "08/05 08:30", c: "270", icon: "split" },
      { id: "MV-2837", t: tr("รับเข้า", "Receive"), item: tr("หลอดดูดกระดาษ", "Paper straws"), from: "EcoPack", to: tr("คลังสยาม", "Siam WH"), qty: "+1,000", unit: tr("ใบ", "pcs"), val: "฿500", time: "07/05 16:42", c: "145", icon: "arrow_down" },
      { id: "MV-2836", t: tr("ปรับสูญหาย", "Adjust loss"), item: tr("บราวนี่", "Brownie"), from: tr("คลังสยาม", "Siam WH"), to: "—", qty: "−2", unit: tr("ชิ้น", "pcs"), val: "−฿56", time: "07/05 14:08", c: "25", icon: "trash" }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">17 · ${t("stock_mgmt")}</span>
        <span class="screen-meta-size">1440 × 900 · Back office</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("stock_mgmt")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">Stock Movements · ${tr("6 รายการวันนี้", "6 today")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" data-route="inventory" style="height:42px">${ic("box", { size: 16 })} ${t("inventory")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="barcode" style="height:42px">${ic("qr", { size: 16 })} ${t("barcode")}</button>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("plus", { size: 16, color: "white" })} ${tr("รับเข้า", "Receive")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:24px;top:116px;display:grid;grid-template-columns:repeat(5, 1fr);gap:14px">
          ${[
            { l: tr("รับเข้าวันนี้", "Receive today"), v: "฿46,500", icon: "arrow_down", c: "145" },
            { l: tr("เบิกใช้วันนี้", "Issue today"), v: "฿14,820", icon: "arrow_up", c: "80" },
            { l: tr("โอนสาขา", "Transfer"), v: "฿6,960", icon: "split", c: "270" },
            { l: tr("ใกล้หมดอายุ", "Near expiry"), v: tr("8 รายการ", "8 items"), icon: "clock", c: "25" },
            { l: tr("รออนุมัติ PO", "PO pending"), v: tr("3 ใบ", "3 docs"), icon: "receipt", c: "188" }
          ].map(k => `
            <div class="tp-glass" style="padding:14px 18px;display:flex;align-items:center;gap:12px">
              <div style="width:36px;height:36px;border-radius:10px;background:linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}));color:white;display:flex;align-items:center;justify-content:center;box-shadow:0 6px 12px -4px oklch(.62 .14 ${k.c} / .5)">${ic(k.icon, { size: 16, color: "white" })}</div>
              <div>
                <div style="font-size:11px;color:var(--tp-ink-mute)">${k.l}</div>
                <div class="tp-tnum" style="font-size:20px;font-weight:600">${k.v}</div>
              </div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:220px;width:920px;bottom:24px;padding:20px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:12px">
            <div>
              <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ความเคลื่อนไหว", "Movements")}</div>
              <div style="font-size:18px;font-weight:600;margin-top:2px">Stock Ledger</div>
            </div>
            <div style="flex:1"></div>
            ${[t("all"), tr("รับเข้า", "Receive"), tr("เบิก", "Issue"), tr("โอน", "Transfer"), tr("ปรับ", "Adjust")].map((tt, i) => `
              <span class="tp-chip ${i === 0 ? "tp-chip-active" : ""}" style="margin-left:4px">${tt}</span>
            `).join("")}
          </div>
          <div style="display:grid;grid-template-columns:44px 110px 1.6fr 1.4fr 100px 110px 110px;gap:10px;padding:10px 14px;font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.05em;border-bottom:1px solid rgba(20,40,80,.08)">
            <span></span><span>${tr("เลขที่", "No.")}</span><span>${tr("สินค้า / ประเภท", "Item / Type")}</span><span>${tr("ต้นทาง → ปลายทาง", "From → To")}</span><span style="text-align:right">${tr("จำนวน", "Qty")}</span><span style="text-align:right">${tr("มูลค่า", "Value")}</span><span style="text-align:right">${tr("เวลา", "Time")}</span>
          </div>
          <div style="flex:1;overflow:auto">
            ${moves.map(m => `
              <div style="display:grid;grid-template-columns:44px 110px 1.6fr 1.4fr 100px 110px 110px;gap:10px;padding:12px 14px;align-items:center;border-bottom:1px dashed rgba(20,40,80,.06);font-size:13px">
                <div style="width:32px;height:32px;border-radius:9px;background:oklch(.94 .07 ${m.c});color:oklch(.45 .14 ${m.c});display:flex;align-items:center;justify-content:center">${ic(m.icon, { size: 15, color: "oklch(.45 .14 " + m.c + ")" })}</div>
                <span class="tp-mono" style="font-weight:600">${m.id}</span>
                <div>
                  <div style="font-weight:500">${m.item}</div>
                  <div style="font-size:11px;color:oklch(.45 .14 ${m.c});font-weight:500">${m.t}</div>
                </div>
                <div style="font-size:12px">
                  <span style="color:var(--tp-ink-mute)">${m.from}</span>
                  ${ic("arrow_right", { size: 11, color: "var(--tp-ink-mute)" })}
                  <span style="font-weight:500">${m.to}</span>
                </div>
                <div style="text-align:right">
                  <div class="tp-tnum" style="font-weight:600;color:${m.qty.startsWith("−") ? "oklch(.55 .15 25)" : "oklch(.45 .14 150)"}">${m.qty}</div>
                  <div class="tp-mono" style="font-size:10px;color:var(--tp-ink-mute)">${m.unit}</div>
                </div>
                <span class="tp-tnum" style="text-align:right;font-weight:500">${m.val}</span>
                <span class="tp-mono" style="text-align:right;font-size:11px;color:var(--tp-ink-mute)">${m.time}</span>
              </div>
            `).join("")}
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:220px;width:460px;height:280px;padding:20px 24px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("แนะนำสั่งซื้อ", "Reorder suggestion")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:12px">Auto Reorder</div>
          ${[
            { n: tr("ผงมัทฉะ", "Matcha powder"), cur: tr("4 ก.ก.", "4 kg"), sug: tr("+10 ก.ก.", "+10 kg"), v: "฿14,500", c: "80" },
            { n: tr("หลอดดูดกระดาษ", "Paper straws"), cur: tr("380 ใบ", "380 pcs"), sug: "+1,000", v: "฿500", c: "80" },
            { n: tr("บราวนี่", "Brownie"), cur: tr("0 ชิ้น", "0 pcs"), sug: tr("+30", "+30"), v: "฿840", c: "25" }
          ].map((r, i, arr) => `
            <div style="display:flex;padding:10px 0;border-bottom:${i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none"};align-items:center;gap:10px">
              <div style="width:32px;height:32px;border-radius:8px;background:oklch(.94 .07 ${r.c});color:oklch(.45 .14 ${r.c});display:flex;align-items:center;justify-content:center">${ic("bell", { size: 14, color: "oklch(.45 .14 " + r.c + ")" })}</div>
              <div style="flex:1">
                <div style="font-size:13px;font-weight:500">${r.n}</div>
                <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute)">${tr("เหลือ", "Now")} ${r.cur} · ${tr("แนะนำ", "Suggest")} ${r.sug}</div>
              </div>
              <span class="tp-tnum" style="font-size:13px;font-weight:600">${r.v}</span>
              <button class="tp-btn tp-btn-primary" style="height:32px;padding:0 12px;font-size:12px">${tr("สั่ง", "Order")}</button>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:520px;width:460px;bottom:24px;padding:20px 24px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ตำแหน่งคลัง", "Warehouse")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:12px">Bin Map</div>
          <div style="display:grid;grid-template-columns:repeat(4, 1fr);grid-template-rows:repeat(3, 56px);gap:6px">
            ${[
              { l: "A1", c: "188" }, { l: "A2", c: "188" }, { l: "A3", c: "80" }, { l: "A4", c: "188" },
              { l: "B1", c: "188" }, { l: "B2", c: "25" }, { l: "B3", c: "188" }, { l: "B4", c: "145" },
              { l: "C1", c: "145" }, { l: "C2", c: "188" }, { l: "C3", c: "80" }, { l: "C4", c: "188" }
            ].map(b => `
              <div style="border-radius:8px;background:linear-gradient(160deg, oklch(.92 .06 ${b.c}), oklch(.78 .10 ${b.c}));
                box-shadow:inset 0 1px 0 rgba(255,255,255,.6), 0 2px 6px -3px rgba(20,40,80,.15);
                display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:600;color:white;font-family:var(--tp-font-mono)">${b.l}</div>
            `).join("")}
          </div>
          <div style="margin-top:14px;display:flex;gap:14px;font-size:11px">
            <span style="display:flex;align-items:center;gap:4px"><span style="width:8px;height:8px;border-radius:2px;background:oklch(.78 .10 188)"></span> ${tr("ปกติ", "Normal")}</span>
            <span style="display:flex;align-items:center;gap:4px"><span style="width:8px;height:8px;border-radius:2px;background:oklch(.78 .10 80)"></span> ${tr("ใกล้หมด", "Low")}</span>
            <span style="display:flex;align-items:center;gap:4px"><span style="width:8px;height:8px;border-radius:2px;background:oklch(.78 .10 25)"></span> ${tr("หมด", "Out")}</span>
            <span style="display:flex;align-items:center;gap:4px"><span style="width:8px;height:8px;border-radius:2px;background:oklch(.78 .10 145)"></span> ${tr("ของใหม่", "New")}</span>
          </div>
        </div>
      </div>
    `;
  }

  /* 18 · SHIPPING PROVIDERS ─────────────────────────────── */
  function renderShippingProviders() {
    const providers = [
      { n: "Grab Express", short: "GRAB", c: "145", desc: tr("ส่งใน 30 นาที กทม.&ปริมณฑล", "Bangkok 30-min delivery"), linked: true, fee: "฿38–95", orders: 124, sla: "98%" },
      { n: "LINE MAN", short: "LM", c: "145", desc: tr("ฟู้ดและพัสดุ ผูก LINE OA", "Food + parcel via LINE OA"), linked: true, fee: "฿35–80", orders: 86, sla: "96%" },
      { n: "Lalamove", short: "LM2", c: "25", desc: tr("พัสดุใหญ่ มอเตอร์ไซค์ + 4-ล้อ", "Large parcels, bike + truck"), linked: true, fee: "฿55–220", orders: 42, sla: "94%" },
      { n: "Robinhood", short: "RH", c: "188", desc: tr("ฟรีค่า GP สำหรับร้านขนาดเล็ก", "No GP fee for small shops"), linked: false, fee: "—", orders: 0, sla: "—" },
      { n: tr("ไปรษณีย์ไทย", "Thailand Post"), short: "TH", c: "270", desc: tr("EMS / Kerry-light ทั่วประเทศ", "EMS · nationwide"), linked: true, fee: "฿32–150", orders: 28, sla: "92%" },
      { n: "Flash Express", short: "FL", c: "80", desc: tr("ปลายทาง COD รับ 7 วัน/สัปดาห์", "COD · 7 days/week"), linked: true, fee: "฿25–120", orders: 36, sla: "95%" },
      { n: "Kerry Express", short: "KE", c: "25", desc: tr("พัสดุครบวงจร เก็บปลายทางได้", "Full service · COD"), linked: false, fee: "—", orders: 0, sla: "—" },
      { n: "J&T Express", short: "JT", c: "25", desc: tr("ราคาประหยัด เน้นต่างจังหวัด", "Budget · upcountry"), linked: true, fee: "฿28–110", orders: 18, sla: "91%" }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">18 · ${t("shipping_providers")}</span>
        <span class="screen-meta-size">1440 × 900 · Operations</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("shipping_providers")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("เชื่อมต่อ Logistics Partner · 6 พร้อมใช้", "6 logistics partners connected")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" data-route="admin" style="height:42px">${ic("settings", { size: 16 })} ${tr("ตั้งค่า API", "API settings")}</button>
            <button class="tp-btn tp-btn-primary" data-route="shipping_label" style="height:42px">${ic("printer", { size: 16, color: "white" })} ${tr("พิมพ์ใบปะหน้า", "Print labels")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:24px;top:116px;display:grid;grid-template-columns:repeat(4, 1fr);gap:16px">
          ${[
            { l: tr("พัสดุที่จะส่งวันนี้", "Outbound today"), v: "47", c: "188", icon: "box" },
            { l: tr("เรียกรถสำเร็จ", "Pickup success"), v: "32", c: "145", icon: "check" },
            { l: tr("รอเรียกรถ", "Pending pickup"), v: "12", c: "80", icon: "clock" },
            { l: tr("ค่าขนส่งวันนี้", "Shipping cost"), v: "฿2,840", c: "270", icon: "cash" }
          ].map(k => `
            <div class="tp-glass" style="padding:16px 22px;display:flex;align-items:center;gap:14px">
              <div style="width:44px;height:44px;border-radius:12px;background:linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}));color:white;display:flex;align-items:center;justify-content:center;box-shadow:0 6px 14px -4px oklch(.62 .14 ${k.c} / .5)">${ic(k.icon, { size: 18, color: "white" })}</div>
              <div>
                <div style="font-size:12px;color:var(--tp-ink-mute)">${k.l}</div>
                <div class="tp-tnum" style="font-size:26px;font-weight:600;letter-spacing:-.02em;margin-top:2px">${k.v}</div>
              </div>
            </div>
          `).join("")}
        </div>

        <div style="position:absolute;left:24px;right:24px;top:240px;bottom:24px;display:grid;grid-template-columns:repeat(4, 1fr);grid-auto-rows:minmax(0, 1fr);gap:16px">
          ${providers.map(p => `
            <div class="tp-glass" style="padding:20px;display:flex;flex-direction:column;position:relative;overflow:hidden">
              <div style="position:absolute;right:-20px;top:-20px;width:110px;height:110px;border-radius:50%;background:radial-gradient(circle, oklch(.85 .14 ${p.c} / .35), transparent 70%);filter:blur(10px)"></div>
              <div style="display:flex;align-items:center;gap:12px">
                <div style="width:48px;height:48px;border-radius:14px;
                  background:linear-gradient(160deg, oklch(.85 .14 ${p.c}), oklch(.55 .14 ${p.c}));color:white;display:flex;align-items:center;justify-content:center;
                  font-weight:700;font-size:14px;letter-spacing:-.01em;
                  box-shadow:0 8px 16px -6px oklch(.55 .14 ${p.c} / .5), inset 0 1px 0 rgba(255,255,255,.5);font-family:var(--tp-font-mono)">${p.short}</div>
                <div style="flex:1;min-width:0">
                  <div style="font-size:14px;font-weight:600">${p.n}</div>
                  <div style="font-size:11px;color:${p.linked ? "oklch(.45 .14 150)" : "var(--tp-ink-mute)"};font-weight:500;display:flex;align-items:center;gap:4px;margin-top:2px">
                    <span style="width:6px;height:6px;border-radius:50%;background:${p.linked ? "oklch(.62 .14 150)" : "oklch(.75 .03 230)"}"></span>
                    ${p.linked ? tr("เชื่อมแล้ว", "Connected") : tr("ยังไม่เชื่อม", "Not connected")}
                  </div>
                </div>
              </div>
              <div style="font-size:12px;color:var(--tp-ink-soft);margin-top:10px;line-height:1.4;flex:1">${p.desc}</div>
              <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px;margin-top:12px;padding-top:12px;border-top:1px dashed var(--tp-line)">
                <div><div style="font-size:10px;color:var(--tp-ink-mute)">${tr("ค่าส่ง", "Fee")}</div><div class="tp-mono" style="font-size:11px;font-weight:600">${p.fee}</div></div>
                <div><div style="font-size:10px;color:var(--tp-ink-mute)">${tr("ออเดอร์", "Orders")}</div><div class="tp-tnum" style="font-size:13px;font-weight:600">${p.orders}</div></div>
                <div><div style="font-size:10px;color:var(--tp-ink-mute)">SLA</div><div class="tp-tnum" style="font-size:13px;font-weight:600">${p.sla}</div></div>
              </div>
              <button data-route="${p.linked ? "shipping_label" : "admin"}" style="margin-top:12px;height:36px;border-radius:10px;font-family:inherit;font-size:12px;font-weight:500;cursor:pointer;
                border:${p.linked ? "1px solid var(--tp-line)" : "none"};
                background:${p.linked ? "white" : "linear-gradient(160deg, oklch(.62 .14 195), oklch(.45 .14 220))"};
                color:${p.linked ? "var(--tp-ink)" : "white"};
                box-shadow:${p.linked ? "none" : "0 6px 14px -6px oklch(.50 .14 220 / .55)"}">${p.linked ? tr("เรียกรถ", "Call pickup") : tr("เชื่อมต่อ", "Connect")}</button>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* 19 · COUPONS ─────────────────────────────── */
  function renderCoupons() {
    const coupons = [
      { code: "SUMMER25", t: tr("ลด 25%", "25% off"), on: tr("ทุกเมนูเย็น", "All cold drinks"), used: 184, lim: 500, exp: tr("31 พ.ค.", "31 May"), c: "188", status: "active" },
      { code: "FREEDLV", t: tr("ส่งฟรี", "Free delivery"), on: tr("ออเดอร์ ≥ ฿200", "Orders ≥ ฿200"), used: 96, lim: "—", exp: tr("ไม่จำกัด", "Unlimited"), c: "145", status: "active" },
      { code: "WELCOME50", t: tr("ลด ฿50", "฿50 off"), on: tr("ลูกค้าใหม่", "New customers"), used: 248, lim: 1000, exp: tr("ต่ออัตโนมัติ", "Auto-renew"), c: "270", status: "active" },
      { code: "SONGKRAN", t: tr("ซื้อ 1 แถม 1", "1+1"), on: tr("13–15 เม.ย.", "13–15 Apr"), used: 642, lim: 642, exp: tr("หมดแล้ว", "Ended"), c: "25", status: "ended" },
      { code: "BDAY100", t: tr("ลด ฿100", "฿100 off"), on: tr("วันเกิดสมาชิก", "Member birthday"), used: 38, lim: "—", exp: tr("ตลอดปี", "All year"), c: "80", status: "active" },
      { code: "VIPGOLD", t: tr("ลด 15%", "15% off"), on: tr("สมาชิก Gold", "Gold members"), used: 24, lim: "—", exp: tr("ไม่จำกัด", "Unlimited"), c: "80", status: "active" }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">19 · ${t("coupons")}</span>
        <span class="screen-meta-size">1440 × 900 · Marketing</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("coupons")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("5 แคมเปญใช้งาน · 1,232 ครั้ง/เดือน", "5 active campaigns · 1,232 redemptions/mo")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" data-route="dashboard" style="height:42px">${ic("chart", { size: 16 })} ROI</button>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("plus", { size: 16, color: "white" })} ${tr("สร้างคูปอง", "New coupon")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:24px;top:116px;display:grid;grid-template-columns:repeat(4, 1fr);gap:16px">
          ${[
            { l: tr("ใช้คูปองวันนี้", "Used today"), v: "84", c: "188" },
            { l: tr("ส่วนลดรวมเดือนนี้", "Discount total"), v: "฿42,580", c: "25" },
            { l: "Conversion Rate", v: "32.4%", c: "270" },
            { l: tr("ROI ของแคมเปญ", "Campaign ROI"), v: "4.2×", c: "145" }
          ].map(k => `
            <div class="tp-glass" style="padding:18px 22px">
              <div style="font-size:12px;color:var(--tp-ink-mute)">${k.l}</div>
              <div class="tp-tnum" style="font-size:28px;font-weight:600;letter-spacing:-.02em;margin-top:4px;color:oklch(.45 .14 ${k.c})">${k.v}</div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:240px;right:380px;bottom:24px;padding:20px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:14px">
            <div>
              <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("คูปองทั้งหมด", "All coupons")}</div>
              <div style="font-size:18px;font-weight:600;margin-top:2px">Active Campaigns</div>
            </div>
            <div style="flex:1"></div>
            ${[t("all"), tr("ใช้งาน", "Active"), tr("หมดอายุ", "Ended"), tr("ร่าง", "Draft")].map((tt, i) => `
              <span class="tp-chip ${i === 0 ? "tp-chip-active" : ""}" style="margin-left:4px">${tt}</span>
            `).join("")}
          </div>

          <div style="flex:1;overflow:auto;display:grid;grid-template-columns:1fr 1fr;gap:14px;align-content:start;padding-right:4px">
            ${coupons.map(c => `
              <div style="position:relative;border-radius:16px;padding:16px 20px;
                background:${c.status === "ended" ? "linear-gradient(140deg, oklch(.95 .01 230), oklch(.92 .01 230))" : `linear-gradient(140deg, oklch(.96 .04 ${c.c}), oklch(.92 .06 ${c.c}))`};
                border:1px solid oklch(.85 .06 ${c.c});opacity:${c.status === "ended" ? 0.6 : 1};overflow:hidden;min-height:156px">
                <div style="position:absolute;left:-8px;top:50%;width:16px;height:16px;border-radius:50%;background:white;margin-top:-8px"></div>
                <div style="position:absolute;right:-8px;top:50%;width:16px;height:16px;border-radius:50%;background:white;margin-top:-8px"></div>
                <div style="display:flex;align-items:center;gap:12px">
                  <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(160deg, oklch(.85 .14 ${c.c}), oklch(.55 .14 ${c.c}));color:white;display:flex;align-items:center;justify-content:center;
                    font-size:18px;font-weight:700;
                    box-shadow:0 6px 14px -6px oklch(.55 .14 ${c.c} / .5), inset 0 1px 0 rgba(255,255,255,.5)">${ic("tag", { size: 20, color: "white" })}</div>
                  <div style="flex:1">
                    <div style="font-size:16px;font-weight:700;color:oklch(.40 .14 ${c.c})">${c.t}</div>
                    <div style="font-size:12px;color:var(--tp-ink-soft)">${c.on}</div>
                  </div>
                  <div style="font-size:10px;font-weight:700;padding:3px 10px;border-radius:999px;background:${c.status === "active" ? "oklch(.94 .08 145)" : "oklch(.94 .03 230)"};color:${c.status === "active" ? "oklch(.45 .14 150)" : "var(--tp-ink-mute)"};text-transform:uppercase;letter-spacing:.05em">${c.status === "active" ? tr("ใช้งาน", "ACTIVE") : tr("หมดแล้ว", "ENDED")}</div>
                </div>
                <div style="margin-top:14px;padding-top:12px;border-top:1px dashed oklch(.75 .08 ${c.c} / .5);display:flex;align-items:center">
                  <div class="tp-mono" style="font-size:13px;font-weight:700;letter-spacing:.15em;color:oklch(.40 .14 ${c.c})">${c.code}</div>
                  <div style="flex:1"></div>
                  <div class="tp-mono" style="font-size:10px;color:var(--tp-ink-mute)">${tr("หมด", "Exp")}: ${c.exp}</div>
                </div>
                <div style="margin-top:8px;display:flex;align-items:center;gap:10px">
                  <div style="flex:1;height:5px;background:rgba(20,40,80,.08);border-radius:999px;overflow:hidden">
                    <div style="height:100%;width:${c.lim === "—" ? 30 : Math.min(100, (c.used / c.lim) * 100)}%;background:linear-gradient(90deg, oklch(.78 .14 ${c.c}), oklch(.55 .14 ${c.c}))"></div>
                  </div>
                  <span class="tp-mono" style="font-size:11px;font-weight:600">${c.used}/${c.lim}</span>
                </div>
              </div>
            `).join("")}
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:240px;width:332px;bottom:24px;padding:20px 22px;display:flex;flex-direction:column">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ใช้งานสูงสุดสัปดาห์นี้", "Top this week")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:14px">Top Performers</div>
          ${[
            { c: "WELCOME50", v: 248, p: 100, hue: 270 },
            { c: "SUMMER25", v: 184, p: 74, hue: 188 },
            { c: "FREEDLV", v: 96, p: 39, hue: 145 },
            { c: "BDAY100", v: 38, p: 15, hue: 80 }
          ].map(b => `
            <div style="margin-bottom:12px">
              <div style="display:flex;justify-content:space-between;margin-bottom:4px">
                <span class="tp-mono" style="font-size:12px;font-weight:600">${b.c}</span>
                <span class="tp-tnum" style="font-size:12px;font-weight:600">${b.v}</span>
              </div>
              <div style="height:8px;background:rgba(20,40,80,.06);border-radius:999px;overflow:hidden">
                <div style="height:100%;width:${b.p}%;background:linear-gradient(90deg, oklch(.78 .12 ${b.hue}), oklch(.55 .14 ${b.hue}));border-radius:999px"></div>
              </div>
            </div>
          `).join("")}
          <div style="flex:1"></div>
          <div style="margin-top:16px;padding:16px;border-radius:14px;position:relative;overflow:hidden;
            background:linear-gradient(140deg, oklch(.50 .14 250), oklch(.30 .12 270));color:white;
            box-shadow:0 14px 28px -14px oklch(.30 .12 270 / .55)">
            <div style="position:absolute;right:-30px;top:-30px;width:120px;height:120px;border-radius:50%;background:radial-gradient(circle, oklch(.85 .14 80 / .35), transparent 70%)"></div>
            <div style="font-size:11px;opacity:.8;text-transform:uppercase;letter-spacing:.1em">Preview</div>
            <div style="font-size:22px;font-weight:700;margin-top:6px">${tr("ลด ฿100", "฿100 off")}</div>
            <div style="font-size:11px;opacity:.85">${tr("วันเกิดสมาชิก", "Member birthday")}</div>
            <div class="tp-mono" style="margin-top:14px;padding:6px 10px;border-radius:8px;background:rgba(255,255,255,.18);border:1px dashed rgba(255,255,255,.35);font-weight:700;letter-spacing:.15em;text-align:center;font-size:14px">BDAY100</div>
          </div>
        </div>
      </div>
    `;
  }

  /* 20 · STAFF ─────────────────────────────── */
  function renderStaff() {
    const staff = [
      { name: tr("นัทธมน ปัญญาวิทย์", "Nattamon P."), nick: "นัท", role: tr("ผู้จัดการสาขา", "Branch mgr"), branch: tr("สยาม", "Siam"), on: true, hours: "07:00–19:00", sales: "฿42,580", c: "270" },
      { name: tr("ณัฐภัทร เพิ่มศรี", "Natpat S."), nick: "เก่ง", role: t("cashier"), branch: tr("สยาม", "Siam"), on: true, hours: "08:00–17:00", sales: "฿18,420", c: "188" },
      { name: tr("พิชชา ภูริทัตต์", "Picha P."), nick: "พิช", role: tr("บาริสต้า", "Barista"), branch: tr("สยาม", "Siam"), on: true, hours: "06:30–15:30", sales: "฿14,580", c: "145" },
      { name: tr("ธีรเทพ มงคลรัตน์", "Theerathep M."), nick: "เต้", role: tr("ไรเดอร์", "Rider"), branch: tr("สยาม", "Siam"), on: true, hours: "09:00–20:00", sales: "฿8,420", c: "80" },
      { name: tr("สุนิสา จันทรา", "Sunisa C."), nick: "ฝน", role: tr("บาริสต้า", "Barista"), branch: tr("สยาม", "Siam"), on: false, hours: tr("วันหยุด", "Off"), sales: "—", c: "230" },
      { name: tr("ณภัทร ศิริสุข", "Naphat S."), nick: "นัท", role: tr("พนักงานเสิร์ฟ", "Server"), branch: tr("อโศก", "Asoke"), on: true, hours: "10:00–22:00", sales: "฿9,820", c: "25" },
      { name: tr("อัจฉรา ดวงสว่าง", "Aut-chara D."), nick: "หลิน", role: tr("บาริสต้า", "Barista"), branch: tr("อโศก", "Asoke"), on: true, hours: "07:00–16:00", sales: "฿16,240", c: "188" }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">20 · ${t("staff")}</span>
        <span class="screen-meta-size">1440 × 900 · HR</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("staff")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("8 คน · กำลังทำงาน 6 · กะเช้า 4 / กะบ่าย 2", "8 people · 6 working · morning 4 / evening 2")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" style="height:42px">${ic("clock", { size: 16 })} ${tr("ตารางกะ", "Schedule")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="accounting" style="height:42px">${ic("receipt", { size: 16 })} ${tr("เงินเดือน", "Payroll")}</button>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("plus", { size: 16, color: "white" })} ${tr("เพิ่มพนักงาน", "Add staff")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:24px;top:116px;display:grid;grid-template-columns:repeat(4, 1fr);gap:16px">
          ${[
            { l: tr("พนักงานทั้งหมด", "All staff"), v: tr("24 คน", "24"), c: "270" },
            { l: tr("กำลังทำงาน", "On duty"), v: tr("16 คน", "16"), c: "145" },
            { l: tr("ยอดขาย/คน เฉลี่ย", "Avg sales/person"), v: "฿14,580", c: "188" },
            { l: tr("เงินเดือนเดือนนี้", "Payroll"), v: "฿184,000", c: "80" }
          ].map(k => `
            <div class="tp-glass" style="padding:18px 22px">
              <div style="font-size:12px;color:var(--tp-ink-mute)">${k.l}</div>
              <div class="tp-tnum" style="font-size:28px;font-weight:600;letter-spacing:-.02em;margin-top:4px;color:oklch(.40 .14 ${k.c})">${k.v}</div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:240px;right:380px;bottom:24px;padding:20px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:12px">
            <div style="flex:0 0 280px;height:38px;background:white;border-radius:12px;border:1px solid var(--tp-line);display:flex;align-items:center;padding:0 14px;gap:8px">
              ${ic("search", { size: 14, color: "var(--tp-ink-mute)" })}
              <input placeholder="${tr("ค้นหาชื่อ / ตำแหน่ง...", "Search name / role...")}" style="flex:1;border:none;background:transparent;outline:none;font-family:inherit;font-size:13px"/>
            </div>
            <div style="flex:1"></div>
            ${[t("all"), tr("ผู้จัดการ", "Manager"), t("cashier"), tr("บาริสต้า", "Barista"), tr("ไรเดอร์", "Rider")].map((tt, i) => `
              <span class="tp-chip ${i === 0 ? "tp-chip-active" : ""}" style="margin-left:4px">${tt}</span>
            `).join("")}
          </div>
          <div style="display:grid;grid-template-columns:44px 2.2fr 1.2fr 1fr 1fr 1.1fr 80px;gap:12px;padding:10px 14px;font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.05em;border-bottom:1px solid rgba(20,40,80,.08)">
            <span></span><span>${tr("ชื่อ", "Name")}</span><span>${tr("ตำแหน่ง", "Role")}</span><span>${tr("สาขา", "Branch")}</span><span>${tr("เวลา", "Hours")}</span><span style="text-align:right">${tr("ยอดวันนี้", "Today's sales")}</span><span></span>
          </div>
          <div style="flex:1;overflow:auto">
            ${staff.map(s => `
              <div style="display:grid;grid-template-columns:44px 2.2fr 1.2fr 1fr 1fr 1.1fr 80px;gap:12px;padding:12px 14px;align-items:center;border-bottom:1px dashed rgba(20,40,80,.06);font-size:13px">
                <div style="position:relative">
                  <div style="width:36px;height:36px;border-radius:50%;background:linear-gradient(160deg, oklch(.85 .14 ${s.c}), oklch(.55 .14 ${s.c}));color:white;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;box-shadow:0 4px 10px -4px oklch(.55 .14 ${s.c} / .5)">${s.nick.slice(0, 1)}</div>
                  <div style="position:absolute;right:-2px;bottom:-2px;width:12px;height:12px;border-radius:50%;background:${s.on ? "oklch(.62 .14 150)" : "oklch(.75 .03 230)"};border:2px solid white"></div>
                </div>
                <div>
                  <div style="font-weight:500">${s.name}</div>
                  <div style="font-size:11px;color:var(--tp-ink-mute)">"${s.nick}"</div>
                </div>
                <span class="tp-chip" style="height:24px;font-size:11px;padding:0 10px">${s.role}</span>
                <span style="color:var(--tp-ink-soft)">${s.branch}</span>
                <span class="tp-mono" style="font-size:12px;color:${s.on ? "var(--tp-ink)" : "var(--tp-ink-mute)"}">${s.hours}</span>
                <span class="tp-tnum" style="text-align:right;font-weight:600">${s.sales}</span>
                <button style="width:28px;height:28px;border-radius:8px;border:1px solid var(--tp-line);background:white;cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--tp-ink-soft);justify-self:end">${ic("more", { size: 13 })}</button>
              </div>
            `).join("")}
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:240px;width:332px;height:300px;padding:20px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ตารางกะวันนี้", "Today's shifts")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:14px">${tr("กะ 08 พ.ค.", "Shifts 08 May")}</div>
          ${[
            { n: tr("นัท", "Nat"), s: 7, e: 19, c: "270" },
            { n: tr("เก่ง", "Geng"), s: 8, e: 17, c: "188" },
            { n: tr("พิช", "Pich"), s: 6.5, e: 15.5, c: "145" },
            { n: tr("เต้", "Tay"), s: 9, e: 20, c: "80" }
          ].map(s => {
            const left = ((s.s - 6) / 14) * 100;
            const width = ((s.e - s.s) / 14) * 100;
            return `
              <div style="display:flex;align-items:center;margin-bottom:10px">
                <span style="width:32px;font-size:11px;font-weight:600;color:var(--tp-ink-soft)">${s.n}</span>
                <div style="flex:1;height:22px;background:rgba(20,40,80,.05);border-radius:6px;position:relative">
                  <div style="position:absolute;left:${left}%;width:${width}%;top:0;bottom:0;border-radius:6px;background:linear-gradient(90deg, oklch(.78 .12 ${s.c}), oklch(.55 .14 ${s.c}));color:white;font-size:10px;font-weight:600;display:flex;align-items:center;padding-left:6px;font-family:var(--tp-font-mono)">${s.s}–${s.e}</div>
                </div>
              </div>
            `;
          }).join("")}
          <div style="display:flex;justify-content:space-between;margin-top:8px;font-size:10px;color:var(--tp-ink-mute);font-family:var(--tp-font-mono)">
            ${["06", "10", "14", "18", "22"].map(t1 => `<span>${t1}h</span>`).join("")}
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:560px;width:332px;bottom:24px;padding:20px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ผู้นำยอดขาย", "Sales leaderboard")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:12px">${tr("Top วันนี้", "Top today")}</div>
          ${[
            { n: tr("นัทธมน", "Nattamon"), s: "฿42,580", c: "80" },
            { n: tr("อัจฉรา", "Aut-chara"), s: "฿16,240", c: "230" },
            { n: tr("พิชชา", "Picha"), s: "฿14,580", c: "25" },
            { n: tr("ณัฐภัทร", "Natpat"), s: "฿18,420", c: "270" }
          ].map((s, i, arr) => `
            <div style="display:flex;align-items:center;padding:10px 0;border-bottom:${i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none"};gap:10px">
              <div style="width:28px;height:28px;border-radius:50%;
                background:${i < 3 ? `linear-gradient(160deg, oklch(.85 .14 ${s.c}), oklch(.55 .14 ${s.c}))` : "oklch(.94 .03 230)"};
                color:${i < 3 ? "white" : "var(--tp-ink-mute)"};display:flex;align-items:center;justify-content:center;font-weight:700;font-size:12px">${i + 1}</div>
              <span style="flex:1;font-size:13px;font-weight:500">${s.n}</span>
              <span class="tp-tnum" style="font-size:13px;font-weight:600">${s.s}</span>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* 21 · ADMIN ─────────────────────────────── */
  function renderAdmin() {
    const sections = [
      { i: "tag", t: tr("ข้อมูลร้านค้า", "Shop info"), c: "188", route: null },
      { i: "users", t: tr("ผู้ใช้ & สิทธิ์", "Users & roles"), c: "270", route: null, active: true },
      { i: "receipt", t: tr("ภาษี & ใบกำกับ", "Tax & invoice"), c: "25", route: "tax_invoice" },
      { i: "pin", t: tr("สาขา", "Branches"), c: "145", route: null },
      { i: "monitor", t: tr("อุปกรณ์ POS", "POS devices"), c: "80", route: null },
      { i: "card", t: tr("ช่องทางชำระ", "Payment methods"), c: "188", route: "payment" },
      { i: "split", t: tr("เชื่อมต่อระบบ", "Integrations"), c: "230", route: "shipping_providers" },
      { i: "settings", t: tr("ความปลอดภัย", "Security"), c: "25", route: null },
      { i: "box", t: tr("สำรองข้อมูล", "Backup"), c: "270", route: "sync_api" }
    ];
    const roles = [
      { r: tr("เจ้าของร้าน", "Owner"), count: 1, p: [tr("ทั้งหมด", "All")], c: "270", desc: tr("เข้าถึงทุกระบบ", "Access everything") },
      { r: tr("ผู้จัดการสาขา", "Branch manager"), count: 3, p: [tr("ขาย", "Sell"), t("staff"), tr("คลัง", "Stock"), tr("รายงาน", "Reports")], c: "188", desc: tr("จัดการสาขาที่ดูแล", "Manage own branch") },
      { r: tr("หัวหน้าแคชเชียร์", "Cashier lead"), count: 2, p: [tr("ขาย", "Sell"), t("discount"), "Void"], c: "145", desc: tr("อนุมัติส่วนลด/ยกเลิกบิล", "Approve discounts/voids") },
      { r: t("cashier"), count: 8, p: [tr("ขาย", "Sell"), tr("พิมพ์ใบเสร็จ", "Print receipt")], c: "80", desc: tr("ขายเท่านั้น", "Sales only") },
      { r: tr("บาริสต้า / ครัว", "Barista / Kitchen"), count: 6, p: ["KDS"], c: "25", desc: tr("ดูเฉพาะหน้าครัว", "Kitchen view only") },
      { r: tr("ไรเดอร์", "Rider"), count: 4, p: [t("delivery")], c: "230", desc: tr("อัปเดตสถานะส่ง", "Update delivery status") }
    ];
    const toggles = [
      { l: tr("เปิดใช้ระบบสมาชิก", "Enable members"), on: true },
      { l: tr("บังคับปิดกะก่อนล็อกเอาต์", "Force close shift on logout"), on: true },
      { l: tr("อนุมัติ Void อัตโนมัติ < ฿100", "Auto approve void < ฿100"), on: false },
      { l: tr("พิมพ์ใบเสร็จอัตโนมัติ", "Auto print receipt"), on: true },
      { l: tr("ส่ง e-Tax ทันที", "Send e-Tax immediately"), on: true },
      { l: tr("เก็บ log ทุกธุรกรรม 7 ปี", "Keep audit log 7 years"), on: true }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">21 · ${t("admin")}</span>
        <span class="screen-meta-size">1440 × 900 · System</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("admin")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("ผู้ใช้ 24 คน · 5 สาขา · 12 อุปกรณ์ · เวอร์ชัน 4.2.1", "24 users · 5 branches · 12 devices · v4.2.1")}</div>
            </div>
            <div style="flex:1"></div>
            <span class="tp-chip tp-chip-success">${ic("check", { size: 13 })} ${tr("เชื่อมต่อปกติ", "All connected")}</span>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("check", { size: 16, color: "white" })} ${tr("บันทึก", "Save settings")}</button>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:116px;width:260px;bottom:24px;padding:14px">
          <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.08em;padding:8px 10px">${tr("ตั้งค่าระบบ", "System settings")}</div>
          ${sections.map(s => `
            <div ${s.route ? `data-route="${s.route}"` : ""} style="display:flex;align-items:center;gap:10px;padding:11px 12px;margin-bottom:4px;border-radius:11px;cursor:pointer;font-size:13px;font-weight:500;
              background:${s.active ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent"};
              color:${s.active ? "white" : "var(--tp-ink-soft)"};
              box-shadow:${s.active ? "0 6px 14px -8px oklch(.25 .07 265 / .55)" : "none"}">
              <div style="width:28px;height:28px;border-radius:8px;background:${s.active ? "rgba(255,255,255,.2)" : "oklch(.94 .07 " + s.c + ")"};color:${s.active ? "white" : "oklch(.45 .14 " + s.c + ")"};display:flex;align-items:center;justify-content:center">${ic(s.i, { size: 14, color: s.active ? "white" : "oklch(.45 .14 " + s.c + ")" })}</div>
              <span style="flex:1">${s.t}</span>
              ${ic("arrow_right", { size: 12, color: s.active ? "white" : "var(--tp-ink-mute)" })}
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;left:304px;top:116px;right:380px;bottom:24px;padding:22px">
          <div style="display:flex;align-items:flex-end;margin-bottom:18px">
            <div>
              <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ผู้ใช้ & บทบาท", "Users & Roles")}</div>
              <div style="font-size:22px;font-weight:700;margin-top:2px">Roles & Permissions</div>
              <div style="font-size:12px;color:var(--tp-ink-mute);margin-top:4px">${tr("กำหนดสิทธิ์เข้าถึงสำหรับแต่ละบทบาท", "Configure access for each role")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" style="height:38px">${ic("plus", { size: 14 })} ${tr("สร้างบทบาท", "Add role")}</button>
          </div>
          <div style="display:grid;gap:10px">
            ${roles.map(r => `
              <div style="padding:14px 18px;border-radius:14px;background:white;border:1px solid var(--tp-line);box-shadow:0 4px 10px -6px rgba(20,40,80,.08);border-left:4px solid oklch(.65 .14 ${r.c});display:flex;align-items:center;gap:14px">
                <div style="width:44px;height:44px;border-radius:12px;background:linear-gradient(160deg, oklch(.85 .14 ${r.c}), oklch(.55 .14 ${r.c}));color:white;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:16px;box-shadow:0 4px 10px -4px oklch(.55 .14 ${r.c} / .5)">${r.count}</div>
                <div style="flex:1">
                  <div style="font-size:14px;font-weight:600">${r.r}</div>
                  <div style="font-size:12px;color:var(--tp-ink-mute);margin-top:2px">${r.desc}</div>
                </div>
                <div style="display:flex;gap:4px;flex-wrap:wrap;max-width:320px;justify-content:flex-end">
                  ${r.p.map(perm => `<span class="tp-chip" style="height:22px;font-size:10px;padding:0 8px;background:oklch(.94 .07 ${r.c});color:oklch(.40 .14 ${r.c});border-color:oklch(.85 .08 ${r.c})">${perm}</span>`).join("")}
                </div>
                <button style="width:30px;height:30px;border-radius:8px;border:1px solid var(--tp-line);background:white;cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--tp-ink-soft)">${ic("more", { size: 14 })}</button>
              </div>
            `).join("")}
          </div>
          <div style="margin-top:22px;padding:16px;border-radius:14px;background:oklch(.96 .03 220);border:1px solid oklch(.85 .04 220);display:flex;align-items:center;gap:12px">
            <div style="width:36px;height:36px;border-radius:10px;background:linear-gradient(160deg, oklch(.78 .12 195), oklch(.55 .14 220));color:white;display:flex;align-items:center;justify-content:center">${ic("settings", { size: 16, color: "white" })}</div>
            <div style="flex:1">
              <div style="font-size:13px;font-weight:600">${tr("ตารางสิทธิ์ละเอียด", "Permission matrix")}</div>
              <div style="font-size:11px;color:var(--tp-ink-mute)">${tr("กำหนด Read/Write/Approve รายฟีเจอร์", "Configure Read/Write/Approve per feature")}</div>
            </div>
            <button class="tp-btn tp-btn-ghost" style="height:36px">${tr("เปิด", "Open")}</button>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:116px;width:332px;height:340px;padding:20px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("การตั้งค่าด่วน", "Quick settings")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:14px">Quick Toggles</div>
          ${toggles.map((t1, i, arr) => `
            <div style="display:flex;align-items:center;padding:8px 0;border-bottom:${i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none"}">
              <span style="flex:1;font-size:13px">${t1.l}</span>
              <div style="width:38px;height:22px;border-radius:999px;background:${t1.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)"};position:relative;cursor:pointer;
                box-shadow:${t1.on ? "inset 0 1px 0 rgba(255,255,255,.25), 0 4px 10px -4px oklch(.50 .14 220 / .5)" : "inset 0 1px 2px rgba(20,40,80,.08)"}">
                <div style="position:absolute;top:2px;left:${t1.on ? 18 : 2}px;width:18px;height:18px;border-radius:50%;background:white;box-shadow:0 2px 4px rgba(20,40,80,.2);transition:all .2s"></div>
              </div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:476px;width:332px;bottom:24px;padding:20px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">Audit Log</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:12px">${tr("กิจกรรมล่าสุด", "Recent activity")}</div>
          ${[
            { u: tr("นัท", "Nat"), a: tr("อนุมัติ Void บิล A1038", "Approved void A1038"), t: "14:42", c: "25" },
            { u: tr("เก่ง", "Geng"), a: tr("ใช้คูปอง WELCOME50", "Redeemed WELCOME50"), t: "14:38", c: "188" },
            { u: "Owner", a: tr("เพิ่มผู้ใช้ ฝน (บาริสต้า)", "Added user Fon (Barista)"), t: "13:20", c: "270" },
            { u: tr("นัท", "Nat"), a: tr("เปลี่ยนราคา ชาไทย ฿55→฿65", "Price change Thai Tea ฿55→฿65"), t: "12:14", c: "80" }
          ].map((l, i, arr) => `
            <div style="display:flex;padding:10px 0;border-bottom:${i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none"};gap:10px">
              <div style="width:28px;height:28px;border-radius:50%;background:linear-gradient(160deg, oklch(.85 .12 ${l.c}), oklch(.55 .14 ${l.c}));color:white;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:11px;flex-shrink:0">${l.u.slice(0, 1)}</div>
              <div style="flex:1;min-width:0">
                <div style="font-size:12px;font-weight:500">${l.u} · ${l.a}</div>
                <div class="tp-mono" style="font-size:10px;color:var(--tp-ink-mute)">${tr("วันนี้", "Today")} ${l.t}</div>
              </div>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* 22 · BARCODE MANAGER ─────────────────────────────── */
  function renderBarcode() {
    const items = [
      { sku: "ESP-001", name: tr("เอสเปรสโซ่ ดับเบิ้ลช็อต", "Espresso double shot"), code: "8851234567001", type: "EAN-13", price: "฿65", qty: 482, c: "25" },
      { sku: "LATTE-002", name: tr("ลาเต้ร้อน 12oz", "Hot Latte 12oz"), code: "8851234567025", type: "EAN-13", price: "฿85", qty: 360, c: "188", selected: true },
      { sku: "MATCHA-018", name: tr("มัทฉะลาเต้เย็น", "Iced Matcha Latte"), code: "8851234568018", type: "EAN-13", price: "฿95", qty: 145, c: "145" },
      { sku: "BREW-CR-005", name: tr("ครัวซองต์อัลมอนด์", "Almond Croissant"), code: "8851234560205", type: "EAN-13", price: "฿95", qty: 28, c: "80" },
      { sku: "BREW-BR-012", name: tr("บราวนี่", "Brownie"), code: "8851234560312", type: "EAN-13", price: "฿85", qty: 0, c: "25" },
      { sku: "MERCH-T-001", name: tr("เสื้อยืดโลโก้ M", "Logo Tee M"), code: "TP-MERCH-001M", type: "Code 128", price: "฿590", qty: 24, c: "270" },
      { sku: "BEAN-AR-200", name: tr("เมล็ดกาแฟ Arabica 200g", "Arabica beans 200g"), code: "8851234567890", type: "EAN-13", price: "฿380", qty: 86, c: "25" }
    ];

    const fakeBarcodeBars = (code, count) => Array.from({ length: count }).map((_, j) => {
      const w = ((code.charCodeAt(j % code.length) + j) % 4) + 1;
      const filled = ((code.charCodeAt(j % code.length) >> (j % 5)) & 1);
      return `<div style="width:${w}px;height:100%;background:${filled ? "var(--tp-ink)" : "transparent"}"></div>`;
    }).join("");

    return `
      <div class="screen-meta">
        <span class="screen-meta-label">22 · ${t("barcode")}</span>
        <span class="screen-meta-size">1440 × 900 · Operations</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("barcode")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("247 รายการ · พิมพ์วันนี้ 1,420 ดวง", "247 SKUs · 1,420 printed today")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" style="height:42px">${ic("qr", { size: 16 })} ${tr("สแกนทดสอบ", "Test scan")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="inventory" style="height:42px">${ic("box", { size: 16 })} ${t("inventory")}</button>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("printer", { size: 16, color: "white" })} ${tr("พิมพ์ฉลาก", "Print labels")}</button>
          </div>
        </div>

        <div style="position:absolute;left:24px;right:24px;top:116px;display:grid;grid-template-columns:repeat(4, 1fr);gap:16px">
          ${[
            { l: tr("บาร์โค้ดในระบบ", "Barcodes in system"), v: "247", c: "188" },
            { l: tr("ยังไม่ผูก", "Not linked"), v: "12", c: "25" },
            { l: tr("พิมพ์วันนี้", "Printed today"), v: "1,420", c: "145" },
            { l: tr("สแกนวันนี้", "Scans today"), v: "3,648", c: "270" }
          ].map(k => `
            <div class="tp-glass" style="padding:18px 22px">
              <div style="font-size:12px;color:var(--tp-ink-mute)">${k.l}</div>
              <div class="tp-tnum" style="font-size:28px;font-weight:600;letter-spacing:-.02em;margin-top:4px;color:oklch(.40 .14 ${k.c})">${k.v}</div>
            </div>
          `).join("")}
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:240px;width:720px;bottom:24px;padding:20px;display:flex;flex-direction:column">
          <div style="display:flex;align-items:center;margin-bottom:12px;gap:10px">
            <div style="flex:0 0 240px;height:38px;background:white;border-radius:12px;border:1px solid var(--tp-line);display:flex;align-items:center;padding:0 14px;gap:8px">
              ${ic("search", { size: 14, color: "var(--tp-ink-mute)" })}
              <input placeholder="${tr("ค้นหา SKU / ชื่อสินค้า...", "Search SKU / name...")}" style="flex:1;border:none;background:transparent;outline:none;font-family:inherit;font-size:13px"/>
            </div>
            <div style="flex:1"></div>
            ${["EAN-13", "Code 128", "QR", t("all")].map((tt, i, arr) => `<span class="tp-chip ${i === arr.length - 1 ? "tp-chip-active" : ""}" style="margin-left:4px">${tt}</span>`).join("")}
          </div>
          <div style="display:grid;grid-template-columns:100px 1.5fr 1.4fr 90px 70px 80px 80px;gap:10px;padding:10px 14px;font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.05em;border-bottom:1px solid rgba(20,40,80,.08)">
            <span>SKU</span><span>${tr("สินค้า", "Item")}</span><span>${tr("บาร์โค้ด", "Barcode")}</span><span>${tr("ชนิด", "Type")}</span><span style="text-align:right">${tr("ราคา", "Price")}</span><span style="text-align:right">${tr("คงเหลือ", "Stock")}</span><span style="text-align:center">${tr("พิมพ์", "Print")}</span>
          </div>
          <div style="flex:1;overflow:auto">
            ${items.map(it => `
              <div style="display:grid;grid-template-columns:100px 1.5fr 1.4fr 90px 70px 80px 80px;gap:10px;padding:12px 14px;align-items:center;border-bottom:1px dashed rgba(20,40,80,.06);font-size:13px;
                background:${it.selected ? "linear-gradient(90deg, oklch(.96 .04 188 / .6), transparent)" : "transparent"};border-radius:${it.selected ? 10 : 0}px">
                <span class="tp-mono" style="font-size:11px;font-weight:600;color:oklch(.45 .14 ${it.c})">${it.sku}</span>
                <div>
                  <div style="font-weight:500">${it.name}</div>
                  <div class="tp-mono" style="font-size:10px;color:var(--tp-ink-mute)">${it.code}</div>
                </div>
                <div style="display:flex;align-items:stretch;gap:1px;height:28px">${fakeBarcodeBars(it.code, 32)}</div>
                <span class="tp-chip" style="height:22px;font-size:10px;padding:0 8px;background:oklch(.94 .07 ${it.c});color:oklch(.40 .14 ${it.c})">${it.type}</span>
                <span class="tp-tnum" style="text-align:right;font-weight:500">${it.price}</span>
                <span class="tp-tnum" style="text-align:right;color:${it.qty === 0 ? "oklch(.55 .15 25)" : "var(--tp-ink)"};font-weight:${it.qty === 0 ? 600 : 400}">${it.qty}</span>
                <button style="height:28px;border-radius:8px;border:1px solid var(--tp-line);background:white;cursor:pointer;display:flex;align-items:center;justify-content:center;color:var(--tp-ink-soft);justify-self:center">${ic("printer", { size: 12 })}</button>
              </div>
            `).join("")}
          </div>
          <div style="margin-top:12px;padding-top:12px;border-top:1px dashed var(--tp-line);display:flex;align-items:center;gap:10px">
            <span style="font-size:12px;color:var(--tp-ink-mute)">${tr("เลือกแล้ว", "Selected")}</span>
            <span class="tp-chip tp-chip-active">3 ${tr("รายการ", "items")}</span>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-primary" style="height:36px">${ic("printer", { size: 14, color: "white" })} ${tr("พิมพ์ที่เลือก", "Print selected")}</button>
          </div>
        </div>

        <div style="position:absolute;right:24px;top:240px;width:656px;bottom:24px;display:flex;flex-direction:column;gap:16px">
          <div class="tp-glass" style="padding:20px 24px;display:flex;gap:18px;align-items:center">
            <div style="width:88px;height:88px;border-radius:14px;overflow:hidden;flex-shrink:0">${pi({ label: "LATTE-002", hue: 188, kind: "circle" })}</div>
            <div style="flex:1">
              <div style="font-size:11px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("กำลังแสดง", "Now showing")}</div>
              <div style="font-size:18px;font-weight:600;margin-top:2px">${tr("ลาเต้ร้อน 12oz", "Hot Latte 12oz")}</div>
              <div class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute);margin-top:4px">SKU: LATTE-002 · ฿85 · ${tr("คงเหลือ", "Stock")} 360</div>
              <div style="margin-top:10px;background:white;padding:6px 10px 4px;border-radius:4px;display:inline-block">
                <div style="display:flex;align-items:stretch;gap:1px;height:42px">${fakeBarcodeBars("8851234567025", 60)}</div>
                <div class="tp-mono" style="font-size:11px;letter-spacing:.15em;color:#0e1a30;text-align:center;margin-top:2px">8851234567025</div>
              </div>
            </div>
            <div style="display:flex;flex-direction:column;gap:6px">
              <button class="tp-btn tp-btn-ghost" style="height:32px;font-size:11px">${tr("คัดลอก", "Copy")}</button>
              <button class="tp-btn tp-btn-ghost" style="height:32px;font-size:11px">${tr("สร้างใหม่", "Regen")}</button>
              <button class="tp-btn tp-btn-primary" style="height:32px;font-size:11px">${tr("พิมพ์", "Print")}</button>
            </div>
          </div>

          <div class="tp-glass" style="padding:20px 24px;flex:1;display:flex;flex-direction:column">
            <div style="display:flex;align-items:center;margin-bottom:10px">
              <div>
                <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("เลย์เอาต์ฉลาก", "Label layout")}</div>
                <div style="font-size:16px;font-weight:600;margin-top:2px">${tr("A4 — 3×8 ดวง · 50×30mm", "A4 — 3×8 stickers · 50×30mm")}</div>
              </div>
              <div style="flex:1"></div>
              ${[{ l: "30×20", a: false }, { l: "50×30", a: true }, { l: "75×40", a: false }, { l: tr("ม้วน", "Roll"), a: false }].map(s => `<span class="tp-chip ${s.a ? "tp-chip-active" : ""}" style="margin-left:4px">${s.l}</span>`).join("")}
            </div>
            <div style="flex:1;background:white;border-radius:14px;border:1px solid var(--tp-line);box-shadow:inset 0 1px 0 rgba(255,255,255,.5), 0 4px 14px -8px rgba(20,40,80,.12);padding:18px;display:grid;grid-template-columns:repeat(3, 1fr);grid-auto-rows:1fr;gap:6px;position:relative;overflow:hidden">
              ${Array.from({ length: 12 }).map((_, i) => {
                const sku = ["LATTE-002", "ESP-001", "MATCHA-018", "BREW-CR-005"][i % 4];
                const code = ["8851234567025", "8851234567001", "8851234568018", "8851234560205"][i % 4];
                const price = ["฿85", "฿65", "฿95", "฿95"][i % 4];
                return `
                  <div style="border:1px dashed oklch(.78 .03 220);border-radius:4px;padding:5px 6px;display:flex;flex-direction:column;justify-content:center;font-size:8px">
                    <div style="font-weight:600;font-size:8px;line-height:1.1">Thaiprompt Coffee</div>
                    <div style="font-family:var(--tp-font-mono);font-size:7px;color:var(--tp-ink-mute)">${sku}</div>
                    <div style="display:flex;align-items:stretch;gap:.5px;height:18px;margin:3px 0 1px">${fakeBarcodeBars(code, 24)}</div>
                    <div style="display:flex;justify-content:space-between">
                      <span class="tp-mono" style="font-size:6px;letter-spacing:.05em">${code}</span>
                      <span style="font-weight:700;font-size:9px;color:oklch(.40 .14 25)">${price}</span>
                    </div>
                  </div>
                `;
              }).join("")}
            </div>
            <div style="display:flex;gap:16px;margin-top:12px;font-size:11px;color:var(--tp-ink-mute)">
              <span>${tr("กระดาษ", "Paper")}: <strong style="color:var(--tp-ink)">A4 · 24 ${tr("ดวง", "stickers")}</strong></span>
              <span>${tr("ทำสำเนา", "Copies")}: <strong style="color:var(--tp-ink)">×2</strong></span>
              <div style="flex:1"></div>
              <span style="color:oklch(.45 .14 150);font-weight:500">● ${tr("พร้อมพิมพ์ 24 ดวง", "Ready · 24 stickers")}</span>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  /* 23 · SHIPPING LABEL ─────────────────────────────── */
  function renderShippingLabel() {
    const queue = [
      { id: "SH-2042", to: tr("คุณกานต์ ว.", "K.Karn"), addr: tr("ทองหล่อ ซ.10 กทม.", "Thonglor 10, BKK"), p: "Grab", c: "145", w: "1.4 กก.", cod: null, status: "selected" },
      { id: "SH-2041", to: tr("บจก. สยามคอฟฟี่", "Siam Coffee Co."), addr: tr("ปทุมวัน กทม.", "Pathumwan, BKK"), p: "LINE MAN", c: "145", w: "3.2 กก.", cod: null, status: "ready" },
      { id: "SH-2040", to: tr("คุณนิภา ส.", "K.Nipa"), addr: tr("เชียงใหม่ 50000", "Chiang Mai 50000"), p: "Flash", c: "80", w: "0.8 กก.", cod: "฿420", status: "ready" },
      { id: "SH-2039", to: tr("ร้านพิ้งกี้คาเฟ่", "Pinky Café"), addr: tr("พระราม 9 กทม.", "Rama 9, BKK"), p: "Lalamove", c: "25", w: "8.0 กก.", cod: null, status: "ready" },
      { id: "SH-2038", to: tr("คุณภัทรพล ก.", "K.Pattarapol"), addr: tr("ภูเก็ต 83000", "Phuket 83000"), p: tr("ไปรษณีย์ไทย", "Thailand Post"), c: "270", w: "0.5 กก.", cod: "฿180", status: "ready" }
    ];
    return `
      <div class="screen-meta">
        <span class="screen-meta-label">23 · ${t("shipping_label")}</span>
        <span class="screen-meta-size">1440 × 900 · Print station</span>
      </div>
      <div class="screen-frame landscape">
        <div class="screen-bg"></div>

        <div style="position:absolute;left:24px;right:24px;top:24px;height:76px" class="tp-glass">
          <div style="display:flex;align-items:center;height:100%;padding:0 22px;gap:16px">
            ${bm(42)}
            <div>
              <div style="font-size:17px;font-weight:600">${t("shipping_label")}</div>
              <div style="font-size:12px;color:var(--tp-ink-mute)">${tr("5 พัสดุพร้อมพิมพ์ · Brother QL-1110NWB · 4×6\"", "5 packages ready · Brother QL-1110NWB · 4×6\"")}</div>
            </div>
            <div style="flex:1"></div>
            <button class="tp-btn tp-btn-ghost" data-route="shipping_providers" style="height:42px">${ic("split", { size: 16 })} ${t("shipping_providers")}</button>
            <button class="tp-btn tp-btn-ghost" data-route="delivery" style="height:42px">${ic("phone", { size: 16 })} ${t("delivery")}</button>
            <button class="tp-btn tp-btn-primary" style="height:42px">${ic("printer", { size: 16, color: "white" })} ${tr("พิมพ์ทั้งหมด", "Print all")} (5)</button>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;left:24px;top:116px;width:420px;bottom:24px;padding:20px;display:flex;flex-direction:column">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("คิวพิมพ์ใบปะหน้า", "Print queue")}</div>
          <div style="font-size:18px;font-weight:600;margin-top:2px;margin-bottom:14px">Print Queue · 5</div>
          <div style="flex:1;overflow:auto;display:flex;flex-direction:column;gap:10px">
            ${queue.map(q => `
              <div style="padding:12px 14px;border-radius:12px;
                background:${q.status === "selected" ? "linear-gradient(140deg, oklch(.96 .06 195), oklch(.92 .08 220))" : "white"};
                border:${q.status === "selected" ? "1px solid oklch(.78 .12 195)" : "1px solid var(--tp-line)"};
                box-shadow:${q.status === "selected" ? "0 8px 18px -10px oklch(.55 .14 220 / .35)" : "0 2px 6px -3px rgba(20,40,80,.06)"};
                cursor:pointer">
                <div style="display:flex;align-items:center;gap:10px;margin-bottom:6px">
                  <div style="width:18px;height:18px;border-radius:5px;border:${q.status === "selected" ? "none" : "1.5px solid oklch(.75 .03 220)"};background:${q.status === "selected" ? "linear-gradient(160deg, oklch(.62 .14 195), oklch(.45 .14 220))" : "white"};display:flex;align-items:center;justify-content:center">
                    ${q.status === "selected" ? ic("check", { size: 12, color: "white" }) : ""}
                  </div>
                  <span class="tp-mono" style="font-size:11px;font-weight:700">${q.id}</span>
                  <span class="tp-chip" style="height:20px;font-size:10px;padding:0 8px;background:oklch(.94 .08 ${q.c});color:oklch(.40 .14 ${q.c})">${q.p}</span>
                  <div style="flex:1"></div>
                  <span class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute)">${q.w}</span>
                </div>
                <div style="font-size:13px;font-weight:500">${q.to}</div>
                <div style="font-size:11px;color:var(--tp-ink-mute);margin-top:1px">${q.addr}</div>
                ${q.cod ? `<div style="margin-top:6px;padding:4px 8px;border-radius:6px;background:oklch(.96 .04 80);border:1px solid oklch(.85 .10 80);display:inline-flex;align-items:center;gap:4px;font-size:10px;font-weight:600;color:oklch(.45 .14 80)">${ic("cash", { size: 11, color: "oklch(.45 .14 80)" })} COD ${q.cod}</div>` : ""}
              </div>
            `).join("")}
          </div>
          <div style="margin-top:12px;padding-top:12px;border-top:1px dashed var(--tp-line)">
            <div style="display:flex;align-items:center;margin-bottom:8px">
              <span style="font-size:12px;color:var(--tp-ink-mute)">${tr("รวม", "Total")}</span>
              <div style="flex:1"></div>
              <span class="tp-tnum" style="font-size:16px;font-weight:700">13.9 กก. · ฿2,840</span>
            </div>
            <button class="tp-btn tp-btn-primary" style="width:100%;height:44px">${ic("printer", { size: 16, color: "white" })} ${tr("พิมพ์และยืนยันส่ง 5 พัสดุ", "Print & confirm 5 packages")}</button>
          </div>
        </div>

        <div style="position:absolute;left:460px;top:116px;width:540px;bottom:290px;display:flex;flex-direction:column">
          <div class="tp-glass" style="padding:14px;margin-bottom:10px;display:flex;align-items:center;gap:10px">
            <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ตัวอย่างใบปะหน้า", "Label preview")} · SH-2042</div>
            <div style="flex:1"></div>
            <span class="tp-chip tp-chip-active">4×6"</span>
            <span class="tp-chip">A6</span>
          </div>
          <div style="flex:1;background:white;border-radius:12px;border:1px solid var(--tp-line);
            box-shadow:0 14px 30px -16px rgba(20,40,80,.18), inset 0 1px 0 rgba(255,255,255,.7);
            padding:18px;display:flex;flex-direction:column;font-family:var(--tp-font-mono);color:#0e1a30;position:relative;overflow:hidden">
            <div style="display:flex;align-items:center;border-bottom:2px solid #0e1a30;padding-bottom:10px;margin-bottom:12px">
              <div style="width:56px;height:56px;border-radius:12px;background:linear-gradient(160deg, oklch(.50 .14 145), oklch(.35 .14 150));color:white;display:flex;align-items:center;justify-content:center;font-size:18px;font-weight:800;letter-spacing:-.02em">GR</div>
              <div style="margin-left:12px;flex:1">
                <div style="font-size:18px;font-weight:800;font-family:var(--tp-font)">GRAB EXPRESS</div>
                <div style="font-size:11px;opacity:.7">Same-day Bangkok · GE-25080842</div>
              </div>
              <div style="text-align:right">
                <div style="font-size:10px;opacity:.7">SERVICE</div>
                <div style="font-size:14px;font-weight:800;padding:3px 10px;border:2px solid #0e1a30;border-radius:6px;margin-top:2px">EXPRESS</div>
              </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;padding-bottom:12px;border-bottom:1px dashed #0e1a30">
              <div>
                <div style="font-size:9px;opacity:.6;letter-spacing:.15em">FROM</div>
                <div style="font-size:12px;font-weight:700;margin-top:3px;font-family:var(--tp-font)">Thaiprompt Coffee — Siam</div>
                <div style="font-size:10px;margin-top:2px;line-height:1.4">${tr("989 อาคารสยามทาวเวอร์ ชั้น 8", "989 Siam Tower, 8F")}<br/>${tr("ปทุมวัน กทม. 10330", "Pathumwan, BKK 10330")}<br/>02-555-0188</div>
              </div>
              <div>
                <div style="font-size:9px;opacity:.6;letter-spacing:.15em">TO</div>
                <div style="font-size:14px;font-weight:700;margin-top:3px;font-family:var(--tp-font)">${tr("คุณกานต์ วิริยะกุล", "K.Karn Wiriyakul")}</div>
                <div style="font-size:10px;margin-top:2px;line-height:1.4">${tr("88/24 ทองหล่อ ซ.10", "88/24 Thonglor Soi 10")}<br/>${tr("วัฒนา กทม. 10110", "Wattana, BKK 10110")}<br/>081-234-5678</div>
              </div>
            </div>
            <div style="padding:14px 0;border-bottom:1px dashed #0e1a30">
              <div style="font-size:10px;opacity:.6;letter-spacing:.15em">TRACKING NO.</div>
              <div style="font-size:22px;font-weight:800;letter-spacing:.08em;margin-top:2px">GE25080842TH</div>
              <div style="margin-top:8px;background:white;padding:6px 10px 4px;border-radius:4px;display:inline-block">
                <div style="display:flex;align-items:stretch;gap:1px;height:48px">
                  ${Array.from({ length: 60 }).map((_, j) => {
                    const code = "GE25080842TH";
                    const w = ((code.charCodeAt(j % code.length) + j) % 4) + 1;
                    const filled = ((code.charCodeAt(j % code.length) >> (j % 5)) & 1);
                    return `<div style="width:${w}px;height:100%;background:${filled ? "#0e1a30" : "transparent"}"></div>`;
                  }).join("")}
                </div>
                <div class="tp-mono" style="font-size:11px;letter-spacing:.15em;color:#0e1a30;text-align:center;margin-top:2px">GE25080842TH</div>
              </div>
            </div>
            <div style="flex:1;display:flex;margin-top:12px;gap:14px;align-items:stretch">
              <div style="flex:1;display:grid;grid-template-columns:1fr 1fr;gap:6px 12px;font-size:11px;align-content:start">
                <div><div style="opacity:.6;font-size:9px">WEIGHT</div><div style="font-weight:700">1.4 KG</div></div>
                <div><div style="opacity:.6;font-size:9px">PIECES</div><div style="font-weight:700">1 / 1</div></div>
                <div><div style="opacity:.6;font-size:9px">PAYMENT</div><div style="font-weight:700">PREPAID</div></div>
                <div><div style="opacity:.6;font-size:9px">FEE</div><div style="font-weight:700">฿58</div></div>
                <div><div style="opacity:.6;font-size:9px">DATE</div><div style="font-weight:700">08/05/2026</div></div>
                <div><div style="opacity:.6;font-size:9px">ROUTE</div><div style="font-weight:700">BKK→BKK</div></div>
              </div>
              <div style="width:100px;height:100px;background:white;border:2px solid #0e1a30;padding:4px">
                <div style="display:grid;grid-template-columns:repeat(8, 1fr);grid-auto-rows:1fr;gap:1px;width:100%;height:100%">
                  ${Array.from({ length: 64 }).map((_, i) => {
                    const f = (i * 7 + (i >> 2) * 13) % 3;
                    return `<div style="background:${f ? "#0e1a30" : "white"}"></div>`;
                  }).join("")}
                </div>
              </div>
            </div>
            <div style="margin-top:8px;padding-top:8px;border-top:1px dashed #0e1a30;display:flex;align-items:center;justify-content:space-between">
              <span style="font-size:9px;opacity:.7">HANDLE WITH CARE</span>
              <span style="font-size:9px;font-weight:700">POWERED BY THAIPROMPT POS</span>
            </div>
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:116px;width:396px;height:340px;padding:20px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("เครื่องพิมพ์", "Printer")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px">Brother QL-1110NWB</div>
          <div style="margin-top:14px;padding:14px;border-radius:12px;background:oklch(.96 .04 145);border:1px solid oklch(.85 .08 150);display:flex;align-items:center;gap:12px">
            <div style="width:36px;height:36px;border-radius:50%;background:linear-gradient(160deg, oklch(.78 .12 145), oklch(.50 .14 150));color:white;display:flex;align-items:center;justify-content:center;box-shadow:0 0 0 4px oklch(.85 .12 145 / .35)">${ic("check", { size: 18, color: "white" })}</div>
            <div style="flex:1">
              <div style="font-size:13px;font-weight:600;color:oklch(.35 .14 150)">${tr("พร้อมพิมพ์", "Ready")}</div>
              <div style="font-size:11px;color:var(--tp-ink-mute)">Wi-Fi · 192.168.1.42 · 24°C</div>
            </div>
          </div>
          <div style="margin-top:14px;display:flex;flex-direction:column;gap:10px">
            ${[
              { l: tr("กระดาษม้วน", "Roll paper"), v: "DK-22246 (4×6\")", p: 78 },
              { l: tr("หมึก", "Ink"), v: tr("ปกติ", "Normal"), p: 92 }
            ].map(m => `
              <div>
                <div style="display:flex;justify-content:space-between;margin-bottom:4px">
                  <span style="font-size:12px;color:var(--tp-ink-soft)">${m.l}</span>
                  <span class="tp-mono" style="font-size:11px;color:var(--tp-ink-mute)">${m.v} · ${m.p}%</span>
                </div>
                <div style="height:8px;background:rgba(20,40,80,.06);border-radius:999px;overflow:hidden">
                  <div style="height:100%;width:${m.p}%;background:${m.p > 30 ? "linear-gradient(90deg, oklch(.78 .14 145), oklch(.55 .14 150))" : "oklch(.62 .14 25)"};border-radius:999px"></div>
                </div>
              </div>
            `).join("")}
          </div>
        </div>

        <div class="tp-glass" style="position:absolute;right:24px;top:476px;width:396px;bottom:24px;padding:20px 22px">
          <div style="font-size:12px;color:var(--tp-ink-mute);text-transform:uppercase;letter-spacing:.1em">${tr("ตัวเลือกการพิมพ์", "Print options")}</div>
          <div style="font-size:17px;font-weight:600;margin-top:2px;margin-bottom:12px">Print Options</div>
          ${[
            { l: tr("พิมพ์ 2 สำเนา (สำหรับร้าน)", "Print 2 copies (for store)"), on: true },
            { l: tr("รวมแบนเนอร์ปิดงานกะ", "Include shift summary"), on: true },
            { l: tr("พิมพ์ Manifest ลงท้าย", "Append manifest"), on: true },
            { l: tr("ขนาดตัวอักษรใหญ่พิเศษ", "Extra large fonts"), on: false },
            { l: tr("ส่งรหัส tracking ทาง SMS", "SMS tracking to customer"), on: true }
          ].map((tg, i, arr) => `
            <div style="display:flex;align-items:center;padding:8px 0;border-bottom:${i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none"}">
              <span style="flex:1;font-size:13px">${tg.l}</span>
              <div style="width:38px;height:22px;border-radius:999px;background:${tg.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)"};position:relative;
                box-shadow:${tg.on ? "inset 0 1px 0 rgba(255,255,255,.25), 0 4px 10px -4px oklch(.50 .14 220 / .5)" : "inset 0 1px 2px rgba(20,40,80,.08)"}">
                <div style="position:absolute;top:2px;left:${tg.on ? 18 : 2}px;width:18px;height:18px;border-radius:50%;background:white;box-shadow:0 2px 4px rgba(20,40,80,.2)"></div>
              </div>
            </div>
          `).join("")}
        </div>
      </div>
    `;
  }

  /* ────────────────────────────────────────────────
     EXPORT REGISTRY
     ────────────────────────────────────────────────*/
  window.SCREENS = {
    overview:        renderOverview,
    login:           renderLogin,
    cashier:         renderCashier,
    payment:         renderPayment,
    receipt:         renderReceipt,
    customer_display: renderCustomerDisplay,
    kds:             renderKDS,
    dashboard:       renderDashboard,
    inventory:       renderInventory,
    tablet:          renderTablet,
    mobile_order:    renderMobileOrder,
    mobile_mgr:      renderMobileManager,
    accounting:      renderAccounting,
    create_bill:     renderCreateBill,
    tax_invoice:     renderTaxInvoice,
    nfc_scan:        renderNFCScan,
    delivery:        renderDelivery,
    stock_mgmt:      renderStockMgmt,
    shipping_providers: renderShippingProviders,
    coupons:         renderCoupons,
    staff:           renderStaff,
    admin:           renderAdmin,
    barcode:         renderBarcode,
    shipping_label:  renderShippingLabel,
    architecture:    renderArchitecture,
    sync_api:        renderSync
  };
})();

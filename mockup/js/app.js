// Thaiprompt POS Mockup — application shell

(function() {
  const NAV = [
    { group: "nav_meta", items: [
      { id: "overview", icon: "home" }
    ]},
    { group: "nav_pos", items: [
      { id: "login",     icon: "user" },
      { id: "cashier",   icon: "grid", badge: "★" },
      { id: "payment",   icon: "qr" },
      { id: "nfc_scan",  icon: "card" },
      { id: "receipt",   icon: "receipt" }
    ]},
    { group: "nav_secondary", items: [
      { id: "customer_display", icon: "monitor" },
      { id: "kds",              icon: "fire" }
    ]},
    { group: "nav_back", items: [
      { id: "dashboard", icon: "chart" },
      { id: "inventory", icon: "box" },
      { id: "stock_mgmt", icon: "layers" },
      { id: "staff",     icon: "users" }
    ]},
    { group: "nav_business", items: [
      { id: "accounting",  icon: "chart" },
      { id: "create_bill", icon: "receipt" },
      { id: "tax_invoice", icon: "receipt" },
      { id: "coupons",     icon: "tag" }
    ]},
    { group: "nav_ops", items: [
      { id: "delivery",            icon: "phone" },
      { id: "shipping_providers",  icon: "split" },
      { id: "admin",               icon: "settings" }
    ]},
    { group: "nav_print", items: [
      { id: "barcode",        icon: "qr" },
      { id: "shipping_label", icon: "printer" }
    ]},
    { group: "nav_mobile", items: [
      { id: "tablet",       icon: "table" },
      { id: "mobile_order", icon: "phone" },
      { id: "mobile_mgr",   icon: "user" }
    ]},
    { group: "nav_meta", items: [
      { id: "architecture", icon: "layers" },
      { id: "sync_api",     icon: "cloud" }
    ]}
  ];

  const t  = (k, v) => window.I18N.t(k, v);
  const ic = (n, o) => window.Icon(n, o);
  const bm = (s) => window.BrandMark(s);

  let currentRoute = "overview";

  function renderShell() {
    const root = document.getElementById("app");
    root.innerHTML = `
      <div class="app-shell">
        <div class="brand">
          <div class="brand-mark">${bm(44)}</div>
          <div class="brand-text">
            <div class="brand-title">${t("brand_title")}</div>
            <div class="brand-sub">${t("brand_subtitle")}</div>
          </div>
        </div>

        <div class="topbar">
          <div>
            <span class="topbar-title" id="topbar-title">${t(currentRoute)}</span>
            <span class="topbar-sub" id="topbar-sub"></span>
          </div>
          <div class="topbar-spacer"></div>
          <span class="sync-banner">${ic("cloud", { size: 14 })} ${t("online")}</span>
          <span class="tp-chip"><span class="tp-dot"></span> ${t("ready")}</span>
          <span class="tp-chip tp-mono">14:42</span>
          <div class="lang-switch" role="tablist">
            <button data-lang="th" class="${window.I18N.lang === "th" ? "on" : ""}">ไทย</button>
            <button data-lang="en" class="${window.I18N.lang === "en" ? "on" : ""}">EN</button>
          </div>
        </div>

        <nav class="nav" id="nav"></nav>

        <div class="canvas">
          <div class="canvas-bg"></div>
          <div class="canvas-inner" id="canvas-inner"></div>
        </div>
      </div>

      <div class="xman-watermark">
        <span class="dot"></span>
        <span>${t("studio")} · ${t("version")}</span>
      </div>
    `;

    renderNav();
    renderRoute();

    // language toggle
    root.querySelectorAll(".lang-switch button").forEach(btn => {
      btn.addEventListener("click", () => {
        window.I18N.set(btn.dataset.lang);
        renderShell();
      });
    });

    // delegated nav clicks (cards on overview can also navigate)
    root.addEventListener("click", e => {
      const navItem = e.target.closest("[data-route]");
      if (navItem) {
        navigate(navItem.dataset.route);
        return;
      }
      const cardItem = e.target.closest("[data-nav]");
      if (cardItem) {
        navigate(cardItem.dataset.nav);
      }
    });
  }

  function renderNav() {
    const navEl = document.getElementById("nav");
    // dedupe meta groups so only first one renders the meta section *before* main
    let html = "";
    let seenGroups = new Set();
    for (const g of NAV) {
      if (seenGroups.has(g.group)) {
        // append items into the first group with this title
        continue;
      }
      seenGroups.add(g.group);
      // collect all items across NAV that share this group
      const items = NAV.filter(x => x.group === g.group).flatMap(x => x.items);
      html += `<div class="nav-group">
        <div class="nav-group-title">${t(g.group)}</div>
        ${items.map(it => `
          <button class="nav-item ${it.id === currentRoute ? "active" : ""}" data-route="${it.id}">
            <span class="nav-item-icon">${ic(it.icon, { size: 20 })}</span>
            <span>${t(it.id)}</span>
            ${it.badge ? `<span class="nav-item-meta">${it.badge}</span>` : ""}
          </button>
        `).join("")}
      </div>`;
    }
    navEl.innerHTML = html;
  }

  function renderRoute() {
    const inner = document.getElementById("canvas-inner");
    const fn = window.SCREENS[currentRoute] || window.SCREENS.overview;
    inner.innerHTML = fn();
    document.getElementById("topbar-title").textContent = t(currentRoute);
    const sub = subtitleForRoute(currentRoute);
    document.getElementById("topbar-sub").textContent = sub;
  }

  function subtitleForRoute(r) {
    const map = {
      overview: window.I18N.lang === "th" ? "พรีวิวทุกหน้าจอของระบบ · กดแต่ละการ์ดเพื่อดู" : "Preview every screen · click any card",
      login: "1280 × 800 · Windows / Tablet",
      cashier: "1440 × 900 · Windows",
      payment: "1100 × 800 · Modal",
      receipt: "380 × 720 · Thermal 80mm",
      customer_display: "1280 × 800 · Second monitor",
      kds: "1440 × 900 · Kitchen",
      dashboard: "1440 × 900 · Back office",
      inventory: "1440 × 900 · Back office",
      tablet: "1024 × 768 · iPad",
      mobile_order: "390 × 844 · iOS / Android",
      mobile_mgr: "390 × 844 · iOS / Android",
      accounting: "1440 × 900 · Back office",
      create_bill: "1440 × 900 · Back office",
      tax_invoice: "1440 × 900 · Back office",
      nfc_scan: "1280 × 800 · Payment device",
      delivery: "1440 × 900 · Operations",
      stock_mgmt: "1440 × 900 · Back office",
      shipping_providers: "1440 × 900 · Operations",
      coupons: "1440 × 900 · Marketing",
      staff: "1440 × 900 · HR",
      admin: "1440 × 900 · System",
      barcode: "1440 × 900 · Operations",
      shipping_label: "1440 × 900 · Print station",
      architecture: window.I18N.lang === "th" ? "Stack + โครงสร้างโปรเจค" : "Stack + project structure",
      sync_api: "API + Sync sequence"
    };
    return map[r] || "";
  }

  function navigate(route) {
    if (!window.SCREENS[route]) return;
    currentRoute = route;
    document.querySelectorAll(".nav-item").forEach(el => {
      el.classList.toggle("active", el.dataset.route === route);
    });
    renderRoute();
    document.querySelector(".canvas").scrollTo({ top: 0, behavior: "smooth" });
  }

  window.addEventListener("DOMContentLoaded", renderShell);
  window.addEventListener("i18n:change", () => renderShell());
})();

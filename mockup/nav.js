// Thaiprompt POS mockup — quick-jump navigation HUD
// Floats a collapsible index over the design canvas so you can jump to any of
// the 39 screens without scrolling through the canvas. Does NOT touch screen
// code (no drift risk). Pure DOM + scrollIntoView on the host DesignCanvas
// scroller (find by walking up from the artboard element).
(function () {
  if (window.__tpNavBooted) return;
  window.__tpNavBooted = true;

  // Source of truth — must match index.html DCSection/DCArtboard ids.
  // [groupLabel, [ [num, label, artboardId, sectionId], ... ]]
  var GROUPS = [
    ['Cashier flow', [
      ['01', 'Cashier · จอขายหลัก', 'cashier', 'hero'],
      ['02', 'Payment · ชำระเงิน', 'payment', 'payment'],
      ['03', 'Receipt · ใบเสร็จ', 'receipt', 'payment'],
      ['04', 'Login · PIN', 'login', 'payment'],
    ]],
    ['Secondary displays', [
      ['05', 'Customer Display', 'cust', '2nd'],
      ['06', 'Kitchen Display (KDS)', 'kds', '2nd'],
    ]],
    ['Back office', [
      ['07', 'Sales Dashboard', 'dash', 'back'],
      ['08', 'Inventory · คลังสินค้า', 'inv', 'back'],
    ]],
    ['Business / Finance', [
      ['12', 'การจัดการบัญชี', 'acct', 'biz'],
      ['13', 'สร้างบิล', 'bill', 'biz'],
      ['14', 'ใบกำกับภาษี / e-Tax', 'tax', 'biz'],
      ['15', 'NFC · แตะบัตรชำระ', 'nfc', 'biz'],
      ['16', 'เดลิเวอรี่ · ติดตามไรเดอร์', 'dlv', 'biz'],
    ]],
    ['Operations', [
      ['17', 'จัดการสต็อก / Movements', 'stock', 'ops'],
      ['18', 'ส่งของผ่านผู้ให้บริการ', 'ship', 'ops'],
      ['19', 'ระบบคูปอง / โปรโมชั่น', 'coupon', 'ops'],
      ['20', 'ระบบพนักงาน', 'staff', 'ops'],
      ['21', 'ระบบแอดมิน', 'admin', 'ops'],
      ['22', 'จัดการบาร์โค้ด', 'barcode', 'ops'],
      ['23', 'พิมพ์ใบปะหน้าพัสดุ', 'shiplabel', 'ops'],
    ]],
    ['Advanced', [
      ['24', 'CRM · สมาชิก', 'crm', 'more'],
      ['25', 'ปิดกะ · Z-Report', 'shift', 'more'],
      ['26', 'คืนเงิน / Void', 'refund', 'more'],
      ['27', 'ใบสั่งซื้อ Supplier (PO)', 'po', 'more'],
      ['28', 'แก้ไขเมนู + BOM', 'menu', 'more'],
      ['29', 'Multi-Branch HQ', 'hq', 'more'],
    ]],
    ['Table ordering', [
      ['30', 'ออกแบบผังโต๊ะ (เจ้าของ)', 'floorplan', 'tableorder'],
      ['31', 'สแกน QR สั่งจากโต๊ะ', 'selforder', 'tableorder'],
      ['32', 'ติดตามสถานะออเดอร์', 'orderstatus', 'tableorder'],
    ]],
    ['Customer order flow', [
      ['36', 'เมนู · กริดรูปใหญ่', 'cust-menu', 'custorder'],
      ['37', 'เลือกเมนู · ปรับแต่ง', 'cust-item', 'custorder'],
      ['38', 'ตะกร้า · รีวิว', 'cust-cart', 'custorder'],
      ['39', 'ส่งครัวสำเร็จ', 'cust-confirm', 'custorder'],
    ]],
    ['Loyalty', [
      ['33', 'ระดับสมาชิก VIP/Gold', 'tiers', 'loyalty'],
      ['34', 'ศูนย์ส่วนลด', 'discount', 'loyalty'],
      ['35', 'Affiliate · แนะนำเพื่อน', 'affiliate', 'loyalty'],
    ]],
    ['Mobile / iPad', [
      ['09', 'iPad · ผังโต๊ะ Waiter', 'ipad', 'mobile'],
      ['10', 'Mobile · รับออเดอร์ที่โต๊ะ', 'm-order', 'mobile'],
      ['11', 'Mobile · ผู้จัดการ', 'm-mgr', 'mobile'],
    ]],
  ];

  function injectStyles() {
    if (document.getElementById('tp-nav-styles')) return;
    var css = [
      '#tp-nav-fab{position:fixed;top:14px;left:14px;z-index:9999;width:44px;height:44px;border-radius:14px;border:1px solid rgba(255,255,255,.6);background:linear-gradient(180deg,#5DE7DC 0%,#008889 100%);color:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;box-shadow:0 1px 0 rgba(255,255,255,.5) inset,0 -2px 0 rgba(0,0,0,.15) inset,0 8px 18px -4px rgba(0,136,137,.55),0 2px 4px rgba(20,40,80,.18);font-family:Prompt,system-ui,sans-serif;font-weight:600;font-size:16px}',
      '#tp-nav-fab:hover{transform:translateY(-1px)}',
      '#tp-nav-fab:active{transform:translateY(1px)}',
      '#tp-nav-panel{position:fixed;top:70px;left:14px;z-index:9998;width:320px;max-height:calc(100vh - 90px);overflow:auto;background:rgba(255,255,255,.92);backdrop-filter:blur(22px) saturate(180%);-webkit-backdrop-filter:blur(22px) saturate(180%);border:1px solid rgba(255,255,255,.7);border-radius:22px;box-shadow:0 1px 0 rgba(255,255,255,.9) inset,0 30px 60px -30px rgba(20,40,80,.35);padding:14px;font-family:Prompt,system-ui,sans-serif;color:#141B24;display:none}',
      '#tp-nav-panel.open{display:block}',
      '#tp-nav-panel .grp{font-size:11px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:#80878F;margin:14px 6px 6px}',
      '#tp-nav-panel .grp:first-child{margin-top:2px}',
      '#tp-nav-panel a{display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:10px;text-decoration:none;color:inherit;font-size:13px;line-height:1.25;transition:background .12s}',
      '#tp-nav-panel a:hover{background:rgba(0,189,190,.12)}',
      '#tp-nav-panel a .num{font-family:JetBrains Mono,monospace;font-feature-settings:"tnum";font-size:11px;font-weight:600;width:24px;flex:0 0 24px;color:#008889}',
      '#tp-nav-panel a .lbl{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',
      '#tp-nav-panel .hint{font-size:11px;color:#80878F;padding:8px 10px 2px;line-height:1.4}',
      '#tp-nav-panel hr{border:0;border-top:1px solid rgba(208,217,222,.6);margin:10px 6px}',
      '@media(max-width:600px){#tp-nav-panel{width:calc(100vw - 28px)}}',
    ].join('\n');
    var el = document.createElement('style');
    el.id = 'tp-nav-styles';
    el.textContent = css;
    document.head.appendChild(el);
  }

  function buildPanel() {
    var panel = document.createElement('div');
    panel.id = 'tp-nav-panel';
    var html = '<div class="hint">39 หน้า · คลิกเพื่อกระโดดไปหน้าที่ต้องการ · Esc ปิด</div><hr/>';
    GROUPS.forEach(function (g) {
      html += '<div class="grp">' + g[0] + '</div>';
      g[1].forEach(function (row) {
        var num = row[0], label = row[1], aid = row[2];
        html += '<a href="#" data-aid="' + aid + '"><span class="num">' + num + '</span><span class="lbl">' + label + '</span></a>';
      });
    });
    panel.innerHTML = html;
    document.body.appendChild(panel);

    panel.addEventListener('click', function (e) {
      var a = e.target.closest('a[data-aid]');
      if (!a) return;
      e.preventDefault();
      var aid = a.getAttribute('data-aid');
      jumpTo(aid);
      panel.classList.remove('open');
    });
  }

  function buildFab() {
    var fab = document.createElement('button');
    fab.id = 'tp-nav-fab';
    fab.type = 'button';
    fab.setAttribute('aria-label', 'Quick jump');
    fab.title = 'Quick jump to any of 39 screens';
    fab.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6h16M4 12h16M4 18h16"/></svg>';
    fab.addEventListener('click', function () {
      var p = document.getElementById('tp-nav-panel');
      if (p) p.classList.toggle('open');
    });
    document.body.appendChild(fab);

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        var p = document.getElementById('tp-nav-panel');
        if (p) p.classList.remove('open');
      }
    });
  }

  // Find the artboard's host DOM node by data-dc-slot label match or by id.
  // DesignCanvas renders artboards into [data-dc-slot] wrappers; we cannot
  // rely on the JSX id propagating to DOM, so fall back to label text.
  function findArtboard(aid) {
    // direct id (if DCArtboard sets dom id)
    var byId = document.getElementById(aid);
    if (byId) return byId;
    // by label text — artboards have a .dc-labeltext span with the label
    var labels = document.querySelectorAll('.dc-labeltext .dc-editable');
    for (var i = 0; i < labels.length; i++) {
      var txt = labels[i].textContent || '';
      // labels are like "01 · Cashier · จอขายหลัก" — match by leading number
      var num = aidToNum(aid);
      if (num && txt.indexOf(num) === 0) {
        return labels[i].closest('[data-dc-slot]');
      }
    }
    return null;
  }

  function aidToNum(aid) {
    var map = {
      cashier: '01', payment: '02', receipt: '03', login: '04',
      cust: '05', kds: '06', dash: '07', inv: '08',
      ipad: '09', 'm-order': '10', 'm-mgr': '11',
      acct: '12', bill: '13', tax: '14', nfc: '15', dlv: '16',
      stock: '17', ship: '18', coupon: '19', staff: '20', admin: '21',
      barcode: '22', shiplabel: '23',
      crm: '24', shift: '25', refund: '26', po: '27', menu: '28', hq: '29',
      floorplan: '30', selforder: '31', orderstatus: '32',
      tiers: '33', discount: '34', affiliate: '35',
      'cust-menu': '36', 'cust-item': '37', 'cust-cart': '38', 'cust-confirm': '39',
    };
    return map[aid] || null;
  }

  function jumpTo(aid) {
    var node = findArtboard(aid);
    if (!node) {
      // canvas may still be mounting — retry shortly
      setTimeout(function () {
        var n = findArtboard(aid);
        if (n) n.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
      }, 200);
      return;
    }
    node.scrollIntoView({ behavior: 'smooth', block: 'center', inline: 'center' });
  }

  function boot() {
    injectStyles();
    buildFab();
    buildPanel();
    // optional: route from hash on load (e.g. open #screen=14 → jump)
    var m = location.hash.match(/screen=([^&]+)/);
    if (m) setTimeout(function () { jumpTo(m[1]); }, 400);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();

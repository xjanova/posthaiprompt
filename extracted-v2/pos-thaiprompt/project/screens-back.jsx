// Thaiprompt POS — Sales Dashboard + Inventory

const DashboardScreen = () => {
  // simple chart paths
  const sales = [38, 52, 47, 65, 58, 78, 82, 70, 88, 92, 85, 96, 110, 105];
  const max = 120;
  const w = 720, h = 220, pad = 16;
  const pts = sales.map((v, i) => `${pad + (i * (w - pad * 2)) / (sales.length - 1)},${h - pad - (v / max) * (h - pad * 2)}`).join(" ");
  const areaPath = `M ${pts.split(" ")[0]} L ${pts} L ${w - pad},${h - pad} L ${pad},${h - pad} Z`;

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>

      {/* header */}
      <header style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }} className="tp-glass">
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>แดชบอร์ดยอดขาย</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>สาขา สยาม สแควร์ · 8 พ.ค. 2568</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", background: "rgba(255,255,255,.5)", borderRadius: 12, padding: 4, gap: 2, border: "1px solid rgba(255,255,255,.6)" }}>
          {["วันนี้", "สัปดาห์", "เดือน", "ปี"].map((t, i) => (
            <button key={i} style={{
              padding: "8px 18px", borderRadius: 9, border: "none", cursor: "pointer",
              fontFamily: "inherit", fontSize: 13, fontWeight: 500,
              background: i === 0 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent",
              color: i === 0 ? "white" : "var(--tp-ink-soft)",
              boxShadow: i === 0 ? "0 1px 0 rgba(255,255,255,.15) inset, 0 6px 14px -6px oklch(.25 .07 265 / .55)" : "none"
            }}>{t}</button>
          ))}
        </div>
        <button className="tp-btn tp-btn-ghost" style={{ height: 42, padding: "0 16px" }}><TPIcon name="receipt" size={16}/> ส่งออก</button>
      </header>

      {/* KPI cards */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "ยอดขายรวม", v: "฿42,580", d: "+12.4%", up: true, c: "188", icon: "chart" },
          { l: "บิล", v: "248", d: "+18 จากเมื่อวาน", up: true, c: "270", icon: "receipt" },
          { l: "ค่าเฉลี่ย/บิล", v: "฿172", d: "−2.1%", up: false, c: "25", icon: "user" },
          { l: "ลูกค้าใหม่", v: "32", d: "+8 ใหม่", up: true, c: "80", icon: "users" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "20px 22px", position: "relative", overflow: "hidden" }}>
            <div style={{
              position: "absolute", right: -20, top: -20, width: 110, height: 110, borderRadius: "50%",
              background: `radial-gradient(circle, oklch(.85 .12 ${k.c} / .35), transparent 70%)`,
              filter: "blur(10px)"
            }}/>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 12,
                background: `linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: `0 6px 14px -4px oklch(.65 .14 ${k.c} / .5)`
              }}><TPIcon name={k.icon} size={20}/></div>
              <div style={{ fontSize: 13, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            </div>
            <div className="tp-tnum" style={{ fontSize: 32, fontWeight: 600, letterSpacing: "-.02em", color: "var(--tp-indigo-deep)" }}>{k.v}</div>
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 6, fontSize: 12 }}>
              <div style={{
                display: "inline-flex", alignItems: "center", gap: 3,
                padding: "2px 8px", borderRadius: 999, fontWeight: 600,
                background: k.up ? "oklch(.94 .08 145)" : "oklch(.94 .08 25)",
                color: k.up ? "oklch(.45 .14 150)" : "oklch(.55 .15 25)"
              }}>
                <TPIcon name={k.up ? "arrow-up" : "arrow-down"} size={12}/>
                {k.d}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* main chart */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 296, width: 880, height: 360, padding: "22px 26px" }}>
        <div style={{ display: "flex", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ยอดขายรายชั่วโมง</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>06:00 → 20:00</div>
          </div>
          <div style={{ flex: 1 }}/>
          <div style={{ display: "flex", gap: 14, fontSize: 12 }}>
            <span style={{ display: "flex", alignItems: "center", gap: 6 }}><span style={{ width: 10, height: 10, borderRadius: "50%", background: "oklch(.62 .14 195)" }}/> วันนี้</span>
            <span style={{ display: "flex", alignItems: "center", gap: 6, color: "var(--tp-ink-mute)" }}><span style={{ width: 10, height: 10, borderRadius: "50%", background: "oklch(.85 .04 230)" }}/> เมื่อวาน</span>
          </div>
        </div>

        <div style={{ marginTop: 18, position: "relative" }}>
          <svg viewBox={`0 0 ${w} ${h}`} style={{ width: "100%", height: 220 }}>
            <defs>
              <linearGradient id="dash-area" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="oklch(.72 .13 190)" stopOpacity=".45"/>
                <stop offset="100%" stopColor="oklch(.72 .13 190)" stopOpacity="0"/>
              </linearGradient>
              <linearGradient id="dash-line" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor="oklch(.72 .13 190)"/>
                <stop offset="100%" stopColor="oklch(.50 .14 250)"/>
              </linearGradient>
            </defs>
            {[0, 1, 2, 3, 4].map(i => (
              <line key={i} x1={pad} x2={w - pad} y1={pad + ((h - pad * 2) * i) / 4} y2={pad + ((h - pad * 2) * i) / 4} stroke="rgba(20,40,80,.06)" strokeWidth="1"/>
            ))}
            <path d={areaPath} fill="url(#dash-area)"/>
            <polyline points={pts} fill="none" stroke="url(#dash-line)" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
            {sales.map((v, i) => {
              const x = pad + (i * (w - pad * 2)) / (sales.length - 1);
              const y = h - pad - (v / max) * (h - pad * 2);
              return <circle key={i} cx={x} cy={y} r="3.5" fill="white" stroke="oklch(.62 .14 195)" strokeWidth="2"/>;
            })}
            {/* peak callout */}
            {(() => {
              const i = sales.indexOf(Math.max(...sales));
              const x = pad + (i * (w - pad * 2)) / (sales.length - 1);
              const y = h - pad - (sales[i] / max) * (h - pad * 2);
              return <g>
                <circle cx={x} cy={y} r="7" fill="oklch(.62 .14 195)" opacity=".25"/>
                <circle cx={x} cy={y} r="4.5" fill="oklch(.62 .14 195)"/>
                <rect x={x - 38} y={y - 30} width="76" height="22" rx="6" fill="oklch(.22 .02 250)"/>
                <text x={x} y={y - 15} fill="white" fontSize="12" fontWeight="600" textAnchor="middle" fontFamily="var(--tp-font)">฿4,820</text>
              </g>;
            })()}
          </svg>
          <div style={{ display: "flex", justifyContent: "space-between", padding: "0 16px", marginTop: 8, fontSize: 11, color: "var(--tp-ink-mute)", fontFamily: "var(--tp-font-mono)" }}>
            {["06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"].map((t) => <span key={t}>{t}h</span>)}
          </div>
        </div>
      </div>

      {/* top items */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 296, width: 504, height: 360, padding: "22px 26px" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 18 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เมนูขายดี</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>Top 5 วันนี้</div>
          </div>
          <div style={{ flex: 1 }}/>
          <span className="tp-chip">ดูทั้งหมด</span>
        </div>

        {[
          { n: "ชาไทยเย็น", q: 84, r: "฿5,460", hue: 25, kind: "rect" },
          { n: "ชาเขียวมัทฉะลาเต้", q: 62, r: "฿5,270", hue: 145, kind: "circle" },
          { n: "อเมริกาโน่เย็น", q: 51, r: "฿3,570", hue: 35, kind: "rect" },
          { n: "ลาเต้ร้อน", q: 48, r: "฿3,600", hue: 50, kind: "circle" },
          { n: "ครัวซองต์อัลมอนด์", q: 32, r: "฿1,760", hue: 40, kind: "rect" },
        ].map((it, i) => {
          const pct = (it.q / 84) * 100;
          return (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 14 }}>
              <span className="tp-tnum" style={{ width: 22, fontSize: 13, fontWeight: 600, color: "var(--tp-ink-mute)" }}>{i + 1}</span>
              <div style={{ width: 36, height: 36, borderRadius: 10, overflow: "hidden", flexShrink: 0 }}>
                <TPProductImg hue={it.hue} kind={it.kind}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{it.n}</span>
                  <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{it.r}</span>
                </div>
                <div style={{ height: 6, background: "rgba(20,40,80,.06)", borderRadius: 999, overflow: "hidden" }}>
                  <div style={{
                    height: "100%", width: `${pct}%`,
                    background: `linear-gradient(90deg, oklch(.78 .12 ${it.hue}), oklch(.55 .14 ${it.hue}))`,
                    borderRadius: 999
                  }}/>
                </div>
              </div>
              <span className="tp-tnum" style={{ width: 36, fontSize: 12, color: "var(--tp-ink-mute)", textAlign: "right" }}>{it.q} แก้ว</span>
            </div>
          );
        })}
      </div>

      {/* split — payment + recent orders */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 676, width: 440, bottom: 24, padding: "22px 26px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>วิธีการชำระ</div>
        <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>สัดส่วน</div>

        {/* donut + legend */}
        <div style={{ display: "flex", alignItems: "center", gap: 22, marginTop: 16 }}>
          <svg width="130" height="130" viewBox="0 0 42 42">
            <circle cx="21" cy="21" r="15.9" fill="white" stroke="oklch(.95 .01 220)" strokeWidth="6"/>
            {(() => {
              const segs = [
                { p: 58, c: "oklch(.62 .14 195)" },
                { p: 22, c: "oklch(.45 .15 280)" },
                { p: 14, c: "oklch(.78 .14 28)" },
                { p: 6, c: "oklch(.78 .14 80)" },
              ];
              let off = 0;
              return segs.map((s, i) => {
                const e = <circle key={i} cx="21" cy="21" r="15.9" fill="transparent" stroke={s.c} strokeWidth="6" strokeDasharray={`${s.p} ${100 - s.p}`} strokeDashoffset={-off} transform="rotate(-90 21 21)"/>;
                off += s.p;
                return e;
              });
            })()}
            <text x="21" y="20" fontSize="5" fontWeight="600" textAnchor="middle" fill="var(--tp-ink)" fontFamily="var(--tp-font)">฿42.5K</text>
            <text x="21" y="25" fontSize="2.5" textAnchor="middle" fill="var(--tp-ink-mute)" fontFamily="var(--tp-font)">รวมวันนี้</text>
          </svg>
          <div style={{ flex: 1, display: "grid", gap: 9 }}>
            {[
              { l: "พร้อมเพย์ / QR", p: 58, c: "oklch(.62 .14 195)" },
              { l: "บัตรเครดิต", p: 22, c: "oklch(.45 .15 280)" },
              { l: "เงินสด", p: 14, c: "oklch(.78 .14 28)" },
              { l: "อีวอลเล็ท", p: 6, c: "oklch(.78 .14 80)" },
            ].map((l, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12 }}>
                <span style={{ width: 10, height: 10, borderRadius: 3, background: l.c }}/>
                <span style={{ flex: 1, color: "var(--tp-ink-soft)" }}>{l.l}</span>
                <span className="tp-tnum" style={{ fontWeight: 600 }}>{l.p}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="tp-glass" style={{ position: "absolute", left: 488, right: 24, top: 676, bottom: 24, padding: "22px 26px" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>คำสั่งซื้อล่าสุด</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>ตามเวลา</div>
          </div>
          <div style={{ flex: 1 }}/>
          <span className="tp-chip">ดูทั้งหมด</span>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "70px 1fr 90px 100px 80px", padding: "0 6px 8px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>เลขที่</span><span>โต๊ะ / ลูกค้า</span><span>วิธีจ่าย</span><span style={{ textAlign: "right" }}>ยอด</span><span style={{ textAlign: "right" }}>เวลา</span>
        </div>
        {[
          { id: "A1042", t: "โต๊ะ 7", p: "QR", v: "฿331", tm: "14:42", st: "ใหม่", c: "188" },
          { id: "A1041", t: "Take Away", p: "เงินสด", v: "฿185", tm: "14:38", st: "เสร็จ", c: "145" },
          { id: "A1040", t: "โต๊ะ 3", p: "บัตร Visa", v: "฿420", tm: "14:32", st: "เสร็จ", c: "145" },
          { id: "A1039", t: "โต๊ะ 12", p: "QR", v: "฿245", tm: "14:24", st: "เสร็จ", c: "145" },
          { id: "A1038", t: "Delivery", p: "QR", v: "฿410", tm: "14:18", st: "ส่งแล้ว", c: "145" },
        ].map((r, i) => (
          <div key={i} style={{ display: "grid", gridTemplateColumns: "70px 1fr 90px 100px 80px", alignItems: "center", padding: "10px 6px", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13 }}>
            <span className="tp-mono" style={{ fontWeight: 600 }}>{r.id}</span>
            <span>{r.t}</span>
            <span style={{ color: "var(--tp-ink-mute)" }}>{r.p}</span>
            <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>{r.v}</span>
            <span className="tp-mono" style={{ textAlign: "right", fontSize: 12, color: "var(--tp-ink-mute)" }}>{r.tm}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

const InventoryScreen = () => {
  const items = [
    { code: "TT-01", name: "ชาไทย (ใบ)", cat: "วัตถุดิบ", stock: 28, unit: "ก.ก.", min: 10, cost: 280, sold: 84, status: "ok", hue: 25, kind: "rect" },
    { code: "MT-02", name: "ผงมัทฉะ", cat: "วัตถุดิบ", stock: 4, unit: "ก.ก.", min: 5, cost: 1450, sold: 62, status: "low", hue: 145, kind: "circle" },
    { code: "MK-03", name: "นมสดวัวแดง", cat: "วัตถุดิบ", stock: 42, unit: "ลัง", min: 20, cost: 580, sold: 132, status: "ok", hue: 50, kind: "rect" },
    { code: "CB-04", name: "เมล็ดกาแฟ Arabica", cat: "วัตถุดิบ", stock: 18, unit: "ก.ก.", min: 12, cost: 920, sold: 51, status: "ok", hue: 35, kind: "circle" },
    { code: "CR-05", name: "ครัวซองต์อัลมอนด์", cat: "เบเกอรี่", stock: 12, unit: "ชิ้น", min: 20, cost: 32, sold: 32, status: "low", hue: 40, kind: "rect" },
    { code: "BR-06", name: "บราวนี่ช็อกโกแลต", cat: "เบเกอรี่", stock: 0, unit: "ชิ้น", min: 15, cost: 28, sold: 18, status: "out", hue: 28, kind: "rect" },
    { code: "CP-07", name: "แก้วพลาสติก 16oz", cat: "บรรจุภัณฑ์", stock: 1240, unit: "ใบ", min: 500, cost: 1.8, sold: 248, status: "ok", hue: 220, kind: "rect" },
    { code: "ST-08", name: "หลอดดูดกระดาษ", cat: "บรรจุภัณฑ์", stock: 380, unit: "ใบ", min: 500, cost: 0.5, sold: 220, status: "low", hue: 200, kind: "rect" },
    { code: "SY-09", name: "น้ำเชื่อม Vanilla", cat: "ไซรัป", stock: 14, unit: "ขวด", min: 6, cost: 320, sold: 22, status: "ok", hue: 65, kind: "circle" },
    { code: "SY-10", name: "น้ำเชื่อม Hazelnut", cat: "ไซรัป", stock: 7, unit: "ขวด", min: 6, cost: 380, sold: 14, status: "ok", hue: 85, kind: "circle" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>

      <header style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }} className="tp-glass">
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>คลังสินค้า</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>284 รายการ · อัปเดต 14:30</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="arrow-down" size={16}/> นำเข้า</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="arrow-up" size={16}/> ส่งออก CSV</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> เพิ่มสินค้า</button>
        </div>
      </header>

      {/* summary cards */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "มูลค่าคลังรวม", v: "฿284,540", c: "188" },
          { l: "รายการทั้งหมด", v: "284", c: "270" },
          { l: "ใกล้หมด", v: "12", c: "80" },
          { l: "หมดสต็อก", v: "3", c: "25" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "16px 22px", display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{
              width: 8, height: 56, borderRadius: 999,
              background: `linear-gradient(180deg, oklch(.85 .12 ${k.c}), oklch(.55 .14 ${k.c}))`
            }}/>
            <div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
              <div className="tp-tnum" style={{ fontSize: 26, fontWeight: 600, letterSpacing: "-.02em", marginTop: 2 }}>{k.v}</div>
            </div>
          </div>
        ))}
      </div>

      {/* table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 240, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        {/* table toolbar */}
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
          <div style={{
            flex: "0 0 320px", height: 40,
            background: "white", borderRadius: 12, border: "1px solid var(--tp-line)",
            display: "flex", alignItems: "center", padding: "0 14px", gap: 10,
          }}>
            <TPIcon name="search" size={16} color="var(--tp-ink-mute)"/>
            <input placeholder="ค้นหา รหัส / ชื่อสินค้า…" style={{ flex: 1, border: "none", background: "transparent", outline: "none", fontFamily: "inherit", fontSize: 14 }}/>
          </div>
          {["ทั้งหมด", "วัตถุดิบ", "เบเกอรี่", "ไซรัป", "บรรจุภัณฑ์"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"}>{t}</span>
          ))}
          <div style={{ flex: 1 }}/>
          <span className="tp-chip" style={{ background: "oklch(.94 .08 25)", color: "oklch(.45 .15 25)", border: "1px solid oklch(.85 .10 25)" }}>
            <TPIcon name="bell" size={13}/> 12 ใกล้หมด
          </span>
        </div>

        {/* header row */}
        <div style={{ display: "grid", gridTemplateColumns: "100px 2fr 1fr 1fr 1fr 1fr 1.2fr 90px", gap: 14, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>รหัส</span>
          <span>สินค้า</span>
          <span>หมวดหมู่</span>
          <span style={{ textAlign: "right" }}>คงเหลือ</span>
          <span style={{ textAlign: "right" }}>ขั้นต่ำ</span>
          <span style={{ textAlign: "right" }}>ต้นทุน/หน่วย</span>
          <span>สถานะ</span>
          <span></span>
        </div>

        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {items.map((it, i) => {
            const stColor = it.status === "out" ? "25" : it.status === "low" ? "80" : "145";
            const stLabel = it.status === "out" ? "หมดสต็อก" : it.status === "low" ? "ใกล้หมด" : "ปกติ";
            const pct = Math.min(100, (it.stock / (it.min * 3)) * 100);
            return (
              <div key={i} style={{
                display: "grid", gridTemplateColumns: "100px 2fr 1fr 1fr 1fr 1fr 1.2fr 90px",
                gap: 14, padding: "12px 14px", alignItems: "center",
                borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13,
                background: i % 2 ? "rgba(255,255,255,.25)" : "transparent",
                borderRadius: 8,
              }}>
                <span className="tp-mono" style={{ fontWeight: 600, color: "var(--tp-ink-soft)" }}>{it.code}</span>
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, overflow: "hidden", flexShrink: 0 }}>
                    <TPProductImg hue={it.hue} kind={it.kind}/>
                  </div>
                  <div>
                    <div style={{ fontWeight: 500 }}>{it.name}</div>
                    <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ขายแล้ว {it.sold} {it.unit}</div>
                  </div>
                </div>
                <span className="tp-chip" style={{ height: 24, fontSize: 11, padding: "0 10px" }}>{it.cat}</span>
                <div style={{ textAlign: "right" }}>
                  <div className="tp-tnum" style={{ fontWeight: 600, fontSize: 14 }}>{it.stock.toLocaleString()}</div>
                  <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>{it.unit}</div>
                </div>
                <span className="tp-tnum" style={{ textAlign: "right", color: "var(--tp-ink-mute)" }}>{it.min}</span>
                <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 500 }}>฿{it.cost.toLocaleString()}</span>
                <div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <div style={{ flex: 1, height: 5, background: "rgba(20,40,80,.06)", borderRadius: 999, overflow: "hidden" }}>
                      <div style={{
                        height: "100%", width: `${pct}%`,
                        background: `linear-gradient(90deg, oklch(.78 .14 ${stColor}), oklch(.55 .14 ${stColor}))`,
                        borderRadius: 999
                      }}/>
                    </div>
                    <span style={{
                      fontSize: 10, fontWeight: 600, padding: "2px 8px", borderRadius: 999,
                      background: `oklch(.94 .08 ${stColor})`,
                      color: `oklch(.45 .14 ${stColor})`
                    }}>{stLabel}</span>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 4, justifyContent: "flex-end" }}>
                  <button style={{ width: 30, height: 30, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)" }}><TPIcon name="plus" size={15}/></button>
                  <button style={{ width: 30, height: 30, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)" }}><TPIcon name="more" size={15}/></button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};

window.DashboardScreen = DashboardScreen;
window.InventoryScreen = InventoryScreen;

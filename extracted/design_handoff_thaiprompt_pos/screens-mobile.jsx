// Thaiprompt POS — Mobile (Manager / Waiter) + Tablet (Waiter)

const MobileManagerScreen = () => (
  <div className="tp-app" style={{ width: 390, height: 844, position: "relative", overflow: "hidden", background: "white", borderRadius: 44 }}>
    <div className="tp-bg" style={{ borderRadius: 44 }}/>
    {/* status bar */}
    <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 50, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 30px", fontSize: 14, fontWeight: 600 }}>
      <span className="tp-mono">14:42</span>
      <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
        <TPIcon name="wifi" size={14}/>
        <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" strokeWidth="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/><rect x="19" y="4" width="2" height="3" rx="1" fill="currentColor"/></svg>
      </div>
    </div>

    <div style={{ position: "absolute", left: 0, right: 0, top: 50, bottom: 84, padding: "10px 18px", overflow: "auto" }}>
      {/* greeting */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "6px 4px 18px" }}>
        <div style={{
          width: 44, height: 44, borderRadius: "50%",
          background: "linear-gradient(135deg, oklch(.82 .14 80), oklch(.65 .14 50))",
          color: "white", display: "flex", alignItems: "center", justifyContent: "center",
          fontSize: 16, fontWeight: 600, boxShadow: "0 6px 14px -4px rgba(20,40,80,.3)"
        }}>ป</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>สวัสดี, ผู้จัดการ</div>
          <div style={{ fontSize: 16, fontWeight: 600 }}>ปริม สุข</div>
        </div>
        <button className="tp-btn tp-btn-ghost tp-btn-icon" style={{ width: 40, height: 40 }}>
          <TPIcon name="bell" size={18}/>
          <span style={{ position: "absolute", top: 6, right: 6, width: 8, height: 8, borderRadius: "50%", background: "oklch(.65 .18 25)", boxShadow: "0 0 0 2px white" }}/>
        </button>
      </div>

      {/* hero card */}
      <div style={{
        padding: "20px 22px", borderRadius: 26,
        background: "linear-gradient(160deg, oklch(.40 .14 250) 0%, oklch(.20 .08 270) 100%)",
        color: "white", position: "relative", overflow: "hidden",
        boxShadow: "0 1px 0 rgba(255,255,255,.15) inset, 0 20px 40px -20px oklch(.25 .08 270 / .6)",
      }}>
        <div style={{ position: "absolute", width: 180, height: 180, right: -50, top: -50, borderRadius: "50%",
          background: "linear-gradient(135deg, oklch(.78 .14 188 / .6), transparent)" }}/>
        <div style={{ position: "absolute", width: 110, height: 110, right: 30, bottom: -40, borderRadius: "50%",
          background: "oklch(.78 .18 28 / .35)", filter: "blur(20px)" }}/>

        <div style={{ position: "relative" }}>
          <div style={{ fontSize: 11, opacity: .8, letterSpacing: ".1em", textTransform: "uppercase" }}>ยอดขายวันนี้</div>
          <div className="tp-tnum" style={{ fontSize: 38, fontWeight: 600, letterSpacing: "-.02em", marginTop: 4 }}>฿42,580</div>
          <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 4, fontSize: 12 }}>
            <span style={{ display: "inline-flex", alignItems: "center", gap: 3, padding: "2px 8px", borderRadius: 999, background: "oklch(.78 .14 145 / .35)", border: "1px solid oklch(.78 .14 145 / .5)" }}>
              <TPIcon name="arrow-up" size={12}/> 12.4%
            </span>
            <span style={{ opacity: .85 }}>กับเมื่อวาน</span>
          </div>

          {/* mini chart */}
          <svg viewBox="0 0 200 50" style={{ width: "100%", height: 50, marginTop: 14 }}>
            <defs>
              <linearGradient id="m-fill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="oklch(.85 .14 80)" stopOpacity=".6"/>
                <stop offset="100%" stopColor="oklch(.85 .14 80)" stopOpacity="0"/>
              </linearGradient>
            </defs>
            <path d="M0,40 L15,30 L30,35 L45,22 L60,28 L75,18 L90,15 L105,22 L120,12 L135,16 L150,8 L165,14 L180,5 L200,10 L200,50 L0,50 Z" fill="url(#m-fill)"/>
            <path d="M0,40 L15,30 L30,35 L45,22 L60,28 L75,18 L90,15 L105,22 L120,12 L135,16 L150,8 L165,14 L180,5 L200,10" fill="none" stroke="oklch(.85 .14 80)" strokeWidth="2" strokeLinecap="round"/>
          </svg>
        </div>
      </div>

      {/* quick stats */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginTop: 14 }}>
        {[
          { l: "บิล", v: "248", c: "188", icon: "receipt" },
          { l: "ลูกค้าใหม่", v: "32", c: "80", icon: "users" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "14px 16px", borderRadius: 18 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 30, height: 30, borderRadius: 9, background: `linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name={k.icon} size={16}/></div>
              <span style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</span>
            </div>
            <div className="tp-tnum" style={{ fontSize: 24, fontWeight: 600, marginTop: 6 }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* sections */}
      <div style={{ marginTop: 22, display: "flex", alignItems: "center" }}>
        <h3 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>ลัด</h3>
        <div style={{ flex: 1 }}/>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginTop: 10 }}>
        {[
          { i: "grid", l: "ขาย", c: "188" },
          { i: "box", l: "สต็อก", c: "270" },
          { i: "users", l: "ลูกค้า", c: "25" },
          { i: "chart", l: "รายงาน", c: "80" },
        ].map((it, i) => (
          <button key={i} style={{
            background: "rgba(255,255,255,.65)", border: "1px solid rgba(255,255,255,.7)",
            borderRadius: 18, padding: "14px 6px", cursor: "pointer", fontFamily: "inherit",
            display: "flex", flexDirection: "column", alignItems: "center", gap: 8,
            boxShadow: "0 1px 0 rgba(255,255,255,.85) inset, 0 6px 14px -10px rgba(20,40,80,.18)"
          }}>
            <div style={{ width: 38, height: 38, borderRadius: 12, background: `linear-gradient(160deg, oklch(.85 .12 ${it.c}), oklch(.62 .14 ${it.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 6px 14px -4px oklch(.65 .14 ${it.c} / .5)` }}><TPIcon name={it.i} size={20}/></div>
            <span style={{ fontSize: 11, fontWeight: 500, color: "var(--tp-ink)" }}>{it.l}</span>
          </button>
        ))}
      </div>

      {/* alerts */}
      <div style={{ marginTop: 22, display: "flex", alignItems: "center" }}>
        <h3 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>การแจ้งเตือน</h3>
        <div style={{ flex: 1 }}/>
        <span style={{ fontSize: 12, color: "var(--tp-teal-deep)" }}>ดูทั้งหมด</span>
      </div>
      {[
        { i: "bell", c: "25", t: "บราวนี่ช็อกโกแลตหมดสต็อก", s: "5 นาทีที่แล้ว" },
        { i: "tag", c: "80", t: "ผงมัทฉะใกล้หมด · เหลือ 4 ก.ก.", s: "12 นาทีที่แล้ว" },
        { i: "star", c: "188", t: "ยอดขายเช้าทะลุ ฿20K", s: "1 ชั่วโมงที่แล้ว" },
      ].map((a, i) => (
        <div key={i} style={{
          display: "flex", gap: 12, alignItems: "center",
          padding: "12px 14px", borderRadius: 16, marginTop: 8,
          background: "rgba(255,255,255,.55)", border: "1px solid rgba(255,255,255,.6)",
          boxShadow: "0 1px 0 rgba(255,255,255,.7) inset"
        }}>
          <div style={{ width: 36, height: 36, borderRadius: 11, background: `linear-gradient(160deg, oklch(.92 .08 ${a.c}), oklch(.78 .12 ${a.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name={a.i} size={16}/></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 500 }}>{a.t}</div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>{a.s}</div>
          </div>
          <TPIcon name="arrow-right" size={14} color="var(--tp-ink-mute)"/>
        </div>
      ))}
    </div>

    {/* tab bar */}
    <div style={{
      position: "absolute", left: 14, right: 14, bottom: 14, height: 64,
      borderRadius: 26, padding: "0 8px",
      background: "linear-gradient(180deg, rgba(255,255,255,.85), rgba(255,255,255,.55))",
      border: "1px solid rgba(255,255,255,.7)",
      backdropFilter: "blur(22px) saturate(180%)",
      boxShadow: "0 1px 0 rgba(255,255,255,.9) inset, 0 -1px 0 rgba(20,40,80,.06) inset, 0 12px 30px -10px rgba(20,40,80,.18)",
      display: "flex", alignItems: "center"
    }}>
      {[
        { i: "chart", l: "หน้าหลัก", on: true },
        { i: "receipt", l: "บิล" },
        { i: "grid", l: "เมนู" },
        { i: "users", l: "ลูกค้า" },
        { i: "user", l: "ฉัน" },
      ].map((it, i) => (
        <button key={i} style={{
          flex: 1, height: 56, border: "none", background: "transparent", cursor: "pointer", fontFamily: "inherit",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 3,
          color: it.on ? "var(--tp-teal-deep)" : "var(--tp-ink-mute)",
          fontWeight: it.on ? 600 : 400,
        }}>
          <TPIcon name={it.i} size={22}/>
          <span style={{ fontSize: 10 }}>{it.l}</span>
          {it.on && <div style={{ position: "absolute", bottom: 6, width: 4, height: 4, borderRadius: "50%", background: "var(--tp-teal-deep)" }}/>}
        </button>
      ))}
    </div>

    {/* home indicator */}
    <div style={{ position: "absolute", left: "50%", bottom: 6, transform: "translateX(-50%)", width: 134, height: 5, borderRadius: 999, background: "rgba(20,40,80,.4)" }}/>
  </div>
);

const TabletWaiterScreen = () => {
  const tables = [
    { n: "1", st: "ว่าง", min: "", c: "230" },
    { n: "2", st: "ใช้งาน", min: "12 นาที", c: "188", g: 4, of: 4 },
    { n: "3", st: "บิล", min: "32 นาที", c: "80", g: 3, of: 4 },
    { n: "4", st: "ว่าง", min: "", c: "230" },
    { n: "5", st: "ใช้งาน", min: "8 นาที", c: "188", g: 2, of: 2 },
    { n: "6", st: "ว่าง", min: "", c: "230" },
    { n: "7", st: "ใช้งาน", min: "24 นาที", c: "188", g: 2, of: 4, active: true },
    { n: "8", st: "ทำความสะอาด", min: "", c: "270" },
    { n: "9", st: "ว่าง", min: "", c: "230" },
    { n: "10", st: "จอง", min: "15:00", c: "25", g: 0, of: 6 },
    { n: "11", st: "ว่าง", min: "", c: "230" },
    { n: "12", st: "ใช้งาน", min: "5 นาที", c: "188", g: 3, of: 4 },
  ];
  return (
    <div className="tp-app" style={{ width: 1024, height: 768, position: "relative", overflow: "hidden", background: "black", borderRadius: 28 }}>
      <div style={{ position: "absolute", inset: 14, borderRadius: 18, overflow: "hidden" }}>
        <div className="tp-bg" style={{ position: "absolute", inset: 0 }}/>

        <header style={{ position: "absolute", left: 16, right: 16, top: 16, height: 64, display: "flex", alignItems: "center", padding: "0 18px", gap: 14 }} className="tp-glass">
          <TPLogo size={36}/>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>ผังโต๊ะ · Floor Plan</div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>iPad · Waiter Mode</div>
          </div>
          <div style={{ flex: 1 }}/>
          <div style={{ display: "flex", gap: 8 }}>
            <span className="tp-chip"><span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.78 .04 230)" }}/> ว่าง 4</span>
            <span className="tp-chip"><span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.62 .14 195)" }}/> ใช้งาน 5</span>
            <span className="tp-chip"><span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.72 .14 80)" }}/> รอเก็บเงิน 1</span>
          </div>
          <button className="tp-btn tp-btn-primary" style={{ height: 38, fontSize: 13 }}><TPIcon name="plus" size={15}/> ออเดอร์ใหม่</button>
        </header>

        <div style={{ position: "absolute", left: 16, right: 16, top: 96, bottom: 16, display: "grid", gridTemplateColumns: "1fr 280px", gap: 14 }}>
          {/* floor */}
          <div className="tp-glass" style={{ padding: 18 }}>
            <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
              <h3 style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>ชั้น 1 · ในร้าน</h3>
              <div style={{ flex: 1 }}/>
              <div style={{ display: "flex", gap: 4, padding: 3, borderRadius: 10, background: "rgba(255,255,255,.55)", border: "1px solid rgba(255,255,255,.7)" }}>
                <span className="tp-chip" style={{ height: 26, fontSize: 11, background: "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))", color: "white", border: "none" }}>ในร้าน</span>
                <span style={{ padding: "5px 10px", fontSize: 11, color: "var(--tp-ink-mute)" }}>นอกร้าน</span>
                <span style={{ padding: "5px 10px", fontSize: 11, color: "var(--tp-ink-mute)" }}>Take Away</span>
              </div>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
              {tables.map((t, i) => (
                <div key={i} style={{
                  height: 116, borderRadius: 18, padding: 14, position: "relative", cursor: "pointer",
                  background: t.active
                    ? `linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))`
                    : t.st === "ว่าง"
                      ? "linear-gradient(160deg, rgba(255,255,255,.95), rgba(255,255,255,.65))"
                      : `linear-gradient(160deg, oklch(.95 .07 ${t.c}), oklch(.88 .10 ${t.c}))`,
                  border: t.active ? "1px solid rgba(255,255,255,.4)" : "1px solid rgba(255,255,255,.7)",
                  color: t.active ? "white" : "var(--tp-ink)",
                  boxShadow: t.active
                    ? "0 1px 0 rgba(255,255,255,.4) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 14px 28px -10px oklch(.45 .14 250 / .55)"
                    : "0 1px 0 rgba(255,255,255,.9) inset, 0 8px 18px -10px rgba(20,40,80,.18)",
                }}>
                  <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
                    <span style={{ fontSize: 24, fontWeight: 600 }}>โต๊ะ {t.n}</span>
                    {t.of && <span style={{ fontSize: 11, opacity: .7, marginLeft: "auto" }}><TPIcon name="users" size={11} style={{ display: "inline", verticalAlign: "-2px" }}/> {t.g}/{t.of}</span>}
                  </div>
                  <div style={{
                    display: "inline-block", marginTop: 8,
                    padding: "3px 9px", borderRadius: 999, fontSize: 10, fontWeight: 600,
                    background: t.active ? "rgba(255,255,255,.22)" : t.st === "ว่าง" ? "rgba(20,40,80,.06)" : `oklch(.55 .14 ${t.c} / .15)`,
                    color: t.active ? "white" : t.st === "ว่าง" ? "var(--tp-ink-mute)" : `oklch(.45 .14 ${t.c})`
                  }}>{t.st}</div>
                  {t.min && <div style={{ position: "absolute", bottom: 12, left: 14, fontSize: 11, opacity: .8, fontFamily: "var(--tp-font-mono)" }}>{t.min}</div>}
                  {t.active && <div style={{ position: "absolute", bottom: 12, right: 14 }}>
                    <div style={{ width: 26, height: 26, borderRadius: "50%", background: "rgba(255,255,255,.25)", border: "1px solid rgba(255,255,255,.4)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                      <TPIcon name="arrow-right" size={14}/>
                    </div>
                  </div>}
                </div>
              ))}
            </div>
          </div>

          {/* selected table panel */}
          <div className="tp-glass" style={{ padding: 18, display: "flex", flexDirection: "column" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เลือกอยู่</div>
            <div style={{ fontSize: 22, fontWeight: 600, marginTop: 2 }}>โต๊ะ 7</div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>2/4 ที่นั่ง · เริ่ม 14:18</div>

            <div style={{ marginTop: 14, padding: "10px 12px", borderRadius: 14, background: "rgba(255,255,255,.55)", border: "1px solid rgba(255,255,255,.7)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginBottom: 4 }}>คำสั่งซื้อ #A1042</div>
              {[
                ["ชาไทยเย็น × 2", "฿130"],
                ["ชาเขียวมัทฉะ (L)", "฿95"],
                ["ครัวซองต์", "฿55"],
                ["อเมริกาโน่ร้อน", "฿60"],
              ].map(([k, v], i) => (
                <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "5px 0", fontSize: 12, borderBottom: i < 3 ? "1px dashed rgba(20,40,80,.08)" : "none" }}>
                  <span>{k}</span><span className="tp-tnum" style={{ fontWeight: 500 }}>{v}</span>
                </div>
              ))}
            </div>

            <div style={{ marginTop: 12, padding: "10px 14px", borderRadius: 14, background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.18 .06 270))", color: "white", display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <span style={{ fontSize: 13 }}>รวม</span>
              <span className="tp-tnum" style={{ fontSize: 22, fontWeight: 600 }}>฿331</span>
            </div>

            <div style={{ flex: 1 }}/>

            <div style={{ display: "grid", gap: 8 }}>
              <button className="tp-btn tp-btn-ghost" style={{ height: 42, fontSize: 13 }}><TPIcon name="plus" size={15}/> เพิ่มเมนู</button>
              <button className="tp-btn tp-btn-ghost" style={{ height: 42, fontSize: 13 }}><TPIcon name="split" size={15}/> ย้าย / รวมโต๊ะ</button>
              <button className="tp-btn tp-btn-coral" style={{ height: 48, fontSize: 14, fontWeight: 600 }}>ส่งบิล <TPIcon name="arrow-right" size={16}/></button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const MobileOrderScreen = () => (
  <div className="tp-app" style={{ width: 390, height: 844, position: "relative", overflow: "hidden", background: "white", borderRadius: 44 }}>
    <div className="tp-bg" style={{ borderRadius: 44 }}/>

    {/* status bar */}
    <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 50, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 30px", fontSize: 14, fontWeight: 600 }}>
      <span className="tp-mono">14:42</span>
      <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
        <TPIcon name="wifi" size={14}/>
        <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" strokeWidth="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/></svg>
      </div>
    </div>

    {/* nav */}
    <div style={{ position: "absolute", top: 50, left: 0, right: 0, padding: "10px 18px", display: "flex", alignItems: "center", gap: 10 }}>
      <button className="tp-btn tp-btn-ghost tp-btn-icon" style={{ width: 38, height: 38 }}><TPIcon name="arrow-right" size={16} style={{ transform: "rotate(180deg)" }}/></button>
      <div>
        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>โต๊ะ 7 · 2 ท่าน</div>
        <div style={{ fontSize: 16, fontWeight: 600 }}>รับออเดอร์</div>
      </div>
      <div style={{ flex: 1 }}/>
      <button className="tp-btn tp-btn-ghost tp-btn-icon" style={{ width: 38, height: 38 }}><TPIcon name="search" size={16}/></button>
    </div>

    {/* category tabs */}
    <div className="tp-scroll" style={{ position: "absolute", top: 110, left: 0, right: 0, padding: "0 18px", overflow: "auto", whiteSpace: "nowrap" }}>
      <div style={{ display: "inline-flex", gap: 8 }}>
        {["ของร้อน", "ของเย็น", "กาแฟ", "เบเกอรี่", "ชุดเซ็ต", "ของหวาน"].map((c, i) => (
          <span key={i} className={i === 1 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ height: 34, padding: "0 16px", fontSize: 13 }}>{c}</span>
        ))}
      </div>
    </div>

    {/* product list */}
    <div className="tp-scroll" style={{ position: "absolute", top: 160, left: 0, right: 0, bottom: 110, padding: "0 18px", overflow: "auto" }}>
      {[
        { n: "ชาไทยเย็น", p: 65, hue: 25, kind: "rect", note: "ขายดี · 84 แก้ว/วัน" },
        { n: "ชาเขียวมัทฉะลาเต้", p: 85, hue: 145, kind: "circle", note: "ออร์แกนิก ส่งจากเชียงราย" },
        { n: "อเมริกาโน่เย็น", p: 70, hue: 35, kind: "rect", note: "เมล็ด Single Origin" },
        { n: "ลาเต้ร้อน", p: 75, hue: 50, kind: "circle", note: "นมโอ๊ตได้" },
        { n: "โกโก้ปั่น", p: 80, hue: 28, kind: "rect", note: "ใหม่ · ใช้ผงโกโก้เบลเยียม" },
      ].map((p, i) => (
        <div key={i} style={{
          display: "flex", gap: 12, padding: 12, borderRadius: 18, marginBottom: 10,
          background: "rgba(255,255,255,.65)", border: "1px solid rgba(255,255,255,.7)",
          boxShadow: "0 1px 0 rgba(255,255,255,.85) inset, 0 4px 10px -6px rgba(20,40,80,.12)",
        }}>
          <div style={{ width: 78, height: 78, borderRadius: 14, overflow: "hidden", flexShrink: 0 }}>
            <TPProductImg hue={p.hue} kind={p.kind}/>
          </div>
          <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}>
            <div style={{ fontSize: 14, fontWeight: 600 }}>{p.n}</div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>{p.note}</div>
            <div style={{ flex: 1 }}/>
            <div style={{ display: "flex", alignItems: "center" }}>
              <span className="tp-tnum" style={{ fontSize: 16, fontWeight: 600, color: "var(--tp-teal-deep)" }}>฿{p.p}</span>
              <div style={{ flex: 1 }}/>
              <button className="tp-btn tp-btn-primary" style={{ width: 34, height: 34, padding: 0, borderRadius: 11 }}><TPIcon name="plus" size={16}/></button>
            </div>
          </div>
        </div>
      ))}
    </div>

    {/* cart bar */}
    <div style={{
      position: "absolute", left: 14, right: 14, bottom: 24,
      borderRadius: 26, padding: "12px 16px",
      background: "linear-gradient(160deg, oklch(.78 .14 28) 0%, oklch(.55 .18 25) 100%)",
      color: "white",
      boxShadow: "0 1px 0 rgba(255,255,255,.4) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 18px 36px -12px oklch(.55 .18 25 / .55)",
      display: "flex", alignItems: "center", gap: 14,
    }}>
      <div style={{ width: 44, height: 44, borderRadius: 14, background: "rgba(255,255,255,.22)", display: "flex", alignItems: "center", justifyContent: "center", border: "1px solid rgba(255,255,255,.3)", position: "relative" }}>
        <TPIcon name="cart" size={22}/>
        <span style={{ position: "absolute", top: -4, right: -4, width: 18, height: 18, borderRadius: "50%", background: "white", color: "oklch(.55 .18 25)", fontSize: 10, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center" }}>4</span>
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 11, opacity: .85 }}>ในตะกร้า</div>
        <div style={{ fontSize: 16, fontWeight: 600 }}>4 รายการ · ฿340</div>
      </div>
      <button style={{
        background: "rgba(255,255,255,.92)", color: "oklch(.45 .18 25)",
        border: "none", borderRadius: 16, padding: "10px 16px", fontFamily: "inherit",
        fontSize: 14, fontWeight: 600, cursor: "pointer",
        boxShadow: "0 1px 0 rgba(255,255,255,.95) inset, 0 6px 14px -4px rgba(20,40,80,.2)"
      }}>ส่งบิล <TPIcon name="arrow-right" size={14} style={{ verticalAlign: "-2px" }}/></button>
    </div>

    <div style={{ position: "absolute", left: "50%", bottom: 6, transform: "translateX(-50%)", width: 134, height: 5, borderRadius: 999, background: "rgba(20,40,80,.4)" }}/>
  </div>
);

window.MobileManagerScreen = MobileManagerScreen;
window.TabletWaiterScreen = TabletWaiterScreen;
window.MobileOrderScreen = MobileOrderScreen;

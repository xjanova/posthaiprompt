// Thaiprompt POS — Customer Self-Order at Table (full flow, Thai food restaurant)
// 4 screens: Menu (grid) · Item Customize · Cart Review · Order Confirmation

// ─── small shared bits ──────────────────────────────────────────
const PhoneFrame = ({ children }) => (
  <div className="tp-app" style={{ width: 390, height: 844, position: "relative", overflow: "hidden", background: "oklch(.985 .008 220)", borderRadius: 44, boxShadow: "0 0 0 8px #0e1014, 0 0 0 9px #2a2d34" }}>
    <div className="tp-bg" style={{ borderRadius: 44 }}/>
    {children}
    {/* notch */}
    <div style={{ position: "absolute", top: 14, left: "50%", transform: "translateX(-50%)", width: 110, height: 32, background: "#0e1014", borderRadius: 999, zIndex: 50 }}/>
    {/* home indicator */}
    <div style={{ position: "absolute", left: "50%", bottom: 8, transform: "translateX(-50%)", width: 134, height: 5, borderRadius: 999, background: "rgba(20,40,80,.42)", zIndex: 50 }}/>
  </div>
);

const StatusBar = ({ time = "19:42", dark = false }) => (
  <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 50, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 30px 0", fontSize: 14, fontWeight: 600, color: dark ? "white" : "var(--tp-ink)", zIndex: 30 }}>
    <span className="tp-mono">{time}</span>
    <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
      <TPIcon name="wifi" size={14}/>
      <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" strokeWidth="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/></svg>
    </div>
  </div>
);

// thai-food themed placeholder dish image
const DishImg = ({ hue = 25, label = "DISH" }) => (
  <div style={{ width: "100%", height: "100%", position: "relative", overflow: "hidden",
    background: `radial-gradient(120% 90% at 30% 20%, oklch(.94 .08 ${hue}) 0%, oklch(.78 .14 ${hue}) 45%, oklch(.55 .14 ${hue}) 100%)`
  }}>
    <div className="tp-img-ph" style={{ position: "absolute", inset: 0, opacity: .25 }}/>
    {/* plate */}
    <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -50%)",
      width: "72%", aspectRatio: "1 / 1", borderRadius: "50%",
      background: "radial-gradient(circle at 35% 30%, rgba(255,255,255,.6), rgba(255,255,255,.1) 55%, rgba(0,0,0,.15) 100%)",
      border: "1px solid rgba(255,255,255,.55)",
      boxShadow: "0 18px 36px -10px rgba(0,0,0,.35), inset 0 2px 0 rgba(255,255,255,.5)"
    }}/>
    {/* food blob on plate */}
    <div style={{ position: "absolute", left: "50%", top: "52%", transform: "translate(-50%, -50%)",
      width: "44%", aspectRatio: "1 / 1", borderRadius: "44% 56% 60% 40% / 50% 44% 56% 50%",
      background: `radial-gradient(circle at 40% 30%, oklch(.88 .14 ${hue + 10}), oklch(.55 .18 ${hue}) 70%, oklch(.35 .14 ${hue - 5}))`,
      boxShadow: "inset 0 -4px 8px rgba(0,0,0,.2), 0 4px 8px rgba(0,0,0,.15)"
    }}/>
    {/* highlight */}
    <div style={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(255,255,255,.18) 0%, transparent 30%, transparent 70%, rgba(0,0,0,.18) 100%)" }}/>
    <div style={{ position: "absolute", left: 10, bottom: 8, fontSize: 9, fontFamily: "var(--tp-font-mono)", color: "rgba(255,255,255,.75)", letterSpacing: ".1em", textTransform: "uppercase" }}>{label}</div>
  </div>
);

// ════════════════════════════════════════════════════════════════
// 36 · MENU (grid view, Thai food)
// ════════════════════════════════════════════════════════════════
const CustMenuScreen = () => {
  const cats = [
    { l: "แนะนำ", icon: "star", on: true },
    { l: "ข้าว", icon: "fire", on: false },
    { l: "ก๋วยเตี๋ยว", icon: "tag", on: false },
    { l: "ยำ/ส้มตำ", icon: "leaf", on: false },
    { l: "ทอด/ย่าง", icon: "fire", on: false },
    { l: "เครื่องดื่ม", icon: "coffee", on: false },
    { l: "ของหวาน", icon: "star", on: false },
  ];
  const dishes = [
    { n: "ข้าวกะเพราหมูสับไข่ดาว", th: "เนื้อหมูสับ · พริกสด · ใบกะเพรา", price: 75, hue: 25, label: "GAPRAO", tag: { l: "ขายดี #1", c: "coral" }, hot: 2 },
    { n: "ผัดไทยกุ้งสด", th: "เส้นจันท์ · กุ้งแม่น้ำ · ถั่วลิสง", price: 120, hue: 45, label: "PAD-THAI", tag: { l: "Signature", c: "gold" } },
    { n: "ต้มยำกุ้งน้ำข้น", th: "กุ้งใหญ่ · เห็ดฟาง · นมข้นจืด", price: 220, hue: 18, label: "TOMYUM", tag: { l: "แนะนำ", c: "teal" }, hot: 3 },
    { n: "ส้มตำไทยปูม้า", th: "มะละกอเส้น · ปูม้าสด · กุ้งแห้ง", price: 95, hue: 130, label: "SOMTAM", hot: 3 },
    { n: "แกงเขียวหวานไก่", th: "ไก่บ้าน · กะทิสด · พริกขี้หนู", price: 110, hue: 145, label: "GAENG", hot: 2 },
    { n: "ข้าวเหนียวมะม่วง", th: "มะม่วงน้ำดอกไม้ · กะทิหวาน", price: 85, hue: 90, label: "MANGO", tag: { l: "ตามฤดู", c: "leaf" } },
  ];

  return (
    <PhoneFrame>
      <StatusBar time="19:24"/>

      {/* header */}
      <div style={{ position: "absolute", top: 50, left: 0, right: 0, padding: "18px 18px 16px", zIndex: 20 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <TPLogo size={36}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>สวัสดี · ยินดีต้อนรับสู่</div>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: "-.01em" }}>ครัวคุณยาย · สยาม สแควร์</div>
          </div>
          <div style={{
            padding: "6px 12px", borderRadius: 12,
            background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))",
            color: "white", textAlign: "center",
            boxShadow: "0 8px 16px -6px oklch(.45 .14 250 / .5)"
          }}>
            <div style={{ fontSize: 9, opacity: .85, letterSpacing: ".15em" }}>TABLE</div>
            <div className="tp-mono" style={{ fontSize: 16, fontWeight: 800, lineHeight: 1 }}>T7</div>
          </div>
        </div>

        {/* search */}
        <div style={{ marginTop: 14, height: 44, background: "white", borderRadius: 14, border: "1px solid var(--tp-line)", display: "flex", alignItems: "center", padding: "0 14px", gap: 10, boxShadow: "0 4px 12px -6px rgba(20,40,80,.1)" }}>
          <TPIcon name="search" size={16} color="var(--tp-ink-mute)"/>
          <span style={{ flex: 1, fontSize: 13, color: "var(--tp-ink-mute)" }}>ค้นหาเมนู เช่น "กะเพรา"</span>
          <button style={{ width: 30, height: 30, borderRadius: 9, border: "none", background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
            <TPIcon name="filter" size={13}/>
          </button>
        </div>
      </div>

      {/* category scroll */}
      <div className="tp-scroll" style={{ position: "absolute", top: 196, left: 0, right: 0, padding: "0 18px", overflow: "auto", whiteSpace: "nowrap", zIndex: 15 }}>
        <div style={{ display: "inline-flex", gap: 6 }}>
          {cats.map((c, i) => (
            <span key={i} style={{
              display: "inline-flex", alignItems: "center", gap: 6,
              height: 36, padding: "0 14px", borderRadius: 999, cursor: "pointer",
              background: c.on ? "linear-gradient(180deg, oklch(.32 .08 265), oklch(.20 .06 270))" : "rgba(255,255,255,.85)",
              color: c.on ? "white" : "var(--tp-ink-soft)",
              border: c.on ? "none" : "1px solid var(--tp-line)",
              fontSize: 12, fontWeight: 600,
              boxShadow: c.on ? "0 4px 12px -4px oklch(.25 .07 265 / .55)" : "0 1px 0 rgba(255,255,255,.8) inset"
            }}>
              <TPIcon name={c.icon} size={12}/> {c.l}
            </span>
          ))}
        </div>
      </div>

      {/* featured hero */}
      <div style={{ position: "absolute", top: 246, left: 18, right: 18, height: 108, borderRadius: 20,
        background: "linear-gradient(135deg, oklch(.38 .12 18) 0%, oklch(.22 .08 25) 100%)",
        padding: "16px 18px", color: "white", overflow: "hidden",
        boxShadow: "0 18px 36px -12px oklch(.30 .12 18 / .55)"
      }}>
        <div style={{ position: "absolute", right: -20, bottom: -20, width: 130, height: 130, borderRadius: "50%",
          background: "radial-gradient(circle, oklch(.85 .14 80 / .55), transparent 70%)", filter: "blur(6px)" }}/>
        <div style={{ position: "absolute", right: 14, top: 14, width: 80, height: 80, borderRadius: "50%", overflow: "hidden",
          border: "2px solid rgba(255,255,255,.4)", boxShadow: "0 10px 24px -6px rgba(0,0,0,.5)" }}>
          <DishImg hue={25} label=""/>
        </div>
        <span style={{ display: "inline-flex", alignItems: "center", gap: 4, padding: "3px 9px", fontSize: 9, fontWeight: 700, borderRadius: 999, background: "linear-gradient(90deg, oklch(.85 .14 80), oklch(.70 .14 60))", color: "oklch(.25 .08 60)", letterSpacing: ".1em", textTransform: "uppercase" }}>
          <TPIcon name="fire" size={10}/> Set อาหารกลางวัน
        </span>
        <div style={{ fontSize: 17, fontWeight: 700, marginTop: 6, letterSpacing: "-.01em" }}>กะเพรา + น้ำดื่ม</div>
        <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginTop: 4 }}>
          <span className="tp-tnum" style={{ fontSize: 20, fontWeight: 800, color: "oklch(.85 .14 80)" }}>฿89</span>
          <span className="tp-tnum" style={{ fontSize: 12, textDecoration: "line-through", opacity: .55 }}>฿105</span>
          <span style={{ fontSize: 10, opacity: .85 }}>· ถึง 14:00</span>
        </div>
      </div>

      {/* section title */}
      <div style={{ position: "absolute", top: 372, left: 18, right: 18, display: "flex", alignItems: "baseline", gap: 8 }}>
        <span style={{ fontSize: 16, fontWeight: 700 }}>แนะนำสำหรับคุณ</span>
        <span style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>· {dishes.length} จาน</span>
        <div style={{ flex: 1 }}/>
        <span style={{ fontSize: 11, fontWeight: 600, color: "var(--tp-teal-deep)" }}>ดูทั้งหมด ›</span>
      </div>

      {/* grid */}
      <div className="tp-scroll" style={{ position: "absolute", top: 402, left: 0, right: 0, bottom: 102, padding: "0 18px 16px", overflow: "auto" }}>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
          {dishes.map((d, i) => (
            <div key={i} style={{
              borderRadius: 18, overflow: "hidden",
              background: "linear-gradient(160deg, rgba(255,255,255,.95), rgba(255,255,255,.78))",
              border: "1px solid rgba(255,255,255,.7)",
              boxShadow: "0 1px 0 rgba(255,255,255,.9) inset, 0 8px 18px -10px rgba(20,40,80,.18)",
              position: "relative"
            }}>
              <div style={{ height: 120, position: "relative" }}>
                <DishImg hue={d.hue} label={d.label}/>
                {d.tag && (
                  <div style={{ position: "absolute", top: 8, left: 8, padding: "3px 8px", borderRadius: 999, fontSize: 9, fontWeight: 700, letterSpacing: ".05em", color: "white",
                    background: d.tag.c === "coral" ? "linear-gradient(180deg, oklch(.78 .18 28), oklch(.58 .18 25))"
                      : d.tag.c === "gold" ? "linear-gradient(180deg, oklch(.85 .14 85), oklch(.65 .14 75))"
                      : d.tag.c === "leaf" ? "linear-gradient(180deg, oklch(.72 .14 145), oklch(.50 .14 150))"
                      : "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))",
                    boxShadow: "0 4px 10px -4px rgba(0,0,0,.3)"
                  }}>{d.tag.l}</div>
                )}
                {d.hot && (
                  <div style={{ position: "absolute", top: 8, right: 8, padding: "2px 6px", borderRadius: 999, fontSize: 10, background: "rgba(0,0,0,.55)", backdropFilter: "blur(8px)", color: "oklch(.88 .18 28)" }}>
                    {"🌶".repeat(d.hot)}
                  </div>
                )}
              </div>
              <div style={{ padding: "10px 12px 12px" }}>
                <div style={{ fontSize: 13, fontWeight: 600, lineHeight: 1.2, minHeight: 32 }}>{d.n}</div>
                <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", marginTop: 3, lineHeight: 1.3, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{d.th}</div>
                <div style={{ display: "flex", alignItems: "center", marginTop: 8 }}>
                  <span className="tp-tnum" style={{ fontSize: 15, fontWeight: 800, color: "var(--tp-teal-deep)" }}>฿{d.price}</span>
                  <div style={{ flex: 1 }}/>
                  <button style={{ width: 30, height: 30, borderRadius: 10, border: "none", background: "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", boxShadow: "0 4px 10px -3px oklch(.55 .13 195 / .55), 0 1px 0 rgba(255,255,255,.4) inset" }}>
                    <TPIcon name="plus" size={14}/>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* floating call waiter */}
      <button style={{
        position: "absolute", right: 16, bottom: 112, zIndex: 40,
        width: 48, height: 48, borderRadius: 16, border: "none",
        background: "white", boxShadow: "0 10px 22px -8px rgba(20,40,80,.25), 0 1px 0 rgba(255,255,255,.9) inset",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", cursor: "pointer", gap: 1
      }}>
        <TPIcon name="bell" size={18} color="oklch(.55 .18 25)"/>
        <span style={{ fontSize: 7, fontWeight: 700, color: "oklch(.45 .18 25)" }}>เรียก</span>
      </button>

      {/* cart bar */}
      <div style={{
        position: "absolute", left: 14, right: 14, bottom: 24,
        borderRadius: 22, padding: "10px 14px",
        background: "linear-gradient(160deg, oklch(.38 .12 18) 0%, oklch(.22 .08 25) 100%)",
        color: "white",
        boxShadow: "0 1px 0 rgba(255,255,255,.25) inset, 0 -2px 0 rgba(0,0,0,.2) inset, 0 18px 36px -12px oklch(.30 .12 18 / .6)",
        display: "flex", alignItems: "center", gap: 10
      }}>
        <div style={{ display: "flex" }}>
          {[25, 45, 18].map((h, i) => (
            <div key={i} style={{ width: 36, height: 36, borderRadius: 12, overflow: "hidden", border: "2px solid oklch(.22 .08 25)", marginLeft: i === 0 ? 0 : -10 }}>
              <DishImg hue={h} label=""/>
            </div>
          ))}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 10, opacity: .8 }}>ในตะกร้า · 3 จาน</div>
          <div className="tp-tnum" style={{ fontSize: 16, fontWeight: 700 }}>฿415</div>
        </div>
        <button style={{ background: "linear-gradient(180deg, oklch(.85 .14 80), oklch(.70 .14 70))", color: "oklch(.22 .08 25)", border: "none", borderRadius: 14, padding: "10px 14px", fontFamily: "inherit", fontSize: 13, fontWeight: 800, cursor: "pointer", display: "flex", alignItems: "center", gap: 6, boxShadow: "0 1px 0 rgba(255,255,255,.5) inset, 0 6px 14px -4px oklch(.70 .14 70 / .55)" }}>
          ดูตะกร้า <TPIcon name="arrow-right" size={13}/>
        </button>
      </div>
    </PhoneFrame>
  );
};

// ════════════════════════════════════════════════════════════════
// 37 · ITEM DETAIL / CUSTOMIZE
// ════════════════════════════════════════════════════════════════
const CustItemScreen = () => {
  return (
    <PhoneFrame>
      {/* hero image full-bleed */}
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 380, zIndex: 5 }}>
        <DishImg hue={25} label="GAPRAO MOO-SAB"/>
        {/* dark gradient overlay */}
        <div style={{ position: "absolute", inset: 0, background: "linear-gradient(180deg, rgba(0,0,0,.35) 0%, transparent 30%, transparent 60%, rgba(0,0,0,.05) 100%)" }}/>
      </div>

      <StatusBar dark/>

      {/* top nav over image */}
      <div style={{ position: "absolute", top: 56, left: 16, right: 16, display: "flex", alignItems: "center", zIndex: 25 }}>
        <button style={{ width: 38, height: 38, borderRadius: 12, border: "1px solid rgba(255,255,255,.35)", background: "rgba(0,0,0,.3)", backdropFilter: "blur(10px)", color: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <TPIcon name="arrow-right" size={16} style={{ transform: "rotate(180deg)" }}/>
        </button>
        <div style={{ flex: 1 }}/>
        <div style={{ padding: "6px 12px", borderRadius: 999, background: "rgba(0,0,0,.3)", backdropFilter: "blur(10px)", color: "white", fontSize: 11, fontWeight: 600, border: "1px solid rgba(255,255,255,.25)" }}>
          <TPIcon name="pin" size={11} style={{ verticalAlign: "-1px", marginRight: 4 }}/> โต๊ะ T7
        </div>
      </div>

      {/* sheet */}
      <div style={{ position: "absolute", top: 320, left: 0, right: 0, bottom: 0, background: "oklch(.985 .008 220)", borderRadius: "28px 28px 0 0", padding: "12px 22px 0", zIndex: 20, boxShadow: "0 -10px 30px -10px rgba(20,40,80,.18)" }}>
        {/* handle */}
        <div style={{ width: 44, height: 5, borderRadius: 999, background: "var(--tp-line)", margin: "0 auto 14px" }}/>

        <div style={{ display: "flex", alignItems: "flex-start", gap: 8 }}>
          <div style={{ flex: 1 }}>
            <div style={{ display: "flex", gap: 6, marginBottom: 6 }}>
              <span style={{ padding: "2px 8px", borderRadius: 999, fontSize: 9, fontWeight: 700, background: "linear-gradient(180deg, oklch(.78 .18 28), oklch(.58 .18 25))", color: "white", letterSpacing: ".05em" }}>ขายดี #1</span>
              <span style={{ padding: "2px 8px", borderRadius: 999, fontSize: 9, fontWeight: 600, background: "oklch(.96 .04 28)", color: "oklch(.45 .15 25)" }}>🌶 เผ็ดกลาง</span>
            </div>
            <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-.02em", lineHeight: 1.1 }}>ข้าวกะเพราหมูสับไข่ดาว</div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 4, lineHeight: 1.4 }}>หมูสับสด ผัดกับใบกะเพราไทย พริกขี้หนูสวน เสิร์ฟพร้อมไข่ดาวกรอบ ข้าวหอมมะลิ</div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 4, padding: "5px 10px", borderRadius: 12, background: "linear-gradient(180deg, oklch(.96 .04 80), oklch(.92 .06 75))", border: "1px solid oklch(.85 .08 80)" }}>
            <TPIcon name="star" size={12} color="oklch(.55 .14 75)"/>
            <span className="tp-tnum" style={{ fontSize: 12, fontWeight: 700 }}>4.9</span>
          </div>
        </div>

        {/* quick meta */}
        <div style={{ display: "flex", gap: 6, marginTop: 12 }}>
          {[
            { i: "clock", l: "~12 นาที" },
            { i: "fire", l: "520 kcal" },
            { i: "leaf", l: "ไม่มีถั่ว" }
          ].map((m, i) => (
            <div key={i} style={{ flex: 1, padding: "8px 6px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)", display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
              <TPIcon name={m.i} size={14} color="var(--tp-ink-soft)"/>
              <span style={{ fontSize: 10, fontWeight: 600 }}>{m.l}</span>
            </div>
          ))}
        </div>

        {/* options scroll */}
        <div className="tp-scroll" style={{ marginTop: 16, marginLeft: -22, marginRight: -22, paddingLeft: 22, paddingRight: 22, paddingBottom: 110, overflow: "auto", maxHeight: 380 }}>
          {/* size */}
          <div style={{ display: "flex", alignItems: "baseline", marginBottom: 8 }}>
            <span style={{ fontSize: 13, fontWeight: 700 }}>ขนาด</span>
            <span style={{ fontSize: 10, color: "oklch(.55 .18 25)", marginLeft: 6, fontWeight: 600 }}>* จำเป็น</span>
            <div style={{ flex: 1 }}/>
            <span style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>เลือก 1</span>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6, marginBottom: 16 }}>
            {[
              { l: "ปกติ", p: "", on: false },
              { l: "พิเศษ", p: "+15", on: true },
              { l: "จัมโบ้", p: "+30", on: false },
            ].map((s, i) => (
              <div key={i} style={{
                padding: "10px 6px", borderRadius: 12, textAlign: "center",
                background: s.on ? "linear-gradient(180deg, oklch(.32 .08 265), oklch(.20 .06 270))" : "white",
                color: s.on ? "white" : "var(--tp-ink)",
                border: s.on ? "1px solid oklch(.30 .08 265)" : "1px solid var(--tp-line)",
                boxShadow: s.on ? "0 6px 14px -4px oklch(.25 .07 265 / .5)" : "none",
                cursor: "pointer"
              }}>
                <div style={{ fontSize: 13, fontWeight: 600 }}>{s.l}</div>
                <div className="tp-tnum" style={{ fontSize: 10, opacity: .8, marginTop: 2 }}>{s.p || "ราคามาตรฐาน"}</div>
              </div>
            ))}
          </div>

          {/* spiciness */}
          <div style={{ display: "flex", alignItems: "center", marginBottom: 8 }}>
            <span style={{ fontSize: 13, fontWeight: 700 }}>ระดับความเผ็ด</span>
            <div style={{ flex: 1 }}/>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 6, marginBottom: 16 }}>
            {[
              { l: "ไม่เผ็ด", h: 0, on: false },
              { l: "น้อย", h: 1, on: false },
              { l: "กลาง", h: 2, on: true },
              { l: "เผ็ดมาก", h: 4, on: false },
            ].map((s, i) => (
              <div key={i} style={{
                padding: "8px 4px", borderRadius: 10, textAlign: "center",
                background: s.on ? "linear-gradient(180deg, oklch(.94 .10 28), oklch(.85 .14 25 / .35))" : "white",
                color: s.on ? "oklch(.40 .18 25)" : "var(--tp-ink-soft)",
                border: s.on ? "1.5px solid oklch(.65 .18 25)" : "1px solid var(--tp-line)",
                cursor: "pointer"
              }}>
                <div style={{ fontSize: 12, marginBottom: 2 }}>{s.h === 0 ? "—" : "🌶".repeat(s.h)}</div>
                <div style={{ fontSize: 10, fontWeight: 600 }}>{s.l}</div>
              </div>
            ))}
          </div>

          {/* add-ons */}
          <div style={{ display: "flex", alignItems: "baseline", marginBottom: 8 }}>
            <span style={{ fontSize: 13, fontWeight: 700 }}>เพิ่มเติม</span>
            <span style={{ fontSize: 10, color: "var(--tp-ink-mute)", marginLeft: 6 }}>เลือกได้หลายอย่าง</span>
          </div>
          {[
            { l: "ไข่ดาวเพิ่ม 1 ฟอง", p: 15, on: true },
            { l: "ขอข้าวเพิ่ม", p: 10, on: false },
            { l: "พริกน้ำปลาเพิ่ม", p: 0, on: true },
            { l: "ไม่ใส่กระเทียม", p: 0, on: false },
          ].map((a, i, arr) => (
            <div key={i} style={{ display: "flex", alignItems: "center", padding: "10px 0", borderBottom: i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none" }}>
              <div style={{
                width: 22, height: 22, borderRadius: 7,
                background: a.on ? "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))" : "white",
                border: a.on ? "none" : "1.5px solid var(--tp-line)",
                display: "flex", alignItems: "center", justifyContent: "center", marginRight: 12,
                boxShadow: a.on ? "0 2px 6px -2px oklch(.55 .13 195 / .55)" : "none"
              }}>
                {a.on && <TPIcon name="check" size={14} color="white" stroke={2.2}/>}
              </div>
              <span style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>{a.l}</span>
              <span className="tp-tnum" style={{ fontSize: 12, fontWeight: 700, color: a.p ? "var(--tp-teal-deep)" : "var(--tp-ink-mute)" }}>{a.p ? `+฿${a.p}` : "ฟรี"}</span>
            </div>
          ))}

          {/* note */}
          <div style={{ marginTop: 16, fontSize: 13, fontWeight: 700, marginBottom: 8 }}>หมายเหตุถึงร้าน</div>
          <div style={{ padding: "12px 14px", borderRadius: 14, background: "white", border: "1px solid var(--tp-line)", minHeight: 60, fontSize: 13, color: "var(--tp-ink-mute)" }}>
            ไม่ใส่ผักชี แพ้กลิ่น 🙏
          </div>
        </div>
      </div>

      {/* bottom action — qty + add to cart */}
      <div style={{ position: "absolute", left: 14, right: 14, bottom: 24, zIndex: 30, display: "flex", gap: 8 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 0, background: "white", borderRadius: 18, border: "1px solid var(--tp-line)", padding: 5, boxShadow: "0 8px 20px -8px rgba(20,40,80,.18)" }}>
          <button style={{ width: 38, height: 46, border: "none", background: "transparent", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)" }}>
            <TPIcon name="minus" size={16}/>
          </button>
          <span className="tp-tnum" style={{ width: 30, textAlign: "center", fontSize: 16, fontWeight: 800 }}>2</span>
          <button style={{ width: 38, height: 46, border: "none", background: "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))", color: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: 13, boxShadow: "0 4px 10px -3px oklch(.55 .13 195 / .55)" }}>
            <TPIcon name="plus" size={16}/>
          </button>
        </div>
        <button style={{
          flex: 1, height: 56, borderRadius: 18, border: "none",
          background: "linear-gradient(160deg, oklch(.38 .12 18) 0%, oklch(.22 .08 25) 100%)",
          color: "white", fontFamily: "inherit", fontSize: 14, fontWeight: 700, cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
          boxShadow: "0 1px 0 rgba(255,255,255,.3) inset, 0 -2px 0 rgba(0,0,0,.2) inset, 0 14px 28px -10px oklch(.30 .12 18 / .6)"
        }}>
          <span>เพิ่มลงตะกร้า</span>
          <span style={{ width: 1, height: 20, background: "rgba(255,255,255,.3)" }}/>
          <span className="tp-tnum" style={{ fontWeight: 800 }}>฿180</span>
        </button>
      </div>
    </PhoneFrame>
  );
};

// ════════════════════════════════════════════════════════════════
// 38 · CART REVIEW
// ════════════════════════════════════════════════════════════════
const CustCartScreen = () => {
  const items = [
    { n: "ข้าวกะเพราหมูสับไข่ดาว", o: "พิเศษ · เผ็ดกลาง · ไข่ดาวเพิ่ม", q: 2, p: 180, hue: 25, l: "GAPRAO" },
    { n: "ผัดไทยกุ้งสด", o: "ปกติ · กุ้งเพิ่ม 2 ตัว", q: 1, p: 150, hue: 45, l: "PADTHAI" },
    { n: "ต้มยำกุ้งน้ำข้น", o: "ถ้วยกลาง · เผ็ดน้อย", q: 1, p: 220, hue: 18, l: "TOMYUM", note: "ไม่ใส่ผักชี แพ้กลิ่น" },
  ];
  const subtotal = 730;
  const service = 73;
  const total = 803;

  return (
    <PhoneFrame>
      <StatusBar time="19:32"/>

      {/* nav */}
      <div style={{ position: "absolute", top: 50, left: 0, right: 0, padding: "10px 18px", display: "flex", alignItems: "center", gap: 12, zIndex: 20 }}>
        <button style={{ width: 38, height: 38, borderRadius: 12, border: "1px solid var(--tp-line)", background: "rgba(255,255,255,.85)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <TPIcon name="arrow-right" size={16} style={{ transform: "rotate(180deg)" }}/>
        </button>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: "-.02em" }}>ตะกร้าของคุณ</div>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", display: "flex", alignItems: "center", gap: 6 }}>
            <TPIcon name="pin" size={11}/> โต๊ะ T7 · 2 ท่าน
          </div>
        </div>
        <button style={{ width: 38, height: 38, borderRadius: 12, border: "1px solid var(--tp-line)", background: "rgba(255,255,255,.85)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "oklch(.55 .18 25)" }}>
          <TPIcon name="trash" size={16}/>
        </button>
      </div>

      {/* items */}
      <div className="tp-scroll" style={{ position: "absolute", top: 108, left: 0, right: 0, bottom: 304, overflow: "auto", padding: "0 18px" }}>
        {items.map((it, i) => (
          <div key={i} style={{
            display: "flex", gap: 12, padding: 12, borderRadius: 18, marginBottom: 10,
            background: "linear-gradient(160deg, rgba(255,255,255,.95), rgba(255,255,255,.8))",
            border: "1px solid rgba(255,255,255,.7)",
            boxShadow: "0 1px 0 rgba(255,255,255,.9) inset, 0 6px 14px -8px rgba(20,40,80,.14)"
          }}>
            <div style={{ width: 76, height: 76, borderRadius: 14, overflow: "hidden", flexShrink: 0 }}>
              <DishImg hue={it.hue} label={it.l}/>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: "flex", alignItems: "flex-start", gap: 6 }}>
                <span style={{ fontSize: 14, fontWeight: 700, flex: 1, lineHeight: 1.2 }}>{it.n}</span>
                <button style={{ width: 22, height: 22, borderRadius: 7, border: "none", background: "rgba(20,40,80,.06)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-mute)" }}>
                  <TPIcon name="x" size={11}/>
                </button>
              </div>
              <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", marginTop: 3, lineHeight: 1.35 }}>{it.o}</div>
              {it.note && (
                <div style={{ marginTop: 5, padding: "3px 8px", borderRadius: 6, background: "oklch(.96 .04 80)", color: "oklch(.45 .14 75)", fontSize: 10, fontWeight: 500, display: "inline-flex", alignItems: "center", gap: 4 }}>
                  📝 {it.note}
                </div>
              )}
              <div style={{ display: "flex", alignItems: "center", marginTop: 8 }}>
                <span className="tp-tnum" style={{ fontSize: 15, fontWeight: 800, color: "var(--tp-teal-deep)" }}>฿{it.p * it.q}</span>
                <div style={{ flex: 1 }}/>
                <div style={{ display: "flex", alignItems: "center", gap: 0, background: "white", borderRadius: 10, border: "1px solid var(--tp-line)", padding: 3 }}>
                  <button style={{ width: 26, height: 26, border: "none", background: "transparent", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)" }}>
                    <TPIcon name="minus" size={12}/>
                  </button>
                  <span className="tp-tnum" style={{ width: 24, textAlign: "center", fontSize: 13, fontWeight: 700 }}>{it.q}</span>
                  <button style={{ width: 26, height: 26, border: "none", background: "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))", color: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: 8 }}>
                    <TPIcon name="plus" size={12}/>
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}

        {/* add more inline */}
        <button style={{
          width: "100%", padding: 14, borderRadius: 16,
          background: "rgba(255,255,255,.5)", border: "1.5px dashed oklch(.62 .14 195 / .55)",
          color: "var(--tp-teal-deep)", fontFamily: "inherit", fontSize: 13, fontWeight: 600, cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8
        }}>
          <TPIcon name="plus" size={15}/> สั่งเพิ่มอีกจาน
        </button>

        {/* coupon */}
        <div style={{ marginTop: 16, padding: "14px 14px", borderRadius: 16, background: "linear-gradient(135deg, oklch(.96 .08 80), oklch(.92 .10 70))", border: "1px solid oklch(.85 .10 75)", display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 36, height: 36, borderRadius: 11, background: "linear-gradient(180deg, oklch(.85 .14 80), oklch(.65 .14 70))", color: "oklch(.22 .08 60)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 4px 10px -3px oklch(.65 .14 70 / .5)" }}>
            <TPIcon name="tag" size={16}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, fontWeight: 700 }}>มีโค้ดส่วนลด?</div>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>สมาชิก Gold ใช้โค้ด <span className="tp-mono">TP-GOLD</span></div>
          </div>
          <button style={{ padding: "6px 12px", borderRadius: 10, border: "none", background: "oklch(.22 .08 60)", color: "white", fontSize: 11, fontWeight: 700, cursor: "pointer", fontFamily: "inherit" }}>ใส่โค้ด</button>
        </div>
      </div>

      {/* summary */}
      <div style={{ position: "absolute", left: 14, right: 14, bottom: 24, borderRadius: 24, padding: "18px 18px 14px",
        background: "linear-gradient(160deg, rgba(255,255,255,.97), rgba(255,255,255,.85))",
        border: "1px solid rgba(255,255,255,.7)", backdropFilter: "blur(20px)",
        boxShadow: "0 1px 0 rgba(255,255,255,.9) inset, 0 -2px 0 rgba(20,40,80,.04) inset, 0 18px 36px -12px rgba(20,40,80,.22)",
        zIndex: 25
      }}>
        {/* rows */}
        {[
          { l: "ค่าอาหาร (4 จาน)", v: `฿${subtotal}` },
          { l: "Service Charge 10%", v: `฿${service}` },
        ].map((r, i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", fontSize: 12, color: "var(--tp-ink-soft)", marginBottom: 6 }}>
            <span>{r.l}</span>
            <span className="tp-tnum">{r.v}</span>
          </div>
        ))}
        <div style={{ height: 1, background: "var(--tp-line)", margin: "8px 0 10px" }}/>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
          <div>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ยอดรวม</div>
            <div className="tp-tnum" style={{ fontSize: 26, fontWeight: 800, color: "var(--tp-ink)", letterSpacing: "-.02em" }}>฿{total}</div>
          </div>
          <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", textAlign: "right", lineHeight: 1.4 }}>
            ชำระที่โต๊ะ<br/>หลังเสิร์ฟครบ
          </div>
        </div>

        <button style={{
          width: "100%", marginTop: 14, height: 56, borderRadius: 18, border: "none",
          background: "linear-gradient(160deg, oklch(.38 .12 18) 0%, oklch(.22 .08 25) 100%)",
          color: "white", fontFamily: "inherit", fontSize: 15, fontWeight: 800, cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
          boxShadow: "0 1px 0 rgba(255,255,255,.25) inset, 0 -2px 0 rgba(0,0,0,.2) inset, 0 14px 28px -10px oklch(.30 .12 18 / .6)"
        }}>
          <TPIcon name="fire" size={18} color="oklch(.85 .14 80)"/>
          ส่งครัวเลย · เริ่มทำทันที
          <TPIcon name="arrow-right" size={16}/>
        </button>
      </div>
    </PhoneFrame>
  );
};

// ════════════════════════════════════════════════════════════════
// 39 · ORDER CONFIRMATION (sent to kitchen)
// ════════════════════════════════════════════════════════════════
const CustConfirmScreen = () => {
  return (
    <PhoneFrame>
      <StatusBar time="19:33"/>

      {/* big celebratory hero */}
      <div style={{ position: "absolute", top: 60, left: 18, right: 18, bottom: 130, borderRadius: 28, overflow: "hidden",
        background: "linear-gradient(160deg, oklch(.78 .14 188) 0%, oklch(.45 .14 250) 60%, oklch(.30 .12 270) 100%)",
        boxShadow: "0 24px 60px -20px oklch(.30 .12 270 / .6)"
      }}>
        {/* decorative orbs */}
        <div style={{ position: "absolute", right: -40, top: -40, width: 200, height: 200, borderRadius: "50%", background: "radial-gradient(circle, oklch(.85 .14 80 / .55), transparent 70%)", filter: "blur(8px)" }}/>
        <div style={{ position: "absolute", left: -30, bottom: 100, width: 140, height: 140, borderRadius: "50%", background: "radial-gradient(circle, oklch(.78 .18 28 / .45), transparent 70%)", filter: "blur(10px)" }}/>

        {/* check mark badge */}
        <div style={{ position: "absolute", top: 50, left: "50%", transform: "translateX(-50%)" }}>
          <div style={{ width: 96, height: 96, borderRadius: "50%",
            background: "linear-gradient(160deg, oklch(.85 .14 80) 0%, oklch(.65 .14 60) 100%)",
            border: "4px solid rgba(255,255,255,.4)",
            display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 18px 36px -10px oklch(.65 .14 60 / .65), inset 0 2px 0 rgba(255,255,255,.5)"
          }}>
            <TPIcon name="check" size={48} color="white" stroke={3}/>
          </div>
          {/* ripple */}
          <div style={{ position: "absolute", inset: -12, borderRadius: "50%", border: "2px solid rgba(255,255,255,.25)" }}/>
          <div style={{ position: "absolute", inset: -24, borderRadius: "50%", border: "2px solid rgba(255,255,255,.12)" }}/>
        </div>

        {/* text */}
        <div style={{ position: "absolute", top: 180, left: 22, right: 22, textAlign: "center", color: "white" }}>
          <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: "-.02em", lineHeight: 1.1 }}>ส่งครัวเรียบร้อย ✨</div>
          <div style={{ fontSize: 13, marginTop: 8, opacity: .88 }}>ครัวรับออเดอร์แล้ว · เริ่มทำทันที<br/>นั่งสบายๆ ได้เลยค่ะ</div>

          {/* order number card */}
          <div style={{ marginTop: 22, display: "inline-flex", alignItems: "center", gap: 18,
            padding: "16px 22px", borderRadius: 18,
            background: "rgba(255,255,255,.14)", border: "1px solid rgba(255,255,255,.28)",
            backdropFilter: "blur(20px)",
            boxShadow: "0 1px 0 rgba(255,255,255,.25) inset"
          }}>
            <div style={{ textAlign: "left" }}>
              <div style={{ fontSize: 9, opacity: .8, letterSpacing: ".15em" }}>ORDER #</div>
              <div className="tp-mono" style={{ fontSize: 22, fontWeight: 800, letterSpacing: ".02em" }}>A1042</div>
            </div>
            <div style={{ width: 1, height: 30, background: "rgba(255,255,255,.3)" }}/>
            <div style={{ textAlign: "left" }}>
              <div style={{ fontSize: 9, opacity: .8, letterSpacing: ".15em" }}>TABLE</div>
              <div className="tp-mono" style={{ fontSize: 22, fontWeight: 800 }}>T7</div>
            </div>
            <div style={{ width: 1, height: 30, background: "rgba(255,255,255,.3)" }}/>
            <div style={{ textAlign: "left" }}>
              <div style={{ fontSize: 9, opacity: .8, letterSpacing: ".15em" }}>ETA</div>
              <div className="tp-mono" style={{ fontSize: 22, fontWeight: 800 }}>~14<span style={{ fontSize: 12, opacity: .8 }}>นาที</span></div>
            </div>
          </div>
        </div>

        {/* progress strip */}
        <div style={{ position: "absolute", bottom: 28, left: 22, right: 22 }}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10, color: "white" }}>
            {[
              { l: "ส่งครัว", icon: "check", on: true, now: false },
              { l: "ครัวรับ", icon: "fire", on: true, now: true },
              { l: "กำลังทำ", icon: "coffee", on: false, now: false },
              { l: "เสิร์ฟ", icon: "star", on: false, now: false }
            ].map((s, i) => (
              <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 5 }}>
                <div style={{ width: 30, height: 30, borderRadius: "50%",
                  background: s.now ? "linear-gradient(160deg, oklch(.85 .14 80), oklch(.65 .14 60))"
                    : s.on ? "rgba(255,255,255,.92)" : "rgba(255,255,255,.15)",
                  color: s.now ? "white" : s.on ? "oklch(.45 .14 250)" : "rgba(255,255,255,.55)",
                  border: s.now ? "none" : s.on ? "none" : "1px solid rgba(255,255,255,.25)",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  boxShadow: s.now ? "0 6px 14px -4px oklch(.65 .14 60 / .65), 0 0 0 4px oklch(.85 .14 80 / .25)" : "none"
                }}>
                  <TPIcon name={s.icon} size={14} stroke={2}/>
                </div>
                <span style={{ fontSize: 10, fontWeight: 600, opacity: s.on ? 1 : .65 }}>{s.l}</span>
              </div>
            ))}
          </div>
          {/* progress bar */}
          <div style={{ height: 4, borderRadius: 999, background: "rgba(255,255,255,.18)", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: "42%", borderRadius: 999, background: "linear-gradient(90deg, oklch(.85 .14 80), oklch(.78 .14 28))", boxShadow: "0 0 12px oklch(.85 .14 80 / .8)" }}/>
          </div>
        </div>
      </div>

      {/* actions */}
      <div style={{ position: "absolute", left: 14, right: 14, bottom: 24, display: "flex", gap: 8, zIndex: 25 }}>
        <button style={{
          flex: 1, height: 56, borderRadius: 18,
          background: "white", color: "var(--tp-ink)",
          border: "1px solid var(--tp-line)", fontFamily: "inherit", fontSize: 13, fontWeight: 700, cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
          boxShadow: "0 8px 20px -8px rgba(20,40,80,.18), 0 1px 0 rgba(255,255,255,.9) inset"
        }}>
          <TPIcon name="plus" size={16}/> สั่งเพิ่ม
        </button>
        <button style={{
          flex: 1.5, height: 56, borderRadius: 18, border: "none",
          background: "linear-gradient(160deg, oklch(.38 .12 18), oklch(.22 .08 25))",
          color: "white", fontFamily: "inherit", fontSize: 13, fontWeight: 700, cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
          boxShadow: "0 14px 28px -10px oklch(.30 .12 18 / .6), 0 1px 0 rgba(255,255,255,.25) inset"
        }}>
          <TPIcon name="receipt" size={16}/> ติดตามออเดอร์
        </button>
      </div>
    </PhoneFrame>
  );
};

window.CustMenuScreen = CustMenuScreen;
window.CustItemScreen = CustItemScreen;
window.CustCartScreen = CustCartScreen;
window.CustConfirmScreen = CustConfirmScreen;

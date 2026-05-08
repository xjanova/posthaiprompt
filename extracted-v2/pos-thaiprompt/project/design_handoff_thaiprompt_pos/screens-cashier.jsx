// Thaiprompt POS — Screen 1: Cashier (main POS terminal, Windows)
// 1440 × 900

const CashierScreen = () => {
  const cats = [
    { id: "hot", name: "ของร้อน", icon: "fire", count: 18, hue: 25 },
    { id: "cold", name: "ของเย็น", icon: "leaf", count: 22, hue: 188 },
    { id: "coffee", name: "กาแฟ", icon: "coffee", count: 14, hue: 60 },
    { id: "bakery", name: "เบเกอรี่", icon: "tag", count: 11, hue: 35 },
    { id: "set", name: "ชุดเซ็ต", icon: "star", count: 6, hue: 280 },
  ];
  const products = [
    { name: "ชาไทยเย็น", price: 65, hue: 25, tag: "ขายดี", kind: "rect", code: "TT-01" },
    { name: "ชาเขียวมัทฉะลาเต้", price: 85, hue: 145, kind: "circle", code: "MT-02" },
    { name: "อเมริกาโน่เย็น", price: 70, hue: 35, kind: "rect", code: "AM-03" },
    { name: "ลาเต้ร้อน", price: 75, hue: 50, kind: "circle", code: "LT-04" },
    { name: "โกโก้ปั่น", price: 80, hue: 28, tag: "ใหม่", kind: "rect", code: "CC-05" },
    { name: "ชามะนาวโซดา", price: 55, hue: 105, kind: "circle", code: "LM-06" },
    { name: "เอสเปรสโซ่", price: 60, hue: 40, kind: "rect", code: "ES-07" },
    { name: "นมสดน้ำผึ้ง", price: 65, hue: 70, kind: "rect", code: "HM-08" },
    { name: "ชาดำเย็น", price: 50, hue: 30, kind: "circle", code: "BT-09" },
    { name: "คาปูชิโน่", price: 75, hue: 45, kind: "rect", code: "CP-10" },
    { name: "สตรอเบอร์รี่ปั่น", price: 90, hue: 18, tag: "พรีเมียม", kind: "circle", code: "SB-11" },
    { name: "ชาใต้หวันโอชา", price: 70, hue: 165, kind: "rect", code: "OC-12" },
  ];
  const cart = [
    { name: "ชาไทยเย็น", note: "หวานน้อย ไม่เพิ่มไข่มุก", qty: 2, price: 65, hue: 25, kind: "rect" },
    { name: "ชาเขียวมัทฉะลาเต้", note: "ขนาดใหญ่ +10", qty: 1, price: 95, hue: 145, kind: "circle" },
    { name: "ครัวซองต์อัลมอนด์", note: "อุ่น", qty: 1, price: 55, hue: 35, kind: "rect" },
    { name: "อเมริกาโน่ร้อน", note: "ไม่ใส่น้ำตาล", qty: 1, price: 60, hue: 30, kind: "circle" },
  ];
  const subtotal = cart.reduce((s, i) => s + i.qty * i.price, 0);
  const discount = 30;
  const tax = Math.round((subtotal - discount) * 0.07);
  const total = subtotal - discount + tax;

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>

      {/* ─── side rail ─── */}
      <aside style={{
        position: "absolute", left: 18, top: 18, bottom: 18, width: 84,
        display: "flex", flexDirection: "column", alignItems: "center",
        padding: "20px 0", gap: 10,
      }} className="tp-glass">
        <TPLogo size={48}/>
        <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: ".15em", marginTop: 2, color: "var(--tp-ink-soft)" }}>POS</div>
        <div style={{ height: 1, width: 36, background: "var(--tp-line)", margin: "12px 0" }}/>
        {[
          { i: "grid", on: true, l: "ขาย" },
          { i: "receipt", l: "บิล" },
          { i: "users", l: "ลูกค้า" },
          { i: "box", l: "สต็อก" },
          { i: "chart", l: "รายงาน" },
          { i: "table", l: "โต๊ะ" },
          { i: "settings", l: "ตั้งค่า" },
        ].map((it, k) => (
          <button key={k} style={{
            width: 56, height: 56, borderRadius: 16, border: "none", cursor: "pointer",
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 3,
            background: it.on ? "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))" : "transparent",
            color: it.on ? "white" : "var(--tp-ink-soft)",
            boxShadow: it.on ? "0 1px 0 rgba(255,255,255,.5) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 8px 18px -6px oklch(.55 .13 195 / .55)" : "none",
            fontFamily: "inherit",
          }}>
            <TPIcon name={it.i} size={22}/>
            <span style={{ fontSize: 10, fontWeight: 500 }}>{it.l}</span>
          </button>
        ))}
        <div style={{ flex: 1 }}/>
        <button className="tp-btn tp-btn-icon" style={{ width: 56, height: 56, borderRadius: 16 }}><TPIcon name="logout" size={22}/></button>
      </aside>

      {/* ─── top bar ─── */}
      <header style={{
        position: "absolute", left: 124, right: 18, top: 18, height: 76,
        display: "flex", alignItems: "center", padding: "0 22px", gap: 18,
      }} className="tp-glass">
        <div style={{
          flex: "0 0 360px", height: 44,
          background: "rgba(255,255,255,.65)", borderRadius: 14, border: "1px solid rgba(255,255,255,.7)",
          display: "flex", alignItems: "center", padding: "0 14px", gap: 10,
          boxShadow: "0 1px 0 rgba(255,255,255,.85) inset",
        }}>
          <TPIcon name="search" size={18} color="var(--tp-ink-soft)"/>
          <input placeholder="ค้นหาสินค้า / สแกนบาร์โค้ด…" style={{ flex: 1, border: "none", background: "transparent", outline: "none", fontFamily: "inherit", fontSize: 14, color: "var(--tp-ink)" }}/>
          <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", padding: "3px 8px", borderRadius: 6, background: "rgba(20,40,80,.06)" }}>F2</span>
        </div>

        <div style={{ display: "flex", gap: 8 }}>
          <span className="tp-chip tp-chip-active"><TPIcon name="table" size={13}/> โต๊ะ 7 · 4 ที่นั่ง</span>
          <span className="tp-chip">ทานที่นี่</span>
          <span className="tp-chip">กลับบ้าน</span>
        </div>

        <div style={{ flex: 1 }}/>

        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span className="tp-chip"><span className="tp-dot"/> ออนไลน์</span>
          <span className="tp-chip"><TPIcon name="printer" size={13}/> พร้อม</span>
          <span className="tp-chip tp-mono">14:32</span>
        </div>

        <div style={{ width: 1, height: 36, background: "var(--tp-line)" }}/>

        <button className="tp-btn tp-btn-ghost" style={{ height: 44, padding: "0 14px", gap: 10 }}>
          <div style={{
            width: 30, height: 30, borderRadius: "50%",
            background: "linear-gradient(135deg, oklch(.82 .14 80), oklch(.65 .14 50))",
            display: "flex", alignItems: "center", justifyContent: "center",
            color: "white", fontSize: 13, fontWeight: 600,
            boxShadow: "0 4px 10px -3px rgba(20,40,80,.3)"
          }}>ป</div>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start", lineHeight: 1.15 }}>
            <span style={{ fontSize: 13, fontWeight: 600 }}>ปริม สุข</span>
            <span style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>แคชเชียร์ #02</span>
          </div>
        </button>
      </header>

      {/* ─── product area ─── */}
      <main style={{ position: "absolute", left: 124, top: 110, bottom: 18, right: 478 }}>
        {/* category strip */}
        <div style={{ display: "flex", gap: 12, marginBottom: 14, overflow: "hidden" }}>
          {cats.map((c, i) => (
            <button key={c.id} style={{
              flex: 1, minWidth: 0, height: 86, borderRadius: 20, border: "none", cursor: "pointer",
              padding: "0 16px", display: "flex", alignItems: "center", gap: 12,
              background: i === 0
                ? `linear-gradient(160deg, oklch(.82 .12 ${c.hue}), oklch(.55 .14 ${c.hue}))`
                : "linear-gradient(160deg, rgba(255,255,255,.92), rgba(255,255,255,.62))",
              color: i === 0 ? "white" : "var(--tp-ink)",
              border: i === 0 ? "1px solid rgba(255,255,255,.4)" : "1px solid rgba(255,255,255,.7)",
              boxShadow: i === 0
                ? `0 1px 0 rgba(255,255,255,.5) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 12px 24px -10px oklch(.55 .14 ${c.hue} / .5)`
                : "0 1px 0 rgba(255,255,255,.9) inset, 0 8px 18px -10px rgba(20,40,80,.18)",
              fontFamily: "inherit", textAlign: "left",
            }}>
              <div style={{
                width: 46, height: 46, borderRadius: 14,
                background: i === 0 ? "rgba(255,255,255,.25)" : `linear-gradient(160deg, oklch(.92 .08 ${c.hue}), oklch(.78 .13 ${c.hue}))`,
                display: "flex", alignItems: "center", justifyContent: "center",
                color: "white", boxShadow: i === 0 ? "0 1px 0 rgba(255,255,255,.4) inset" : `0 6px 14px -4px oklch(.65 .14 ${c.hue} / .5)`
              }}>
                <TPIcon name={c.icon} size={22}/>
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
                <span style={{ fontSize: 17, fontWeight: 600, letterSpacing: "-.01em" }}>{c.name}</span>
                <span style={{ fontSize: 12, opacity: .8 }}>{c.count} รายการ</span>
              </div>
            </button>
          ))}
        </div>

        {/* product grid */}
        <div className="tp-glass" style={{ height: "calc(100% - 100px)", padding: 18, overflow: "hidden" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
            <h3 style={{ margin: 0, fontSize: 18, fontWeight: 600, letterSpacing: "-.01em" }}>ของร้อน <span style={{ color: "var(--tp-ink-mute)", fontWeight: 400, fontSize: 14 }}>· 18 รายการ</span></h3>
            <div style={{ flex: 1 }}/>
            <div style={{ display: "flex", gap: 6 }}>
              <span className="tp-chip">ทั้งหมด</span>
              <span className="tp-chip">ขายดี</span>
              <span className="tp-chip">โปรโมชั่น</span>
              <button className="tp-btn tp-btn-ghost" style={{ height: 30, padding: "0 12px", fontSize: 13 }}><TPIcon name="filter" size={14}/> ตัวกรอง</button>
            </div>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14 }}>
            {products.map((p, i) => (
              <div key={i} className="tp-prod" style={{ height: 200 }}>
                <div className="tp-prod-img">
                  <TPProductImg label={p.code} hue={p.hue} kind={p.kind}/>
                </div>
                {p.tag && <div style={{
                  position: "absolute", top: 18, left: 18,
                  padding: "4px 10px", borderRadius: 999, fontSize: 11, fontWeight: 600,
                  background: p.tag === "ใหม่" ? "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))"
                            : p.tag === "พรีเมียม" ? "linear-gradient(180deg, oklch(.40 .07 270), oklch(.25 .06 265))"
                            : "linear-gradient(180deg, oklch(.78 .18 28), oklch(.60 .18 25))",
                  color: "white", boxShadow: "0 4px 10px -3px rgba(20,40,80,.3)"
                }}>{p.tag}</div>}
                <div style={{ padding: "0 14px 12px" }}>
                  <div style={{ fontSize: 14, fontWeight: 500, marginBottom: 4 }}>{p.name}</div>
                  <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
                    <span className="tp-tnum" style={{ fontSize: 19, fontWeight: 600, color: "var(--tp-teal-deep)" }}>฿{p.price}</span>
                    <span style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>/แก้ว</span>
                    <div style={{ flex: 1 }}/>
                    <button className="tp-btn tp-btn-primary" style={{ width: 30, height: 30, padding: 0, borderRadius: 10 }}>
                      <TPIcon name="plus" size={16}/>
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>

      {/* ─── cart side panel ─── */}
      <aside style={{
        position: "absolute", right: 18, top: 110, bottom: 18, width: 446,
        display: "flex", flexDirection: "column",
      }} className="tp-glass">
        {/* order header */}
        <div style={{ padding: "20px 22px 14px", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <div style={{ display: "flex", alignItems: "center" }}>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <h2 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>คำสั่งซื้อ #A1042</h2>
                <span style={{ padding: "3px 10px", fontSize: 11, fontWeight: 600, borderRadius: 999, background: "oklch(.92 .08 145)", color: "oklch(.42 .12 150)" }}>เปิด</span>
              </div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 3 }}>โต๊ะ 7 · ลูกค้า 2 ท่าน · เริ่ม 14:18</div>
            </div>
            <div style={{ flex: 1 }}/>
            <button className="tp-btn tp-btn-ghost tp-btn-icon" style={{ width: 38, height: 38 }}><TPIcon name="more" size={18}/></button>
          </div>
        </div>

        {/* cart items */}
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto", padding: "10px 14px" }}>
          {cart.map((it, k) => (
            <div key={k} style={{
              display: "flex", gap: 12, padding: 10, borderRadius: 16,
              background: "rgba(255,255,255,.55)", border: "1px solid rgba(255,255,255,.65)",
              marginBottom: 8, boxShadow: "0 1px 0 rgba(255,255,255,.7) inset, 0 4px 10px -6px rgba(20,40,80,.1)",
            }}>
              <div style={{ width: 56, height: 56, borderRadius: 12, overflow: "hidden", flexShrink: 0 }}>
                <TPProductImg hue={it.hue} kind={it.kind}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", justifyContent: "space-between", gap: 8 }}>
                  <span style={{ fontSize: 14, fontWeight: 500, lineHeight: 1.2 }}>{it.name}</span>
                  <span className="tp-tnum" style={{ fontSize: 14, fontWeight: 600 }}>฿{it.qty * it.price}</span>
                </div>
                <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 3, lineHeight: 1.3 }}>{it.note}</div>
                <div style={{ display: "flex", alignItems: "center", marginTop: 8, gap: 8 }}>
                  <div style={{ display: "flex", alignItems: "center", height: 28, borderRadius: 999, background: "white", border: "1px solid var(--tp-line)", padding: "0 4px" }}>
                    <button style={{ width: 22, height: 22, borderRadius: "50%", border: "none", background: "rgba(20,40,80,.05)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name="minus" size={12}/></button>
                    <span className="tp-tnum" style={{ width: 26, textAlign: "center", fontSize: 13, fontWeight: 600 }}>{it.qty}</span>
                    <button style={{ width: 22, height: 22, borderRadius: "50%", border: "none", background: "var(--tp-teal)", color: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name="plus" size={12} color="white"/></button>
                  </div>
                  <button style={{ height: 26, padding: "0 10px", borderRadius: 999, border: "1px solid var(--tp-line)", background: "white", fontSize: 11, fontFamily: "inherit", color: "var(--tp-ink-soft)", cursor: "pointer" }}>หมายเหตุ</button>
                  <div style={{ flex: 1 }}/>
                  <button style={{ width: 26, height: 26, borderRadius: 8, border: "none", background: "transparent", cursor: "pointer", color: "var(--tp-coral-deep)" }}><TPIcon name="trash" size={15}/></button>
                </div>
              </div>
            </div>
          ))}

          {/* discount line */}
          <div style={{
            display: "flex", alignItems: "center", gap: 10, padding: "10px 14px",
            margin: "8px 4px", borderRadius: 12,
            background: "linear-gradient(160deg, oklch(.95 .08 80), oklch(.92 .10 65))",
            border: "1px solid oklch(.85 .10 75)",
          }}>
            <TPIcon name="tag" size={16} color="oklch(.55 .14 70)"/>
            <span style={{ fontSize: 13, fontWeight: 500, color: "oklch(.35 .08 70)" }}>คูปอง · TP-MAY30</span>
            <div style={{ flex: 1 }}/>
            <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600, color: "oklch(.45 .14 70)" }}>−฿30</span>
          </div>
        </div>

        {/* totals + actions */}
        <div style={{ padding: "16px 22px 18px", borderTop: "1px solid rgba(20,40,80,.08)" }}>
          <div style={{ display: "grid", gap: 6, fontSize: 13, marginBottom: 10 }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "var(--tp-ink-soft)" }}>
              <span>ยอดรวมย่อย</span><span className="tp-tnum">฿{subtotal}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "oklch(.55 .14 70)" }}>
              <span>ส่วนลด</span><span className="tp-tnum">−฿{discount}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "var(--tp-ink-soft)" }}>
              <span>ภาษี VAT 7%</span><span className="tp-tnum">฿{tax}</span>
            </div>
          </div>
          <div style={{
            display: "flex", justifyContent: "space-between", alignItems: "baseline",
            padding: "12px 16px", borderRadius: 16,
            background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.18 .06 270))",
            color: "white", marginBottom: 12,
            boxShadow: "0 1px 0 rgba(255,255,255,.15) inset, 0 10px 22px -10px oklch(.25 .07 265 / .6)",
          }}>
            <span style={{ fontSize: 15, fontWeight: 500 }}>รวมทั้งสิ้น</span>
            <span className="tp-tnum" style={{ fontSize: 30, fontWeight: 600, letterSpacing: "-.02em" }}>฿{total}</span>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8, marginBottom: 10 }}>
            <button className="tp-btn tp-btn-ghost" style={{ height: 42, fontSize: 13 }}><TPIcon name="split" size={15}/> แยกบิล</button>
            <button className="tp-btn tp-btn-ghost" style={{ height: 42, fontSize: 13 }}><TPIcon name="tag" size={15}/> คูปอง</button>
            <button className="tp-btn tp-btn-ghost" style={{ height: 42, fontSize: 13 }}><TPIcon name="user" size={15}/> สมาชิก</button>
          </div>

          <button className="tp-btn tp-btn-coral" style={{ width: "100%", height: 60, fontSize: 18, fontWeight: 600, borderRadius: 18 }}>
            ชำระเงิน · ฿{total}
            <TPIcon name="arrow-right" size={20}/>
          </button>
        </div>
      </aside>
    </div>
  );
};

window.CashierScreen = CashierScreen;

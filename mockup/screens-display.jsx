// Thaiprompt POS — Customer Display (2nd screen) + Kitchen Display + Sales Dashboard

const CustomerDisplay = () => {
  const items = [
    { n: "ชาไทยเย็น × 2", p: 130 },
    { n: "ชาเขียวมัทฉะลาเต้ (L)", p: 95 },
    { n: "ครัวซองต์อัลมอนด์", p: 55 },
    { n: "อเมริกาโน่ร้อน", p: 60 },
  ];
  return (
    <div className="tp-app" style={{ width: 1280, height: 800, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      <div className="tp-orb" style={{ width: 380, height: 380, right: -100, top: -120, background: "oklch(.85 .18 28)" }}/>
      <div className="tp-orb" style={{ width: 320, height: 320, left: -80, bottom: -100, background: "oklch(.78 .14 188)" }}/>

      {/* top brand strip */}
      <div style={{ position: "absolute", top: 30, left: 30, display: "flex", alignItems: "center", gap: 14 }}>
        <TPLogo size={48}/>
        <div>
          <div style={{ fontSize: 18, fontWeight: 600, letterSpacing: "-.01em" }}>ไทยพร้อม คาเฟ่</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>สยาม สแควร์ · กำลังรับออเดอร์</div>
        </div>
      </div>
      <div style={{ position: "absolute", top: 30, right: 30, display: "flex", gap: 10 }}>
        <span className="tp-chip"><span className="tp-dot"/> สาขาเปิด</span>
        <span className="tp-chip tp-mono">14:42 · 8 พ.ค.</span>
      </div>

      {/* main 2-col layout */}
      <div style={{ position: "absolute", inset: "94px 30px 30px", display: "grid", gridTemplateColumns: "1.4fr 1fr", gap: 20 }}>
        {/* left — promo carousel */}
        <div style={{
          borderRadius: 32, position: "relative", overflow: "hidden",
          background: "linear-gradient(160deg, oklch(.78 .14 188) 0%, oklch(.40 .15 280) 100%)",
          boxShadow: "0 1px 0 rgba(255,255,255,.3) inset, 0 30px 60px -30px rgba(20,40,80,.4)",
        }}>
          <div style={{ position: "absolute", inset: 0, opacity: .35,
            background: "radial-gradient(circle at 80% 20%, oklch(.90 .15 28 / .9), transparent 50%), radial-gradient(circle at 10% 80%, oklch(.85 .14 80 / .7), transparent 50%)"
          }}/>
          {/* glass orbs */}
          <div style={{ position: "absolute", width: 260, height: 260, right: -40, bottom: -40, borderRadius: "50%",
            background: "linear-gradient(135deg, rgba(255,255,255,.30), rgba(255,255,255,.06))",
            backdropFilter: "blur(20px)", border: "1px solid rgba(255,255,255,.3)" }}/>
          <div style={{ position: "absolute", width: 130, height: 130, right: 220, bottom: 80, borderRadius: "50%",
            background: "oklch(.85 .18 28 / .6)", filter: "blur(8px)" }}/>
          <div style={{ position: "absolute", width: 90, height: 90, right: 160, bottom: 280, borderRadius: "50%",
            background: "linear-gradient(135deg, oklch(.95 .14 80 / .8), oklch(.78 .14 80 / .5))",
            backdropFilter: "blur(8px)", border: "1px solid rgba(255,255,255,.4)" }}/>

          <div style={{ position: "relative", padding: 50, color: "white", height: "100%", display: "flex", flexDirection: "column" }}>
            <span style={{
              alignSelf: "flex-start",
              padding: "6px 14px", borderRadius: 999,
              background: "rgba(255,255,255,.2)", border: "1px solid rgba(255,255,255,.35)",
              fontSize: 12, fontWeight: 600, letterSpacing: ".05em", backdropFilter: "blur(10px)"
            }}>โปรเด็ดเดือนพฤษภาคม</span>

            <div style={{ flex: 1 }}/>

            <div style={{ fontSize: 64, fontWeight: 700, lineHeight: 1, letterSpacing: "-.03em", textWrap: "balance" }}>
              ซื้อ 2 แก้ว<br/>
              <span style={{
                background: "linear-gradient(180deg, oklch(.95 .14 80), oklch(.78 .14 80))",
                WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
              }}>ลด 30 บาท</span>
            </div>
            <div style={{ fontSize: 18, opacity: .9, marginTop: 14, maxWidth: 480, lineHeight: 1.45 }}>
              เลือกชาไทย ชาเขียว หรือกาแฟเย็นได้ทุกแก้ว ตลอดเดือน · ใช้คูปอง <span className="tp-mono" style={{ background: "rgba(255,255,255,.22)", padding: "2px 8px", borderRadius: 6 }}>TP-MAY30</span>
            </div>

            <div style={{ display: "flex", gap: 6, marginTop: 30 }}>
              <div style={{ width: 36, height: 5, borderRadius: 999, background: "white" }}/>
              <div style={{ width: 12, height: 5, borderRadius: 999, background: "rgba(255,255,255,.4)" }}/>
              <div style={{ width: 12, height: 5, borderRadius: 999, background: "rgba(255,255,255,.4)" }}/>
              <div style={{ width: 12, height: 5, borderRadius: 999, background: "rgba(255,255,255,.4)" }}/>
            </div>
          </div>
        </div>

        {/* right — order summary */}
        <div className="tp-glass" style={{ padding: "26px 28px", display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>คำสั่งซื้อปัจจุบัน</div>
              <div style={{ fontSize: 22, fontWeight: 600, marginTop: 2 }}>#A1042 · โต๊ะ 7</div>
            </div>
            <div style={{ flex: 1 }}/>
            <div style={{
              padding: "10px 14px", borderRadius: 14, fontSize: 12, fontWeight: 600,
              background: "linear-gradient(180deg, oklch(.95 .12 145), oklch(.85 .14 145))",
              color: "oklch(.32 .12 150)", border: "1px solid oklch(.85 .12 145)"
            }}>กำลังเตรียม</div>
          </div>

          <div className="tp-scroll" style={{ flex: 1, overflow: "auto", margin: "8px -8px" }}>
            {items.map((it, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", padding: "12px 8px",
                borderBottom: "1px dashed rgba(20,40,80,.1)",
              }}>
                <div style={{
                  width: 38, height: 38, borderRadius: 12,
                  background: `linear-gradient(160deg, oklch(.92 .08 ${20 + i * 50}), oklch(.78 .12 ${20 + i * 50}))`,
                  border: "1px solid rgba(255,255,255,.7)",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  color: "white", fontSize: 13, fontWeight: 600,
                  boxShadow: "0 4px 10px -3px rgba(20,40,80,.18)"
                }}>{i + 1}</div>
                <div style={{ flex: 1, marginLeft: 14, fontSize: 16, fontWeight: 500 }}>{it.n}</div>
                <div className="tp-tnum" style={{ fontSize: 17, fontWeight: 600 }}>฿{it.p}</div>
              </div>
            ))}
          </div>

          <div style={{ marginTop: 14, paddingTop: 14, borderTop: "1px solid rgba(20,40,80,.1)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", color: "var(--tp-ink-soft)", fontSize: 13, marginBottom: 4 }}>
              <span>ยอดรวม</span><span className="tp-tnum">฿340</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "oklch(.55 .14 70)", fontSize: 13, marginBottom: 4 }}>
              <span>คูปอง TP-MAY30</span><span className="tp-tnum">−฿30</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", color: "var(--tp-ink-soft)", fontSize: 13, marginBottom: 12 }}>
              <span>ภาษี VAT 7%</span><span className="tp-tnum">฿21</span>
            </div>
            <div style={{
              padding: "16px 18px", borderRadius: 18,
              background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.18 .06 270))",
              color: "white", display: "flex", justifyContent: "space-between", alignItems: "baseline",
              boxShadow: "0 1px 0 rgba(255,255,255,.15) inset, 0 14px 28px -10px oklch(.25 .07 265 / .6)",
            }}>
              <span style={{ fontSize: 17, fontWeight: 500 }}>ยอดสุทธิ</span>
              <span className="tp-tnum" style={{ fontSize: 38, fontWeight: 600, letterSpacing: "-.02em" }}>฿331</span>
            </div>
          </div>

          <div style={{
            marginTop: 14, padding: "12px 14px", borderRadius: 14,
            background: "rgba(255,255,255,.6)", border: "1px solid rgba(255,255,255,.7)",
            display: "flex", alignItems: "center", gap: 12,
          }}>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: "linear-gradient(135deg, oklch(.45 .15 280), oklch(.32 .12 270))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 700 }}>P</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 500 }}>สแกน QR เพื่อชำระ</div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>พร้อมเพย์ · ทุกธนาคาร</div>
            </div>
            <TPIcon name="qr" size={26} color="var(--tp-indigo)"/>
          </div>
        </div>
      </div>
    </div>
  );
};

const KitchenDisplay = () => {
  const tickets = [
    { id: "A1042", table: "โต๊ะ 7", min: 2, color: "188", status: "new",
      items: [{ n: "ชาไทยเย็น", q: 2, note: "หวานน้อย ไม่ใส่ไข่มุก" }, { n: "ชาเขียวมัทฉะ (L)", q: 1, note: "" }, { n: "ครัวซองต์อัลมอนด์", q: 1, note: "อุ่น" }, { n: "อเมริกาโน่ร้อน", q: 1, note: "ไม่ใส่น้ำตาล" }] },
    { id: "A1041", table: "Take Away", min: 4, color: "25", status: "cook",
      items: [{ n: "โกโก้ปั่น", q: 2, note: "" }, { n: "บราวนี่ช็อกโกแลต", q: 1, note: "อุ่น" }] },
    { id: "A1040", table: "โต๊ะ 3", min: 6, color: "80", status: "cook",
      items: [{ n: "เอสเปรสโซ่", q: 1, note: "" }, { n: "คาปูชิโน่", q: 2, note: "นมโอ๊ต +10" }, { n: "ครัวซองต์อัลมอนด์", q: 2, note: "" }, { n: "แซนวิชแฮมชีส", q: 1, note: "ไม่ใส่ผัก" }] },
    { id: "A1039", table: "โต๊ะ 12", min: 8, color: "270", status: "ready",
      items: [{ n: "ชาดำเย็น", q: 2, note: "" }, { n: "ชามะนาวโซดา", q: 2, note: "ไม่ใส่น้ำแข็ง" }] },
    { id: "A1038", table: "Delivery", min: 10, color: "145", status: "ready",
      items: [{ n: "นมสดน้ำผึ้ง", q: 3, note: "" }, { n: "สตรอเบอร์รี่ปั่น", q: 1, note: "" }] },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg tp-bg-dark"/>

      <header style={{ position: "absolute", left: 24, right: 24, top: 24, height: 64, display: "flex", alignItems: "center", padding: "0 22px" }} className="tp-glass-dark">
        <TPLogo size={36}/>
        <div style={{ marginLeft: 12 }}>
          <div style={{ fontSize: 16, fontWeight: 600 }}>Kitchen Display · จอครัว</div>
          <div style={{ fontSize: 11, opacity: .65 }}>สถานี กาแฟ + เบเกอรี่</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", gap: 10 }}>
          <span className="tp-chip" style={{ background: "rgba(255,255,255,.08)", color: "white", border: "1px solid rgba(255,255,255,.15)" }}>
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.78 .14 188)", boxShadow: "0 0 0 3px oklch(.78 .14 188 / .25)" }}/> ใหม่ 1
          </span>
          <span className="tp-chip" style={{ background: "rgba(255,255,255,.08)", color: "white", border: "1px solid rgba(255,255,255,.15)" }}>
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.78 .14 80)" }}/> กำลังทำ 2
          </span>
          <span className="tp-chip" style={{ background: "rgba(255,255,255,.08)", color: "white", border: "1px solid rgba(255,255,255,.15)" }}>
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.78 .14 145)" }}/> พร้อม 2
          </span>
          <span className="tp-chip tp-mono" style={{ background: "rgba(255,255,255,.08)", color: "white", border: "1px solid rgba(255,255,255,.15)" }}>14:42:18</span>
        </div>
      </header>

      <div style={{ position: "absolute", inset: "104px 24px 24px", display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 16 }}>
        {tickets.map((t, k) => {
          const stColor = t.status === "new" ? "188" : t.status === "cook" ? "80" : "145";
          const stLabel = t.status === "new" ? "ใหม่" : t.status === "cook" ? "กำลังทำ" : "พร้อมเสิร์ฟ";
          return (
            <div key={k} style={{
              borderRadius: 22, overflow: "hidden", display: "flex", flexDirection: "column",
              background: "linear-gradient(160deg, rgba(255,255,255,.10), rgba(255,255,255,.04))",
              border: "1px solid rgba(255,255,255,.12)",
              backdropFilter: "blur(20px) saturate(140%)",
              boxShadow: `0 1px 0 rgba(255,255,255,.10) inset, 0 -1px 0 rgba(0,0,0,.2) inset, 0 30px 60px -30px rgba(0,0,0,.6), 0 0 0 1px oklch(.55 .15 ${stColor} / .15) inset`,
              color: "oklch(.95 .01 230)",
              ...(t.status === "ready" ? { boxShadow: `0 1px 0 rgba(255,255,255,.10) inset, 0 0 0 2px oklch(.78 .14 145 / .5), 0 30px 60px -30px rgba(0,0,0,.6), 0 0 40px -10px oklch(.78 .14 145 / .35)` } : {})
            }}>
              {/* ticket head */}
              <div style={{
                padding: "14px 18px", borderBottom: "1px solid rgba(255,255,255,.10)",
                background: `linear-gradient(180deg, oklch(.50 .15 ${stColor} / .35), oklch(.40 .12 ${stColor} / .15))`,
              }}>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                  <span style={{ fontSize: 17, fontWeight: 600 }}>#{t.id}</span>
                  <span className="tp-mono" style={{
                    fontSize: 13, padding: "3px 9px", borderRadius: 999,
                    background: t.min > 5 ? "oklch(.65 .18 25 / .25)" : "rgba(255,255,255,.10)",
                    color: t.min > 5 ? "oklch(.85 .18 28)" : "oklch(.95 .01 230)",
                    border: "1px solid rgba(255,255,255,.15)"
                  }}>{t.min} นาที</span>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 6 }}>
                  <span style={{ fontSize: 13, opacity: .8 }}>{t.table}</span>
                  <span style={{
                    fontSize: 11, padding: "3px 9px", borderRadius: 999, fontWeight: 600,
                    background: `linear-gradient(180deg, oklch(.78 .15 ${stColor}), oklch(.55 .15 ${stColor}))`,
                    color: "white"
                  }}>{stLabel}</span>
                </div>
              </div>

              {/* items */}
              <div style={{ flex: 1, padding: "14px 18px", overflow: "auto" }}>
                {t.items.map((it, j) => (
                  <div key={j} style={{
                    display: "flex", marginBottom: 12, gap: 10,
                    paddingBottom: 10, borderBottom: j < t.items.length - 1 ? "1px dashed rgba(255,255,255,.1)" : "none"
                  }}>
                    <div className="tp-mono" style={{
                      flex: "0 0 28px", height: 24, borderRadius: 8, fontSize: 13, fontWeight: 600,
                      background: "rgba(255,255,255,.10)", border: "1px solid rgba(255,255,255,.15)",
                      display: "flex", alignItems: "center", justifyContent: "center"
                    }}>×{it.q}</div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 14, fontWeight: 500, lineHeight: 1.2 }}>{it.n}</div>
                      {it.note && <div style={{ fontSize: 11, opacity: .65, marginTop: 3, fontStyle: "italic", lineHeight: 1.3 }}>↳ {it.note}</div>}
                    </div>
                  </div>
                ))}
              </div>

              {/* action */}
              <div style={{ padding: 12, borderTop: "1px solid rgba(255,255,255,.08)" }}>
                {t.status === "ready" ? (
                  <button style={{
                    width: "100%", height: 46, borderRadius: 14, border: "none", cursor: "pointer",
                    background: "linear-gradient(180deg, oklch(.78 .14 145), oklch(.55 .14 150))",
                    color: "white", fontFamily: "inherit", fontSize: 14, fontWeight: 600,
                    boxShadow: "0 1px 0 rgba(255,255,255,.4) inset, 0 -2px 0 rgba(0,0,0,.15) inset, 0 8px 18px -4px oklch(.55 .14 150 / .55)"
                  }}>เสิร์ฟแล้ว → จบ</button>
                ) : t.status === "new" ? (
                  <button style={{
                    width: "100%", height: 46, borderRadius: 14, border: "none", cursor: "pointer",
                    background: "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))",
                    color: "white", fontFamily: "inherit", fontSize: 14, fontWeight: 600,
                    boxShadow: "0 1px 0 rgba(255,255,255,.4) inset, 0 -2px 0 rgba(0,0,0,.15) inset, 0 8px 18px -4px oklch(.55 .13 195 / .55)"
                  }}>เริ่มทำ</button>
                ) : (
                  <button style={{
                    width: "100%", height: 46, borderRadius: 14, border: "none", cursor: "pointer",
                    background: "linear-gradient(180deg, oklch(.85 .14 80), oklch(.65 .14 75))",
                    color: "oklch(.25 .05 70)", fontFamily: "inherit", fontSize: 14, fontWeight: 600,
                    boxShadow: "0 1px 0 rgba(255,255,255,.7) inset, 0 -2px 0 rgba(0,0,0,.10) inset, 0 8px 18px -4px oklch(.72 .14 80 / .50)"
                  }}>เสร็จแล้ว ✓</button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

window.CustomerDisplay = CustomerDisplay;
window.KitchenDisplay = KitchenDisplay;

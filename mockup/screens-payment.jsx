// Thaiprompt POS — Login + Payment + Receipt
// Login: 1280×800, Payment 1000×800 (modal context), Receipt 360×640

const LoginScreen = () => {
  const [pin, setPin] = React.useState("••");
  return (
    <div className="tp-app" style={{ width: 1280, height: 800, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {/* decorative orbs */}
      <div className="tp-orb" style={{ width: 360, height: 360, left: -80, top: -80, background: "oklch(.78 .14 188)" }}/>
      <div className="tp-orb" style={{ width: 280, height: 280, right: -60, bottom: -60, background: "oklch(.72 .18 25)" }}/>
      <div className="tp-orb" style={{ width: 200, height: 200, right: 220, top: 80, background: "oklch(.82 .14 80)", opacity: .4 }}/>

      {/* main card */}
      <div className="tp-glass" style={{
        position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -50%)",
        width: 880, height: 560, display: "grid", gridTemplateColumns: "1fr 1fr", overflow: "hidden",
      }}>
        {/* brand side */}
        <div style={{
          position: "relative",
          background: "linear-gradient(160deg, oklch(.78 .14 188) 0%, oklch(.45 .14 250) 100%)",
          padding: 48, color: "white", display: "flex", flexDirection: "column",
        }}>
          <div style={{ position: "absolute", inset: 0, opacity: .3,
            background: "radial-gradient(circle at 80% 0%, oklch(.85 .18 28 / .8), transparent 50%)" }}/>
          <div style={{ position: "absolute", width: 220, height: 220, right: -60, bottom: -60, borderRadius: "50%",
            background: "linear-gradient(135deg, rgba(255,255,255,.25), rgba(255,255,255,.05))",
            border: "1px solid rgba(255,255,255,.3)", backdropFilter: "blur(20px)" }}/>
          <div style={{ position: "absolute", width: 100, height: 100, right: 80, bottom: 200, borderRadius: "50%",
            background: "oklch(.85 .18 28 / .5)", filter: "blur(10px)" }}/>

          <div style={{ position: "relative", display: "flex", alignItems: "center", gap: 14 }}>
            <TPLogo size={56}/>
            <div>
              <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: "-.02em" }}>Thaiprompt</div>
              <div style={{ fontSize: 13, opacity: .85, letterSpacing: ".05em" }}>POINT OF SALE</div>
            </div>
          </div>

          <div style={{ flex: 1 }}/>

          <div style={{ position: "relative" }}>
            <div style={{ fontSize: 32, fontWeight: 600, lineHeight: 1.15, letterSpacing: "-.02em", textWrap: "pretty" }}>
              สวัสดีค่ะ<br/>ยินดีต้อนรับ
            </div>
            <div style={{ fontSize: 14, opacity: .85, marginTop: 14, lineHeight: 1.5, maxWidth: 280 }}>
              เข้าสู่ระบบเพื่อเริ่มขาย ดูรายงาน และจัดการร้านของคุณ
            </div>
          </div>

          <div style={{ position: "relative", display: "flex", gap: 10, marginTop: 32, fontSize: 11, opacity: .8 }}>
            <span className="tp-mono">v 4.2.1</span>
            <span>·</span>
            <span>สาขา สยาม สแควร์</span>
          </div>
        </div>

        {/* pin side */}
        <div style={{ padding: "48px 56px", display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
            <span style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ลงชื่อเข้าใช้</span>
          </div>
          <h1 style={{ margin: 0, fontSize: 28, fontWeight: 600, letterSpacing: "-.02em" }}>กรอกรหัส PIN</h1>

          {/* user picker */}
          <div style={{ display: "flex", gap: 8, marginTop: 20, marginBottom: 24 }}>
            {[
              { n: "ปริม", c: "oklch(.82 .14 80)", on: true },
              { n: "ธนา", c: "oklch(.72 .14 188)" },
              { n: "นิด", c: "oklch(.72 .18 25)" },
              { n: "เม", c: "oklch(.55 .14 280)" },
              { n: "+", c: "var(--tp-line)" },
            ].map((u, i) => (
              <div key={i} style={{ textAlign: "center" }}>
                <div style={{
                  width: 44, height: 44, borderRadius: "50%",
                  background: u.n === "+" ? "transparent" : `linear-gradient(135deg, ${u.c}, oklch(.50 .12 30))`,
                  border: u.on ? "2px solid oklch(.55 .13 195)" : u.n === "+" ? "1.5px dashed var(--tp-line)" : "2px solid white",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  color: u.n === "+" ? "var(--tp-ink-mute)" : "white", fontSize: u.n === "+" ? 18 : 14, fontWeight: 600,
                  boxShadow: u.on ? "0 0 0 3px oklch(.55 .13 195 / .25)" : "0 4px 10px -3px rgba(20,40,80,.2)",
                  cursor: "pointer",
                }}>{u.n}</div>
              </div>
            ))}
          </div>

          {/* pin display */}
          <div style={{ display: "flex", gap: 14, justifyContent: "center", margin: "8px 0 24px" }}>
            {[1, 1, 0, 0].map((d, i) => (
              <div key={i} style={{
                width: 48, height: 56, borderRadius: 16,
                background: "white", border: "1px solid var(--tp-line)",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 1px 0 rgba(255,255,255,.8) inset, 0 4px 10px -6px rgba(20,40,80,.15)",
              }}>
                {d ? <div style={{ width: 14, height: 14, borderRadius: "50%", background: "var(--tp-indigo)" }}/> : null}
              </div>
            ))}
          </div>

          {/* keypad */}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10 }}>
            {["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"].map((k, i) => (
              k === "" ? <div key={i}/> :
              <button key={i} className="tp-key" style={{ height: 64 }}>
                {k === "⌫" ? <TPIcon name="x" size={20}/> : k}
              </button>
            ))}
          </div>

          <div style={{ flex: 1 }}/>

          <button style={{
            background: "transparent", border: "none", color: "var(--tp-ink-mute)",
            fontSize: 13, cursor: "pointer", fontFamily: "inherit", marginTop: 18
          }}>ลืมรหัส PIN?</button>
        </div>
      </div>
    </div>
  );
};

const PaymentScreen = () => {
  const total = 410;
  return (
    <div className="tp-app" style={{ width: 1100, height: 800, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>

      <div style={{ position: "absolute", inset: 24 }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 18 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42, padding: "0 14px", fontSize: 13 }}>
            <TPIcon name="arrow-right" size={16} style={{ transform: "rotate(180deg)" }}/> กลับ
          </button>
          <div style={{ flex: 1 }}/>
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 600, letterSpacing: "-.01em" }}>ชำระเงิน · #A1042</h1>
          <div style={{ flex: 1 }}/>
          <span className="tp-chip"><TPIcon name="clock" size={13}/> รอชำระ</span>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "1.05fr 1fr", gap: 18, height: "calc(100% - 60px)" }}>
          {/* left — methods + amount */}
          <div className="tp-glass" style={{ padding: 24, display: "flex", flexDirection: "column" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 6 }}>ยอดที่ต้องชำระ</div>
            <div className="tp-tnum" style={{ fontSize: 56, fontWeight: 600, letterSpacing: "-.03em", lineHeight: 1, color: "var(--tp-indigo-deep)" }}>฿{total}.00</div>

            <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 12, marginTop: 22 }}>
              {[
                { k: "qr", l: "พร้อมเพย์ / QR", c: "188", on: true, sub: "สแกนจ่ายผ่าน Mobile Banking" },
                { k: "card", l: "บัตรเครดิต / เดบิต", c: "270", sub: "Visa · Master · Union Pay" },
                { k: "cash", l: "เงินสด", c: "80", sub: "รับ–ทอนเงิน" },
                { k: "phone", l: "True Wallet · Rabbit", c: "25", sub: "อีวอลเล็ทอื่น ๆ" },
              ].map((m, i) => (
                <button key={i} style={{
                  position: "relative", padding: "18px 18px", borderRadius: 18, border: "none", cursor: "pointer",
                  background: m.on
                    ? `linear-gradient(160deg, oklch(.78 .14 ${m.c}), oklch(.55 .13 ${m.c}))`
                    : "linear-gradient(160deg, rgba(255,255,255,.95), rgba(255,255,255,.65))",
                  color: m.on ? "white" : "var(--tp-ink)",
                  border: m.on ? "1px solid rgba(255,255,255,.4)" : "1px solid rgba(255,255,255,.7)",
                  textAlign: "left", fontFamily: "inherit",
                  boxShadow: m.on
                    ? `0 1px 0 rgba(255,255,255,.5) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 14px 28px -10px oklch(.55 .13 ${m.c} / .55)`
                    : "0 1px 0 rgba(255,255,255,.9) inset, 0 8px 18px -10px rgba(20,40,80,.18)",
                }}>
                  <div style={{
                    width: 44, height: 44, borderRadius: 14, marginBottom: 12,
                    background: m.on ? "rgba(255,255,255,.22)" : `linear-gradient(160deg, oklch(.92 .08 ${m.c}), oklch(.78 .13 ${m.c}))`,
                    color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                    boxShadow: m.on ? "0 1px 0 rgba(255,255,255,.4) inset" : `0 6px 14px -4px oklch(.65 .14 ${m.c} / .5)`
                  }}><TPIcon name={m.k} size={22}/></div>
                  <div style={{ fontSize: 15, fontWeight: 600 }}>{m.l}</div>
                  <div style={{ fontSize: 12, opacity: .8, marginTop: 2 }}>{m.sub}</div>
                  {m.on && <div style={{ position: "absolute", top: 16, right: 16, width: 22, height: 22, borderRadius: "50%", background: "white", display: "flex", alignItems: "center", justifyContent: "center", color: "oklch(.55 .13 195)", boxShadow: "0 2px 6px rgba(20,40,80,.2)" }}><TPIcon name="check" size={14}/></div>}
                </button>
              ))}
            </div>

            <div style={{ flex: 1 }}/>

            <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
              <button className="tp-btn tp-btn-ghost" style={{ flex: 1, height: 50, fontSize: 14 }}><TPIcon name="receipt" size={17}/> พิมพ์ใบเสนอ</button>
              <button className="tp-btn tp-btn-coral" style={{ flex: 1.4, height: 50, fontSize: 15, fontWeight: 600 }}>
                ยืนยันการชำระ ฿{total}
                <TPIcon name="check" size={18}/>
              </button>
            </div>
          </div>

          {/* right — QR display */}
          <div className="tp-glass" style={{ padding: 24, display: "flex", flexDirection: "column", alignItems: "center" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 14 }}>
              <div style={{ width: 26, height: 26, borderRadius: 8, background: "linear-gradient(135deg, oklch(.45 .15 280), oklch(.32 .12 270))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 13, fontWeight: 700 }}>P</div>
              <div style={{ fontSize: 14, fontWeight: 600 }}>PromptPay · ไทยพร้อม</div>
            </div>

            <div style={{
              width: 320, height: 320, borderRadius: 24, padding: 18,
              background: "white", border: "1px solid var(--tp-line)",
              boxShadow: "0 1px 0 rgba(255,255,255,.9) inset, 0 20px 50px -20px rgba(20,40,80,.3), 0 4px 10px rgba(20,40,80,.1)",
              position: "relative",
            }}>
              {/* QR mockup */}
              <div style={{ width: "100%", height: "100%", position: "relative", borderRadius: 12, overflow: "hidden", background: "white" }}>
                <svg viewBox="0 0 21 21" style={{ width: "100%", height: "100%", imageRendering: "pixelated" }}>
                  {Array.from({ length: 441 }).map((_, i) => {
                    const x = i % 21, y = Math.floor(i / 21);
                    const corner = (x < 7 && y < 7) || (x > 13 && y < 7) || (x < 7 && y > 13);
                    const inner = corner && ((x >= 1 && x <= 5 && y >= 1 && y <= 5) || (x >= 15 && x <= 19 && y >= 1 && y <= 5) || (x >= 1 && x <= 5 && y >= 15 && y <= 19));
                    const innerInner = corner && ((x >= 2 && x <= 4 && y >= 2 && y <= 4) || (x >= 16 && x <= 18 && y >= 2 && y <= 4) || (x >= 2 && x <= 4 && y >= 16 && y <= 18));
                    if (corner && !inner) return <rect key={i} x={x} y={y} width="1" height="1" fill="black"/>;
                    if (inner && !innerInner) return null;
                    if (innerInner) return <rect key={i} x={x} y={y} width="1" height="1" fill="black"/>;
                    const r = (x * 137 + y * 53 + 17) % 100;
                    if (r < 48) return <rect key={i} x={x} y={y} width="1" height="1" fill="black"/>;
                    return null;
                  })}
                </svg>
                <div style={{
                  position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -50%)",
                  width: 60, height: 60, borderRadius: 14, background: "white",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  boxShadow: "0 4px 12px rgba(20,40,80,.15)", border: "1px solid var(--tp-line)"
                }}><TPLogo size={42} glow={false}/></div>
              </div>
            </div>

            <div style={{ display: "flex", gap: 8, marginTop: 18, alignItems: "center" }}>
              <span className="tp-dot"/>
              <span style={{ fontSize: 13, color: "var(--tp-ink-soft)" }}>กำลังรอลูกค้าชำระ…</span>
            </div>

            <div style={{
              marginTop: 14, padding: "10px 18px", borderRadius: 12,
              background: "oklch(.96 .02 220)", border: "1px solid var(--tp-line)",
              fontSize: 12, color: "var(--tp-ink-soft)", textAlign: "center", maxWidth: 320
            }}>
              สแกน QR ด้วยแอปธนาคารหรือ Mobile Banking<br/>
              <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>REF: TP-A1042-7218</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const ReceiptScreen = () => (
  <div className="tp-app" style={{ width: 360, height: 640, position: "relative", overflow: "hidden", padding: 14, background: "linear-gradient(180deg, oklch(.95 .02 220), oklch(.92 .02 215))" }}>
    <div style={{
      width: "100%", height: "100%",
      background: "white", borderRadius: 14,
      boxShadow: "0 1px 0 rgba(255,255,255,.9) inset, 0 20px 60px -20px rgba(20,40,80,.3)",
      padding: "20px 22px", fontFamily: "var(--tp-font-mono)", fontSize: 11.5, color: "#222",
      position: "relative", overflow: "hidden",
    }}>
      {/* zigzag bottom */}
      <div style={{
        position: "absolute", left: 0, right: 0, bottom: -1, height: 14,
        background: `linear-gradient(135deg, white 25%, transparent 25%) -8px 0,
                     linear-gradient(225deg, white 25%, transparent 25%) -8px 0,
                     linear-gradient(315deg, white 25%, transparent 25%),
                     linear-gradient(45deg, white 25%, transparent 25%)`,
        backgroundSize: "16px 14px",
      }}/>

      <div style={{ textAlign: "center", marginBottom: 12, fontFamily: "var(--tp-font)" }}>
        <TPLogo size={44}/>
        <div style={{ fontSize: 16, fontWeight: 600, marginTop: 6 }}>ไทยพร้อม คาเฟ่</div>
        <div style={{ fontSize: 10.5, color: "#777", marginTop: 1 }}>สาขา สยาม สแควร์ · 02-555-1234</div>
      </div>

      <div style={{ borderTop: "1.5px dashed #bbb", paddingTop: 10, marginBottom: 8, display: "flex", justifyContent: "space-between", fontSize: 10.5 }}>
        <span>เลขที่ A1042</span>
        <span>08 พ.ค. 14:42</span>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", fontSize: 10.5, color: "#666", marginBottom: 12 }}>
        <span>โต๊ะ 7 · 2 ท่าน</span>
        <span>แคชเชียร์ ปริม</span>
      </div>

      <div style={{ borderTop: "1.5px dashed #bbb", paddingTop: 10 }}>
        {[
          ["ชาไทยเย็น × 2", "130"],
          ["  หวานน้อย ไม่เพิ่มไข่มุก", ""],
          ["ชาเขียวมัทฉะ (L) × 1", "95"],
          ["ครัวซองต์อัลมอนด์ × 1", "55"],
          ["อเมริกาโน่ร้อน × 1", "60"],
        ].map(([n, p], i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
            <span style={{ color: n.startsWith("  ") ? "#888" : "#222" }}>{n}</span>
            <span>{p}</span>
          </div>
        ))}
      </div>

      <div style={{ borderTop: "1.5px dashed #bbb", marginTop: 10, paddingTop: 8 }}>
        {[["ยอดรวม", "340"], ["คูปอง TP-MAY30", "−30"], ["VAT 7%", "21"]].map(([k, v], i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", marginBottom: 3, color: "#555" }}>
            <span>{k}</span><span>{v}</span>
          </div>
        ))}
      </div>

      <div style={{
        marginTop: 8, padding: "10px 0", borderTop: "2px solid #222", borderBottom: "2px solid #222",
        display: "flex", justifyContent: "space-between", alignItems: "baseline",
        fontFamily: "var(--tp-font)"
      }}>
        <span style={{ fontSize: 14, fontWeight: 600 }}>รวมทั้งสิ้น</span>
        <span style={{ fontSize: 22, fontWeight: 600, fontVariantNumeric: "tabular-nums" }}>฿331</span>
      </div>

      <div style={{ marginTop: 10, fontSize: 10, color: "#666", textAlign: "center" }}>
        ชำระโดย พร้อมเพย์ · REF 7218<br/>
        ภงด.94 — 0735-558-7841
      </div>

      <div style={{ marginTop: 14, textAlign: "center", fontFamily: "var(--tp-font)", fontSize: 11, color: "#444" }}>
        ขอบคุณที่ใช้บริการ ❀<br/>
        สมัครสมาชิกฟรีรับ 1 แก้วทันที
      </div>

      <div style={{ marginTop: 10, display: "flex", justifyContent: "center" }}>
        <svg width="200" height="34" viewBox="0 0 200 34">
          {Array.from({ length: 60 }).map((_, i) => {
            const w = [1,2,1,3,1,1,2,3][i % 8];
            const x = i * 3.3;
            return <rect key={i} x={x} y="0" width={w} height="28" fill="#222"/>;
          })}
        </svg>
      </div>
      <div className="tp-mono" style={{ textAlign: "center", fontSize: 10, marginTop: 4, color: "#666" }}>TP-A1042-2025-05-08</div>
    </div>
  </div>
);

window.LoginScreen = LoginScreen;
window.PaymentScreen = PaymentScreen;
window.ReceiptScreen = ReceiptScreen;

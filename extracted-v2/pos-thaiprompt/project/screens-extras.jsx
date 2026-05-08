// Thaiprompt POS — Extras: Barcode Management + Shipping Label Printer

const _hx = (label, sub, right) => (
  <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
    <TPLogo size={42}/>
    <div>
      <div style={{ fontSize: 17, fontWeight: 600 }}>{label}</div>
      <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{sub}</div>
    </div>
    <div style={{ flex: 1 }}/>
    {right}
  </header>
);

// --- pseudo-barcode renderer (deterministic from string) ---
const Barcode = ({ value = "8851234567890", height = 60, color = "#0e1a30", bg = "white" }) => {
  const seed = [...value].reduce((a, c) => a + c.charCodeAt(0), 7);
  const bars = [];
  for (let i = 0; i < 60; i++) {
    const w = ((seed * (i + 13)) % 5) + 1;
    const filled = ((seed >> (i % 7)) ^ i) & 1;
    bars.push({ w, filled });
  }
  return (
    <div style={{ background: bg, padding: "6px 10px 4px", borderRadius: 4, display: "inline-block" }}>
      <div style={{ display: "flex", alignItems: "stretch", gap: 1, height }}>
        {bars.map((b, i) => (
          <div key={i} style={{ width: b.w, background: b.filled ? color : "transparent" }}/>
        ))}
      </div>
      <div className="tp-mono" style={{ fontSize: 11, letterSpacing: ".15em", color, textAlign: "center", marginTop: 2 }}>{value}</div>
    </div>
  );
};

// === 22 · Barcode Management ===
const BarcodeScreen = () => {
  const items = [
    { sku: "ESP-001", name: "เอสเปรสโซ่ ดับเบิ้ลช็อต", code: "8851234567001", type: "EAN-13", price: "฿65", qty: 482, c: "25" },
    { sku: "LATTE-002", name: "ลาเต้ร้อน 12oz", code: "8851234567025", type: "EAN-13", price: "฿85", qty: 360, c: "188" },
    { sku: "MATCHA-018", name: "มัทฉะลาเต้เย็น", code: "8851234568018", type: "EAN-13", price: "฿95", qty: 145, c: "145" },
    { sku: "BREW-CR-005", name: "ครัวซองต์อัลมอนด์", code: "8851234560205", type: "EAN-13", price: "฿95", qty: 28, c: "80" },
    { sku: "BREW-BR-012", name: "บราวนี่ช็อกโกแลต", code: "8851234560312", type: "EAN-13", price: "฿85", qty: 0, c: "25" },
    { sku: "MERCH-T-001", name: "เสื้อยืดโลโก้ Size M", code: "TP-MERCH-001M", type: "Code 128", price: "฿590", qty: 24, c: "270" },
    { sku: "BEAN-AR-200", name: "เมล็ดกาแฟ Arabica 200g", code: "8851234567890", type: "EAN-13", price: "฿380", qty: 86, c: "25" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hx("จัดการบาร์โค้ด · Barcode Management", "247 รายการ · พิมพ์วันนี้ 1,420 ดวง · เครื่องพิมพ์ Brother QL-820NWB",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="qr" size={16}/> สแกนทดสอบ</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="plus" size={16}/> สร้างจาก SKU</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="printer" size={16}/> พิมพ์ฉลาก</button>
        </div>
      )}

      {/* KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "บาร์โค้ดในระบบ", v: "247", c: "188" },
          { l: "ยังไม่ผูกบาร์โค้ด", v: "12", c: "25" },
          { l: "พิมพ์วันนี้", v: "1,420", c: "145" },
          { l: "สแกนวันนี้", v: "3,648", c: "270" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-.02em", marginTop: 4, color: `oklch(.40 .14 ${k.c})` }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* Left: barcode list */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, width: 720, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12, gap: 10 }}>
          <div style={{ flex: "0 0 240px", height: 38, background: "white", borderRadius: 12, border: "1px solid var(--tp-line)", display: "flex", alignItems: "center", padding: "0 14px", gap: 8 }}>
            <TPIcon name="search" size={14} color="var(--tp-ink-mute)"/>
            <input placeholder="ค้นหา SKU / ชื่อสินค้า..." style={{ flex: 1, border: "none", background: "transparent", outline: "none", fontFamily: "inherit", fontSize: 13 }}/>
          </div>
          <div style={{ flex: 1 }}/>
          {["EAN-13", "Code 128", "QR", "ทั้งหมด"].map((t, i) => (
            <span key={i} className={i === 3 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "100px 1.5fr 1.4fr 90px 70px 80px 80px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>SKU</span><span>สินค้า</span><span>บาร์โค้ด</span><span>ชนิด</span><span style={{ textAlign: "right" }}>ราคา</span><span style={{ textAlign: "right" }}>คงเหลือ</span><span style={{ textAlign: "center" }}>พิมพ์</span>
        </div>

        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {items.map((it, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "100px 1.5fr 1.4fr 90px 70px 80px 80px", gap: 10, padding: "12px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13, background: i === 1 ? "linear-gradient(90deg, oklch(.96 .04 188 / .6), transparent)" : "transparent", borderRadius: i === 1 ? 10 : 0 }}>
              <span className="tp-mono" style={{ fontSize: 11, fontWeight: 600, color: `oklch(.45 .14 ${it.c})` }}>{it.sku}</span>
              <div>
                <div style={{ fontWeight: 500 }}>{it.name}</div>
                <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>{it.code}</div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 1, height: 28 }}>
                {Array.from({ length: 32 }).map((_, j) => (
                  <div key={j} style={{
                    width: ((it.code.charCodeAt(j % it.code.length) + j) % 4) + 1,
                    height: "100%",
                    background: ((it.code.charCodeAt(j % it.code.length) >> (j % 5)) & 1) ? "var(--tp-ink)" : "transparent"
                  }}/>
                ))}
              </div>
              <span className="tp-chip" style={{ height: 22, fontSize: 10, padding: "0 8px", background: `oklch(.94 .07 ${it.c})`, color: `oklch(.40 .14 ${it.c})` }}>{it.type}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 500 }}>{it.price}</span>
              <span className="tp-tnum" style={{ textAlign: "right", color: it.qty === 0 ? "oklch(.55 .15 25)" : "var(--tp-ink)", fontWeight: it.qty === 0 ? 600 : 400 }}>{it.qty}</span>
              <button style={{ height: 28, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)", gap: 4, fontSize: 11, fontFamily: "inherit" }}><TPIcon name="printer" size={12}/></button>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 12, paddingTop: 12, borderTop: "1px dashed var(--tp-line)", display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>เลือกแล้ว</span>
          <span className="tp-chip tp-chip-active">3 รายการ</span>
          <div style={{ flex: 1 }}/>
          <button className="tp-btn tp-btn-ghost" style={{ height: 36 }}><TPIcon name="check" size={14}/> ผูกบาร์โค้ดอัตโนมัติ</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 36 }}><TPIcon name="printer" size={14}/> พิมพ์ที่เลือก</button>
        </div>
      </div>

      {/* Right: preview + label sheet + scanner */}
      <div style={{ position: "absolute", right: 24, top: 240, width: 656, bottom: 24, display: "flex", flexDirection: "column", gap: 16 }}>
        {/* Preview detail card */}
        <div className="tp-glass" style={{ padding: "20px 24px", display: "flex", gap: 18, alignItems: "center" }}>
          <div style={{ width: 88, height: 88, borderRadius: 14, overflow: "hidden", flexShrink: 0 }}>
            <TPProductImg label="LATTE-002" hue={188} kind="circle"/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำลังแสดง</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>ลาเต้ร้อน 12oz</div>
            <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 4 }}>SKU: LATTE-002 · ฿85 · คงเหลือ 360</div>
            <div style={{ marginTop: 10 }}>
              <Barcode value="8851234567025" height={42}/>
            </div>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            <button className="tp-btn tp-btn-ghost" style={{ height: 32, fontSize: 11 }}>คัดลอก</button>
            <button className="tp-btn tp-btn-ghost" style={{ height: 32, fontSize: 11 }}>สร้างใหม่</button>
            <button className="tp-btn tp-btn-primary" style={{ height: 32, fontSize: 11 }}>พิมพ์</button>
          </div>
        </div>

        {/* Label sheet preview */}
        <div className="tp-glass" style={{ padding: "20px 24px", flex: 1, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 10 }}>
            <div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เลย์เอาต์ฉลาก</div>
              <div style={{ fontSize: 16, fontWeight: 600, marginTop: 2 }}>A4 — 3×8 ดวง · 50×30mm</div>
            </div>
            <div style={{ flex: 1 }}/>
            {[
              { l: "30×20", a: false },
              { l: "50×30", a: true },
              { l: "75×40", a: false },
              { l: "ม้วน", a: false },
            ].map((s, i) => (
              <span key={i} className={s.a ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{s.l}</span>
            ))}
          </div>

          <div style={{
            flex: 1, background: "white", borderRadius: 14,
            border: "1px solid var(--tp-line)",
            boxShadow: "inset 0 1px 0 rgba(255,255,255,.5), 0 4px 14px -8px rgba(20,40,80,.12)",
            padding: 18, display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gridAutoRows: "1fr", gap: 6,
            position: "relative"
          }}>
            {/* paper hint */}
            <div style={{ position: "absolute", top: 8, right: 12, fontSize: 9, color: "var(--tp-ink-mute)", fontFamily: "var(--tp-font-mono)", letterSpacing: ".1em" }}>A4 · 210×297mm</div>
            {Array.from({ length: 12 }).map((_, i) => {
              const sku = ["LATTE-002", "ESP-001", "MATCHA-018", "BREW-CR-005"][i % 4];
              const code = ["8851234567025", "8851234567001", "8851234568018", "8851234560205"][i % 4];
              const price = ["฿85", "฿65", "฿95", "฿95"][i % 4];
              return (
                <div key={i} style={{
                  border: "1px dashed oklch(.78 .03 220)",
                  borderRadius: 4,
                  padding: "5px 6px",
                  display: "flex", flexDirection: "column", justifyContent: "center",
                  fontSize: 8
                }}>
                  <div style={{ fontWeight: 600, fontSize: 8, lineHeight: 1.1 }}>Thaiprompt Coffee</div>
                  <div style={{ fontFamily: "var(--tp-font-mono)", fontSize: 7, color: "var(--tp-ink-mute)" }}>{sku}</div>
                  <div style={{ display: "flex", alignItems: "stretch", gap: .5, height: 18, margin: "3px 0 1px" }}>
                    {Array.from({ length: 24 }).map((_, j) => (
                      <div key={j} style={{
                        width: ((code.charCodeAt(j % code.length) + j) % 3) + .5,
                        background: ((code.charCodeAt(j % code.length) >> (j % 4)) & 1) ? "#0e1a30" : "transparent"
                      }}/>
                    ))}
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between" }}>
                    <span className="tp-mono" style={{ fontSize: 6, letterSpacing: ".05em" }}>{code}</span>
                    <span style={{ fontWeight: 700, fontSize: 9, color: "oklch(.40 .14 25)" }}>{price}</span>
                  </div>
                </div>
              );
            })}
          </div>

          <div style={{ display: "flex", gap: 16, marginTop: 12, fontSize: 11, color: "var(--tp-ink-mute)" }}>
            <span>กระดาษ: <strong style={{ color: "var(--tp-ink)" }}>A4 ฉลาก 24 ดวง</strong></span>
            <span>เริ่มที่: <strong style={{ color: "var(--tp-ink)" }}>ดวงที่ 1</strong></span>
            <span>ทำสำเนา: <strong style={{ color: "var(--tp-ink)" }}>×2</strong></span>
            <div style={{ flex: 1 }}/>
            <span style={{ color: "oklch(.45 .14 150)", fontWeight: 500 }}>● พร้อมพิมพ์ 24 ดวง</span>
          </div>
        </div>

        {/* Scanner test */}
        <div className="tp-glass" style={{ padding: "16px 22px", display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{
            width: 56, height: 56, borderRadius: 14,
            background: "linear-gradient(160deg, oklch(.50 .14 250), oklch(.30 .12 270))",
            color: "white", display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 8px 16px -6px oklch(.30 .12 270 / .55)"
          }}><TPIcon name="qr" size={26}/></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เครื่องสแกน</div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Honeywell Voyager 1450g <span style={{ color: "oklch(.45 .14 150)", fontSize: 11, marginLeft: 6 }}>● ออนไลน์</span></div>
            <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>USB-HID · เชื่อม 2 ชั่วโมง 14 นาที · 3,648 สแกน/วัน</div>
          </div>
          <div style={{ padding: "10px 14px", borderRadius: 10, background: "oklch(.96 .04 145)", border: "1px solid oklch(.85 .08 150)" }}>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>สแกนล่าสุด</div>
            <div className="tp-mono" style={{ fontSize: 12, fontWeight: 700, color: "oklch(.40 .14 150)" }}>8851234567025</div>
          </div>
          <button className="tp-btn tp-btn-ghost" style={{ height: 38 }}><TPIcon name="check" size={14}/> ทดสอบ</button>
        </div>
      </div>
    </div>
  );
};

// === 23 · Shipping Label / Banner Print ===
const ShippingLabelScreen = () => {
  const queue = [
    { id: "SH-2042", to: "คุณกานต์ ว.", addr: "ทองหล่อ ซ.10 กทม.", p: "Grab", c: "145", w: "1.4 กก.", cod: null, status: "selected" },
    { id: "SH-2041", to: "บจก. สยามคอฟฟี่", addr: "ปทุมวัน กทม.", p: "LINE MAN", c: "145", w: "3.2 กก.", cod: null, status: "ready" },
    { id: "SH-2040", to: "คุณนิภา ส.", addr: "เชียงใหม่ 50000", p: "Flash", c: "80", w: "0.8 กก.", cod: "฿420", status: "ready" },
    { id: "SH-2039", to: "ร้านพิ้งกี้คาเฟ่", addr: "พระราม 9 กทม.", p: "Lalamove", c: "25", w: "8.0 กก.", cod: null, status: "ready" },
    { id: "SH-2038", to: "คุณภัทรพล ก.", addr: "ภูเก็ต 83000", p: "ไปรษณีย์ไทย", c: "270", w: "0.5 กก.", cod: "฿180", status: "ready" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hx("พิมพ์ใบปะหน้าพัสดุ · ปิดงานส่ง", "5 พัสดุพร้อมพิมพ์ · เครื่อง Brother QL-1110NWB · กระดาษ 4×6\"",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="settings" size={16}/> ตั้งค่าเครื่องพิมพ์</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> ใบเซ็นรับ Manifest</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="printer" size={16}/> พิมพ์ทั้งหมด (5)</button>
        </div>
      )}

      {/* Left: queue */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 420, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>คิวพิมพ์ใบปะหน้า</div>
        <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2, marginBottom: 14 }}>Print Queue · 5 ใบ</div>

        <div className="tp-scroll" style={{ flex: 1, overflow: "auto", display: "flex", flexDirection: "column", gap: 10 }}>
          {queue.map((q, i) => (
            <div key={i} style={{
              padding: "12px 14px", borderRadius: 12,
              background: q.status === "selected" ? "linear-gradient(140deg, oklch(.96 .06 195), oklch(.92 .08 220))" : "white",
              border: q.status === "selected" ? "1px solid oklch(.78 .12 195)" : "1px solid var(--tp-line)",
              boxShadow: q.status === "selected" ? "0 8px 18px -10px oklch(.55 .14 220 / .35)" : "0 2px 6px -3px rgba(20,40,80,.06)",
              cursor: "pointer"
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
                <div style={{ width: 18, height: 18, borderRadius: 5, border: q.status === "selected" ? "none" : "1.5px solid oklch(.75 .03 220)", background: q.status === "selected" ? "linear-gradient(160deg, oklch(.62 .14 195), oklch(.45 .14 220))" : "white", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  {q.status === "selected" && <TPIcon name="check" size={12} color="white" stroke={2.5}/>}
                </div>
                <span className="tp-mono" style={{ fontSize: 11, fontWeight: 700 }}>{q.id}</span>
                <span className="tp-chip" style={{ height: 20, fontSize: 10, padding: "0 8px", background: `oklch(.94 .08 ${q.c})`, color: `oklch(.40 .14 ${q.c})` }}>{q.p}</span>
                <div style={{ flex: 1 }}/>
                <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{q.w}</span>
              </div>
              <div style={{ fontSize: 13, fontWeight: 500 }}>{q.to}</div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 1 }}>{q.addr}</div>
              {q.cod && (
                <div style={{ marginTop: 6, padding: "4px 8px", borderRadius: 6, background: "oklch(.96 .04 80)", border: "1px solid oklch(.85 .10 80)", display: "inline-flex", alignItems: "center", gap: 4, fontSize: 10, fontWeight: 600, color: "oklch(.45 .14 80)" }}>
                  <TPIcon name="cash" size={11}/> เก็บปลายทาง {q.cod}
                </div>
              )}
            </div>
          ))}
        </div>

        <div style={{ marginTop: 12, paddingTop: 12, borderTop: "1px dashed var(--tp-line)" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 8 }}>
            <span style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>รวม</span>
            <div style={{ flex: 1 }}/>
            <span className="tp-tnum" style={{ fontSize: 16, fontWeight: 700 }}>13.9 กก. · ฿2,840</span>
          </div>
          <button className="tp-btn tp-btn-primary" style={{ width: "100%", height: 44 }}>
            <TPIcon name="printer" size={16}/> พิมพ์และยืนยันส่ง 5 พัสดุ
          </button>
        </div>
      </div>

      {/* Center: large label preview (4×6 inch) */}
      <div style={{ position: "absolute", left: 460, top: 116, width: 540, bottom: 290, display: "flex", flexDirection: "column" }}>
        <div className="tp-glass" style={{ padding: 14, marginBottom: 10, display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตัวอย่างใบปะหน้า · SH-2042</div>
          <div style={{ flex: 1 }}/>
          <span className="tp-chip tp-chip-active">4×6"</span>
          <span className="tp-chip">A6</span>
          <span className="tp-chip">100×150</span>
        </div>

        {/* the label paper */}
        <div style={{
          flex: 1, background: "white", borderRadius: 12,
          border: "1px solid var(--tp-line)",
          boxShadow: "0 14px 30px -16px rgba(20,40,80,.18), inset 0 1px 0 rgba(255,255,255,.7)",
          padding: 18, display: "flex", flexDirection: "column",
          fontFamily: "var(--tp-font-mono)", color: "#0e1a30",
          position: "relative", overflow: "hidden"
        }}>
          {/* corner crop marks */}
          {[[0,0],[0,1],[1,0],[1,1]].map(([x,y], i) => (
            <div key={i} style={{
              position: "absolute",
              [x === 0 ? "left" : "right"]: 4,
              [y === 0 ? "top" : "bottom"]: 4,
              width: 12, height: 12,
              borderTop: y === 0 ? "1px solid #0e1a30" : "none",
              borderBottom: y === 1 ? "1px solid #0e1a30" : "none",
              borderLeft: x === 0 ? "1px solid #0e1a30" : "none",
              borderRight: x === 1 ? "1px solid #0e1a30" : "none",
            }}/>
          ))}

          {/* header */}
          <div style={{ display: "flex", alignItems: "center", borderBottom: "2px solid #0e1a30", paddingBottom: 10, marginBottom: 12 }}>
            <div style={{
              width: 56, height: 56, borderRadius: 12,
              background: "linear-gradient(160deg, oklch(.50 .14 145), oklch(.35 .14 150))",
              color: "white", display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 18, fontWeight: 800, letterSpacing: "-.02em"
            }}>GR</div>
            <div style={{ marginLeft: 12, flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 800, fontFamily: "var(--tp-font-sans)" }}>GRAB EXPRESS</div>
              <div style={{ fontSize: 11, opacity: .7 }}>Same-day Bangkok · Order ID: GE-25080842</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 10, opacity: .7 }}>SERVICE</div>
              <div style={{ fontSize: 14, fontWeight: 800, padding: "3px 10px", border: "2px solid #0e1a30", borderRadius: 6, marginTop: 2 }}>EXPRESS</div>
            </div>
          </div>

          {/* sender / recipient */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, paddingBottom: 12, borderBottom: "1px dashed #0e1a30" }}>
            <div>
              <div style={{ fontSize: 9, opacity: .6, letterSpacing: ".15em" }}>FROM · จาก</div>
              <div style={{ fontSize: 12, fontWeight: 700, marginTop: 3, fontFamily: "var(--tp-font-sans)" }}>Thaiprompt Coffee — สยาม</div>
              <div style={{ fontSize: 10, marginTop: 2, lineHeight: 1.4 }}>989 อาคารสยามทาวเวอร์ ชั้น 8<br/>ถ.พระราม 1 ปทุมวัน กทม. 10330<br/>โทร 02-555-0188</div>
            </div>
            <div>
              <div style={{ fontSize: 9, opacity: .6, letterSpacing: ".15em" }}>TO · ผู้รับ</div>
              <div style={{ fontSize: 14, fontWeight: 700, marginTop: 3, fontFamily: "var(--tp-font-sans)" }}>คุณกานต์ วิริยะกุล</div>
              <div style={{ fontSize: 10, marginTop: 2, lineHeight: 1.4 }}>88/24 ทองหล่อ ซ.10<br/>วัฒนา กทม. 10110<br/>โทร 081-234-5678</div>
            </div>
          </div>

          {/* big tracking + barcode */}
          <div style={{ padding: "14px 0", borderBottom: "1px dashed #0e1a30" }}>
            <div style={{ fontSize: 10, opacity: .6, letterSpacing: ".15em" }}>TRACKING NO.</div>
            <div style={{ fontSize: 22, fontWeight: 800, letterSpacing: ".08em", marginTop: 2 }}>GE25080842TH</div>
            <div style={{ marginTop: 8 }}>
              <Barcode value="GE25080842TH" height={48} color="#0e1a30"/>
            </div>
          </div>

          {/* meta + QR */}
          <div style={{ flex: 1, display: "flex", marginTop: 12, gap: 14, alignItems: "stretch" }}>
            <div style={{ flex: 1, display: "grid", gridTemplateColumns: "1fr 1fr", gap: "6px 12px", fontSize: 11, alignContent: "start" }}>
              <div><div style={{ opacity: .6, fontSize: 9 }}>WEIGHT</div><div style={{ fontWeight: 700 }}>1.4 KG</div></div>
              <div><div style={{ opacity: .6, fontSize: 9 }}>PIECES</div><div style={{ fontWeight: 700 }}>1 / 1</div></div>
              <div><div style={{ opacity: .6, fontSize: 9 }}>PAYMENT</div><div style={{ fontWeight: 700 }}>PREPAID</div></div>
              <div><div style={{ opacity: .6, fontSize: 9 }}>FEE</div><div style={{ fontWeight: 700 }}>฿58</div></div>
              <div><div style={{ opacity: .6, fontSize: 9 }}>DATE</div><div style={{ fontWeight: 700 }}>08/05/2026</div></div>
              <div><div style={{ opacity: .6, fontSize: 9 }}>ROUTE</div><div style={{ fontWeight: 700 }}>BKK→BKK</div></div>
            </div>
            {/* QR placeholder */}
            <div style={{ width: 100, height: 100, background: "white", border: "2px solid #0e1a30", padding: 4, display: "grid", gridTemplateColumns: "repeat(8, 1fr)", gridAutoRows: "1fr", gap: 1 }}>
              {Array.from({ length: 64 }).map((_, i) => {
                const f = (i * 7 + (i >> 2) * 13) % 3;
                return <div key={i} style={{ background: f ? "#0e1a30" : "white" }}/>;
              })}
            </div>
          </div>

          {/* footer note */}
          <div style={{ marginTop: 8, paddingTop: 8, borderTop: "1px dashed #0e1a30", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <span style={{ fontSize: 9, opacity: .7 }}>HANDLE WITH CARE · ห้ามวางสินค้าบนกล่อง</span>
            <span style={{ fontSize: 9, fontWeight: 700 }}>POWERED BY THAIPROMPT POS</span>
          </div>
        </div>
      </div>

      {/* Right: printer status + options */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 396, height: 360, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เครื่องพิมพ์</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2 }}>Brother QL-1110NWB</div>

        <div style={{ marginTop: 14, padding: 14, borderRadius: 12, background: "oklch(.96 .04 145)", border: "1px solid oklch(.85 .08 150)", display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{
            width: 36, height: 36, borderRadius: "50%",
            background: "linear-gradient(160deg, oklch(.78 .12 145), oklch(.50 .14 150))",
            color: "white", display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "0 0 0 4px oklch(.85 .12 145 / .35)"
          }}><TPIcon name="check" size={18}/></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: "oklch(.35 .14 150)" }}>พร้อมพิมพ์</div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>Wi-Fi · 192.168.1.42 · 24°C</div>
          </div>
        </div>

        <div style={{ marginTop: 14, display: "flex", flexDirection: "column", gap: 10 }}>
          {[
            { l: "กระดาษม้วน", v: "DK-22246 (4×6\")", p: 78 },
            { l: "หมึก/หัวพิมพ์", v: "ปกติ", p: 92 },
          ].map((m, i) => (
            <div key={i}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ fontSize: 12, color: "var(--tp-ink-soft)" }}>{m.l}</span>
                <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{m.v} · {m.p}%</span>
              </div>
              <div style={{ height: 8, background: "rgba(20,40,80,.06)", borderRadius: 999, overflow: "hidden" }}>
                <div style={{ height: "100%", width: `${m.p}%`, background: m.p > 30 ? "linear-gradient(90deg, oklch(.78 .14 145), oklch(.55 .14 150))" : "oklch(.62 .14 25)", borderRadius: 999 }}/>
              </div>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 18, paddingTop: 14, borderTop: "1px dashed var(--tp-line)" }}>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>คิวงาน</div>
          {[
            { id: "JOB-08-021", n: "5 ใบปะหน้า", t: "รอเริ่ม" },
            { id: "JOB-08-020", n: "3 ใบปะหน้า", t: "เสร็จแล้ว 14:42" },
            { id: "JOB-08-019", n: "Manifest 12 ใบ", t: "เสร็จแล้ว 11:08" },
          ].map((j, i) => (
            <div key={i} style={{ display: "flex", padding: "6px 0", fontSize: 12, gap: 8 }}>
              <span className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)", flex: "0 0 84px" }}>{j.id}</span>
              <span style={{ flex: 1 }}>{j.n}</span>
              <span style={{ fontSize: 11, color: i === 0 ? "oklch(.45 .14 80)" : "var(--tp-ink-mute)", fontWeight: i === 0 ? 600 : 400 }}>{j.t}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right bottom: print options */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 496, width: 396, bottom: 24, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตัวเลือกการพิมพ์</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 12 }}>Print Options</div>

        {[
          { l: "พิมพ์ 2 สำเนา (สำหรับร้าน)", on: true },
          { l: "รวมแบนเนอร์ปิดงานกะ", on: true },
          { l: "พิมพ์ Manifest ลงท้าย", on: true },
          { l: "ขนาดตัวอักษรใหญ่พิเศษ", on: false },
          { l: "ส่งรหัส tracking ทาง SMS", on: true },
        ].map((t, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", padding: "8px 0", borderBottom: i < 4 ? "1px dashed var(--tp-line)" : "none" }}>
            <span style={{ flex: 1, fontSize: 13 }}>{t.l}</span>
            <div style={{
              width: 38, height: 22, borderRadius: 999,
              background: t.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)",
              position: "relative",
              boxShadow: t.on ? "inset 0 1px 0 rgba(255,255,255,.25), 0 4px 10px -4px oklch(.50 .14 220 / .5)" : "inset 0 1px 2px rgba(20,40,80,.08)"
            }}>
              <div style={{ position: "absolute", top: 2, left: t.on ? 18 : 2, width: 18, height: 18, borderRadius: "50%", background: "white", boxShadow: "0 2px 4px rgba(20,40,80,.2)" }}/>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

window.BarcodeScreen = BarcodeScreen;
window.ShippingLabelScreen = ShippingLabelScreen;

// Thaiprompt POS — Business screens: Accounting, Create Bill, Tax Invoice, NFC Scan, Delivery, Receipt of payment

// === 12 · การจัดการบัญชี (Accounting) ===
const AccountingScreen = () => {
  const accounts = [
    { code: "1101", name: "เงินสดในมือ", type: "สินทรัพย์", balance: 184250, dir: "Dr", c: "188" },
    { code: "1102", name: "เงินฝากธนาคาร — ไทยพาณิชย์", type: "สินทรัพย์", balance: 1245680, dir: "Dr", c: "188" },
    { code: "1103", name: "เงินฝากธนาคาร — กสิกรไทย", type: "สินทรัพย์", balance: 482350, dir: "Dr", c: "188" },
    { code: "1201", name: "ลูกหนี้การค้า", type: "สินทรัพย์", balance: 38420, dir: "Dr", c: "188" },
    { code: "2101", name: "เจ้าหนี้การค้า", type: "หนี้สิน", balance: 96420, dir: "Cr", c: "25" },
    { code: "2103", name: "ภาษีขายค้างจ่าย (VAT 7%)", type: "หนี้สิน", balance: 28940, dir: "Cr", c: "25" },
    { code: "4101", name: "รายได้จากการขาย", type: "รายได้", balance: 1284500, dir: "Cr", c: "145" },
    { code: "5101", name: "ต้นทุนขาย", type: "ค่าใช้จ่าย", balance: 542180, dir: "Dr", c: "80" },
    { code: "5201", name: "เงินเดือนพนักงาน", type: "ค่าใช้จ่าย", balance: 184000, dir: "Dr", c: "80" },
    { code: "5301", name: "ค่าเช่าสถานที่", type: "ค่าใช้จ่าย", balance: 65000, dir: "Dr", c: "80" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>การจัดการบัญชี</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>ผังบัญชี · งบทดลอง · พฤษภาคม 2568</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", background: "rgba(255,255,255,.5)", borderRadius: 12, padding: 4, gap: 2, border: "1px solid rgba(255,255,255,.6)" }}>
          {["ผังบัญชี", "สมุดรายวัน", "งบทดลอง", "งบกำไรขาดทุน", "งบดุล"].map((t, i) => (
            <button key={i} style={{
              padding: "8px 16px", borderRadius: 9, border: "none", cursor: "pointer",
              fontFamily: "inherit", fontSize: 13, fontWeight: 500,
              background: i === 0 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent",
              color: i === 0 ? "white" : "var(--tp-ink-soft)",
            }}>{t}</button>
          ))}
        </div>
        <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> บันทึกรายการ</button>
      </header>

      {/* KPI */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "สินทรัพย์รวม", v: "฿1,950,700", d: "+8.2%", up: true, c: "188" },
          { l: "หนี้สินรวม", v: "฿125,360", d: "−3.1%", up: false, c: "25" },
          { l: "ส่วนของเจ้าของ", v: "฿1,825,340", d: "+10.4%", up: true, c: "270" },
          { l: "กำไรสุทธิ (เดือนนี้)", v: "฿493,320", d: "+15.8%", up: true, c: "145" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px", position: "relative", overflow: "hidden" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-.02em", marginTop: 4, color: "var(--tp-indigo-deep)" }}>{k.v}</div>
            <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 6,
              padding: "2px 8px", borderRadius: 999, fontSize: 11, fontWeight: 600,
              background: k.up ? "oklch(.94 .08 145)" : "oklch(.94 .08 25)",
              color: k.up ? "oklch(.45 .14 150)" : "oklch(.55 .15 25)" }}>
              <TPIcon name={k.up ? "arrow-up" : "arrow-down"} size={11}/> {k.d}
            </div>
            <div style={{ position: "absolute", right: -10, top: -10, width: 80, height: 80, borderRadius: "50%",
              background: `radial-gradient(circle, oklch(.85 .12 ${k.c} / .35), transparent 70%)`, filter: "blur(8px)" }}/>
          </div>
        ))}
      </div>

      {/* Chart of accounts table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, width: 920, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>Chart of Accounts</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>ผังบัญชี</div>
          </div>
          <div style={{ flex: 1 }}/>
          <div style={{ display: "flex", gap: 6 }}>
            {["ทั้งหมด", "สินทรัพย์", "หนี้สิน", "รายได้", "ค่าใช้จ่าย"].map((t, i) => (
              <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"}>{t}</span>
            ))}
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "100px 2.4fr 1fr 1fr 140px", gap: 14, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>เลขบัญชี</span><span>ชื่อบัญชี</span><span>ประเภท</span><span style={{ textAlign: "right" }}>ยอดคงเหลือ</span><span style={{ textAlign: "right" }}>Dr / Cr</span>
        </div>

        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {accounts.map((a, i) => (
            <div key={i} style={{
              display: "grid", gridTemplateColumns: "100px 2.4fr 1fr 1fr 140px",
              gap: 14, padding: "12px 14px", alignItems: "center",
              borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13,
              background: i % 2 ? "rgba(255,255,255,.25)" : "transparent",
              borderRadius: 8,
            }}>
              <span className="tp-mono" style={{ fontWeight: 600, color: "var(--tp-ink-soft)" }}>{a.code}</span>
              <span style={{ fontWeight: 500 }}>{a.name}</span>
              <span className="tp-chip" style={{ height: 24, fontSize: 11, padding: "0 10px" }}>{a.type}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>฿{a.balance.toLocaleString()}</span>
              <div style={{ textAlign: "right" }}>
                <span style={{
                  fontSize: 11, fontWeight: 600, padding: "3px 10px", borderRadius: 999,
                  background: `oklch(.94 .08 ${a.c})`, color: `oklch(.45 .14 ${a.c})`,
                  fontFamily: "var(--tp-font-mono)"
                }}>{a.dir === "Dr" ? "เดบิต" : "เครดิต"}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Right: P&L summary + recent journal */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 460, height: 320, padding: "22px 26px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำไร / ขาดทุน</div>
        <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2, marginBottom: 16 }}>เดือนพฤษภาคม</div>
        {[
          { l: "รายได้จากการขาย", v: 1284500, c: "145" },
          { l: "หัก: ส่วนลด", v: -42300, c: "25" },
          { l: "หัก: ต้นทุนขาย", v: -542180, c: "80" },
          { l: "กำไรขั้นต้น", v: 700020, c: "270", bold: true },
          { l: "หัก: ค่าใช้จ่ายในการขาย", v: -84500, c: "80" },
          { l: "หัก: ค่าใช้จ่ายบริหาร", v: -122200, c: "80" },
          { l: "กำไรสุทธิ", v: 493320, c: "188", bold: true, big: true },
        ].map((r, i) => (
          <div key={i} style={{
            display: "flex", padding: "8px 0",
            borderBottom: r.bold ? "1px solid rgba(20,40,80,.15)" : "1px dashed rgba(20,40,80,.06)",
            fontWeight: r.bold ? 600 : 400,
            fontSize: r.big ? 16 : 13,
          }}>
            <span style={{ flex: 1 }}>{r.l}</span>
            <span className="tp-tnum" style={{ color: r.v < 0 ? "oklch(.55 .15 25)" : (r.bold ? `oklch(.45 .14 ${r.c})` : "var(--tp-ink)") }}>
              {r.v < 0 ? "(" : ""}฿{Math.abs(r.v).toLocaleString()}{r.v < 0 ? ")" : ""}
            </span>
          </div>
        ))}
      </div>

      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 580, width: 460, bottom: 24, padding: "18px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>สมุดรายวันล่าสุด</div>
        <div style={{ fontSize: 16, fontWeight: 600, marginTop: 2, marginBottom: 12 }}>Journal Entries</div>
        {[
          { d: "08 พ.ค.", n: "JV-0428", desc: "รับชำระบิล A1042", v: "฿331" },
          { d: "08 พ.ค.", n: "JV-0427", desc: "ซื้อเมล็ดกาแฟ", v: "฿8,460" },
          { d: "07 พ.ค.", n: "JV-0426", desc: "จ่ายค่าเช่า พ.ค.", v: "฿65,000" },
          { d: "07 พ.ค.", n: "JV-0425", desc: "รับชำระลูกหนี้ คุณสมชาย", v: "฿4,200" },
        ].map((j, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", padding: "10px 0", borderBottom: "1px dashed rgba(20,40,80,.06)", gap: 10 }}>
            <div style={{ width: 38, height: 38, borderRadius: 10, background: "linear-gradient(160deg, oklch(.92 .05 220), oklch(.85 .06 230))", display: "flex", alignItems: "center", justifyContent: "center", color: "oklch(.45 .12 250)" }}>
              <TPIcon name="receipt" size={16}/>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: 500 }}>{j.desc}</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{j.n} · {j.d}</div>
            </div>
            <span className="tp-tnum" style={{ fontWeight: 600, fontSize: 13 }}>{j.v}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

// === 13 · สร้างบิล (Create Bill / Invoice) ===
const CreateBillScreen = () => {
  const items = [
    { name: "ชาไทยเย็น", qty: 4, price: 65, note: "หวานน้อย" },
    { name: "ชาเขียวมัทฉะลาเต้", qty: 2, price: 85, note: "" },
    { name: "ครัวซองต์อัลมอนด์", qty: 3, price: 55, note: "อุ่นก่อนเสิร์ฟ" },
    { name: "เค้กส้ม", qty: 1, price: 95, note: "" },
  ];
  const sub = items.reduce((s, it) => s + it.qty * it.price, 0);
  const disc = 30;
  const vat = Math.round(((sub - disc) * 7) / 107);
  const net = sub - disc;

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>สร้างบิล</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>เลขที่: <span className="tp-mono">INV-2568-0428</span> · ผู้บันทึก: คุณนัท</div>
        </div>
        <div style={{ flex: 1 }}/>
        <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="x" size={16}/> ยกเลิก</button>
        <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> บันทึกร่าง</button>
        <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="check" size={16}/> ออกบิล</button>
      </header>

      {/* Left: customer + items */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 880, bottom: 24, padding: 24, display: "flex", flexDirection: "column", gap: 18 }}>
        {/* customer block */}
        <div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>ข้อมูลลูกค้า</div>
          <div style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr 1fr", gap: 12 }}>
            <div style={{ background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ชื่อ — นามสกุล / บริษัท</div>
              <div style={{ fontSize: 15, fontWeight: 500, marginTop: 2 }}>บริษัท สยาม คอฟฟี่ จำกัด</div>
            </div>
            <div style={{ background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>เบอร์โทร</div>
              <div className="tp-mono" style={{ fontSize: 15, fontWeight: 500, marginTop: 2 }}>02-218-5400</div>
            </div>
            <div style={{ background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>เลขผู้เสียภาษี</div>
              <div className="tp-mono" style={{ fontSize: 15, fontWeight: 500, marginTop: 2 }}>0105563012345</div>
            </div>
          </div>
          <div style={{ marginTop: 10, background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ที่อยู่จัดส่ง</div>
            <div style={{ fontSize: 14, marginTop: 2 }}>989 อาคารสยามพิวรรธน์ ทาวเวอร์ ชั้น 14 ถ.พระราม 1 แขวงปทุมวัน เขตปทุมวัน กรุงเทพฯ 10330</div>
          </div>
        </div>

        {/* item table */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 8 }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>รายการสินค้า</div>
            <div style={{ flex: 1 }}/>
            <button className="tp-btn tp-btn-ghost" style={{ height: 34, fontSize: 12 }}><TPIcon name="plus" size={14}/> เพิ่มรายการ</button>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "44px 2.6fr 80px 100px 110px 40px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
            <span>#</span><span>สินค้า</span><span style={{ textAlign: "right" }}>จำนวน</span><span style={{ textAlign: "right" }}>ราคา</span><span style={{ textAlign: "right" }}>รวม</span><span></span>
          </div>
          <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
            {items.map((it, i) => (
              <div key={i} style={{
                display: "grid", gridTemplateColumns: "44px 2.6fr 80px 100px 110px 40px",
                gap: 10, padding: "12px 14px", alignItems: "center",
                borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13,
              }}>
                <span className="tp-mono" style={{ color: "var(--tp-ink-mute)" }}>{i + 1}</span>
                <div>
                  <div style={{ fontWeight: 500 }}>{it.name}</div>
                  {it.note && <div style={{ fontSize: 11, color: "oklch(.55 .15 25)", marginTop: 2 }}>* {it.note}</div>}
                </div>
                <span className="tp-tnum" style={{ textAlign: "right" }}>{it.qty}</span>
                <span className="tp-tnum" style={{ textAlign: "right" }}>฿{it.price}</span>
                <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>฿{(it.qty * it.price).toLocaleString()}</span>
                <button style={{ width: 28, height: 28, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-mute)" }}><TPIcon name="trash" size={14}/></button>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right: invoice settings + total */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 488, bottom: 24, padding: 24, display: "flex", flexDirection: "column" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตั้งค่าเอกสาร</div>

        <div style={{ marginTop: 14, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          <div style={{ background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>วันที่ออก</div>
            <div className="tp-mono" style={{ fontSize: 14, fontWeight: 500, marginTop: 2 }}>08 พ.ค. 2568</div>
          </div>
          <div style={{ background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ครบกำหนด</div>
            <div className="tp-mono" style={{ fontSize: 14, fontWeight: 500, marginTop: 2 }}>22 พ.ค. 2568</div>
          </div>
        </div>

        <div style={{ marginTop: 10, background: "white", border: "1px solid var(--tp-line)", borderRadius: 12, padding: "10px 14px" }}>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>เครดิตเทอม</div>
          <div style={{ fontSize: 14, fontWeight: 500, marginTop: 2 }}>14 วัน</div>
        </div>

        {/* type radio */}
        <div style={{ marginTop: 14, fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ประเภทเอกสาร</div>
        <div style={{ marginTop: 8, display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 8 }}>
          {[
            { l: "ใบกำกับภาษี", on: true },
            { l: "ใบเสร็จรับเงิน", on: false },
            { l: "ใบแจ้งหนี้", on: false },
            { l: "ใบเสนอราคา", on: false },
          ].map((t, i) => (
            <button key={i} style={{
              padding: "10px 12px", borderRadius: 12, fontFamily: "inherit",
              fontSize: 13, fontWeight: 500, cursor: "pointer",
              border: t.on ? "1.5px solid oklch(.62 .14 195)" : "1px solid var(--tp-line)",
              background: t.on ? "oklch(.96 .04 195)" : "white",
              color: t.on ? "oklch(.40 .14 200)" : "var(--tp-ink-soft)",
              display: "flex", alignItems: "center", justifyContent: "center", gap: 6
            }}>
              {t.on && <TPIcon name="check" size={14}/>}
              {t.l}
            </button>
          ))}
        </div>

        <div style={{ flex: 1 }}/>

        {/* totals */}
        <div style={{ borderTop: "1px dashed var(--tp-line)", paddingTop: 16, fontSize: 14 }}>
          <div style={{ display: "flex", padding: "6px 0" }}>
            <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>ยอดรวมก่อนหักส่วนลด</span>
            <span className="tp-tnum">฿{sub.toLocaleString()}</span>
          </div>
          <div style={{ display: "flex", padding: "6px 0" }}>
            <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>ส่วนลด</span>
            <span className="tp-tnum" style={{ color: "oklch(.55 .15 25)" }}>−฿{disc.toLocaleString()}</span>
          </div>
          <div style={{ display: "flex", padding: "6px 0" }}>
            <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>ภาษีมูลค่าเพิ่ม 7% (รวมแล้ว)</span>
            <span className="tp-tnum">฿{vat.toLocaleString()}</span>
          </div>
          <div style={{
            display: "flex", padding: "14px 16px", marginTop: 10, borderRadius: 14,
            background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.20 .06 270))",
            color: "white",
            boxShadow: "0 8px 22px -10px oklch(.25 .07 265 / .55), 0 1px 0 rgba(255,255,255,.12) inset",
            alignItems: "baseline"
          }}>
            <span style={{ flex: 1, fontSize: 14, opacity: .85 }}>ยอดสุทธิที่ต้องชำระ</span>
            <span className="tp-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-.01em" }}>฿{net.toLocaleString()}.00</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// === 14 · ใบกำกับภาษี (Tax Invoice) ===
const TaxInvoiceScreen = () => {
  const items = [
    { name: "ชาไทยเย็น (สูตรพิเศษ)", qty: 4, price: 65 },
    { name: "ชาเขียวมัทฉะลาเต้", qty: 2, price: 85 },
    { name: "ครัวซองต์อัลมอนด์", qty: 3, price: 55 },
    { name: "เค้กส้ม", qty: 1, price: 95 },
  ];
  const sub = items.reduce((s, it) => s + it.qty * it.price - 30 / items.length, 0);
  const beforeVat = Math.round((sub * 100) / 107);
  const vat = Math.round((sub * 7) / 107);

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>ใบกำกับภาษี / ใบเสร็จรับเงิน</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>ตัวอย่างก่อนพิมพ์ · เลขที่ <span className="tp-mono">TAX-2568-001428</span></div>
        </div>
        <div style={{ flex: 1 }}/>
        <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="arrow-down" size={16}/> ดาวน์โหลด PDF</button>
        <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="printer" size={16}/> พิมพ์</button>
        <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="check" size={16}/> ส่ง e-Tax</button>
      </header>

      {/* Document preview canvas */}
      <div style={{ position: "absolute", left: 24, right: 360, top: 116, bottom: 24, display: "flex", justifyContent: "center", alignItems: "flex-start", overflow: "auto", padding: "20px 0" }}>
        <div style={{
          width: 720, minHeight: 920,
          background: "white",
          borderRadius: 12,
          boxShadow: "0 30px 70px -25px rgba(20,40,80,.25), 0 8px 22px -10px rgba(20,40,80,.15)",
          padding: "44px 56px",
          fontFamily: "var(--tp-font)",
          color: "var(--tp-ink)",
          position: "relative",
          overflow: "hidden",
        }}>
          {/* gradient stripe */}
          <div style={{ position: "absolute", left: 0, top: 0, right: 0, height: 6, background: "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 250))" }}/>
          {/* watermark */}
          <div style={{ position: "absolute", right: -40, top: 120, opacity: .04, transform: "rotate(-22deg)", fontSize: 140, fontWeight: 700, pointerEvents: "none" }}>TAX INVOICE</div>

          {/* header */}
          <div style={{ display: "flex", alignItems: "flex-start" }}>
            <TPLogo size={56} glow={false}/>
            <div style={{ marginLeft: 14 }}>
              <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: "-.01em" }}>Thaiprompt Coffee Co., Ltd.</div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>444 อาคารสยามสแควร์วัน ชั้น 8, ถ.พระราม 1, ปทุมวัน กรุงเทพฯ 10330</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>เลขประจำตัวผู้เสียภาษี: 0107555000123 · สำนักงานใหญ่</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>โทร 02-555-0123 · contact@thaiprompt.co.th</div>
            </div>
            <div style={{ flex: 1 }}/>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 18, fontWeight: 700, letterSpacing: "-.01em" }}>ใบกำกับภาษี / ใบเสร็จรับเงิน</div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>TAX INVOICE / RECEIPT</div>
              <div style={{ marginTop: 8, fontSize: 11, color: "var(--tp-ink-mute)" }}>ต้นฉบับ — ORIGINAL</div>
            </div>
          </div>

          {/* meta box */}
          <div style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr", gap: 14, marginTop: 26 }}>
            <div style={{ border: "1px solid var(--tp-line)", borderRadius: 10, padding: "12px 16px" }}>
              <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".08em" }}>ลูกค้า / Customer</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginTop: 4 }}>บริษัท สยาม คอฟฟี่ จำกัด</div>
              <div style={{ fontSize: 11, marginTop: 2, color: "var(--tp-ink-soft)" }}>989 อาคารสยามพิวรรธน์ ทาวเวอร์ ชั้น 14 ถ.พระราม 1 แขวงปทุมวัน เขตปทุมวัน กรุงเทพฯ 10330</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 4 }}>TAX ID: 0105563012345 · สำนักงานใหญ่</div>
            </div>
            <div style={{ border: "1px solid var(--tp-line)", borderRadius: 10, padding: "12px 16px" }}>
              <div style={{ display: "grid", gridTemplateColumns: "auto 1fr", gap: "6px 12px", fontSize: 12 }}>
                <span style={{ color: "var(--tp-ink-mute)" }}>เลขที่:</span><span className="tp-mono" style={{ fontWeight: 600 }}>TAX-2568-001428</span>
                <span style={{ color: "var(--tp-ink-mute)" }}>วันที่:</span><span className="tp-mono">08 พ.ค. 2568</span>
                <span style={{ color: "var(--tp-ink-mute)" }}>ครบกำหนด:</span><span className="tp-mono">22 พ.ค. 2568</span>
                <span style={{ color: "var(--tp-ink-mute)" }}>ผู้ขาย:</span><span>คุณนัทธมน</span>
                <span style={{ color: "var(--tp-ink-mute)" }}>อ้างอิง:</span><span className="tp-mono">PO-SC-9982</span>
              </div>
            </div>
          </div>

          {/* items */}
          <table style={{ width: "100%", borderCollapse: "collapse", marginTop: 22, fontSize: 12 }}>
            <thead>
              <tr style={{ background: "oklch(.96 .02 220)", textAlign: "left" }}>
                <th style={{ padding: "10px 12px", fontWeight: 600, fontSize: 11, color: "var(--tp-ink-soft)", textTransform: "uppercase", letterSpacing: ".05em" }}>#</th>
                <th style={{ padding: "10px 12px", fontWeight: 600, fontSize: 11, color: "var(--tp-ink-soft)", textTransform: "uppercase", letterSpacing: ".05em" }}>รายการ / Description</th>
                <th style={{ padding: "10px 12px", fontWeight: 600, fontSize: 11, color: "var(--tp-ink-soft)", textTransform: "uppercase", letterSpacing: ".05em", textAlign: "right" }}>จำนวน</th>
                <th style={{ padding: "10px 12px", fontWeight: 600, fontSize: 11, color: "var(--tp-ink-soft)", textTransform: "uppercase", letterSpacing: ".05em", textAlign: "right" }}>ราคา/หน่วย</th>
                <th style={{ padding: "10px 12px", fontWeight: 600, fontSize: 11, color: "var(--tp-ink-soft)", textTransform: "uppercase", letterSpacing: ".05em", textAlign: "right" }}>จำนวนเงิน</th>
              </tr>
            </thead>
            <tbody>
              {items.map((it, i) => (
                <tr key={i} style={{ borderBottom: "1px dashed var(--tp-line)" }}>
                  <td className="tp-mono" style={{ padding: "12px", color: "var(--tp-ink-mute)" }}>{i + 1}</td>
                  <td style={{ padding: "12px", fontWeight: 500 }}>{it.name}</td>
                  <td className="tp-tnum" style={{ padding: "12px", textAlign: "right" }}>{it.qty}</td>
                  <td className="tp-tnum" style={{ padding: "12px", textAlign: "right" }}>{it.price.toFixed(2)}</td>
                  <td className="tp-tnum" style={{ padding: "12px", textAlign: "right", fontWeight: 500 }}>{(it.qty * it.price).toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* totals box */}
          <div style={{ display: "flex", marginTop: 20 }}>
            <div style={{ flex: 1, padding: "14px 16px", border: "1px dashed var(--tp-line)", borderRadius: 10, fontSize: 11, color: "var(--tp-ink-soft)" }}>
              <div style={{ fontWeight: 600, color: "var(--tp-ink)", marginBottom: 4 }}>หมายเหตุ</div>
              <div>ชำระโดยโอนเข้าบัญชี ไทยพาณิชย์ เลขที่ 123-4-56789-0 ชื่อ บจก. ไทยพรอมพ์ คอฟฟี่ — กรุณาแนบสลิปกลับ contact@thaiprompt.co.th</div>
            </div>
            <div style={{ width: 280, marginLeft: 16, fontSize: 12 }}>
              <div style={{ display: "flex", padding: "6px 0", borderBottom: "1px dashed var(--tp-line)" }}>
                <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>มูลค่าก่อน VAT</span>
                <span className="tp-tnum">{beforeVat.toLocaleString()}.00</span>
              </div>
              <div style={{ display: "flex", padding: "6px 0", borderBottom: "1px dashed var(--tp-line)" }}>
                <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>ภาษีมูลค่าเพิ่ม 7%</span>
                <span className="tp-tnum">{vat.toLocaleString()}.00</span>
              </div>
              <div style={{
                display: "flex", padding: "12px 14px", marginTop: 8, borderRadius: 10,
                background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.20 .06 270))",
                color: "white",
              }}>
                <span style={{ flex: 1, fontWeight: 500 }}>รวมทั้งสิ้น</span>
                <span className="tp-tnum" style={{ fontWeight: 700, fontSize: 16 }}>฿{Math.round(sub).toLocaleString()}.00</span>
              </div>
            </div>
          </div>

          {/* signatures */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 32, marginTop: 64, fontSize: 11, color: "var(--tp-ink-soft)" }}>
            <div style={{ borderTop: "1px solid var(--tp-line)", paddingTop: 8, textAlign: "center" }}>ผู้รับเงิน / Received by</div>
            <div style={{ borderTop: "1px solid var(--tp-line)", paddingTop: 8, textAlign: "center" }}>ผู้รับสินค้า / Received goods</div>
          </div>
        </div>
      </div>

      {/* Right: e-tax status panel */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 312, bottom: 24, padding: "22px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>สถานะ e-Tax Invoice</div>

        {[
          { l: "บันทึกร่าง", t: "08 พ.ค. 14:32", done: true },
          { l: "ออกเลขที่เอกสาร", t: "08 พ.ค. 14:33", done: true },
          { l: "ลงลายเซ็นดิจิทัล", t: "08 พ.ค. 14:33", done: true },
          { l: "ส่งให้กรมสรรพากร", t: "รอดำเนินการ", done: false, current: true },
          { l: "ส่งให้ลูกค้าทาง Email", t: "—", done: false },
        ].map((s, i, arr) => (
          <div key={i} style={{ display: "flex", gap: 12, marginTop: i === 0 ? 16 : 0 }}>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
              <div style={{
                width: 26, height: 26, borderRadius: "50%",
                background: s.done ? "linear-gradient(160deg, oklch(.78 .14 145), oklch(.55 .14 150))" : (s.current ? "white" : "oklch(.96 .01 220)"),
                border: s.current ? "2px solid oklch(.62 .14 195)" : "none",
                display: "flex", alignItems: "center", justifyContent: "center",
                color: s.done ? "white" : "var(--tp-ink-mute)",
                boxShadow: s.done ? "0 4px 10px -3px oklch(.55 .14 150 / .5)" : "none"
              }}>
                {s.done ? <TPIcon name="check" size={14}/> : <span style={{ fontSize: 12, fontWeight: 600 }}>{i + 1}</span>}
              </div>
              {i < arr.length - 1 && <div style={{ width: 2, flex: 1, background: s.done ? "oklch(.78 .14 145)" : "var(--tp-line)", margin: "4px 0" }}/>}
            </div>
            <div style={{ paddingBottom: 18, flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 500 }}>{s.l}</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>{s.t}</div>
            </div>
          </div>
        ))}

        <div style={{ marginTop: 6, padding: 14, borderRadius: 12, background: "oklch(.96 .03 220)", border: "1px solid oklch(.85 .04 220)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, fontWeight: 600 }}>
            <TPIcon name="check" size={14} color="oklch(.55 .14 200)"/>
            ผ่านการตรวจสอบโครงสร้าง
          </div>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 4 }}>เอกสารถูกต้องตามรูปแบบ XML ของกรมสรรพากร พร้อมส่ง</div>
        </div>
      </div>
    </div>
  );
};

// === 15 · NFC Card Scan ===
const NFCScanScreen = () => {
  return (
    <div className="tp-app" style={{ width: 1280, height: 800, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {/* radial spotlight */}
      <div style={{ position: "absolute", inset: 0,
        background: "radial-gradient(circle at 50% 45%, oklch(.85 .14 195 / .35), transparent 60%)" }}/>

      <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 64, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
        <TPLogo size={36}/>
        <div style={{ fontSize: 15, fontWeight: 600 }}>แตะบัตรเพื่อชำระ</div>
        <div style={{ flex: 1 }}/>
        <span className="tp-chip"><TPIcon name="receipt" size={13}/> บิล A1042</span>
        <span className="tp-chip"><TPIcon name="user" size={13}/> คุณนัท</span>
      </header>

      {/* center NFC visual */}
      <div style={{ position: "absolute", left: 0, right: 360, top: 100, bottom: 24, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        {/* pulse rings */}
        <div style={{ position: "relative", width: 460, height: 460, display: "flex", alignItems: "center", justifyContent: "center" }}>
          {[1, 2, 3].map(r => (
            <div key={r} style={{
              position: "absolute", width: 460 - r * 30, height: 460 - r * 30, borderRadius: "50%",
              border: "2px solid oklch(.62 .14 195)",
              opacity: 0.5 - r * 0.12,
              animation: `nfcpulse 2.6s ease-out ${r * 0.3}s infinite`
            }}/>
          ))}
          <style>{`@keyframes nfcpulse { 0% { transform: scale(.8); opacity: .55 } 80% { transform: scale(1.15); opacity: 0 } 100% { transform: scale(1.15); opacity: 0 } }`}</style>

          {/* NFC reader puck */}
          <div style={{
            width: 240, height: 240, borderRadius: "50%",
            background: "linear-gradient(160deg, oklch(.85 .12 188), oklch(.55 .14 200) 70%, oklch(.40 .14 250))",
            boxShadow: "0 30px 80px -20px oklch(.45 .14 230 / .55), 0 8px 22px -8px oklch(.50 .14 250 / .45), inset 0 2px 0 rgba(255,255,255,.5), inset 0 -3px 0 rgba(20,40,80,.15)",
            display: "flex", alignItems: "center", justifyContent: "center",
            position: "relative",
          }}>
            {/* wave icon */}
            <svg width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.6" strokeLinecap="round" style={{ filter: "drop-shadow(0 4px 8px rgba(20,40,80,.3))" }}>
              <path d="M5 8a10 10 0 0 1 14 0"/>
              <path d="M8 11a6 6 0 0 1 8 0"/>
              <path d="M11 14a2 2 0 0 1 2 0"/>
              <circle cx="12" cy="17" r="1" fill="white"/>
            </svg>
          </div>

          {/* glassy card hovering */}
          <div style={{
            position: "absolute", right: 30, top: 80,
            width: 220, height: 138, borderRadius: 16,
            background: "linear-gradient(140deg, oklch(.50 .15 270 / .85), oklch(.30 .12 290 / .85))",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,.35)",
            boxShadow: "0 24px 50px -16px rgba(20,40,80,.45), inset 0 1px 0 rgba(255,255,255,.55)",
            transform: "rotate(-12deg)",
            padding: "16px 18px", color: "white", overflow: "hidden"
          }}>
            <div style={{ position: "absolute", left: -20, bottom: -20, width: 120, height: 120, borderRadius: "50%", background: "radial-gradient(circle, oklch(.78 .14 28 / .6), transparent 70%)", filter: "blur(8px)" }}/>
            {/* chip + nfc */}
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 32, height: 24, borderRadius: 4, background: "linear-gradient(135deg, oklch(.85 .14 80), oklch(.65 .12 80))", boxShadow: "inset 0 1px 0 rgba(255,255,255,.5)" }}/>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.8" opacity=".8"><path d="M5 8a10 10 0 0 1 14 0"/><path d="M8 11a6 6 0 0 1 8 0"/></svg>
            </div>
            <div className="tp-mono" style={{ fontSize: 16, letterSpacing: ".15em", marginTop: 28, opacity: .9 }}>•••• 4827</div>
            <div style={{ display: "flex", marginTop: 6, fontSize: 9, opacity: .7, textTransform: "uppercase", letterSpacing: ".15em" }}>
              <span>VISA Platinum</span>
              <div style={{ flex: 1 }}/>
              <span>05/29</span>
            </div>
          </div>
        </div>

        <div style={{ marginTop: 20, fontSize: 26, fontWeight: 600, letterSpacing: "-.01em" }}>กรุณาแตะบัตรหรือมือถือ</div>
        <div style={{ fontSize: 14, color: "var(--tp-ink-mute)", marginTop: 6 }}>รองรับ NFC: บัตรเครดิต/เดบิต Visa, Master, JCB · Apple Pay · Google Pay · พร้อมเพย์ Tag</div>
      </div>

      {/* Right: amount + alt methods */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 100, width: 312, bottom: 24, padding: "22px 26px", display: "flex", flexDirection: "column" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ยอดที่ต้องชำระ</div>
        <div className="tp-tnum" style={{ fontSize: 56, fontWeight: 700, letterSpacing: "-.03em", lineHeight: 1, marginTop: 6, color: "var(--tp-indigo-deep)" }}>฿1,335</div>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 4 }}>17 รายการ · บิล A1042 · โต๊ะ 7</div>

        <div style={{ marginTop: 22, padding: 14, borderRadius: 14, background: "oklch(.96 .03 195)", border: "1px solid oklch(.85 .05 195)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, fontWeight: 600, color: "oklch(.40 .14 200)" }}>
            <span style={{ width: 8, height: 8, borderRadius: "50%", background: "oklch(.62 .14 195)", boxShadow: "0 0 0 4px oklch(.62 .14 195 / .25)" }}/>
            กำลังรอบัตร...
          </div>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 4 }}>นำบัตรมาวางใกล้เครื่องอ่าน 2-3 ซม. ค้างไว้จนกว่าจะดังบี๊บ</div>
        </div>

        <div style={{ flex: 1 }}/>

        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>หรือชำระแบบอื่น</div>
        {[
          { i: "qr", l: "พร้อมเพย์ QR" },
          { i: "cash", l: "เงินสด" },
          { i: "card", l: "รูดบัตรในเครื่อง" },
        ].map((m, i) => (
          <button key={i} style={{
            display: "flex", alignItems: "center", gap: 10, width: "100%",
            padding: "12px 14px", marginBottom: 8, borderRadius: 12,
            border: "1px solid var(--tp-line)", background: "white",
            cursor: "pointer", fontFamily: "inherit", fontSize: 13, fontWeight: 500,
            textAlign: "left",
          }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: "oklch(.95 .03 220)", display: "flex", alignItems: "center", justifyContent: "center", color: "oklch(.45 .12 250)" }}>
              <TPIcon name={m.i} size={16}/>
            </div>
            <span style={{ flex: 1 }}>{m.l}</span>
            <TPIcon name="arrow-right" size={14} color="var(--tp-ink-mute)"/>
          </button>
        ))}

        <button className="tp-btn tp-btn-ghost" style={{ marginTop: 4, height: 44 }}><TPIcon name="x" size={14}/> ยกเลิกธุรกรรม</button>
      </div>
    </div>
  );
};

// === 16 · Delivery ===
const DeliveryScreen = () => {
  const orders = [
    { id: "DLV-1042", cust: "คุณสมชาย ม.", addr: "สุขุมวิท 39 ซอย 5", items: 4, amount: 420, status: "preparing", rider: "—", eta: "—", km: 2.4, c: "80" },
    { id: "DLV-1041", cust: "คุณนภา ส.", addr: "พญาไท ตึก One City", items: 2, amount: 180, status: "ready", rider: "—", eta: "พร้อมส่ง", km: 0.9, c: "188" },
    { id: "DLV-1040", cust: "คุณกานต์ ว.", addr: "ทองหล่อ ซ.10", items: 6, amount: 695, status: "delivering", rider: "พี่โต้ง", eta: "8 นาที", km: 3.1, c: "270" },
    { id: "DLV-1039", cust: "บจก. ไอแซค", addr: "อโศก ดิเอ็มดิสทริค", items: 12, amount: 1840, status: "delivering", rider: "พี่นัท", eta: "12 นาที", km: 4.2, c: "270" },
    { id: "DLV-1038", cust: "คุณมินตรา ก.", addr: "เอกมัย ซ.5 บ้าน 14/2", items: 3, amount: 285, status: "delivered", rider: "พี่โต้ง", eta: "ส่งแล้ว 14:02", km: 1.8, c: "145" },
  ];
  const statusLabel = { preparing: "กำลังเตรียม", ready: "พร้อมส่ง", delivering: "กำลังส่ง", delivered: "ส่งแล้ว" };

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>เดลิเวอรี่ · ติดตามออเดอร์</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>5 ออเดอร์กำลังดำเนินการ · ไรเดอร์ 3 คน</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", background: "rgba(255,255,255,.5)", borderRadius: 12, padding: 4, gap: 2, border: "1px solid rgba(255,255,255,.6)" }}>
          {["ทั้งหมด", "เตรียม", "พร้อมส่ง", "กำลังส่ง", "ส่งแล้ว"].map((t, i) => (
            <button key={i} style={{
              padding: "8px 16px", borderRadius: 9, border: "none", cursor: "pointer",
              fontFamily: "inherit", fontSize: 13, fontWeight: 500,
              background: i === 0 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent",
              color: i === 0 ? "white" : "var(--tp-ink-soft)",
            }}>{t}</button>
          ))}
        </div>
        <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> ออเดอร์ใหม่</button>
      </header>

      {/* Map area */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 880, bottom: 24, padding: 0, overflow: "hidden", position: "absolute" }}>
        <div style={{
          position: "absolute", inset: 0,
          background: "linear-gradient(180deg, oklch(.92 .04 200), oklch(.96 .02 220))"
        }}/>
        {/* fake map streets */}
        <svg viewBox="0 0 880 760" style={{ position: "absolute", inset: 0, width: "100%", height: "100%" }}>
          <defs>
            <pattern id="map-grid" width="60" height="60" patternUnits="userSpaceOnUse">
              <path d="M 60 0 L 0 0 0 60" fill="none" stroke="oklch(.85 .03 200)" strokeWidth="1"/>
            </pattern>
          </defs>
          <rect width="880" height="760" fill="url(#map-grid)"/>
          {/* roads */}
          <path d="M 0 380 L 880 380" stroke="white" strokeWidth="22" strokeLinecap="round"/>
          <path d="M 0 380 L 880 380" stroke="oklch(.85 .03 200)" strokeWidth="1"/>
          <path d="M 200 0 L 200 760" stroke="white" strokeWidth="16" strokeLinecap="round"/>
          <path d="M 580 0 L 580 760" stroke="white" strokeWidth="18" strokeLinecap="round"/>
          <path d="M 0 180 Q 300 220 460 100 T 880 240" stroke="white" strokeWidth="14" fill="none" strokeLinecap="round"/>
          <path d="M 100 760 Q 250 600 460 580 T 880 540" stroke="white" strokeWidth="12" fill="none" strokeLinecap="round"/>
          {/* parks */}
          <circle cx="700" cy="180" r="80" fill="oklch(.92 .07 145)" opacity=".7"/>
          <rect x="60" y="500" width="140" height="100" rx="14" fill="oklch(.92 .07 145)" opacity=".7"/>
          {/* river */}
          <path d="M 0 660 Q 200 620 460 700 T 880 680" stroke="oklch(.85 .07 220)" strokeWidth="34" fill="none" strokeLinecap="round" opacity=".6"/>

          {/* route line */}
          <path d="M 440 380 Q 540 320 580 240 T 720 160" stroke="oklch(.50 .14 250)" strokeWidth="4" fill="none" strokeDasharray="8 6" strokeLinecap="round"/>
          <path d="M 440 380 Q 360 440 280 480 T 160 540" stroke="oklch(.62 .14 195)" strokeWidth="4" fill="none" strokeDasharray="8 6" strokeLinecap="round"/>

          {/* shop pin (origin) */}
          <g transform="translate(440 380)">
            <circle r="22" fill="oklch(.62 .14 195 / .3)"/>
            <circle r="14" fill="oklch(.50 .14 250)" stroke="white" strokeWidth="3"/>
            <text y="5" fontSize="14" fill="white" textAnchor="middle" fontWeight="700">T</text>
          </g>

          {/* customer pins */}
          {[
            { x: 720, y: 160, c: "270", l: "1041" },
            { x: 160, y: 540, c: "270", l: "1040" },
            { x: 280, y: 240, c: "80", l: "1042" },
            { x: 600, y: 540, c: "188", l: "1039" },
            { x: 760, y: 480, c: "145", l: "1038" },
          ].map((p, i) => (
            <g key={i} transform={`translate(${p.x} ${p.y})`}>
              <circle r="20" fill={`oklch(.78 .14 ${p.c} / .35)`}/>
              <path d="M 0 -16 C 9 -16 14 -8 14 -2 C 14 6 0 18 0 18 C 0 18 -14 6 -14 -2 C -14 -8 -9 -16 0 -16 Z" fill={`oklch(.55 .14 ${p.c})`} stroke="white" strokeWidth="2.5"/>
              <circle cy="-3" r="5" fill="white"/>
            </g>
          ))}

          {/* rider markers */}
          {[
            { x: 540, y: 280, n: "พี่โต้ง" },
            { x: 360, y: 460, n: "พี่นัท" },
          ].map((r, i) => (
            <g key={i} transform={`translate(${r.x} ${r.y})`}>
              <circle r="22" fill="oklch(.85 .14 80 / .4)"/>
              <circle r="15" fill="oklch(.65 .15 50)" stroke="white" strokeWidth="3"/>
              <path d="M -5 -3 a 5 5 0 1 1 10 0 v 1 h -10 z M -7 6 h 14 v 5 h -14 z" fill="white" transform="translate(0 -1)"/>
            </g>
          ))}
        </svg>

        {/* map controls */}
        <div style={{ position: "absolute", right: 16, top: 16, display: "flex", flexDirection: "column", gap: 6 }}>
          {[{ i: "plus" }, { i: "minus" }, { i: "pin" }].map((b, i) => (
            <button key={i} style={{
              width: 40, height: 40, borderRadius: 10,
              background: "white", border: "1px solid var(--tp-line)",
              boxShadow: "0 6px 14px -6px rgba(20,40,80,.18)",
              cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
              color: "var(--tp-ink)"
            }}><TPIcon name={b.i} size={16}/></button>
          ))}
        </div>

        {/* legend pill */}
        <div className="tp-glass" style={{ position: "absolute", left: 16, top: 16, padding: "10px 14px", display: "flex", gap: 14, fontSize: 12, alignItems: "center" }}>
          <span style={{ display: "flex", alignItems: "center", gap: 6 }}><span style={{ width: 10, height: 10, borderRadius: "50%", background: "oklch(.50 .14 250)" }}/> ร้าน</span>
          <span style={{ display: "flex", alignItems: "center", gap: 6 }}><span style={{ width: 10, height: 10, borderRadius: "50%", background: "oklch(.65 .15 50)" }}/> ไรเดอร์</span>
          <span style={{ display: "flex", alignItems: "center", gap: 6 }}><span style={{ width: 10, height: 10, borderRadius: "50%", background: "oklch(.55 .14 270)" }}/> ลูกค้า</span>
        </div>

        {/* selected order popover */}
        <div className="tp-glass" style={{ position: "absolute", left: 16, bottom: 16, width: 360, padding: 16 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: "linear-gradient(160deg, oklch(.85 .12 270), oklch(.55 .14 280))", display: "flex", alignItems: "center", justifyContent: "center", color: "white" }}>
              <TPIcon name="phone" size={18}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>DLV-1040 — กำลังส่ง</div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>คุณกานต์ ว. · ทองหล่อ ซ.10</div>
            </div>
            <span className="tp-tnum" style={{ fontSize: 16, fontWeight: 600 }}>฿695</span>
          </div>
          <div style={{ marginTop: 12, padding: 10, borderRadius: 10, background: "rgba(255,255,255,.65)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12 }}>
              <span style={{ color: "var(--tp-ink-mute)" }}>ไรเดอร์</span><span style={{ fontWeight: 600 }}>พี่โต้ง · BMA-1234</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginTop: 4 }}>
              <span style={{ color: "var(--tp-ink-mute)" }}>เหลือเวลาประมาณ</span><span className="tp-mono" style={{ fontWeight: 600 }}>8 นาที · 3.1 กม.</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right: order list */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 488, bottom: 24, padding: 18, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>คิวออเดอร์</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>วันนี้</div>
          </div>
          <div style={{ flex: 1 }}/>
          <button className="tp-btn tp-btn-ghost" style={{ height: 34, fontSize: 12 }}><TPIcon name="filter" size={14}/> ตัวกรอง</button>
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto", paddingRight: 4 }}>
          {orders.map((o, i) => (
            <div key={i} style={{
              padding: 14, marginBottom: 10, borderRadius: 14,
              background: "white", border: "1px solid var(--tp-line)",
              boxShadow: "0 4px 10px -6px rgba(20,40,80,.08)",
              borderLeft: `4px solid oklch(.65 .14 ${o.c})`,
            }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span className="tp-mono" style={{ fontSize: 13, fontWeight: 600 }}>{o.id}</span>
                <span style={{
                  fontSize: 10, fontWeight: 600, padding: "3px 9px", borderRadius: 999,
                  background: `oklch(.94 .08 ${o.c})`, color: `oklch(.45 .14 ${o.c})`,
                }}>{statusLabel[o.status]}</span>
                <div style={{ flex: 1 }}/>
                <span className="tp-tnum" style={{ fontSize: 14, fontWeight: 600 }}>฿{o.amount}</span>
              </div>
              <div style={{ marginTop: 8, fontSize: 13, fontWeight: 500 }}>{o.cust}</div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", display: "flex", alignItems: "center", gap: 4, marginTop: 2 }}>
                <TPIcon name="pin" size={12}/> {o.addr} · {o.km} กม.
              </div>
              <div style={{ display: "flex", alignItems: "center", marginTop: 10, paddingTop: 8, borderTop: "1px dashed var(--tp-line)", fontSize: 11, color: "var(--tp-ink-mute)" }}>
                <TPIcon name="cart" size={12} style={{ marginRight: 4 }}/> {o.items} รายการ
                <span style={{ margin: "0 8px" }}>·</span>
                <TPIcon name="user" size={12} style={{ marginRight: 4 }}/> {o.rider}
                <div style={{ flex: 1 }}/>
                <span className="tp-mono">{o.eta}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

window.AccountingScreen = AccountingScreen;
window.CreateBillScreen = CreateBillScreen;
window.TaxInvoiceScreen = TaxInvoiceScreen;
window.NFCScanScreen = NFCScanScreen;
window.DeliveryScreen = DeliveryScreen;

// Thaiprompt POS — Membership tiers, Discount center, Affiliate program

const _hm = (label, sub, right) => (
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

// === 33 · Membership Tiers ===
const MembershipTiersScreen = () => {
  const tiers = [
    {
      n: "Bronze", th: "บรอนซ์", c: "25",
      from: 0, to: 4999, members: 404, rate: "1 บาท = 1 แต้ม",
      bg: "linear-gradient(140deg, oklch(.78 .14 28), oklch(.55 .14 30) 70%, oklch(.38 .10 30))",
      perks: ["รับแต้มสะสมทุกการซื้อ", "ของขวัญวันเกิด 1 แก้ว", "อัปเดตโปรพิเศษทาง SMS"]
    },
    {
      n: "Silver", th: "ซิลเวอร์", c: "230",
      from: 5000, to: 19999, members: 548, rate: "1 บาท = 1.2 แต้ม",
      bg: "linear-gradient(140deg, oklch(.85 .03 230), oklch(.62 .04 240) 70%, oklch(.42 .03 250))",
      perks: ["ทุกสิทธิ์ Bronze", "ส่วนลด 5% ทุกบิล", "ฟรีอัปไซส์ 4 ครั้ง/เดือน"]
    },
    {
      n: "Gold", th: "โกลด์", c: "80",
      from: 20000, to: 49999, members: 248, rate: "1 บาท = 1.5 แต้ม", popular: true,
      bg: "linear-gradient(140deg, oklch(.88 .14 90), oklch(.68 .14 75) 70%, oklch(.50 .12 60))",
      perks: ["ทุกสิทธิ์ Silver", "ส่วนลด 10% ทุกบิล", "ฟรีค่าส่งทุกเดลิเวอรี่", "เข้าร่วม Tasting Event"]
    },
    {
      n: "Platinum / VIP", th: "วีไอพี", c: "270",
      from: 50000, to: 99999, members: 84, rate: "1 บาท = 2 แต้ม",
      bg: "linear-gradient(140deg, oklch(.50 .14 280), oklch(.32 .12 290) 70%, oklch(.18 .08 270))",
      perks: ["ทุกสิทธิ์ Gold", "ส่วนลด 15% ทุกบิล", "เครื่องดื่มเปิดร้านฟรี 1 แก้ว/วัน", "Personal barista"]
    },
    {
      n: "Diamond / Premium", th: "พรีเมียม", c: "188",
      from: 100000, to: null, members: 28, rate: "1 บาท = 3 แต้ม",
      bg: "linear-gradient(140deg, oklch(.85 .14 188), oklch(.55 .13 195) 50%, oklch(.30 .10 220))",
      perks: ["ทุกสิทธิ์ VIP", "ส่วนลด 20% ทุกบิล", "Private Lounge เข้าได้ทุกสาขา", "Concierge ส่วนตัว"]
    },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hm("ระดับสมาชิก · Membership Program", "5 ระดับ · 1,312 สมาชิกรวม · ยอดสะสมรวม ฿8.4M",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> รายงานสมาชิก</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> สร้างระดับใหม่</button>
        </div>
      )}

      {/* tier cards row */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 14 }}>
        {tiers.map((t, i) => (
          <div key={i} style={{
            position: "relative", borderRadius: 22, padding: 0,
            background: t.bg, color: "white",
            boxShadow: `0 18px 36px -14px oklch(.45 .14 ${t.c} / .55), 0 1px 0 rgba(255,255,255,.3) inset`,
            overflow: "hidden", height: 240
          }}>
            <div style={{ position: "absolute", right: -20, top: -20, width: 110, height: 110, borderRadius: "50%", background: "radial-gradient(circle, rgba(255,255,255,.3), transparent 70%)", filter: "blur(8px)" }}/>
            <div style={{ position: "absolute", left: -16, bottom: -30, width: 130, height: 130, borderRadius: "50%", background: "radial-gradient(circle, rgba(255,255,255,.18), transparent 70%)", filter: "blur(10px)" }}/>

            {t.popular && (
              <div style={{ position: "absolute", top: 12, right: 12, padding: "3px 8px", fontSize: 9, fontWeight: 700, borderRadius: 999, background: "white", color: `oklch(.45 .14 ${t.c})`, letterSpacing: ".1em" }}>POPULAR</div>
            )}

            <div style={{ padding: "18px 18px 14px", position: "relative" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: "50%",
                  background: "rgba(255,255,255,.22)",
                  border: "1.5px solid rgba(255,255,255,.45)",
                  backdropFilter: "blur(8px)",
                  display: "flex", alignItems: "center", justifyContent: "center"
                }}><TPIcon name="star" size={18}/></div>
                <div>
                  <div style={{ fontSize: 9, opacity: .75, letterSpacing: ".15em", textTransform: "uppercase" }}>TIER {i + 1}</div>
                  <div style={{ fontSize: 16, fontWeight: 800, letterSpacing: "-.01em" }}>{t.n}</div>
                </div>
              </div>
              <div style={{ fontSize: 11, opacity: .8, marginTop: 8 }}>ใช้จ่ายสะสม</div>
              <div className="tp-tnum" style={{ fontSize: 17, fontWeight: 700, lineHeight: 1.1 }}>
                ฿{t.from.toLocaleString()}{t.to ? ` – ฿${t.to.toLocaleString()}` : "+"}
              </div>
            </div>

            <div style={{ padding: "0 18px 16px", position: "relative" }}>
              <div style={{ height: 1, background: "rgba(255,255,255,.2)", marginBottom: 10 }}/>
              <div style={{ display: "flex", justifyContent: "space-between", fontSize: 11 }}>
                <div>
                  <div style={{ opacity: .75 }}>สมาชิก</div>
                  <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700 }}>{t.members}</div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{ opacity: .75 }}>การได้แต้ม</div>
                  <div className="tp-mono" style={{ fontSize: 12, fontWeight: 600 }}>{t.rate}</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Bottom: edit panel + comparison */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 376, bottom: 24, display: "grid", gridTemplateColumns: "1fr 1.3fr", gap: 16 }}>
        {/* Editor: Gold tier active */}
        <div className="tp-glass" style={{ padding: 22, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: "linear-gradient(160deg, oklch(.88 .14 90), oklch(.65 .14 75))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 6px 14px -4px oklch(.65 .14 75 / .5)" }}>
              <TPIcon name="star" size={18}/>
            </div>
            <div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำลังแก้ไข</div>
              <div style={{ fontSize: 17, fontWeight: 700 }}>Gold · โกลด์</div>
            </div>
            <div style={{ flex: 1 }}/>
            <button className="tp-btn tp-btn-primary" style={{ height: 36 }}>บันทึก</button>
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ขั้นต่ำ (สะสม)</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>฿20,000</div>
            </div>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>สูงสุด</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>฿49,999</div>
            </div>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ตัวคูณแต้ม</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>1.5×</div>
            </div>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ส่วนลด</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, marginTop: 2, color: "oklch(.45 .14 80)" }}>10%</div>
            </div>
          </div>

          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginTop: 18, marginBottom: 8 }}>สิทธิ์พิเศษ</div>
          <div style={{ flex: 1 }}>
            {tiers[2].perks.map((p, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 0", borderBottom: i < tiers[2].perks.length - 1 ? "1px dashed var(--tp-line)" : "none" }}>
                <div style={{ width: 24, height: 24, borderRadius: 7, background: "linear-gradient(160deg, oklch(.88 .14 90), oklch(.65 .14 75))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}><TPIcon name="check" size={12}/></div>
                <span style={{ flex: 1, fontSize: 13 }}>{p}</span>
                <button style={{ width: 26, height: 26, borderRadius: 7, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-mute)" }}><TPIcon name="trash" size={12}/></button>
              </div>
            ))}
            <button className="tp-btn tp-btn-ghost" style={{ width: "100%", marginTop: 10, height: 38, fontSize: 12 }}><TPIcon name="plus" size={14}/> เพิ่มสิทธิ์</button>
          </div>
        </div>

        {/* Comparison matrix */}
        <div className="tp-glass" style={{ padding: 22 }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตารางเปรียบเทียบ</div>
              <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2 }}>สิทธิ์แต่ละระดับ</div>
            </div>
            <div style={{ flex: 1 }}/>
            <span className="tp-chip">5 ระดับ</span>
          </div>

          {/* matrix */}
          <div style={{ display: "grid", gridTemplateColumns: "1.4fr repeat(5, 1fr)", gap: 0, fontSize: 12 }}>
            <div style={{ padding: "10px 12px", color: "var(--tp-ink-mute)", fontWeight: 600, textTransform: "uppercase", fontSize: 10, letterSpacing: ".05em" }}>สิทธิ์</div>
            {tiers.map((t, i) => (
              <div key={i} style={{ padding: "8px 4px", textAlign: "center" }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 10, margin: "0 auto",
                  background: t.bg,
                  display: "flex", alignItems: "center", justifyContent: "center",
                  color: "white", boxShadow: `0 4px 10px -3px oklch(.45 .14 ${t.c} / .5)`
                }}><TPIcon name="star" size={14}/></div>
                <div style={{ fontSize: 10, fontWeight: 600, marginTop: 4 }}>{t.n.split(" / ")[0]}</div>
              </div>
            ))}

            {[
              { l: "ส่วนลดทุกบิล", v: ["—", "5%", "10%", "15%", "20%"] },
              { l: "ของขวัญวันเกิด", v: [1, 1, 1, 2, 3], render: v => v ? `${v} แก้ว` : "—" },
              { l: "ฟรีอัปไซส์", v: ["—", "4 ครั้ง", "ไม่จำกัด", "ไม่จำกัด", "ไม่จำกัด"] },
              { l: "ฟรีค่าส่ง", v: [false, false, true, true, true] },
              { l: "Tasting Event", v: [false, false, true, true, true] },
              { l: "Personal Barista", v: [false, false, false, true, true] },
              { l: "Private Lounge", v: [false, false, false, false, true] },
              { l: "Concierge", v: [false, false, false, false, true] },
            ].map((row, ri) => (
              <React.Fragment key={ri}>
                <div style={{ padding: "10px 12px", fontWeight: 500, borderTop: "1px dashed var(--tp-line)", display: "flex", alignItems: "center" }}>{row.l}</div>
                {row.v.map((v, vi) => (
                  <div key={vi} style={{ padding: "10px 4px", textAlign: "center", borderTop: "1px dashed var(--tp-line)", color: typeof v === "boolean" ? (v ? "oklch(.45 .14 150)" : "var(--tp-ink-mute)") : "var(--tp-ink)", fontWeight: typeof v === "string" || row.render ? 600 : 400 }}>
                    {typeof v === "boolean" ? (v ? <TPIcon name="check" size={14}/> : "—") : row.render ? row.render(v) : v}
                  </div>
                ))}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

// === 34 · Discount Center ===
const DiscountCenterScreen = () => {
  const rules = [
    { n: "ส่วนลดสมาชิก Gold ขึ้นไป", t: "auto-member", v: "10–20%", c: "80", on: true, used: 248, scope: "ทุกบิล · Gold/VIP/Premium" },
    { n: "Happy Hour 14:00–17:00", t: "time", v: "−15%", c: "188", on: true, used: 184, scope: "เฉพาะของเย็น · จันทร์–ศุกร์" },
    { n: "นักศึกษา (ยืนยันบัตร)", t: "auto-segment", v: "−10%", c: "270", on: true, used: 96, scope: "ทุกเมนู · จันทร์–อาทิตย์" },
    { n: "เกิน ฿500 ลดทันที", t: "threshold", v: "−฿50", c: "145", on: true, used: 142, scope: "บิลรวม ≥ ฿500" },
    { n: "ซื้อ 2 ลด 30", t: "bundle", v: "1+1−30", c: "25", on: true, used: 642, scope: "ชาไทย / ชาเขียว · เครื่องดื่มเย็น" },
    { n: "Birthday Voucher", t: "auto-birthday", v: "−฿100", c: "80", on: true, used: 38, scope: "วันเกิดสมาชิก ±7 วัน" },
    { n: "พนักงานบริษัท XYZ", t: "corporate", v: "−12%", c: "188", on: false, used: 0, scope: "อีเมล @xyz.co.th" },
    { n: "Flash Sale 14 ก.พ.", t: "campaign", v: "−25%", c: "25", on: false, used: 184, scope: "เฉพาะวันที่ระบุ" },
  ];
  const typeLabel = {
    "auto-member": "ตามระดับสมาชิก",
    "time": "ตามช่วงเวลา",
    "auto-segment": "ตามกลุ่ม",
    "threshold": "ขั้นต่ำ",
    "bundle": "ซื้อคู่",
    "auto-birthday": "วันเกิด",
    "corporate": "องค์กร",
    "campaign": "แคมเปญ",
  };

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hm("ศูนย์ส่วนลด · Discount Center", "6 กฎใช้งาน · ส่วนลดรวมเดือนนี้ ฿42,580 · ผลกระทบ −2.8% ต่อยอด",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> รายงานส่วนลด</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> สร้างกฎใหม่</button>
        </div>
      )}

      {/* KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "ส่วนลดวันนี้", v: "฿1,840", c: "25" },
          { l: "บิลที่ได้ส่วนลด", v: "72%", c: "188" },
          { l: "ส่วนลดเฉลี่ย/บิล", v: "฿38", c: "80" },
          { l: "Conversion Lift", v: "+18.4%", c: "145" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-.02em", marginTop: 4, color: `oklch(.40 .14 ${k.c})` }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* Left: rules list */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, right: 380, bottom: 24, padding: 20 }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กฎส่วนลด</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>Discount Rules</div>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "อัตโนมัติ", "ใช้งาน", "ปิด"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "40px 2.2fr 1fr 1fr 100px 80px 70px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span></span><span>ชื่อกฎ</span><span>ประเภท</span><span>ขอบเขต</span><span style={{ textAlign: "right" }}>ส่วนลด</span><span style={{ textAlign: "right" }}>ใช้</span><span style={{ textAlign: "center" }}>เปิด</span>
        </div>

        <div className="tp-scroll" style={{ flex: 1, overflow: "auto", maxHeight: "calc(100% - 80px)" }}>
          {rules.map((r, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "40px 2.2fr 1fr 1fr 100px 80px 70px", gap: 10, padding: "14px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13, background: i === 1 ? "linear-gradient(90deg, oklch(.96 .04 188 / .6), transparent)" : "transparent", borderRadius: 8 }}>
              <div style={{
                width: 32, height: 32, borderRadius: 9,
                background: `linear-gradient(160deg, oklch(.92 .07 ${r.c}), oklch(.78 .12 ${r.c}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: `0 4px 10px -4px oklch(.62 .14 ${r.c} / .5)`
              }}><TPIcon name="tag" size={14}/></div>
              <span style={{ fontWeight: 500 }}>{r.n}</span>
              <span className="tp-chip" style={{ height: 22, fontSize: 10, padding: "0 8px", background: `oklch(.94 .07 ${r.c})`, color: `oklch(.40 .14 ${r.c})` }}>{typeLabel[r.t]}</span>
              <span style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{r.scope}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 700, color: `oklch(.45 .14 ${r.c})` }}>{r.v}</span>
              <span className="tp-tnum" style={{ textAlign: "right", color: "var(--tp-ink-mute)" }}>{r.used}</span>
              <div style={{
                justifySelf: "center",
                width: 34, height: 20, borderRadius: 999,
                background: r.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)",
                position: "relative", cursor: "pointer",
                boxShadow: r.on ? "inset 0 1px 0 rgba(255,255,255,.25), 0 4px 10px -4px oklch(.50 .14 220 / .5)" : "inset 0 1px 2px rgba(20,40,80,.08)"
              }}>
                <div style={{ position: "absolute", top: 2, left: r.on ? 16 : 2, width: 16, height: 16, borderRadius: "50%", background: "white", boxShadow: "0 2px 4px rgba(20,40,80,.2)" }}/>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Right: rule editor preview */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 332, bottom: 24, padding: "22px 22px", display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.55 .13 195))", color: "white", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <TPIcon name="clock" size={16}/>
          </div>
          <div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำลังแก้ไข</div>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Happy Hour 14:00–17:00</div>
          </div>
        </div>

        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>ประเภทส่วนลด</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6 }}>
          {[
            { l: "เปอร์เซ็นต์", on: true },
            { l: "บาท", on: false },
            { l: "ฟรีรายการ", on: false },
          ].map((t, i) => (
            <button key={i} style={{ padding: "10px 8px", borderRadius: 10, border: t.on ? "1.5px solid oklch(.62 .14 195)" : "1px solid var(--tp-line)", background: t.on ? "oklch(.96 .04 195)" : "white", color: t.on ? "oklch(.40 .14 200)" : "var(--tp-ink-soft)", fontSize: 12, fontWeight: 500, cursor: "pointer", fontFamily: "inherit" }}>{t.l}</button>
          ))}
        </div>

        <div style={{ marginTop: 14, padding: "16px 18px", borderRadius: 14, background: "linear-gradient(140deg, oklch(.78 .14 188), oklch(.45 .14 250))", color: "white", boxShadow: "0 10px 22px -10px oklch(.45 .14 250 / .55)" }}>
          <div style={{ fontSize: 11, opacity: .85, textTransform: "uppercase", letterSpacing: ".1em" }}>ลด</div>
          <div className="tp-tnum" style={{ fontSize: 42, fontWeight: 800, letterSpacing: "-.02em", lineHeight: 1 }}>15<span style={{ fontSize: 22, fontWeight: 600, opacity: .85 }}>%</span></div>
          <div style={{ fontSize: 11, opacity: .8, marginTop: 4 }}>ของยอดรวมก่อนภาษี</div>
        </div>

        <div style={{ marginTop: 14, fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>เงื่อนไข</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {[
            { i: "clock", l: "ทุกวัน 14:00 – 17:00" },
            { i: "table", l: "เฉพาะของเย็น (5 หมวด)" },
            { i: "users", l: "ทุกลูกค้า" },
            { i: "pin", l: "ทุกสาขา (6 สาขา)" },
          ].map((c, i) => (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, padding: "8px 12px", borderRadius: 10, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ width: 24, height: 24, borderRadius: 7, background: "oklch(.94 .04 220)", color: "oklch(.45 .14 220)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <TPIcon name={c.i} size={12}/>
              </div>
              <span style={{ flex: 1, fontSize: 12 }}>{c.l}</span>
              <TPIcon name="more" size={12} color="var(--tp-ink-mute)"/>
            </div>
          ))}
        </div>

        <div style={{ flex: 1 }}/>

        <div style={{ marginTop: 12, padding: 12, borderRadius: 12, background: "oklch(.96 .04 145)", border: "1px solid oklch(.85 .08 150)", fontSize: 11, color: "oklch(.35 .12 150)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, fontWeight: 700, marginBottom: 4 }}>
            <TPIcon name="check" size={13}/> ผลกระทบประมาณการ
          </div>
          ประมาณ <strong>+24 บิล/วัน</strong> · <strong>−฿320/วัน</strong> ในส่วนลด
        </div>
      </div>
    </div>
  );
};

// === 35 · Affiliate Program ===
const AffiliateScreen = () => {
  const partners = [
    { n: "คุณกานต์ วิริยะกุล", code: "GAN20", since: "ม.ค. 2568", refs: 84, sales: 42580, comm: 2129, status: "active", c: "270" },
    { n: "พี่หมูทอม รีวิว", code: "PMUTOM", since: "ก.พ. 2568", refs: 62, sales: 31420, comm: 1571, status: "active", c: "188" },
    { n: "Cafe Hop Bangkok IG", code: "CAFEHOP", since: "ก.พ. 2568", refs: 48, sales: 28640, comm: 1432, status: "active", c: "80" },
    { n: "บริษัท สยามพีอาร์", code: "SIAMPR", since: "มี.ค. 2568", refs: 142, sales: 84200, comm: 4210, status: "premium", c: "270" },
    { n: "คุณนภา ส.", code: "NAPA10", since: "เม.ย. 2568", refs: 18, sales: 8420, comm: 421, status: "active", c: "145" },
    { n: "Nina Coffee Vlog", code: "NINACFE", since: "เม.ย. 2568", refs: 28, sales: 14580, comm: 729, status: "pending", c: "25" },
  ];
  const statusLabel = { active: "Active", premium: "Premium", pending: "รออนุมัติ" };

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hm("Affiliate · ระบบแนะนำเพื่อน", "6 พาร์ทเนอร์ · 382 referrals เดือนนี้ · จ่ายค่าคอมแล้ว ฿10,492",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="cash" size={16}/> จ่ายค่าคอม</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> รายงาน</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> เชิญพาร์ทเนอร์</button>
        </div>
      )}

      {/* program hero card */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, height: 168, display: "grid", gridTemplateColumns: "1.2fr 1fr 1fr", gap: 16 }}>
        <div style={{
          padding: "22px 24px", borderRadius: 22, position: "relative", overflow: "hidden",
          background: "linear-gradient(140deg, oklch(.50 .14 280) 0%, oklch(.32 .12 290) 60%, oklch(.18 .08 270))",
          color: "white",
          boxShadow: "0 18px 36px -14px oklch(.30 .12 270 / .55)"
        }}>
          <div style={{ position: "absolute", right: -30, top: -30, width: 160, height: 160, borderRadius: "50%", background: "radial-gradient(circle, oklch(.85 .14 80 / .45), transparent 70%)", filter: "blur(10px)" }}/>
          <div style={{ position: "absolute", left: 20, bottom: -40, width: 120, height: 120, borderRadius: "50%", background: "radial-gradient(circle, oklch(.78 .14 188 / .5), transparent 70%)", filter: "blur(8px)" }}/>

          <span style={{ display: "inline-block", padding: "3px 10px", fontSize: 9, fontWeight: 700, borderRadius: 999, background: "rgba(255,255,255,.18)", border: "1px solid rgba(255,255,255,.3)", letterSpacing: ".15em" }}>AFFILIATE PROGRAM</span>
          <div style={{ fontSize: 26, fontWeight: 800, marginTop: 10, letterSpacing: "-.02em", lineHeight: 1.1 }}>
            ค่าคอม <span style={{
              background: "linear-gradient(180deg, oklch(.95 .14 80), oklch(.78 .14 60))",
              WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent"
            }}>5%</span> · ตลอดชีพลูกค้า
          </div>
          <div style={{ fontSize: 13, opacity: .85, marginTop: 6 }}>แนะนำเพื่อน — ทุกบิลของเค้า คุณได้ส่วนแบ่งทันที ตลอดอายุสมาชิก</div>
        </div>

        {[
          { l: "Referrals เดือนนี้", v: "382", d: "+18.4%", c: "188", icon: "users" },
          { l: "ค่าคอมที่ต้องจ่าย", v: "฿18,420", d: "รออนุมัติ ฿4,820", c: "80", icon: "cash" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "20px 24px", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", right: -20, top: -20, width: 110, height: 110, borderRadius: "50%", background: `radial-gradient(circle, oklch(.85 .12 ${k.c} / .35), transparent 70%)`, filter: "blur(10px)" }}/>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: `linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 6px 14px -4px oklch(.62 .14 ${k.c} / .5)` }}>
                <TPIcon name={k.icon} size={16}/>
              </div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            </div>
            <div className="tp-tnum" style={{ fontSize: 32, fontWeight: 800, letterSpacing: "-.02em", marginTop: 8 }}>{k.v}</div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 4 }}>{k.d}</div>
          </div>
        ))}
      </div>

      {/* Bottom: partner table + commission tiers */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 304, bottom: 24, display: "grid", gridTemplateColumns: "1.5fr 1fr", gap: 16 }}>
        <div className="tp-glass" style={{ padding: 20, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
            <div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>พาร์ทเนอร์</div>
              <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2 }}>Top Affiliates</div>
            </div>
            <div style={{ flex: 1 }}/>
            {["ทั้งหมด", "Active", "Premium", "รออนุมัติ"].map((t, i) => (
              <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
            ))}
          </div>

          <div style={{ display: "grid", gridTemplateColumns: "44px 1.8fr 90px 80px 1fr 110px 90px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
            <span></span><span>ชื่อ / รหัส</span><span>เข้าร่วม</span><span style={{ textAlign: "right" }}>Refs</span><span style={{ textAlign: "right" }}>ยอดที่นำมา</span><span style={{ textAlign: "right" }}>ค่าคอม</span><span style={{ textAlign: "center" }}>สถานะ</span>
          </div>
          <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
            {partners.map((p, i) => (
              <div key={i} style={{ display: "grid", gridTemplateColumns: "44px 1.8fr 90px 80px 1fr 110px 90px", gap: 10, padding: "12px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: "50%",
                  background: `linear-gradient(160deg, oklch(.85 .14 ${p.c}), oklch(.55 .14 ${p.c}))`,
                  color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                  fontWeight: 700, fontSize: 13,
                  boxShadow: `0 4px 10px -4px oklch(.55 .14 ${p.c} / .5)`
                }}>{p.n.replace(/^(คุณ|พี่|บริษัท\s*)/, "").slice(0, 1)}</div>
                <div>
                  <div style={{ fontWeight: 500 }}>{p.n}</div>
                  <div className="tp-mono" style={{ fontSize: 11, color: `oklch(.45 .14 ${p.c})`, fontWeight: 600, letterSpacing: ".05em" }}>{p.code}</div>
                </div>
                <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{p.since}</span>
                <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>{p.refs}</span>
                <span className="tp-tnum" style={{ textAlign: "right" }}>฿{p.sales.toLocaleString()}</span>
                <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 700, color: "oklch(.45 .14 80)" }}>฿{p.comm.toLocaleString()}</span>
                <span style={{ textAlign: "center", fontSize: 10, fontWeight: 700, padding: "3px 10px", borderRadius: 999, background: p.status === "premium" ? "linear-gradient(180deg, oklch(.50 .14 280), oklch(.32 .12 290))" : p.status === "pending" ? "oklch(.94 .07 25)" : "oklch(.94 .07 145)", color: p.status === "premium" ? "white" : p.status === "pending" ? "oklch(.45 .15 25)" : "oklch(.40 .14 150)", justifySelf: "center" }}>{statusLabel[p.status]}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Commission tiers */}
        <div className="tp-glass" style={{ padding: 22, display: "flex", flexDirection: "column" }}>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ระดับค่าคอม</div>
          <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2, marginBottom: 14 }}>Commission Tiers</div>

          {[
            { n: "Bronze · เริ่มต้น", rate: "3%", req: "1–10 referrals/เดือน", c: "25" },
            { n: "Silver", rate: "5%", req: "11–30 referrals/เดือน", c: "230" },
            { n: "Gold", rate: "7%", req: "31–80 referrals/เดือน", c: "80" },
            { n: "Premium · พาร์ทเนอร์", rate: "10%", req: "80+ referrals · ดีล private", c: "270", current: true },
          ].map((t, i) => (
            <div key={i} style={{
              padding: "14px 16px", borderRadius: 14, marginBottom: 10,
              background: t.current ? `linear-gradient(140deg, oklch(.50 .14 280), oklch(.32 .12 290))` : "white",
              border: t.current ? "none" : "1px solid var(--tp-line)",
              color: t.current ? "white" : "var(--tp-ink)",
              boxShadow: t.current ? "0 12px 24px -10px oklch(.30 .12 270 / .55)" : "0 4px 10px -6px rgba(20,40,80,.08)",
              display: "flex", alignItems: "center", gap: 12
            }}>
              <div style={{
                width: 38, height: 38, borderRadius: 11,
                background: t.current ? "rgba(255,255,255,.2)" : `linear-gradient(160deg, oklch(.85 .14 ${t.c}), oklch(.55 .14 ${t.c}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                border: t.current ? "1px solid rgba(255,255,255,.3)" : "none",
                boxShadow: t.current ? "none" : `0 4px 10px -3px oklch(.55 .14 ${t.c} / .5)`
              }}><TPIcon name="star" size={16}/></div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{t.n}</div>
                <div style={{ fontSize: 10, opacity: t.current ? .85 : 1, color: t.current ? "white" : "var(--tp-ink-mute)", marginTop: 2 }}>{t.req}</div>
              </div>
              <span className="tp-tnum" style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-.02em" }}>{t.rate}</span>
            </div>
          ))}

          {/* referral link box */}
          <div style={{ marginTop: 8, padding: 14, borderRadius: 12, background: "linear-gradient(140deg, oklch(.96 .04 188), oklch(.92 .06 220))", border: "1px solid oklch(.78 .06 200)" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 6 }}>ลิงก์เชิญพาร์ทเนอร์</div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "8px 12px", borderRadius: 10, background: "white", border: "1px solid var(--tp-line)" }}>
              <TPIcon name="split" size={13} color="oklch(.45 .14 220)"/>
              <span className="tp-mono" style={{ flex: 1, fontSize: 11, color: "var(--tp-ink)", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>thaiprompt.co/affiliate/join?ref=BR-01</span>
              <button style={{ width: 24, height: 24, borderRadius: 6, border: "none", background: "linear-gradient(160deg, oklch(.62 .14 195), oklch(.45 .14 220))", color: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <TPIcon name="receipt" size={11}/>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

window.MembershipTiersScreen = MembershipTiersScreen;
window.DiscountCenterScreen = DiscountCenterScreen;
window.AffiliateScreen = AffiliateScreen;

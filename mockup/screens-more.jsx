// Thaiprompt POS — More: CRM, Shift/Cash, Refund, PO, Menu Editor, Multi-branch HQ

const _hh = (label, sub, right) => (
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

// === 24 · CRM / สมาชิก ===
const CRMScreen = () => {
  const members = [
    { name: "คุณกานต์ วิริยะกุล", phone: "081-234-5678", tier: "Platinum", pts: 12480, spent: "฿84,200", visits: 142, last: "วันนี้", c: "270" },
    { name: "บจก. สยามคอฟฟี่", phone: "02-218-5400", tier: "Gold", pts: 8240, spent: "฿62,180", visits: 84, last: "เมื่อวาน", c: "80" },
    { name: "คุณนภา สุวรรณรัตน์", phone: "089-876-5432", tier: "Gold", pts: 6128, spent: "฿42,500", visits: 96, last: "2 วัน", c: "80" },
    { name: "คุณสมชาย มงคล", phone: "086-555-1234", tier: "Silver", pts: 2480, spent: "฿18,420", visits: 38, last: "3 วัน", c: "230" },
    { name: "คุณนิภา ส.", phone: "092-111-2233", tier: "Silver", pts: 1820, spent: "฿14,250", visits: 24, last: "5 วัน", c: "230" },
    { name: "คุณภัทรพล ก.", phone: "061-444-7788", tier: "Bronze", pts: 482, spent: "฿4,820", visits: 12, last: "1 สัปดาห์", c: "25" },
    { name: "คุณมินตรา ก.", phone: "098-222-5566", tier: "Bronze", pts: 280, spent: "฿2,850", visits: 8, last: "2 สัปดาห์", c: "25" },
  ];
  const tierBg = { Platinum: "270", Gold: "80", Silver: "230", Bronze: "25" };

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hh("CRM · สมาชิกและลูกค้า", "1,284 สมาชิก · 482 active เดือนนี้ · Avg ฿1,640/บิล",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="arrow-up" size={16}/> นำเข้า CSV</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="bell" size={16}/> ส่ง SMS แคมเปญ</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> สมัครสมาชิก</button>
        </div>
      )}

      {/* tier KPI */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "Platinum", v: "84", spent: "฿1.2M", c: "270" },
          { l: "Gold", v: "248", spent: "฿2.4M", c: "80" },
          { l: "Silver", v: "548", spent: "฿1.8M", c: "230" },
          { l: "Bronze", v: "404", spent: "฿620K", c: "25" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", right: -10, top: -10, width: 90, height: 90, borderRadius: "50%",
              background: `radial-gradient(circle, oklch(.85 .14 ${k.c} / .45), transparent 70%)`, filter: "blur(8px)" }}/>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ width: 28, height: 28, borderRadius: 8,
                background: `linear-gradient(160deg, oklch(.85 .14 ${k.c}), oklch(.55 .14 ${k.c}))`,
                display: "flex", alignItems: "center", justifyContent: "center", color: "white",
                boxShadow: `0 4px 10px -3px oklch(.55 .14 ${k.c} / .5)`
              }}><TPIcon name="star" size={14}/></div>
              <span style={{ fontSize: 13, fontWeight: 600, color: `oklch(.40 .14 ${k.c})` }}>{k.l}</span>
            </div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-.02em", marginTop: 8 }}>{k.v} <span style={{ fontSize: 13, fontWeight: 500, color: "var(--tp-ink-mute)" }}>คน</span></div>
            <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>ยอดรวม {k.spent}</div>
          </div>
        ))}
      </div>

      {/* member table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, right: 380, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12, gap: 10 }}>
          <div style={{ flex: "0 0 280px", height: 38, background: "white", borderRadius: 12, border: "1px solid var(--tp-line)", display: "flex", alignItems: "center", padding: "0 14px", gap: 8 }}>
            <TPIcon name="search" size={14} color="var(--tp-ink-mute)"/>
            <input placeholder="ค้นหา ชื่อ / เบอร์ / รหัส..." style={{ flex: 1, border: "none", background: "transparent", outline: "none", fontFamily: "inherit", fontSize: 13 }}/>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "Platinum", "Gold", "Silver", "Bronze"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "44px 1.8fr 1fr 1fr 1fr 90px 80px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span></span><span>ชื่อ / เบอร์</span><span>ระดับ</span><span style={{ textAlign: "right" }}>แต้ม</span><span style={{ textAlign: "right" }}>ยอดรวม</span><span style={{ textAlign: "right" }}>เข้า</span><span>ครั้งล่าสุด</span>
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {members.map((m, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "44px 1.8fr 1fr 1fr 1fr 90px 80px", gap: 10, padding: "12px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13, background: i === 0 ? "linear-gradient(90deg, oklch(.96 .04 270 / .6), transparent)" : "transparent", borderRadius: 8 }}>
              <div style={{
                width: 36, height: 36, borderRadius: "50%",
                background: `linear-gradient(160deg, oklch(.85 .14 ${tierBg[m.tier]}), oklch(.55 .14 ${tierBg[m.tier]}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 13, fontWeight: 700,
                boxShadow: `0 4px 10px -4px oklch(.55 .14 ${tierBg[m.tier]} / .5)`
              }}>{m.name.replace(/^(คุณ|บจก\.?\s*)/, "").slice(0, 1)}</div>
              <div>
                <div style={{ fontWeight: 500 }}>{m.name}</div>
                <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{m.phone}</div>
              </div>
              <span style={{ display: "inline-flex", alignItems: "center", gap: 5, padding: "3px 10px", borderRadius: 999, fontSize: 11, fontWeight: 600,
                background: `linear-gradient(160deg, oklch(.94 .07 ${tierBg[m.tier]}), oklch(.88 .10 ${tierBg[m.tier]}))`,
                color: `oklch(.35 .14 ${tierBg[m.tier]})`,
                border: `1px solid oklch(.85 .10 ${tierBg[m.tier]})`,
                width: "fit-content"
              }}><TPIcon name="star" size={11}/> {m.tier}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600, color: `oklch(.45 .14 ${tierBg[m.tier]})` }}>{m.pts.toLocaleString()}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>{m.spent}</span>
              <span className="tp-tnum" style={{ textAlign: "right", color: "var(--tp-ink-mute)" }}>{m.visits}</span>
              <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{m.last}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right: customer profile preview */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 332, bottom: 24, padding: 0, overflow: "hidden", display: "flex", flexDirection: "column" }}>
        {/* tier card */}
        <div style={{
          padding: "22px 22px 18px",
          background: "linear-gradient(140deg, oklch(.50 .14 280), oklch(.30 .12 290) 70%, oklch(.20 .10 270))",
          color: "white", position: "relative", overflow: "hidden",
        }}>
          <div style={{ position: "absolute", right: -30, top: -30, width: 140, height: 140, borderRadius: "50%",
            background: "radial-gradient(circle, oklch(.85 .14 80 / .5), transparent 70%)", filter: "blur(10px)" }}/>
          <div style={{ position: "absolute", right: 24, top: 20, fontSize: 10, fontWeight: 700, padding: "4px 10px", borderRadius: 999, background: "rgba(255,255,255,.18)", border: "1px solid rgba(255,255,255,.3)", letterSpacing: ".15em" }}>VIP</div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 56, height: 56, borderRadius: "50%", background: "linear-gradient(135deg, oklch(.85 .14 80), oklch(.65 .14 50))", display: "flex", alignItems: "center", justifyContent: "center", color: "white", fontSize: 22, fontWeight: 700, border: "2px solid rgba(255,255,255,.4)", boxShadow: "0 6px 14px -4px rgba(0,0,0,.3)" }}>ก</div>
            <div>
              <div style={{ fontSize: 15, fontWeight: 600 }}>คุณกานต์ วิริยะกุล</div>
              <div className="tp-mono" style={{ fontSize: 11, opacity: .75, marginTop: 2 }}>MEM-00148 · เข้าร่วม ม.ค. 2566</div>
            </div>
          </div>
          <div style={{ marginTop: 16, display: "flex", alignItems: "baseline", gap: 4 }}>
            <span className="tp-tnum" style={{ fontSize: 30, fontWeight: 700, letterSpacing: "-.02em" }}>12,480</span>
            <span style={{ fontSize: 12, opacity: .8 }}>คะแนนสะสม</span>
          </div>
          <div style={{ marginTop: 8, height: 6, borderRadius: 999, background: "rgba(255,255,255,.15)", overflow: "hidden" }}>
            <div style={{ height: "100%", width: "78%", background: "linear-gradient(90deg, oklch(.85 .14 80), oklch(.78 .14 28))", borderRadius: 999 }}/>
          </div>
          <div style={{ fontSize: 10, opacity: .75, marginTop: 5, display: "flex", justifyContent: "space-between" }}>
            <span>Platinum 78%</span><span>ถึง Diamond อีก 2,520 คะแนน</span>
          </div>
        </div>

        <div style={{ padding: "16px 22px", flex: 1, overflow: "auto" }} className="tp-scroll">
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ประวัติซื้อล่าสุด</div>
          {[
            { t: "บิล #A1042", n: "วันนี้ 14:42", v: "฿331" },
            { t: "บิล #A1028", n: "เมื่อวาน 18:12", v: "฿420" },
            { t: "บิล #A1014", n: "07 พ.ค. 11:30", v: "฿185" },
            { t: "บิล #A0998", n: "05 พ.ค. 09:45", v: "฿580" },
          ].map((h, i) => (
            <div key={i} style={{ display: "flex", padding: "10px 0", borderBottom: i < 3 ? "1px dashed var(--tp-line)" : "none", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{h.t}</div>
                <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>{h.n}</div>
              </div>
              <div style={{ flex: 1 }}/>
              <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{h.v}</span>
            </div>
          ))}

          <div style={{ marginTop: 14, padding: 14, borderRadius: 12, background: "oklch(.96 .04 80)", border: "1px solid oklch(.85 .08 80)" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, fontWeight: 600, color: "oklch(.40 .14 80)" }}>
              <TPIcon name="tag" size={13}/> สิทธิ์พิเศษ Platinum
            </div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 6, lineHeight: 1.5 }}>
              • ลด 15% ทุกเมนู<br/>
              • ฟรีค่าส่งทุกบิล<br/>
              • วันเกิดรับฟรี 1 แก้ว<br/>
              • เข้าร่วม Tasting Event 4 ครั้ง/ปี
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

// === 25 · เปิด-ปิดกะ + นับเงินสด ===
const ShiftScreen = () => {
  const cash = [
    { d: "1,000", q: 24, t: 24000 },
    { d: "500", q: 18, t: 9000 },
    { d: "100", q: 42, t: 4200 },
    { d: "50", q: 28, t: 1400 },
    { d: "20", q: 18, t: 360 },
    { d: "10", q: 14, t: 140 },
    { d: "5", q: 12, t: 60 },
    { d: "2", q: 8, t: 16 },
    { d: "1", q: 24, t: 24 },
  ];
  const cashTotal = cash.reduce((s, c) => s + c.t, 0);
  const expectedCash = 38600;
  const diff = cashTotal - expectedCash;

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hh("ปิดกะ · นับเงินสด · Z-Report", "เปิดกะ 07:00 · ปิด 19:42 · คุณนัทธมน · เครื่อง POS-01",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="printer" size={16}/> พิมพ์ Z-Report</button>
          <button className="tp-btn tp-btn-coral" style={{ height: 42 }}><TPIcon name="check" size={16}/> ยืนยันปิดกะ</button>
        </div>
      )}

      {/* Left: shift summary */}
      <div className="tp-glass tp-scroll" style={{ position: "absolute", left: 24, top: 116, width: 600, bottom: 24, padding: "22px 26px", overflow: "auto" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14, paddingBottom: 18, borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <div style={{ width: 56, height: 56, borderRadius: 16, background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 8px 18px -6px oklch(.50 .14 220 / .5)" }}>
            <TPIcon name="clock" size={26}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กะวันนี้ · 8 พ.ค. 2569</div>
            <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: "-.01em" }}>SHIFT-2569-0508-01</div>
            <div className="tp-mono" style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 2 }}>07:00 → 19:42 · 12 ชม. 42 นาที</div>
          </div>
        </div>

        {/* sales breakdown */}
        <div style={{ marginTop: 18, fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>สรุปยอดขาย</div>
        <div style={{ marginTop: 10, display: "grid", gap: 10 }}>
          {[
            { l: "เงินสด", v: 38600, c: "80", icon: "cash" },
            { l: "พร้อมเพย์ QR", v: 86420, c: "188", icon: "qr" },
            { l: "บัตรเครดิต/เดบิต", v: 24580, c: "270", icon: "card" },
            { l: "e-Wallet (True/Rabbit)", v: 8420, c: "145", icon: "phone" },
          ].map((r, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 12,
              padding: "12px 16px", borderRadius: 14,
              background: "white", border: "1px solid var(--tp-line)",
              boxShadow: "0 4px 10px -6px rgba(20,40,80,.08)"
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 10, background: `linear-gradient(160deg, oklch(.85 .12 ${r.c}), oklch(.62 .14 ${r.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 4px 10px -3px oklch(.62 .14 ${r.c} / .5)` }}>
                <TPIcon name={r.icon} size={16}/>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{r.l}</div>
                <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{Math.floor(r.v / 200)} ธุรกรรม</div>
              </div>
              <span className="tp-tnum" style={{ fontSize: 16, fontWeight: 600 }}>฿{r.v.toLocaleString()}</span>
            </div>
          ))}
        </div>

        <div style={{
          marginTop: 16, padding: "16px 20px", borderRadius: 16,
          background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.18 .06 270))",
          color: "white", display: "flex", justifyContent: "space-between", alignItems: "baseline",
          boxShadow: "0 14px 28px -10px oklch(.25 .07 265 / .55)"
        }}>
          <div>
            <div style={{ fontSize: 12, opacity: .8 }}>ยอดขายรวมทั้งกะ</div>
            <div className="tp-mono" style={{ fontSize: 10, opacity: .65, marginTop: 2 }}>458 ธุรกรรม · 12 void · 8 refund</div>
          </div>
          <span className="tp-tnum" style={{ fontSize: 32, fontWeight: 700, letterSpacing: "-.02em" }}>฿158,020</span>
        </div>

        {/* misc */}
        <div style={{ marginTop: 20, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          {[
            { l: "ส่วนลด", v: "−฿4,820", c: "25" },
            { l: "ภาษีรวม", v: "฿10,328", c: "80" },
            { l: "ทิป", v: "฿1,840", c: "145" },
            { l: "Void / Refund", v: "−฿2,640", c: "25" },
          ].map((s, i) => (
            <div key={i} style={{ padding: "10px 14px", borderRadius: 12, background: `oklch(.96 .04 ${s.c})`, border: `1px solid oklch(.85 .06 ${s.c})` }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{s.l}</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 600, color: `oklch(.45 .14 ${s.c})`, marginTop: 2 }}>{s.v}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Center: cash count */}
      <div className="tp-glass" style={{ position: "absolute", left: 648, top: 116, width: 412, bottom: 24, padding: "22px 24px", display: "flex", flexDirection: "column" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>นับเงินสดในลิ้นชัก</div>
        <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2, marginBottom: 14 }}>Cash Drawer Count</div>

        <div style={{ display: "grid", gridTemplateColumns: "60px 1fr 70px 90px", gap: 8, padding: "8px 12px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>ค่า</span><span></span><span style={{ textAlign: "right" }}>จำนวน</span><span style={{ textAlign: "right" }}>รวม</span>
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {cash.map((c, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "60px 1fr 70px 90px", gap: 8, padding: "8px 12px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.05)", fontSize: 13 }}>
              <span className="tp-tnum" style={{ fontWeight: 700, color: "oklch(.45 .14 80)" }}>฿{c.d}</span>
              {/* mini bill icon */}
              <div style={{ height: 18, borderRadius: 3, background: `linear-gradient(135deg, oklch(.92 .07 ${["80","145","25","270","188","230","145","80","25"][i]}), oklch(.85 .10 ${["80","145","25","270","188","230","145","80","25"][i]}))`, border: `1px solid oklch(.75 .08 ${["80","145","25","270","188","230","145","80","25"][i]})` }}/>
              <input className="tp-tnum" type="number" defaultValue={c.q} style={{ width: 60, height: 26, borderRadius: 6, border: "1px solid var(--tp-line)", background: "white", textAlign: "right", padding: "0 8px", fontSize: 13, fontFamily: "var(--tp-font-mono)", justifySelf: "end" }}/>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>฿{c.t.toLocaleString()}</span>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 12, padding: 14, borderRadius: 12, background: "oklch(.96 .04 220)", border: "1px solid oklch(.85 .04 220)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 4, color: "var(--tp-ink-mute)" }}>
            <span>นับได้</span><span className="tp-tnum" style={{ fontWeight: 600 }}>฿{cashTotal.toLocaleString()}</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 4, color: "var(--tp-ink-mute)" }}>
            <span>ควรมี (ตามระบบ)</span><span className="tp-tnum">฿{expectedCash.toLocaleString()}</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", padding: "10px 0 0", marginTop: 6, borderTop: "1px dashed oklch(.78 .04 220)", fontSize: 14, fontWeight: 700 }}>
            <span>ส่วนต่าง</span>
            <span className="tp-tnum" style={{ color: diff === 0 ? "oklch(.40 .14 150)" : diff > 0 ? "oklch(.45 .14 80)" : "oklch(.55 .15 25)" }}>{diff > 0 ? "+" : ""}{diff === 0 ? "ตรงพอดี ✓" : `฿${diff.toLocaleString()}`}</span>
          </div>
        </div>
      </div>

      {/* Right: hourly + actions */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 332, height: 340, padding: "22px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ยอดรายชั่วโมง</div>
        <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2, marginBottom: 14 }}>Sales by Hour</div>
        <svg viewBox="0 0 280 180" style={{ width: "100%", height: 180 }}>
          <defs>
            <linearGradient id="shf-bar" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="oklch(.72 .13 190)"/>
              <stop offset="100%" stopColor="oklch(.45 .14 250)"/>
            </linearGradient>
          </defs>
          {[8, 12, 18, 22, 28, 35, 24, 16, 14, 18, 22, 28, 16].map((v, i) => {
            const x = i * 21 + 8;
            const h = (v / 35) * 140;
            return (
              <g key={i}>
                <rect x={x} y={150 - h} width="14" height={h} rx="3" fill="url(#shf-bar)"/>
              </g>
            );
          })}
          {["07", "10", "13", "16", "19"].map((t, i) => (
            <text key={i} x={8 + i * 21 * 3} y="170" fontSize="9" fill="var(--tp-ink-mute)" fontFamily="var(--tp-font-mono)">{t}h</text>
          ))}
        </svg>
      </div>

      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 476, width: 332, bottom: 24, padding: "22px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เพิ่ม / ถอนระหว่างกะ</div>
        <div style={{ fontSize: 16, fontWeight: 600, marginTop: 2, marginBottom: 10 }}>Pay-ins / Pay-outs</div>

        {[
          { t: "เริ่มกะ — Float", v: "+฿2,000", c: "145", time: "07:00" },
          { t: "เติมเงินทอน", v: "+฿5,000", c: "145", time: "11:24" },
          { t: "ซื้อนม 7-11", v: "−฿820", c: "25", time: "13:08" },
          { t: "จ่ายค่าขนส่ง", v: "−฿340", c: "25", time: "15:42" },
        ].map((l, i) => (
          <div key={i} style={{ display: "flex", padding: "8px 0", borderBottom: i < 3 ? "1px dashed var(--tp-line)" : "none", alignItems: "center", gap: 8 }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: `oklch(.62 .14 ${l.c})` }}/>
            <span style={{ flex: 1, fontSize: 13 }}>{l.t}</span>
            <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{l.time}</span>
            <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600, color: `oklch(.45 .14 ${l.c})`, minWidth: 64, textAlign: "right" }}>{l.v}</span>
          </div>
        ))}

        <button className="tp-btn tp-btn-ghost" style={{ width: "100%", marginTop: 12, height: 38, fontSize: 12 }}><TPIcon name="plus" size={14}/> บันทึกรายการเพิ่ม</button>
      </div>
    </div>
  );
};

// === 26 · Refund / Void ===
const RefundScreen = () => {
  const refunds = [
    { id: "RF-0428", orig: "A1042", reason: "ลูกค้าเปลี่ยนใจ — ยังไม่ทำ", amt: 130, by: "นัท", appr: "นัท", time: "วันนี้ 14:48", status: "approved", c: "145" },
    { id: "RF-0427", orig: "A1038", reason: "สินค้าหก — ทำใหม่ให้", amt: 65, by: "พิช", appr: "นัท", time: "วันนี้ 14:12", status: "approved", c: "145" },
    { id: "RF-0426", orig: "A1029", reason: "ครัวซองต์ไหม้", amt: 55, by: "เก่ง", appr: "—", time: "วันนี้ 13:08", status: "pending", c: "80" },
    { id: "RF-0425", orig: "A1018", reason: "ลูกค้าแพ้นม — เปลี่ยนเป็นโซดา", amt: 95, by: "นัท", appr: "นัท", time: "วันนี้ 11:42", status: "approved", c: "145" },
    { id: "RF-0424", orig: "A0987", reason: "เงินทอนเกิน — รับคืน", amt: 100, by: "เก่ง", appr: "นัท", time: "เมื่อวาน 18:24", status: "approved", c: "145" },
    { id: "RF-0423", orig: "A0982", reason: "บัตรเครดิต Dispute", amt: 1840, by: "Auto", appr: "—", time: "เมื่อวาน 16:30", status: "rejected", c: "25" },
  ];
  const statusLabel = { approved: "อนุมัติ", pending: "รออนุมัติ", rejected: "ไม่อนุมัติ" };

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hh("คืนเงิน · ยกเลิกบิล · Void", "วันนี้ 8 รายการ · รออนุมัติ 1 · มูลค่ารวม ฿2,485",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> รายงานการคืน</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> ออกใบคืนเงิน</button>
        </div>
      )}

      {/* KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "คืนเงินวันนี้", v: "฿485", c: "25" },
          { l: "Void วันนี้", v: "12 บิล", c: "80" },
          { l: "รออนุมัติ", v: "1", c: "80" },
          { l: "อัตราการคืน", v: "1.8%", c: "188" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-.02em", marginTop: 4, color: `oklch(.40 .14 ${k.c})` }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* refund table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, right: 380, bottom: 24, padding: 20 }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>รายการคืนเงิน</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>Refund Log</div>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "อนุมัติแล้ว", "รออนุมัติ", "ไม่อนุมัติ"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "100px 100px 2.2fr 100px 80px 110px 100px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>เลขที่</span><span>บิลต้นทาง</span><span>เหตุผล</span><span>ผู้บันทึก</span><span style={{ textAlign: "right" }}>ยอด</span><span>เวลา</span><span style={{ textAlign: "center" }}>สถานะ</span>
        </div>
        {refunds.map((r, i) => (
          <div key={i} style={{ display: "grid", gridTemplateColumns: "100px 100px 2.2fr 100px 80px 110px 100px", gap: 10, padding: "14px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13, background: i === 2 ? "linear-gradient(90deg, oklch(.96 .04 80 / .6), transparent)" : "transparent", borderRadius: 8 }}>
            <span className="tp-mono" style={{ fontWeight: 700, color: `oklch(.45 .14 ${r.c})` }}>{r.id}</span>
            <span className="tp-mono" style={{ color: "var(--tp-ink-soft)" }}>#{r.orig}</span>
            <div>
              <div style={{ fontWeight: 500 }}>{r.reason}</div>
              <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)", marginTop: 2 }}>อนุมัติโดย {r.appr}</div>
            </div>
            <span style={{ color: "var(--tp-ink-soft)" }}>{r.by}</span>
            <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600, color: "oklch(.55 .15 25)" }}>−฿{r.amt}</span>
            <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{r.time}</span>
            <span style={{ textAlign: "center", fontSize: 10, fontWeight: 600, padding: "4px 10px", borderRadius: 999, background: `oklch(.94 .07 ${r.c})`, color: `oklch(.40 .14 ${r.c})`, justifySelf: "center" }}>{statusLabel[r.status]}</span>
          </div>
        ))}
      </div>

      {/* Right: process refund form */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 332, bottom: 24, padding: "22px 24px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: "linear-gradient(160deg, oklch(.78 .14 28), oklch(.55 .18 25))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 6px 14px -4px oklch(.55 .18 25 / .5)" }}>
            <TPIcon name="arrow-down" size={16}/>
          </div>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำลังประมวล</div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>คืนเงิน RF-0426</div>
          </div>
        </div>

        <div style={{ padding: 14, borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 6 }}>
            <span style={{ color: "var(--tp-ink-mute)" }}>บิลต้นทาง</span>
            <span className="tp-mono" style={{ fontWeight: 600 }}>#A1029</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 6 }}>
            <span style={{ color: "var(--tp-ink-mute)" }}>ลูกค้า</span>
            <span style={{ fontWeight: 500 }}>คุณนภา ส.</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12, marginBottom: 6 }}>
            <span style={{ color: "var(--tp-ink-mute)" }}>ชำระโดย</span>
            <span style={{ fontWeight: 500 }}>QR พร้อมเพย์</span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 12 }}>
            <span style={{ color: "var(--tp-ink-mute)" }}>ออกเมื่อ</span>
            <span className="tp-mono">วันนี้ 13:08</span>
          </div>
        </div>

        <div style={{ marginTop: 14, fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>เหตุผล</div>
        <div style={{ marginTop: 6, padding: "10px 14px", borderRadius: 10, background: "oklch(.96 .04 80)", border: "1px solid oklch(.85 .08 80)", fontSize: 13 }}>
          ครัวซองต์ไหม้ — ลูกค้าขอคืนเงิน
        </div>

        <div style={{ marginTop: 14, fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>คืนกลับช่องทาง</div>
        <div style={{ marginTop: 6, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6 }}>
          {[
            { l: "QR ต้นทาง", on: true },
            { l: "เงินสด", on: false },
          ].map((t, i) => (
            <button key={i} style={{ padding: "10px 12px", borderRadius: 10, border: t.on ? "1.5px solid oklch(.62 .14 195)" : "1px solid var(--tp-line)", background: t.on ? "oklch(.96 .04 195)" : "white", color: t.on ? "oklch(.40 .14 200)" : "var(--tp-ink-soft)", fontSize: 12, fontWeight: 500, cursor: "pointer", fontFamily: "inherit" }}>{t.l}</button>
          ))}
        </div>

        <div style={{ marginTop: 14, padding: "12px 14px", borderRadius: 12, background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.18 .06 270))", color: "white", display: "flex", justifyContent: "space-between", alignItems: "baseline", boxShadow: "0 10px 22px -8px oklch(.25 .07 265 / .5)" }}>
          <span style={{ fontSize: 13 }}>ยอดที่ต้องคืน</span>
          <span className="tp-tnum" style={{ fontSize: 24, fontWeight: 700, letterSpacing: "-.02em" }}>฿55</span>
        </div>

        <div style={{ marginTop: 12, display: "grid", gridTemplateColumns: "1fr 1.4fr", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 44, fontSize: 13 }}><TPIcon name="x" size={14}/> ปฏิเสธ</button>
          <button className="tp-btn tp-btn-coral" style={{ height: 44, fontSize: 14, fontWeight: 600 }}><TPIcon name="check" size={16}/> อนุมัติคืน</button>
        </div>

        <div style={{ marginTop: 14, paddingTop: 14, borderTop: "1px dashed var(--tp-line)", fontSize: 11, color: "var(--tp-ink-mute)", display: "flex", alignItems: "center", gap: 6 }}>
          <TPIcon name="settings" size={12}/> ต้องการสิทธิ์ผู้จัดการ ขึ้นไป
        </div>
      </div>
    </div>
  );
};

// === 27 · Purchase Order ===
const PurchaseOrderScreen = () => {
  const lines = [
    { sku: "BEAN-AR", n: "เมล็ดกาแฟ Arabica (ภูดอย)", q: 50, u: "ก.ก.", p: 920, total: 46000 },
    { sku: "MILK-VR", n: "นมสดวัวแดง (UHT 1L)", q: 12, u: "ลัง", p: 580, total: 6960 },
    { sku: "MATCHA-PR", n: "ผงมัทฉะเกรดพรีเมียม", q: 10, u: "ก.ก.", p: 1450, total: 14500 },
    { sku: "CUP-16", n: "แก้วพลาสติก 16oz", q: 5000, u: "ใบ", p: 1.8, total: 9000 },
    { sku: "STRAW-PP", n: "หลอดดูดกระดาษ", q: 1000, u: "ใบ", p: 0.5, total: 500 },
  ];
  const sub = lines.reduce((s, l) => s + l.total, 0);
  const vat = Math.round((sub * 7) / 100);

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hh("ใบสั่งซื้อ Supplier · Purchase Order", "PO-2569-0142 · ร่าง · ผู้สร้าง คุณนัท · 08 พ.ค. 2569",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="x" size={16}/> ยกเลิก</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> บันทึกร่าง</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="check" size={16}/> ส่งสั่งซื้อ</button>
        </div>
      )}

      {/* Left: supplier + lines */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 880, bottom: 24, padding: 24, display: "flex", flexDirection: "column", gap: 18 }}>
        <div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>ผู้ขาย / Supplier</div>
          <div style={{ display: "grid", gridTemplateColumns: "60px 1fr 220px", gap: 14, padding: "12px 16px", borderRadius: 14, background: "white", border: "1px solid var(--tp-line)", boxShadow: "0 4px 10px -6px rgba(20,40,80,.08)", alignItems: "center" }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, background: "linear-gradient(160deg, oklch(.78 .14 80), oklch(.55 .14 50))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 14, fontFamily: "var(--tp-font-mono)", boxShadow: "0 6px 14px -4px oklch(.55 .14 50 / .5)" }}>HK</div>
            <div>
              <div style={{ fontSize: 15, fontWeight: 600 }}>Hillkoff Coffee Supply Co., Ltd.</div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>คุณวิทยา จันทร์เพ็ญ · 081-555-0142 · supplier@hillkoff.co.th</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>TAX ID: 0505555012345 · ระยะส่ง 3–5 วัน</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>คงค้าง / Credit</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 600, color: "oklch(.45 .14 80)" }}>฿24,500</div>
              <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>เครดิตเทอม 30 วัน</div>
            </div>
          </div>
        </div>

        {/* lines */}
        <div style={{ flex: 1, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 8 }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>รายการสั่งซื้อ</div>
            <div style={{ flex: 1 }}/>
            <button className="tp-btn tp-btn-ghost" style={{ height: 34, fontSize: 12 }}><TPIcon name="plus" size={14}/> เพิ่มสินค้า</button>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "44px 100px 1fr 70px 70px 80px 100px 40px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
            <span>#</span><span>SKU</span><span>สินค้า</span><span style={{ textAlign: "right" }}>จำนวน</span><span>หน่วย</span><span style={{ textAlign: "right" }}>ราคา/หน่วย</span><span style={{ textAlign: "right" }}>รวม</span><span></span>
          </div>
          <div style={{ flex: 1, overflow: "auto" }} className="tp-scroll">
            {lines.map((l, i) => (
              <div key={i} style={{ display: "grid", gridTemplateColumns: "44px 100px 1fr 70px 70px 80px 100px 40px", gap: 10, padding: "12px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13 }}>
                <span className="tp-mono" style={{ color: "var(--tp-ink-mute)" }}>{i + 1}</span>
                <span className="tp-mono" style={{ fontSize: 11, fontWeight: 600 }}>{l.sku}</span>
                <span style={{ fontWeight: 500 }}>{l.n}</span>
                <span className="tp-tnum" style={{ textAlign: "right" }}>{l.q.toLocaleString()}</span>
                <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{l.u}</span>
                <span className="tp-tnum" style={{ textAlign: "right" }}>฿{l.p}</span>
                <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>฿{l.total.toLocaleString()}</span>
                <button style={{ width: 28, height: 28, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-mute)" }}><TPIcon name="trash" size={13}/></button>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right: PO summary */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 488, bottom: 24, padding: 24, display: "flex", flexDirection: "column" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>การจัดส่ง</div>
        <div style={{ marginTop: 10, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
          <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>วันที่สั่ง</div>
            <div className="tp-mono" style={{ fontSize: 14, fontWeight: 600, marginTop: 2 }}>08 พ.ค. 2569</div>
          </div>
          <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>กำหนดส่ง</div>
            <div className="tp-mono" style={{ fontSize: 14, fontWeight: 600, marginTop: 2 }}>13 พ.ค. 2569</div>
          </div>
        </div>
        <div style={{ marginTop: 10, padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ส่งที่</div>
          <div style={{ fontSize: 13, marginTop: 2 }}>คลังกลาง สยาม · 989 อาคารสยามทาวเวอร์ ชั้น 8</div>
        </div>

        <div style={{ marginTop: 18, fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>วิธีชำระเงิน</div>
        <div style={{ marginTop: 8, display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 6 }}>
          {[
            { l: "เครดิต 30 วัน", on: true },
            { l: "โอนทันที", on: false },
            { l: "เก็บปลายทาง", on: false },
          ].map((t, i) => (
            <button key={i} style={{ padding: "10px 8px", borderRadius: 10, border: t.on ? "1.5px solid oklch(.62 .14 195)" : "1px solid var(--tp-line)", background: t.on ? "oklch(.96 .04 195)" : "white", color: t.on ? "oklch(.40 .14 200)" : "var(--tp-ink-soft)", fontSize: 12, fontWeight: 500, cursor: "pointer", fontFamily: "inherit" }}>{t.l}</button>
          ))}
        </div>

        <div style={{ flex: 1 }}/>

        <div style={{ borderTop: "1px dashed var(--tp-line)", paddingTop: 16, fontSize: 14 }}>
          <div style={{ display: "flex", padding: "6px 0" }}>
            <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>ยอดรวมก่อน VAT</span>
            <span className="tp-tnum">฿{sub.toLocaleString()}</span>
          </div>
          <div style={{ display: "flex", padding: "6px 0" }}>
            <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>VAT 7%</span>
            <span className="tp-tnum">฿{vat.toLocaleString()}</span>
          </div>
          <div style={{ display: "flex", padding: "6px 0" }}>
            <span style={{ flex: 1, color: "var(--tp-ink-mute)" }}>ค่าขนส่ง</span>
            <span className="tp-tnum">฿500</span>
          </div>
          <div style={{ display: "flex", padding: "14px 16px", marginTop: 10, borderRadius: 14, background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.20 .06 270))", color: "white", alignItems: "baseline", boxShadow: "0 12px 24px -10px oklch(.25 .07 265 / .55)" }}>
            <span style={{ flex: 1, fontSize: 14, opacity: .85 }}>รวมต้องชำระ</span>
            <span className="tp-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-.02em" }}>฿{(sub + vat + 500).toLocaleString()}</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// === 28 · Menu Editor with Recipe BOM ===
const MenuEditorScreen = () => {
  const menus = [
    { n: "ชาไทยเย็น", cat: "ของเย็น", price: 65, cost: 18.5, margin: 71, on: true, hue: 25, kind: "rect" },
    { n: "ชาเขียวมัทฉะลาเต้", cat: "ของเย็น", price: 85, cost: 32, margin: 62, on: true, hue: 145, kind: "circle" },
    { n: "อเมริกาโน่เย็น", cat: "กาแฟ", price: 70, cost: 14, margin: 80, on: true, hue: 35, kind: "rect" },
    { n: "ลาเต้ร้อน", cat: "กาแฟ", price: 75, cost: 22, margin: 70, on: true, hue: 50, kind: "circle" },
    { n: "โกโก้ปั่น", cat: "ของเย็น", price: 80, cost: 28, margin: 65, on: true, hue: 28, kind: "rect" },
    { n: "ชามะนาวโซดา", cat: "ของเย็น", price: 55, cost: 12, margin: 78, on: true, hue: 105, kind: "circle" },
    { n: "เอสเปรสโซ่ดับเบิ้ลช็อต", cat: "กาแฟ", price: 65, cost: 12, margin: 81, on: false, hue: 40, kind: "rect" },
    { n: "ชุดเซ็ตคู่ ชาไทย+ครัวซองต์", cat: "ชุดเซ็ต", price: 110, cost: 38, margin: 65, on: true, hue: 280, kind: "rect" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hh("จัดการเมนู · สูตรอาหาร", "84 เมนู · 12 หมวด · กำไรเฉลี่ย 68%",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="filter" size={16}/> หมวดหมู่</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="arrow-up" size={16}/> นำเข้าจาก Excel</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> เพิ่มเมนู</button>
        </div>
      )}

      {/* Left: menu list */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 560, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12, gap: 8 }}>
          <div style={{ flex: "0 0 200px", height: 36, background: "white", borderRadius: 10, border: "1px solid var(--tp-line)", display: "flex", alignItems: "center", padding: "0 12px", gap: 8 }}>
            <TPIcon name="search" size={13} color="var(--tp-ink-mute)"/>
            <input placeholder="ค้นหาเมนู..." style={{ flex: 1, border: "none", background: "transparent", outline: "none", fontFamily: "inherit", fontSize: 13 }}/>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "กาแฟ", "ของเย็น"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {menus.map((m, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 12,
              padding: "12px 14px", borderRadius: 12, marginBottom: 6,
              background: i === 1 ? "linear-gradient(90deg, oklch(.96 .04 188), transparent)" : "transparent",
              border: i === 1 ? "1px solid oklch(.85 .07 188)" : "1px solid transparent",
              cursor: "pointer"
            }}>
              <div style={{ width: 44, height: 44, borderRadius: 11, overflow: "hidden", flexShrink: 0 }}>
                <TPProductImg hue={m.hue} kind={m.kind}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ fontSize: 14, fontWeight: 500 }}>{m.n}</span>
                  {!m.on && <span style={{ fontSize: 9, fontWeight: 700, padding: "2px 6px", borderRadius: 4, background: "oklch(.94 .03 230)", color: "var(--tp-ink-mute)", letterSpacing: ".05em" }}>OFF</span>}
                </div>
                <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>{m.cat} · ต้นทุน ฿{m.cost} · กำไร {m.margin}%</div>
              </div>
              <span className="tp-tnum" style={{ fontSize: 16, fontWeight: 700, color: "var(--tp-teal-deep)" }}>฿{m.price}</span>
              <div style={{
                width: 32, height: 18, borderRadius: 999,
                background: m.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)",
                position: "relative", cursor: "pointer",
                boxShadow: m.on ? "inset 0 1px 0 rgba(255,255,255,.25)" : "inset 0 1px 2px rgba(20,40,80,.1)"
              }}>
                <div style={{ position: "absolute", top: 2, left: m.on ? 16 : 2, width: 14, height: 14, borderRadius: "50%", background: "white", boxShadow: "0 2px 4px rgba(20,40,80,.2)" }}/>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Right: detail editor */}
      <div style={{ position: "absolute", left: 608, top: 116, right: 24, bottom: 24, display: "grid", gridTemplateColumns: "1.2fr 1fr", gap: 16 }}>
        {/* visual + options */}
        <div className="tp-glass" style={{ padding: 22, display: "flex", flexDirection: "column" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14, paddingBottom: 16, borderBottom: "1px solid rgba(20,40,80,.08)" }}>
            <div style={{ width: 88, height: 88, borderRadius: 16, overflow: "hidden", flexShrink: 0 }}>
              <TPProductImg hue={145} kind="circle"/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำลังแก้ไข</div>
              <div style={{ fontSize: 20, fontWeight: 700, marginTop: 2 }}>ชาเขียวมัทฉะลาเต้</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>SKU: MATCHA-018 · ของเย็น</div>
            </div>
            <button style={{ width: 36, height: 36, borderRadius: 10, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name="more" size={16}/></button>
          </div>

          <div style={{ marginTop: 16, display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ราคาขาย</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, color: "var(--tp-teal-deep)", marginTop: 2 }}>฿85</div>
            </div>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "white", border: "1px solid var(--tp-line)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>ต้นทุน</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, color: "oklch(.45 .14 80)", marginTop: 2 }}>฿32</div>
            </div>
            <div style={{ padding: "10px 14px", borderRadius: 12, background: "linear-gradient(160deg, oklch(.95 .07 145), oklch(.90 .08 145))", border: "1px solid oklch(.85 .08 145)" }}>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>กำไร</div>
              <div className="tp-tnum" style={{ fontSize: 18, fontWeight: 700, color: "oklch(.40 .14 150)", marginTop: 2 }}>62%</div>
            </div>
          </div>

          {/* options */}
          <div style={{ marginTop: 18 }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 8 }}>ตัวเลือก / Modifiers</div>
            {[
              { g: "ขนาด", opts: [["Regular", 0, true], ["Large", "+10", false], ["XL", "+20", false]] },
              { g: "ความหวาน", opts: [["ปกติ", 0, true], ["หวานน้อย", 0, false], ["ไม่หวาน", 0, false]] },
              { g: "ท็อปปิ้ง", opts: [["ไข่มุก", "+15", false], ["วิปครีม", "+15", false], ["เจลลี่", "+10", false], ["นมโอ๊ต", "+10", false]] },
            ].map((g, gi) => (
              <div key={gi} style={{ marginBottom: 10 }}>
                <div style={{ fontSize: 12, fontWeight: 600, marginBottom: 6 }}>{g.g}</div>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
                  {g.opts.map((o, i) => (
                    <span key={i} style={{
                      padding: "5px 10px", borderRadius: 999, fontSize: 11, fontWeight: 500, cursor: "pointer",
                      background: o[2] ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "white",
                      color: o[2] ? "white" : "var(--tp-ink-soft)",
                      border: o[2] ? "none" : "1px solid var(--tp-line)",
                      display: "inline-flex", alignItems: "center", gap: 5
                    }}>{o[0]} {o[1] && <span className="tp-mono" style={{ opacity: .7 }}>{o[1]}</span>}</span>
                  ))}
                  <button style={{ padding: "5px 10px", borderRadius: 999, fontSize: 11, fontWeight: 500, border: "1px dashed var(--tp-line)", background: "transparent", color: "var(--tp-ink-mute)", cursor: "pointer", fontFamily: "inherit" }}>+ เพิ่ม</button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* recipe BOM */}
        <div className="tp-glass" style={{ padding: 22, display: "flex", flexDirection: "column" }}>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>สูตร / Recipe BOM</div>
          <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2, marginBottom: 14 }}>วัตถุดิบที่ใช้</div>
          <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
            {[
              { n: "ผงมัทฉะเกรดพรีเมียม", q: "3 ก.", c: 14.50, sku: "MATCHA-PR" },
              { n: "นมสดวัวแดง", q: "180 มล.", c: 8.60, sku: "MILK-VR" },
              { n: "น้ำตาลทราย", q: "12 ก.", c: 0.40, sku: "SUGAR-01" },
              { n: "น้ำแข็ง", q: "150 ก.", c: 0.20, sku: "ICE-01" },
              { n: "แก้วพลาสติก 16oz", q: "1 ใบ", c: 1.80, sku: "CUP-16" },
              { n: "หลอดดูดกระดาษ", q: "1 ใบ", c: 0.50, sku: "STRAW-PP" },
              { n: "ฝาแก้ว", q: "1 ใบ", c: 0.80, sku: "LID-16" },
              { n: "ผงครีมเทียม (Topping)", q: "5 ก.", c: 1.20, sku: "TOP-CR" },
              { n: "วิปครีม", q: "10 ก.", c: 4.00, sku: "WHIP-01" },
            ].map((r, i) => (
              <div key={i} style={{ display: "flex", padding: "10px 0", borderBottom: "1px dashed var(--tp-line)", alignItems: "center", gap: 10 }}>
                <div style={{ width: 8, height: 8, borderRadius: "50%", background: `oklch(.62 .14 ${(i * 40 + 140) % 360})` }}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>{r.n}</div>
                  <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>{r.sku}</div>
                </div>
                <span className="tp-mono" style={{ fontSize: 12, color: "var(--tp-ink-mute)", textAlign: "right", minWidth: 60 }}>{r.q}</span>
                <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600, minWidth: 56, textAlign: "right" }}>฿{r.c.toFixed(2)}</span>
              </div>
            ))}
          </div>

          <div style={{ marginTop: 12, padding: "12px 14px", borderRadius: 12, background: "linear-gradient(140deg, oklch(.30 .08 265), oklch(.18 .06 270))", color: "white", display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
            <span style={{ fontSize: 13 }}>รวมต้นทุน/แก้ว</span>
            <span className="tp-tnum" style={{ fontSize: 22, fontWeight: 700 }}>฿32.00</span>
          </div>
          <button className="tp-btn tp-btn-ghost" style={{ width: "100%", marginTop: 8, height: 36, fontSize: 12 }}><TPIcon name="plus" size={14}/> เพิ่มวัตถุดิบ</button>
        </div>
      </div>
    </div>
  );
};

// === 29 · Multi-Branch HQ ===
const MultiBranchScreen = () => {
  const branches = [
    { n: "สยาม สแควร์", code: "BR-01", sales: "฿42,580", growth: 12.4, orders: 248, staff: 8, status: "open", c: "188" },
    { n: "อโศก เทอร์มินอล21", code: "BR-02", sales: "฿38,420", growth: 8.2, orders: 218, staff: 7, status: "open", c: "270" },
    { n: "ทองหล่อ ซอย 10", code: "BR-03", sales: "฿28,640", growth: -2.4, orders: 158, staff: 6, status: "open", c: "80" },
    { n: "เซ็นทรัล ลาดพร้าว", code: "BR-04", sales: "฿24,820", growth: 18.6, orders: 142, staff: 6, status: "open", c: "145" },
    { n: "ChiangMai นิมมาน", code: "BR-05", sales: "฿14,580", growth: 24.8, orders: 86, staff: 4, status: "open", c: "25" },
    { n: "Phuket ป่าตอง", code: "BR-06", sales: "฿0", growth: 0, orders: 0, staff: 5, status: "closed", c: "230" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_hh("สำนักงานใหญ่ · 6 สาขา", "ภาพรวมทุกสาขา · วันนี้ 8 พ.ค. 2569 · เปิด 5 สาขา · ปิด 1",
        <div style={{ display: "flex", gap: 8 }}>
          <div style={{ display: "flex", background: "rgba(255,255,255,.5)", borderRadius: 12, padding: 4, gap: 2, border: "1px solid rgba(255,255,255,.6)" }}>
            {["วันนี้", "สัปดาห์", "เดือน"].map((t, i) => (
              <button key={i} style={{ padding: "8px 14px", borderRadius: 9, border: "none", cursor: "pointer", fontFamily: "inherit", fontSize: 12, fontWeight: 500, background: i === 0 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent", color: i === 0 ? "white" : "var(--tp-ink-soft)" }}>{t}</button>
            ))}
          </div>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> รายงานรวม</button>
        </div>
      )}

      {/* HQ KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "ยอดขายรวมทุกสาขา", v: "฿149,040", d: "+12.8%", c: "188", up: true },
          { l: "ออเดอร์รวม", v: "852", d: "+86 วันนี้", c: "270", up: true },
          { l: "พนักงาน Active", v: "36 / 42", d: "85.7%", c: "80", up: true },
          { l: "Avg per Branch", v: "฿29,808", d: "+5.4%", c: "145", up: true },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", right: -20, top: -20, width: 110, height: 110, borderRadius: "50%", background: `radial-gradient(circle, oklch(.85 .12 ${k.c} / .35), transparent 70%)`, filter: "blur(10px)" }}/>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 700, letterSpacing: "-.02em", marginTop: 4, color: "var(--tp-indigo-deep)" }}>{k.v}</div>
            <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 6, padding: "2px 8px", borderRadius: 999, fontSize: 11, fontWeight: 600, background: "oklch(.94 .08 145)", color: "oklch(.45 .14 150)" }}>
              <TPIcon name="arrow-up" size={11}/> {k.d}
            </div>
          </div>
        ))}
      </div>

      {/* Branch cards */}
      <div style={{ position: "absolute", left: 24, top: 240, right: 480, bottom: 24, display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gridAutoRows: "minmax(0, 1fr)", gap: 14 }}>
        {branches.map((b, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 20px", display: "flex", flexDirection: "column", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 4, background: `linear-gradient(180deg, oklch(.85 .14 ${b.c}), oklch(.55 .14 ${b.c}))` }}/>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{
                width: 44, height: 44, borderRadius: 12,
                background: `linear-gradient(160deg, oklch(.85 .14 ${b.c}), oklch(.55 .14 ${b.c}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: `0 6px 14px -4px oklch(.55 .14 ${b.c} / .5)`
              }}><TPIcon name="pin" size={20}/></div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 600 }}>{b.n}</div>
                <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{b.code} · พนักงาน {b.staff} คน</div>
              </div>
              <span style={{ padding: "3px 10px", borderRadius: 999, fontSize: 10, fontWeight: 600, background: b.status === "open" ? "oklch(.94 .08 145)" : "oklch(.94 .03 230)", color: b.status === "open" ? "oklch(.45 .14 150)" : "var(--tp-ink-mute)" }}>{b.status === "open" ? "● เปิด" : "ปิด"}</span>
            </div>

            <div style={{ marginTop: 14, display: "flex", alignItems: "baseline", gap: 10 }}>
              <span className="tp-tnum" style={{ fontSize: 24, fontWeight: 700, letterSpacing: "-.02em" }}>{b.sales}</span>
              {b.growth !== 0 && (
                <span style={{ display: "inline-flex", alignItems: "center", gap: 3, padding: "2px 8px", borderRadius: 999, fontSize: 11, fontWeight: 600, background: b.growth > 0 ? "oklch(.94 .08 145)" : "oklch(.94 .08 25)", color: b.growth > 0 ? "oklch(.45 .14 150)" : "oklch(.55 .15 25)" }}>
                  <TPIcon name={b.growth > 0 ? "arrow-up" : "arrow-down"} size={10}/> {Math.abs(b.growth)}%
                </span>
              )}
            </div>

            <div style={{ flex: 1 }}/>

            <div style={{ marginTop: 10, display: "flex", gap: 12, fontSize: 11, color: "var(--tp-ink-mute)" }}>
              <span><TPIcon name="receipt" size={11} style={{ verticalAlign: "-1px", marginRight: 4 }}/> {b.orders} บิล</span>
              <span><TPIcon name="users" size={11} style={{ verticalAlign: "-1px", marginRight: 4 }}/> {b.staff} คน</span>
              <div style={{ flex: 1 }}/>
              <span style={{ color: "var(--tp-teal-deep)", fontWeight: 500 }}>เข้าสาขา →</span>
            </div>
          </div>
        ))}
      </div>

      {/* Right: leaderboard + alerts */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 432, height: 380, padding: "22px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตารางผู้นำ</div>
        <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2, marginBottom: 12 }}>Branch Leaderboard</div>

        {branches.filter(b => b.status === "open").sort((a, b) => parseInt(b.sales.replace(/[฿,]/g, "")) - parseInt(a.sales.replace(/[฿,]/g, ""))).map((b, i) => {
          const val = parseInt(b.sales.replace(/[฿,]/g, ""));
          const pct = (val / 42580) * 100;
          return (
            <div key={i} style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 12 }}>
              <span className="tp-tnum" style={{ width: 22, fontSize: 13, fontWeight: 700, color: i < 3 ? `oklch(.45 .14 ${["80","230","25"][i]})` : "var(--tp-ink-mute)" }}>{i + 1}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{b.n}</span>
                  <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{b.sales}</span>
                </div>
                <div style={{ height: 6, background: "rgba(20,40,80,.06)", borderRadius: 999, overflow: "hidden" }}>
                  <div style={{ height: "100%", width: `${pct}%`, background: `linear-gradient(90deg, oklch(.78 .12 ${b.c}), oklch(.55 .14 ${b.c}))`, borderRadius: 999 }}/>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 640, width: 432, bottom: 24, padding: "22px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>การแจ้งเตือนสาขา</div>
        <div style={{ fontSize: 17, fontWeight: 700, marginTop: 2, marginBottom: 10 }}>HQ Alerts</div>
        {[
          { i: "bell", c: "25", t: "ทองหล่อ ซอย 10 · ยอดต่ำกว่าเป้า −12%", s: "5 นาทีที่แล้ว" },
          { i: "tag", c: "80", t: "อโศก · มัทฉะใกล้หมด — ขอ refill", s: "20 นาทีที่แล้ว" },
          { i: "star", c: "145", t: "เชียงใหม่ นิมมาน · ทำสถิติยอดขายรายวัน 🎉", s: "1 ชั่วโมงที่แล้ว" },
          { i: "users", c: "270", t: "ภูเก็ต · ปิดสาขา (พายุฤดูฝน)", s: "วันนี้ 08:00" },
        ].map((a, i) => (
          <div key={i} style={{ display: "flex", padding: "10px 0", borderBottom: i < 3 ? "1px dashed var(--tp-line)" : "none", gap: 10, alignItems: "center" }}>
            <div style={{ width: 32, height: 32, borderRadius: 9, background: `linear-gradient(160deg, oklch(.92 .08 ${a.c}), oklch(.78 .12 ${a.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
              <TPIcon name={a.i} size={14}/>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 500 }}>{a.t}</div>
              <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>{a.s}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

window.CRMScreen = CRMScreen;
window.ShiftScreen = ShiftScreen;
window.RefundScreen = RefundScreen;
window.PurchaseOrderScreen = PurchaseOrderScreen;
window.MenuEditorScreen = MenuEditorScreen;
window.MultiBranchScreen = MultiBranchScreen;

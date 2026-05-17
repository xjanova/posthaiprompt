// Thaiprompt POS — Operations: Stock, Shipping providers, Coupons, Staff, Admin

const _h = (label, sub, right) => (
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

// === 17 · Stock Management ===
const StockManagementScreen = () => {
  const moves = [
    { id: "MV-2841", t: "รับเข้า", item: "เมล็ดกาแฟ Arabica", from: "Hillkoff Supply", to: "คลังสยาม", qty: "+50", unit: "ก.ก.", val: "฿46,000", time: "08 พ.ค. 10:24", c: "145", icon: "arrow-down" },
    { id: "MV-2840", t: "เบิกผลิต", item: "ผงมัทฉะ", from: "คลังสยาม", to: "ครัวร้อน", qty: "−2.5", unit: "ก.ก.", val: "฿3,625", time: "08 พ.ค. 09:12", c: "80", icon: "arrow-up" },
    { id: "MV-2839", t: "โอนระหว่างสาขา", item: "นมสดวัวแดง", from: "คลังสยาม", to: "สาขาอโศก", qty: "−12", unit: "ลัง", val: "฿6,960", time: "08 พ.ค. 08:30", c: "270", icon: "split" },
    { id: "MV-2838", t: "นับสต็อก", item: "ครัวซองต์อัลมอนด์", from: "—", to: "คลังสยาม", qty: "−3", unit: "ชิ้น", val: "−฿96", time: "07 พ.ค. 22:00", c: "25", icon: "check" },
    { id: "MV-2837", t: "รับเข้า", item: "หลอดดูดกระดาษ", from: "EcoPack", to: "คลังสยาม", qty: "+1,000", unit: "ใบ", val: "฿500", time: "07 พ.ค. 16:42", c: "145", icon: "arrow-down" },
    { id: "MV-2836", t: "ปรับสูญหาย", item: "บราวนี่ช็อกโกแลต", from: "คลังสยาม", to: "—", qty: "−2", unit: "ชิ้น", val: "−฿56", time: "07 พ.ค. 14:08", c: "25", icon: "trash" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_h("จัดการสต็อก · ความเคลื่อนไหวคลัง", "Stock Movements · 6 รายการวันนี้",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="check" size={16}/> นับสต็อก</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="split" size={16}/> โอนสาขา</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> รับเข้า</button>
        </div>
      )}

      {/* KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 14 }}>
        {[
          { l: "รับเข้าวันนี้", v: "฿46,500", icon: "arrow-down", c: "145" },
          { l: "เบิกใช้วันนี้", v: "฿14,820", icon: "arrow-up", c: "80" },
          { l: "โอนสาขา", v: "฿6,960", icon: "split", c: "270" },
          { l: "ใกล้หมดอายุ", v: "8 รายการ", icon: "clock", c: "25" },
          { l: "รออนุมัติ PO", v: "3 ใบ", icon: "receipt", c: "188" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "14px 18px", display: "flex", alignItems: "center", gap: 12 }}>
            <div style={{ width: 36, height: 36, borderRadius: 10,
              background: `linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}))`,
              color: "white", display: "flex", alignItems: "center", justifyContent: "center",
              boxShadow: `0 6px 12px -4px oklch(.62 .14 ${k.c} / .5)`
            }}><TPIcon name={k.icon} size={16}/></div>
            <div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>{k.l}</div>
              <div className="tp-tnum" style={{ fontSize: 20, fontWeight: 600 }}>{k.v}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Movements table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 220, width: 920, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ความเคลื่อนไหว</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>Stock Ledger</div>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "รับเข้า", "เบิกใช้", "โอน", "ปรับ"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "44px 110px 1.6fr 1.4fr 100px 110px 110px", gap: 10, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span></span><span>เลขที่</span><span>สินค้า / ประเภท</span><span>ต้นทาง → ปลายทาง</span><span style={{ textAlign: "right" }}>จำนวน</span><span style={{ textAlign: "right" }}>มูลค่า</span><span style={{ textAlign: "right" }}>เวลา</span>
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {moves.map((m, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "44px 110px 1.6fr 1.4fr 100px 110px 110px", gap: 10, padding: "12px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13 }}>
              <div style={{ width: 32, height: 32, borderRadius: 9, background: `oklch(.94 .07 ${m.c})`, color: `oklch(.45 .14 ${m.c})`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <TPIcon name={m.icon} size={15}/>
              </div>
              <span className="tp-mono" style={{ fontWeight: 600 }}>{m.id}</span>
              <div>
                <div style={{ fontWeight: 500 }}>{m.item}</div>
                <div style={{ fontSize: 11, color: `oklch(.45 .14 ${m.c})`, fontWeight: 500 }}>{m.t}</div>
              </div>
              <div style={{ fontSize: 12 }}>
                <span style={{ color: "var(--tp-ink-mute)" }}>{m.from}</span>
                <TPIcon name="arrow-right" size={11} style={{ margin: "0 4px", verticalAlign: "middle" }}/>
                <span style={{ fontWeight: 500 }}>{m.to}</span>
              </div>
              <div style={{ textAlign: "right" }}>
                <div className="tp-tnum" style={{ fontWeight: 600, color: m.qty.startsWith("−") ? "oklch(.55 .15 25)" : "oklch(.45 .14 150)" }}>{m.qty}</div>
                <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>{m.unit}</div>
              </div>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 500 }}>{m.val}</span>
              <span className="tp-mono" style={{ textAlign: "right", fontSize: 11, color: "var(--tp-ink-mute)" }}>{m.time}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right: low stock + reorder */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 220, width: 460, bottom: 360, padding: "20px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>แนะนำสั่งซื้อ</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 12 }}>Auto Reorder</div>
        {[
          { n: "ผงมัทฉะ", cur: "4 ก.ก.", sug: "+10 ก.ก.", v: "฿14,500", c: "80" },
          { n: "หลอดดูดกระดาษ", cur: "380 ใบ", sug: "+1,000", v: "฿500", c: "80" },
          { n: "บราวนี่ช็อกโกแลต", cur: "0 ชิ้น", sug: "+30 ชิ้น", v: "฿840", c: "25" },
        ].map((r, i) => (
          <div key={i} style={{ display: "flex", padding: "10px 0", borderBottom: i < 2 ? "1px dashed var(--tp-line)" : "none", alignItems: "center", gap: 10 }}>
            <div style={{ width: 32, height: 32, borderRadius: 8, background: `oklch(.94 .07 ${r.c})`, color: `oklch(.45 .14 ${r.c})`, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <TPIcon name="bell" size={14}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 500 }}>{r.n}</div>
              <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>เหลือ {r.cur} · แนะนำ {r.sug}</div>
            </div>
            <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{r.v}</span>
            <button className="tp-btn tp-btn-primary" style={{ height: 32, padding: "0 12px", fontSize: 12 }}>สั่ง</button>
          </div>
        ))}
      </div>

      {/* Right bottom: warehouse */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, bottom: 24, width: 460, height: 320, padding: "20px 24px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตำแหน่งคลัง</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 12 }}>Warehouse Map</div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gridTemplateRows: "repeat(3, 56px)", gap: 6 }}>
          {[
            { l: "A1", c: "188" }, { l: "A2", c: "188" }, { l: "A3", c: "80" }, { l: "A4", c: "188" },
            { l: "B1", c: "188" }, { l: "B2", c: "25" }, { l: "B3", c: "188" }, { l: "B4", c: "145" },
            { l: "C1", c: "145" }, { l: "C2", c: "188" }, { l: "C3", c: "80" }, { l: "C4", c: "188" },
          ].map((b, i) => (
            <div key={i} style={{
              borderRadius: 8, background: `linear-gradient(160deg, oklch(.92 .06 ${b.c}), oklch(.78 .10 ${b.c}))`,
              boxShadow: "inset 0 1px 0 rgba(255,255,255,.6), 0 2px 6px -3px rgba(20,40,80,.15)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 12, fontWeight: 600, color: "white",
              fontFamily: "var(--tp-font-mono)"
            }}>{b.l}</div>
          ))}
        </div>
        <div style={{ marginTop: 14, display: "flex", gap: 14, fontSize: 11 }}>
          <span style={{ display: "flex", alignItems: "center", gap: 4 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: "oklch(.78 .10 188)" }}/> ปกติ</span>
          <span style={{ display: "flex", alignItems: "center", gap: 4 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: "oklch(.78 .10 80)" }}/> ใกล้หมด</span>
          <span style={{ display: "flex", alignItems: "center", gap: 4 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: "oklch(.78 .10 25)" }}/> หมด</span>
          <span style={{ display: "flex", alignItems: "center", gap: 4 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: "oklch(.78 .10 145)" }}/> ของใหม่</span>
        </div>
      </div>
    </div>
  );
};

// === 18 · Shipping Providers ===
const ShippingProvidersScreen = () => {
  const providers = [
    { n: "Grab Express", short: "GRAB", c: "145", desc: "ส่งใน 30 นาที กทม.&ปริมณฑล", linked: true, fee: "฿38–95", orders: 124, sla: "98%" },
    { n: "LINE MAN", short: "LM", c: "145", desc: "ฟู้ดและพัสดุ ผูก LINE OA", linked: true, fee: "฿35–80", orders: 86, sla: "96%" },
    { n: "Lalamove", short: "LM2", c: "25", desc: "พัสดุใหญ่ มอเตอร์ไซค์ + 4-ล้อ", linked: true, fee: "฿55–220", orders: 42, sla: "94%" },
    { n: "Robinhood", short: "RH", c: "188", desc: "ฟรีค่า GP สำหรับร้านขนาดเล็ก", linked: false, fee: "—", orders: 0, sla: "—" },
    { n: "ไปรษณีย์ไทย", short: "TH", c: "270", desc: "EMS / Kerry-light ทั่วประเทศ", linked: true, fee: "฿32–150", orders: 28, sla: "92%" },
    { n: "Flash Express", short: "FL", c: "80", desc: "ปลายทาง COD รับ 7 วัน/สัปดาห์", linked: true, fee: "฿25–120", orders: 36, sla: "95%" },
    { n: "Kerry Express", short: "KE", c: "25", desc: "พัสดุครบวงจร เก็บปลายทางได้", linked: false, fee: "—", orders: 0, sla: "—" },
    { n: "J&T Express", short: "JT", c: "25", desc: "ราคาประหยัด เน้นต่างจังหวัด", linked: true, fee: "฿28–110", orders: 18, sla: "91%" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_h("ส่งของไปผู้ให้บริการ", "เชื่อมต่อ Logistics Partner · 6 ผู้ให้บริการพร้อมใช้",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="settings" size={16}/> ตั้งค่า API</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="printer" size={16}/> พิมพ์ใบปะหน้า</button>
        </div>
      )}

      {/* Top: today summary */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "พัสดุที่จะส่งวันนี้", v: "47", c: "188", icon: "box" },
          { l: "เรียกรถสำเร็จ", v: "32", c: "145", icon: "check" },
          { l: "รอเรียกรถ", v: "12", c: "80", icon: "clock" },
          { l: "ค่าขนส่งวันนี้", v: "฿2,840", c: "270", icon: "cash" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "16px 22px", display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: `linear-gradient(160deg, oklch(.85 .12 ${k.c}), oklch(.62 .14 ${k.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 6px 14px -4px oklch(.62 .14 ${k.c} / .5)` }}>
              <TPIcon name={k.icon} size={18}/>
            </div>
            <div>
              <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
              <div className="tp-tnum" style={{ fontSize: 26, fontWeight: 600, letterSpacing: "-.02em", marginTop: 2 }}>{k.v}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Provider grid */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 240, bottom: 280, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gridAutoRows: "minmax(0, 1fr)", gap: 16 }}>
        {providers.map((p, i) => (
          <div key={i} className="tp-glass" style={{ padding: 20, display: "flex", flexDirection: "column", position: "relative", overflow: "hidden" }}>
            <div style={{ position: "absolute", right: -20, top: -20, width: 110, height: 110, borderRadius: "50%", background: `radial-gradient(circle, oklch(.85 .14 ${p.c} / .35), transparent 70%)`, filter: "blur(10px)" }}/>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{
                width: 48, height: 48, borderRadius: 14,
                background: `linear-gradient(160deg, oklch(.85 .14 ${p.c}), oklch(.55 .14 ${p.c}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                fontWeight: 700, fontSize: 14, letterSpacing: "-.01em",
                boxShadow: `0 8px 16px -6px oklch(.55 .14 ${p.c} / .5), inset 0 1px 0 rgba(255,255,255,.5)`,
                fontFamily: "var(--tp-font-mono)"
              }}>{p.short}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{p.n}</div>
                <div style={{ fontSize: 11, color: p.linked ? "oklch(.45 .14 150)" : "var(--tp-ink-mute)", fontWeight: 500, display: "flex", alignItems: "center", gap: 4, marginTop: 2 }}>
                  <span style={{ width: 6, height: 6, borderRadius: "50%", background: p.linked ? "oklch(.62 .14 150)" : "oklch(.75 .03 230)" }}/>
                  {p.linked ? "เชื่อมแล้ว" : "ยังไม่เชื่อม"}
                </div>
              </div>
            </div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-soft)", marginTop: 10, lineHeight: 1.4, flex: 1 }}>{p.desc}</div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6, marginTop: 12, paddingTop: 12, borderTop: "1px dashed var(--tp-line)" }}>
              <div><div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>ค่าส่ง</div><div className="tp-mono" style={{ fontSize: 11, fontWeight: 600 }}>{p.fee}</div></div>
              <div><div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>ออเดอร์</div><div className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{p.orders}</div></div>
              <div><div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>SLA</div><div className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{p.sla}</div></div>
            </div>
            <button style={{
              marginTop: 12, height: 36, borderRadius: 10, fontFamily: "inherit",
              fontSize: 12, fontWeight: 500, cursor: "pointer",
              border: p.linked ? "1px solid var(--tp-line)" : "none",
              background: p.linked ? "white" : "linear-gradient(160deg, oklch(.62 .14 195), oklch(.45 .14 220))",
              color: p.linked ? "var(--tp-ink)" : "white",
              boxShadow: p.linked ? "none" : "0 6px 14px -6px oklch(.50 .14 220 / .55)"
            }}>{p.linked ? "เรียกรถ" : "เชื่อมต่อ"}</button>
          </div>
        ))}
      </div>

      {/* Pending shipments table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, right: 24, bottom: 24, height: 240, padding: "18px 22px", display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 10 }}>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>รอเรียกรถ</div>
          <div style={{ flex: 1 }}/>
          <span className="tp-chip" style={{ background: "oklch(.94 .08 80)", color: "oklch(.50 .14 80)", border: "1px solid oklch(.85 .10 80)" }}>12 รายการ</span>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "120px 1.6fr 1fr 1fr 90px 90px 110px", gap: 12, padding: "8px 12px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span>เลขที่</span><span>ผู้รับ</span><span>ปลายทาง</span><span>ผู้ให้บริการ</span><span style={{ textAlign: "right" }}>นน.</span><span style={{ textAlign: "right" }}>ค่าส่ง</span><span></span>
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {[
            { id: "SH-2042", n: "คุณกานต์ ว.", to: "ทองหล่อ ซ.10", p: "Grab", w: "1.4 กก.", f: "฿58", c: "145" },
            { id: "SH-2041", n: "บจก. สยามคอฟฟี่", to: "ปทุมวัน", p: "LINE MAN", w: "3.2 กก.", f: "฿85", c: "145" },
            { id: "SH-2040", n: "คุณนิภา ส.", to: "เชียงใหม่", p: "Flash", w: "0.8 กก.", f: "฿65", c: "80" },
            { id: "SH-2039", n: "ร้านพิ้งกี้คาเฟ่", to: "พระราม 9", p: "Lalamove", w: "8.0 กก.", f: "฿180", c: "25" },
          ].map((s, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "120px 1.6fr 1fr 1fr 90px 90px 110px", gap: 12, padding: "10px 12px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13 }}>
              <span className="tp-mono" style={{ fontWeight: 600 }}>{s.id}</span>
              <span style={{ fontWeight: 500 }}>{s.n}</span>
              <span style={{ color: "var(--tp-ink-mute)" }}>{s.to}</span>
              <span className="tp-chip" style={{ height: 22, fontSize: 10, padding: "0 8px", background: `oklch(.94 .08 ${s.c})`, color: `oklch(.45 .14 ${s.c})` }}>{s.p}</span>
              <span className="tp-tnum" style={{ textAlign: "right", color: "var(--tp-ink-mute)" }}>{s.w}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>{s.f}</span>
              <button className="tp-btn tp-btn-primary" style={{ height: 30, padding: "0 12px", fontSize: 11 }}>เรียกรถ</button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// === 19 · Coupon System ===
const CouponScreen = () => {
  const coupons = [
    { code: "SUMMER25", t: "ลด 25%", on: "ทุกเมนูเครื่องดื่มเย็น", val: "−25%", used: 184, lim: 500, exp: "31 พ.ค. 68", c: "188", status: "active" },
    { code: "FREEDLV", t: "ส่งฟรี", on: "ออเดอร์ ≥ ฿200 · เดลิเวอรี่", val: "ส่งฟรี", used: 96, lim: "—", exp: "ไม่จำกัด", c: "145", status: "active" },
    { code: "WELCOME50", t: "ลด ฿50", on: "ลูกค้าใหม่ บิลแรก", val: "−฿50", used: 248, lim: 1000, exp: "ต่ออัตโนมัติ", c: "270", status: "active" },
    { code: "SONGKRAN", t: "ซื้อ 1 แถม 1", on: "ชาไทยเย็น เฉพาะ 13–15 เม.ย.", val: "1+1", used: 642, lim: 642, exp: "หมดแล้ว", c: "25", status: "ended" },
    { code: "BDAY100", t: "ลด ฿100", on: "วันเกิดสมาชิก", val: "−฿100", used: 38, lim: "—", exp: "ตลอดปี", c: "80", status: "active" },
    { code: "VIPGOLD", t: "ลด 15%", on: "สมาชิก Gold ขึ้นไป", val: "−15%", used: 24, lim: "—", exp: "ไม่จำกัด", c: "80", status: "active" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_h("ระบบคูปอง · โปรโมชั่น", "5 แคมเปญใช้งาน · 1,232 ครั้งใช้รวมเดือนนี้",
        <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> สร้างคูปองใหม่</button>
      )}

      {/* KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "การใช้คูปองวันนี้", v: "84", c: "188" },
          { l: "ส่วนลดรวมเดือนนี้", v: "฿42,580", c: "25" },
          { l: "Conversion Rate", v: "32.4%", c: "270" },
          { l: "ROI ของแคมเปญ", v: "4.2×", c: "145" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-.02em", marginTop: 4, color: `oklch(.45 .14 ${k.c})` }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* Coupon cards grid */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, right: 380, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>คูปองทั้งหมด</div>
            <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2 }}>Active Campaigns</div>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "ใช้งาน", "หมดอายุ", "ร่าง"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>

        <div className="tp-scroll" style={{ flex: 1, overflow: "auto", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, alignContent: "start", paddingRight: 4 }}>
          {coupons.map((c, i) => (
            <div key={i} style={{
              position: "relative",
              borderRadius: 16, padding: "16px 20px",
              background: c.status === "ended"
                ? "linear-gradient(140deg, oklch(.95 .01 230), oklch(.92 .01 230))"
                : `linear-gradient(140deg, oklch(.96 .04 ${c.c}), oklch(.92 .06 ${c.c}))`,
              border: `1px solid oklch(.85 .06 ${c.c})`,
              opacity: c.status === "ended" ? 0.6 : 1,
              overflow: "hidden",
              minHeight: 156,
            }}>
              {/* perforation circles */}
              <div style={{ position: "absolute", left: -8, top: "50%", width: 16, height: 16, borderRadius: "50%", background: "var(--tp-cream, white)", marginTop: -8 }}/>
              <div style={{ position: "absolute", right: -8, top: "50%", width: 16, height: 16, borderRadius: "50%", background: "var(--tp-cream, white)", marginTop: -8 }}/>
              <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{
                  width: 48, height: 48, borderRadius: 12,
                  background: `linear-gradient(160deg, oklch(.85 .14 ${c.c}), oklch(.55 .14 ${c.c}))`,
                  color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 18, fontWeight: 700,
                  boxShadow: `0 6px 14px -6px oklch(.55 .14 ${c.c} / .5), inset 0 1px 0 rgba(255,255,255,.5)`
                }}><TPIcon name="tag" size={20}/></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 16, fontWeight: 700, color: `oklch(.40 .14 ${c.c})` }}>{c.t}</div>
                  <div style={{ fontSize: 12, color: "var(--tp-ink-soft)" }}>{c.on}</div>
                </div>
                <div style={{ fontSize: 10, fontWeight: 700, padding: "3px 10px", borderRadius: 999, background: c.status === "active" ? "oklch(.94 .08 145)" : "oklch(.94 .03 230)", color: c.status === "active" ? "oklch(.45 .14 150)" : "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em" }}>{c.status === "active" ? "ใช้งาน" : "หมดแล้ว"}</div>
              </div>
              <div style={{ marginTop: 14, paddingTop: 12, borderTop: `1px dashed oklch(.75 .08 ${c.c} / .5)`, display: "flex", alignItems: "center" }}>
                <div className="tp-mono" style={{ fontSize: 13, fontWeight: 700, letterSpacing: ".15em", color: `oklch(.40 .14 ${c.c})` }}>{c.code}</div>
                <div style={{ flex: 1 }}/>
                <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>หมด: {c.exp}</div>
              </div>
              <div style={{ marginTop: 8, display: "flex", alignItems: "center", gap: 10 }}>
                <div style={{ flex: 1, height: 5, background: "rgba(20,40,80,.08)", borderRadius: 999, overflow: "hidden" }}>
                  <div style={{ height: "100%", width: c.lim === "—" ? "30%" : `${Math.min(100, (c.used / c.lim) * 100)}%`, background: `linear-gradient(90deg, oklch(.78 .14 ${c.c}), oklch(.55 .14 ${c.c}))` }}/>
                </div>
                <span className="tp-mono" style={{ fontSize: 11, fontWeight: 600 }}>{c.used}/{c.lim}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Right: create coupon form preview */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 332, bottom: 24, padding: "20px 22px", display: "flex", flexDirection: "column" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ใช้งานสูงสุดสัปดาห์นี้</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 14 }}>Top Performers</div>

        {[
          { c: "WELCOME50", v: 248, p: 100, hue: 270 },
          { c: "SUMMER25", v: 184, p: 74, hue: 188 },
          { c: "FREEDLV", v: 96, p: 39, hue: 145 },
          { c: "BDAY100", v: 38, p: 15, hue: 80 },
        ].map((b, i) => (
          <div key={i} style={{ marginBottom: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
              <span className="tp-mono" style={{ fontSize: 12, fontWeight: 600 }}>{b.c}</span>
              <span className="tp-tnum" style={{ fontSize: 12, fontWeight: 600 }}>{b.v}</span>
            </div>
            <div style={{ height: 8, background: "rgba(20,40,80,.06)", borderRadius: 999, overflow: "hidden" }}>
              <div style={{ height: "100%", width: `${b.p}%`, background: `linear-gradient(90deg, oklch(.78 .12 ${b.hue}), oklch(.55 .14 ${b.hue}))`, borderRadius: 999 }}/>
            </div>
          </div>
        ))}

        <div style={{ flex: 1 }}/>

        {/* preview ticket */}
        <div style={{
          marginTop: 16, padding: 16, borderRadius: 14, position: "relative", overflow: "hidden",
          background: "linear-gradient(140deg, oklch(.50 .14 250), oklch(.30 .12 270))",
          color: "white",
          boxShadow: "0 14px 28px -14px oklch(.30 .12 270 / .55)"
        }}>
          <div style={{ position: "absolute", right: -30, top: -30, width: 120, height: 120, borderRadius: "50%", background: "radial-gradient(circle, oklch(.85 .14 80 / .35), transparent 70%)" }}/>
          <div style={{ fontSize: 11, opacity: .8, textTransform: "uppercase", letterSpacing: ".1em" }}>Preview · กดดู QR ลูกค้า</div>
          <div style={{ fontSize: 22, fontWeight: 700, marginTop: 6 }}>ลด ฿100</div>
          <div style={{ fontSize: 11, opacity: .85 }}>วันเกิดสมาชิก · ใช้ได้ตลอดปี</div>
          <div className="tp-mono" style={{ marginTop: 14, padding: "6px 10px", borderRadius: 8, background: "rgba(255,255,255,.18)", border: "1px dashed rgba(255,255,255,.35)", fontWeight: 700, letterSpacing: ".15em", textAlign: "center", fontSize: 14 }}>BDAY100</div>
        </div>
      </div>
    </div>
  );
};

// === 20 · Staff Management ===
const StaffScreen = () => {
  const staff = [
    { name: "นัทธมน ปัญญาวิทย์", nick: "นัท", role: "ผู้จัดการสาขา", branch: "สยาม", on: true, hours: "07:00–19:00", sales: "฿42,580", c: "270" },
    { name: "ณัฐภัทร เพิ่มศรี", nick: "เก่ง", role: "แคชเชียร์", branch: "สยาม", on: true, hours: "08:00–17:00", sales: "฿18,420", c: "188" },
    { name: "พิชชา ภูริทัตต์", nick: "พิช", role: "บาริสต้า", branch: "สยาม", on: true, hours: "06:30–15:30", sales: "฿14,580", c: "145" },
    { name: "ธีรเทพ มงคลรัตน์", nick: "เต้", role: "ไรเดอร์", branch: "สยาม", on: true, hours: "09:00–20:00", sales: "฿8,420", c: "80" },
    { name: "สุนิสา จันทรา", nick: "ฝน", role: "บาริสต้า", branch: "สยาม", on: false, hours: "วันหยุด", sales: "—", c: "230" },
    { name: "ณภัทร ศิริสุข", nick: "นัท", role: "พนักงานเสิร์ฟ", branch: "อโศก", on: true, hours: "10:00–22:00", sales: "฿9,820", c: "25" },
    { name: "อัจฉรา ดวงสว่าง", nick: "หลิน", role: "บาริสต้า", branch: "อโศก", on: true, hours: "07:00–16:00", sales: "฿16,240", c: "188" },
    { name: "ภูธเนศ จำเริญ", nick: "เนศ", role: "แคชเชียร์", branch: "อโศก", on: false, hours: "วันหยุด", sales: "—", c: "230" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_h("ระบบพนักงาน", "8 คน · กำลังทำงาน 6 · กะเช้า 4 / กะบ่าย 2",
        <div style={{ display: "flex", gap: 8 }}>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="clock" size={16}/> ตารางกะ</button>
          <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="receipt" size={16}/> เงินเดือน</button>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="plus" size={16}/> เพิ่มพนักงาน</button>
        </div>
      )}

      {/* KPIs */}
      <div style={{ position: "absolute", left: 24, right: 24, top: 116, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 16 }}>
        {[
          { l: "พนักงานทั้งหมด", v: "24 คน", c: "270" },
          { l: "กำลังทำงาน", v: "16 คน", c: "145" },
          { l: "ยอดขาย/คน เฉลี่ย", v: "฿14,580", c: "188" },
          { l: "เงินเดือนเดือนนี้", v: "฿184,000", c: "80" },
        ].map((k, i) => (
          <div key={i} className="tp-glass" style={{ padding: "18px 22px" }}>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>{k.l}</div>
            <div className="tp-tnum" style={{ fontSize: 28, fontWeight: 600, letterSpacing: "-.02em", marginTop: 4, color: `oklch(.40 .14 ${k.c})` }}>{k.v}</div>
          </div>
        ))}
      </div>

      {/* Left: staff table */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 240, right: 380, bottom: 24, padding: 20, display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
          <div style={{ flex: "0 0 280px", height: 38, background: "white", borderRadius: 12, border: "1px solid var(--tp-line)", display: "flex", alignItems: "center", padding: "0 14px", gap: 8 }}>
            <TPIcon name="search" size={14} color="var(--tp-ink-mute)"/>
            <input placeholder="ค้นหาชื่อ / ตำแหน่ง..." style={{ flex: 1, border: "none", background: "transparent", outline: "none", fontFamily: "inherit", fontSize: 13 }}/>
          </div>
          <div style={{ flex: 1 }}/>
          {["ทั้งหมด", "ผู้จัดการ", "แคชเชียร์", "บาริสต้า", "ไรเดอร์"].map((t, i) => (
            <span key={i} className={i === 0 ? "tp-chip tp-chip-active" : "tp-chip"} style={{ marginLeft: 4 }}>{t}</span>
          ))}
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "44px 2.2fr 1.2fr 1fr 1fr 1.1fr 80px", gap: 12, padding: "10px 14px", fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".05em", borderBottom: "1px solid rgba(20,40,80,.08)" }}>
          <span></span><span>ชื่อ</span><span>ตำแหน่ง</span><span>สาขา</span><span>เวลาทำงาน</span><span style={{ textAlign: "right" }}>ยอดวันนี้</span><span></span>
        </div>
        <div className="tp-scroll" style={{ flex: 1, overflow: "auto" }}>
          {staff.map((s, i) => (
            <div key={i} style={{ display: "grid", gridTemplateColumns: "44px 2.2fr 1.2fr 1fr 1fr 1.1fr 80px", gap: 12, padding: "12px 14px", alignItems: "center", borderBottom: "1px dashed rgba(20,40,80,.06)", fontSize: 13 }}>
              <div style={{ position: "relative" }}>
                <div style={{
                  width: 36, height: 36, borderRadius: "50%",
                  background: `linear-gradient(160deg, oklch(.85 .14 ${s.c}), oklch(.55 .14 ${s.c}))`,
                  color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                  fontSize: 13, fontWeight: 700,
                  boxShadow: `0 4px 10px -4px oklch(.55 .14 ${s.c} / .5)`
                }}>{s.nick.slice(0, 1)}</div>
                <div style={{
                  position: "absolute", right: -2, bottom: -2,
                  width: 12, height: 12, borderRadius: "50%",
                  background: s.on ? "oklch(.62 .14 150)" : "oklch(.75 .03 230)",
                  border: "2px solid white"
                }}/>
              </div>
              <div>
                <div style={{ fontWeight: 500 }}>{s.name}</div>
                <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>เล่น "{s.nick}"</div>
              </div>
              <span className="tp-chip" style={{ height: 24, fontSize: 11, padding: "0 10px" }}>{s.role}</span>
              <span style={{ color: "var(--tp-ink-soft)" }}>{s.branch}</span>
              <span className="tp-mono" style={{ fontSize: 12, color: s.on ? "var(--tp-ink)" : "var(--tp-ink-mute)" }}>{s.hours}</span>
              <span className="tp-tnum" style={{ textAlign: "right", fontWeight: 600 }}>{s.sales}</span>
              <div style={{ display: "flex", gap: 4, justifyContent: "flex-end" }}>
                <button style={{ width: 28, height: 28, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)" }}><TPIcon name="more" size={13}/></button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Right: schedule + leaderboard */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 240, width: 332, height: 320, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตารางกะวันนี้</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 14 }}>กะ 08 พ.ค.</div>
        {/* timeline */}
        {["นัท", "เก่ง", "พิช", "เต้"].map((n, i) => {
          const slots = [[7, 19], [8, 17], [6.5, 15.5], [9, 20]];
          const [s, e] = slots[i];
          const left = ((s - 6) / 14) * 100;
          const width = ((e - s) / 14) * 100;
          const colors = ["270", "188", "145", "80"];
          return (
            <div key={i} style={{ display: "flex", alignItems: "center", marginBottom: 10 }}>
              <span style={{ width: 32, fontSize: 11, fontWeight: 600, color: "var(--tp-ink-soft)" }}>{n}</span>
              <div style={{ flex: 1, height: 22, background: "rgba(20,40,80,.05)", borderRadius: 6, position: "relative" }}>
                <div style={{ position: "absolute", left: `${left}%`, width: `${width}%`, top: 0, bottom: 0, borderRadius: 6, background: `linear-gradient(90deg, oklch(.78 .12 ${colors[i]}), oklch(.55 .14 ${colors[i]}))`, color: "white", fontSize: 10, fontWeight: 600, display: "flex", alignItems: "center", paddingLeft: 6, fontFamily: "var(--tp-font-mono)" }}>{s}–{e}</div>
              </div>
            </div>
          );
        })}
        <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, fontSize: 10, color: "var(--tp-ink-mute)", fontFamily: "var(--tp-font-mono)" }}>
          {["06", "10", "14", "18", "22"].map(t => <span key={t}>{t}h</span>)}
        </div>
      </div>

      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 580, width: 332, bottom: 24, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ตารางผู้นำ</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 12 }}>Top วันนี้</div>
        {[
          { n: "นัทธมน", s: "฿42,580", trophy: "🥇", c: "80" },
          { n: "อัจฉรา", s: "฿16,240", trophy: "🥈", c: "230" },
          { n: "พิชชา", s: "฿14,580", trophy: "🥉", c: "25" },
          { n: "ณัฐภัทร", s: "฿18,420", trophy: "4", c: "270" },
        ].map((s, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", padding: "10px 0", borderBottom: i < 3 ? "1px dashed var(--tp-line)" : "none", gap: 10 }}>
            <div style={{
              width: 28, height: 28, borderRadius: "50%",
              background: i < 3 ? `linear-gradient(160deg, oklch(.85 .14 ${s.c}), oklch(.55 .14 ${s.c}))` : "oklch(.94 .03 230)",
              color: i < 3 ? "white" : "var(--tp-ink-mute)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontWeight: 700, fontSize: 12,
            }}>{i + 1}</div>
            <span style={{ flex: 1, fontSize: 13, fontWeight: 500 }}>{s.n}</span>
            <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>{s.s}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

// === 21 · Admin Settings ===
const AdminScreen = () => {
  const sections = [
    { i: "shop", t: "ข้อมูลร้านค้า", c: "188" },
    { i: "users", t: "ผู้ใช้ & สิทธิ์", c: "270" },
    { i: "tax", t: "ภาษี & ใบกำกับ", c: "25" },
    { i: "branch", t: "สาขา", c: "145" },
    { i: "device", t: "อุปกรณ์ POS", c: "80" },
    { i: "payment", t: "ช่องทางชำระ", c: "188" },
    { i: "integration", t: "เชื่อมต่อระบบ", c: "230" },
    { i: "security", t: "ความปลอดภัย", c: "25" },
    { i: "backup", t: "สำรองข้อมูล", c: "270" },
  ];
  const sectIcon = { shop: "tag", users: "users", tax: "receipt", branch: "pin", device: "monitor", payment: "card", integration: "split", security: "settings", backup: "box" };

  const roles = [
    { r: "เจ้าของร้าน (Owner)", count: 1, p: ["ทั้งหมด"], c: "270", desc: "เข้าถึงทุกระบบ ทุกสาขา" },
    { r: "ผู้จัดการสาขา", count: 3, p: ["ขาย", "พนักงาน", "คลัง", "รายงาน"], c: "188", desc: "จัดการสาขาที่ดูแล" },
    { r: "หัวหน้าแคชเชียร์", count: 2, p: ["ขาย", "ส่วนลด", "Void"], c: "145", desc: "อนุมัติส่วนลด/ยกเลิกบิล" },
    { r: "แคชเชียร์", count: 8, p: ["ขาย", "พิมพ์ใบเสร็จ"], c: "80", desc: "ขายเท่านั้น" },
    { r: "บาริสต้า / ครัว", count: 6, p: ["KDS"], c: "25", desc: "ดูเฉพาะหน้าครัว" },
    { r: "ไรเดอร์", count: 4, p: ["เดลิเวอรี่"], c: "230", desc: "อัปเดตสถานะส่ง" },
  ];

  const toggles = [
    { l: "เปิดใช้ระบบสมาชิก", on: true },
    { l: "บังคับให้ปิดกะก่อนล็อกเอาต์", on: true },
    { l: "อนุมัติ Void อัตโนมัติ < ฿100", on: false },
    { l: "พิมพ์ใบเสร็จอัตโนมัติ", on: true },
    { l: "ส่ง e-Tax ทันทีหลังจ่าย", on: true },
    { l: "เก็บ log ทุกธุรกรรม 7 ปี", on: true },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>
      {_h("ระบบแอดมิน · ตั้งค่า", "ผู้ใช้ 24 คน · 5 สาขา · 12 อุปกรณ์ · เวอร์ชัน 4.2.1",
        <div style={{ display: "flex", gap: 8 }}>
          <span className="tp-chip" style={{ background: "oklch(.94 .08 145)", color: "oklch(.45 .14 150)", border: "1px solid oklch(.85 .10 150)" }}><TPIcon name="check" size={13}/> เชื่อมต่อปกติ</span>
          <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="check" size={16}/> บันทึกการตั้งค่า</button>
        </div>
      )}

      {/* Left sidebar */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 260, bottom: 24, padding: 14 }}>
        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".08em", padding: "8px 10px" }}>ตั้งค่าระบบ</div>
        {sections.map((s, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 10,
            padding: "11px 12px", marginBottom: 4, borderRadius: 11,
            cursor: "pointer", fontSize: 13, fontWeight: 500,
            background: i === 1 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent",
            color: i === 1 ? "white" : "var(--tp-ink-soft)",
            boxShadow: i === 1 ? "0 6px 14px -8px oklch(.25 .07 265 / .55)" : "none"
          }}>
            <div style={{
              width: 28, height: 28, borderRadius: 8,
              background: i === 1 ? "rgba(255,255,255,.2)" : `oklch(.94 .07 ${s.c})`,
              color: i === 1 ? "white" : `oklch(.45 .14 ${s.c})`,
              display: "flex", alignItems: "center", justifyContent: "center"
            }}><TPIcon name={sectIcon[s.i]} size={14}/></div>
            <span style={{ flex: 1 }}>{s.t}</span>
            <TPIcon name="arrow-right" size={12} color={i === 1 ? "white" : "var(--tp-ink-mute)"}/>
          </div>
        ))}
      </div>

      {/* Center: roles table (active section: Users) */}
      <div className="tp-glass" style={{ position: "absolute", left: 304, top: 116, right: 380, bottom: 24, padding: 22 }}>
        <div style={{ display: "flex", alignItems: "flex-end", marginBottom: 18 }}>
          <div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ผู้ใช้ & บทบาท</div>
            <div style={{ fontSize: 22, fontWeight: 700, marginTop: 2 }}>Roles & Permissions</div>
            <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 4 }}>กำหนดสิทธิ์เข้าถึงแต่ละหน้าของระบบสำหรับแต่ละบทบาท</div>
          </div>
          <div style={{ flex: 1 }}/>
          <button className="tp-btn tp-btn-ghost" style={{ height: 38 }}><TPIcon name="plus" size={14}/> สร้างบทบาท</button>
        </div>

        <div style={{ display: "grid", gap: 10 }}>
          {roles.map((r, i) => (
            <div key={i} style={{
              padding: "14px 18px", borderRadius: 14,
              background: "white", border: "1px solid var(--tp-line)",
              boxShadow: "0 4px 10px -6px rgba(20,40,80,.08)",
              borderLeft: `4px solid oklch(.65 .14 ${r.c})`,
              display: "flex", alignItems: "center", gap: 14
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 12,
                background: `linear-gradient(160deg, oklch(.85 .14 ${r.c}), oklch(.55 .14 ${r.c}))`,
                color: "white", display: "flex", alignItems: "center", justifyContent: "center",
                fontWeight: 700, fontSize: 16,
                boxShadow: `0 4px 10px -4px oklch(.55 .14 ${r.c} / .5)`
              }}>{r.count}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>{r.r}</div>
                <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", marginTop: 2 }}>{r.desc}</div>
              </div>
              <div style={{ display: "flex", gap: 4, flexWrap: "wrap", maxWidth: 320, justifyContent: "flex-end" }}>
                {r.p.map((perm, j) => (
                  <span key={j} className="tp-chip" style={{ height: 22, fontSize: 10, padding: "0 8px", background: `oklch(.94 .07 ${r.c})`, color: `oklch(.40 .14 ${r.c})`, borderColor: `oklch(.85 .08 ${r.c})` }}>{perm}</span>
                ))}
              </div>
              <button style={{ width: 30, height: 30, borderRadius: 8, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--tp-ink-soft)" }}><TPIcon name="more" size={14}/></button>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 22, padding: 16, borderRadius: 14, background: "oklch(.96 .03 220)", border: "1px solid oklch(.85 .04 220)", display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, background: "linear-gradient(160deg, oklch(.78 .12 195), oklch(.55 .14 220))", color: "white", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <TPIcon name="settings" size={16}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 600 }}>Matrix สิทธิ์การใช้งาน</div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>กดเพื่อเปิดตารางสิทธิ์ละเอียด — กำหนด Read/Write/Approve รายฟีเจอร์</div>
          </div>
          <button className="tp-btn tp-btn-ghost" style={{ height: 36 }}>เปิดตาราง</button>
        </div>
      </div>

      {/* Right: toggles + audit log */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 332, height: 360, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>การตั้งค่าด่วน</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 14 }}>Quick Settings</div>
        {toggles.map((t, i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", padding: "8px 0", borderBottom: i < toggles.length - 1 ? "1px dashed var(--tp-line)" : "none" }}>
            <span style={{ flex: 1, fontSize: 13 }}>{t.l}</span>
            <div style={{
              width: 38, height: 22, borderRadius: 999,
              background: t.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)",
              position: "relative", cursor: "pointer",
              boxShadow: t.on ? "inset 0 1px 0 rgba(255,255,255,.25), 0 4px 10px -4px oklch(.50 .14 220 / .5)" : "inset 0 1px 2px rgba(20,40,80,.08)",
              transition: "all .2s"
            }}>
              <div style={{ position: "absolute", top: 2, left: t.on ? 18 : 2, width: 18, height: 18, borderRadius: "50%", background: "white", boxShadow: "0 2px 4px rgba(20,40,80,.2)", transition: "all .2s" }}/>
            </div>
          </div>
        ))}
      </div>

      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 496, width: 332, bottom: 24, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>Audit Log</div>
        <div style={{ fontSize: 17, fontWeight: 600, marginTop: 2, marginBottom: 12 }}>กิจกรรมล่าสุด</div>
        {[
          { u: "นัท", a: "อนุมัติ Void บิล A1038", t: "14:42", c: "25" },
          { u: "เก่ง", a: "ใช้คูปอง WELCOME50", t: "14:38", c: "188" },
          { u: "Owner", a: "เพิ่มผู้ใช้ ฝน (บาริสต้า)", t: "13:20", c: "270" },
          { u: "นัท", a: "เปลี่ยนราคา ชาไทย ฿55→฿65", t: "12:14", c: "80" },
        ].map((l, i) => (
          <div key={i} style={{ display: "flex", padding: "10px 0", borderBottom: i < 3 ? "1px dashed var(--tp-line)" : "none", gap: 10 }}>
            <div style={{ width: 28, height: 28, borderRadius: "50%", background: `linear-gradient(160deg, oklch(.85 .12 ${l.c}), oklch(.55 .14 ${l.c}))`, color: "white", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 11, flexShrink: 0 }}>{l.u.slice(0, 1)}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12, fontWeight: 500 }}>{l.u} · {l.a}</div>
              <div className="tp-mono" style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>วันนี้ {l.t}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

window.StockManagementScreen = StockManagementScreen;
window.ShippingProvidersScreen = ShippingProvidersScreen;
window.CouponScreen = CouponScreen;
window.StaffScreen = StaffScreen;
window.AdminScreen = AdminScreen;

// Thaiprompt POS — Table ordering: Floor Plan Designer + Customer self-order + Live status

// === 30 · Floor Plan Designer (owner draws layout) ===
const FloorPlanDesignerScreen = () => {
  // grid units = 16px; canvas 800x540 internal
  const tables = [
    { id: "T1", x: 60, y: 50, w: 70, h: 70, seats: 2, shape: "circle" },
    { id: "T2", x: 160, y: 50, w: 70, h: 70, seats: 2, shape: "circle" },
    { id: "T3", x: 260, y: 50, w: 110, h: 70, seats: 4, shape: "rect" },
    { id: "T4", x: 400, y: 50, w: 110, h: 70, seats: 4, shape: "rect" },
    { id: "T5", x: 540, y: 50, w: 110, h: 70, seats: 4, shape: "rect" },
    { id: "T6", x: 60, y: 200, w: 90, h: 90, seats: 4, shape: "circle" },
    { id: "T7", x: 180, y: 200, w: 90, h: 90, seats: 4, shape: "circle", selected: true },
    { id: "T8", x: 320, y: 200, w: 130, h: 90, seats: 6, shape: "rect" },
    { id: "T9", x: 480, y: 200, w: 130, h: 90, seats: 6, shape: "rect" },
    { id: "T10", x: 640, y: 200, w: 90, h: 90, seats: 4, shape: "circle" },
    { id: "T11", x: 60, y: 350, w: 150, h: 70, seats: 6, shape: "rect" },
    { id: "T12", x: 240, y: 350, w: 150, h: 70, seats: 6, shape: "rect" },
    { id: "VIP", x: 430, y: 340, w: 200, h: 110, seats: 8, shape: "vip" },
  ];

  // walls & zones
  const zones = [
    { x: 0, y: 0, w: 800, h: 15, type: "wall" },
    { x: 0, y: 525, w: 800, h: 15, type: "wall" },
    { x: 0, y: 0, w: 15, h: 540, type: "wall" },
    { x: 785, y: 0, w: 15, h: 540, type: "wall" },
    { x: 15, y: 470, w: 770, h: 55, type: "bar", label: "บาร์ / Counter" },
    { x: 660, y: 320, w: 125, h: 145, type: "wc", label: "WC" },
  ];

  return (
    <div className="tp-app" style={{ width: 1440, height: 900, position: "relative", overflow: "hidden" }}>
      <div className="tp-bg"/>

      {/* header */}
      <header className="tp-glass" style={{ position: "absolute", left: 24, right: 24, top: 24, height: 76, display: "flex", alignItems: "center", padding: "0 22px", gap: 16 }}>
        <TPLogo size={42}/>
        <div>
          <div style={{ fontSize: 17, fontWeight: 600 }}>ออกแบบผังร้าน · Floor Plan Designer</div>
          <div style={{ fontSize: 12, color: "var(--tp-ink-mute)" }}>สยาม สแควร์ · ชั้น 1 · 12 โต๊ะ + 1 VIP · บันทึกล่าสุด 14:30</div>
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: "flex", background: "rgba(255,255,255,.5)", borderRadius: 12, padding: 4, gap: 2, border: "1px solid rgba(255,255,255,.6)" }}>
          {["ชั้น 1", "ชั้น 2", "ระเบียง"].map((t, i) => (
            <button key={i} style={{ padding: "8px 16px", borderRadius: 9, border: "none", cursor: "pointer", fontFamily: "inherit", fontSize: 13, fontWeight: 500, background: i === 0 ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "transparent", color: i === 0 ? "white" : "var(--tp-ink-soft)" }}>{t}</button>
          ))}
        </div>
        <button className="tp-btn tp-btn-ghost" style={{ height: 42 }}><TPIcon name="qr" size={16}/> สร้าง QR ทุกโต๊ะ</button>
        <button className="tp-btn tp-btn-primary" style={{ height: 42 }}><TPIcon name="check" size={16}/> บันทึก & เผยแพร่</button>
      </header>

      {/* Left palette */}
      <div className="tp-glass" style={{ position: "absolute", left: 24, top: 116, width: 232, bottom: 24, padding: 16 }}>
        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>ลากวางลงบนผัง</div>
        <div style={{ fontSize: 16, fontWeight: 700, marginTop: 2, marginBottom: 12 }}>เครื่องมือ</div>

        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginBottom: 8 }}>โต๊ะ</div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 14 }}>
          {[
            { l: "กลม 2", sh: "circle", s: 2 },
            { l: "กลม 4", sh: "circle", s: 4 },
            { l: "เหลี่ยม 4", sh: "rect", s: 4 },
            { l: "เหลี่ยม 6", sh: "rect", s: 6 },
            { l: "บูธ 4", sh: "booth", s: 4 },
            { l: "บาร์เคาน์เตอร์", sh: "bar", s: 1 },
          ].map((t, i) => (
            <div key={i} style={{
              padding: "10px 6px", borderRadius: 10,
              background: "white", border: "1px solid var(--tp-line)",
              boxShadow: "0 2px 6px -3px rgba(20,40,80,.08)",
              cursor: "grab",
              display: "flex", flexDirection: "column", alignItems: "center", gap: 6
            }}>
              <div style={{
                width: 36, height: 28,
                borderRadius: t.sh === "circle" ? "50%" : 6,
                background: "linear-gradient(160deg, oklch(.92 .04 220), oklch(.85 .05 230))",
                border: "1.5px solid oklch(.62 .14 195)",
                boxShadow: "inset 0 1px 0 rgba(255,255,255,.7)",
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 9, fontWeight: 700, color: "oklch(.45 .14 220)",
              }}>{t.s}</div>
              <span style={{ fontSize: 10, fontWeight: 500 }}>{t.l}</span>
            </div>
          ))}
        </div>

        <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginBottom: 8 }}>โครงสร้าง</div>
        <div style={{ display: "grid", gap: 6 }}>
          {[
            { l: "ผนัง / กำแพง", c: "230", icon: "split" },
            { l: "ประตู", c: "188", icon: "arrow-right" },
            { l: "บาร์ / Counter", c: "80", icon: "tag" },
            { l: "WC / ห้องน้ำ", c: "270", icon: "user" },
            { l: "พื้นที่ครัว", c: "25", icon: "fire" },
            { l: "Outdoor / สวน", c: "145", icon: "leaf" },
          ].map((t, i) => (
            <button key={i} style={{
              display: "flex", alignItems: "center", gap: 10,
              padding: "9px 12px", borderRadius: 10,
              background: "white", border: "1px solid var(--tp-line)",
              cursor: "grab", fontFamily: "inherit", fontSize: 12, fontWeight: 500,
              textAlign: "left",
            }}>
              <div style={{ width: 26, height: 26, borderRadius: 7, background: `oklch(.94 .07 ${t.c})`, color: `oklch(.45 .14 ${t.c})`, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <TPIcon name={t.icon} size={13}/>
              </div>
              <span style={{ flex: 1 }}>{t.l}</span>
              <span style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>::</span>
            </button>
          ))}
        </div>

        <div style={{ marginTop: 14, padding: 10, borderRadius: 10, background: "oklch(.96 .04 220)", border: "1px dashed oklch(.78 .04 220)", fontSize: 11, color: "var(--tp-ink-soft)", lineHeight: 1.5 }}>
          <strong style={{ color: "var(--tp-ink)" }}>💡 เคล็ดลับ</strong><br/>
          ดับเบิ้ลคลิกโต๊ะเพื่อแก้จำนวนที่นั่ง · ลากจุดมุมเพื่อปรับขนาด · กด <span className="tp-mono" style={{ background: "rgba(20,40,80,.08)", padding: "1px 5px", borderRadius: 4 }}>R</span> หมุน 90°
        </div>
      </div>

      {/* Center: canvas */}
      <div className="tp-glass" style={{ position: "absolute", left: 272, top: 116, right: 332, bottom: 24, padding: 14, overflow: "hidden", display: "flex", flexDirection: "column" }}>
        {/* canvas toolbar */}
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10, paddingBottom: 10, borderBottom: "1px solid rgba(20,40,80,.06)" }}>
          <div style={{ display: "flex", gap: 2, background: "rgba(20,40,80,.04)", borderRadius: 8, padding: 3 }}>
            {[{ i: "arrow-right" }, { i: "split" }, { i: "plus" }, { i: "minus" }].map((b, i) => (
              <button key={i} style={{ width: 32, height: 28, borderRadius: 6, border: "none", cursor: "pointer", background: i === 0 ? "white" : "transparent", boxShadow: i === 0 ? "0 2px 4px -1px rgba(20,40,80,.1)" : "none", display: "flex", alignItems: "center", justifyContent: "center", color: i === 0 ? "var(--tp-ink)" : "var(--tp-ink-mute)" }}>
                <TPIcon name={b.i} size={14}/>
              </button>
            ))}
          </div>
          <span className="tp-chip">Snap to grid 16px</span>
          <span className="tp-chip">แสดงเลขโต๊ะ</span>
          <div style={{ flex: 1 }}/>
          <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>100% · 12 ม. × 8 ม.</span>
          <button style={{ width: 28, height: 28, borderRadius: 6, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name="minus" size={12}/></button>
          <button style={{ width: 28, height: 28, borderRadius: 6, border: "1px solid var(--tp-line)", background: "white", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}><TPIcon name="plus" size={12}/></button>
        </div>

        {/* canvas */}
        <div style={{ flex: 1, position: "relative", borderRadius: 12, background: `
          linear-gradient(rgba(20,40,80,.04) 1px, transparent 1px),
          linear-gradient(90deg, rgba(20,40,80,.04) 1px, transparent 1px),
          linear-gradient(180deg, oklch(.96 .015 220), oklch(.93 .02 215))
        `, backgroundSize: "16px 16px, 16px 16px, 100% 100%", border: "1px solid var(--tp-line)", overflow: "hidden", boxShadow: "inset 0 1px 0 rgba(255,255,255,.6), inset 0 0 30px rgba(20,40,80,.04)" }}>
          {/* zones */}
          {zones.map((z, i) => (
            <div key={i} style={{
              position: "absolute", left: z.x, top: z.y, width: z.w, height: z.h,
              background: z.type === "wall" ? "linear-gradient(180deg, oklch(.55 .04 250), oklch(.40 .04 250))"
                : z.type === "bar" ? "linear-gradient(180deg, oklch(.78 .10 80), oklch(.65 .12 80))"
                : "linear-gradient(160deg, oklch(.85 .07 270), oklch(.70 .10 270))",
              borderRadius: z.type === "wall" ? 0 : 8,
              boxShadow: z.type === "wall" ? "inset 0 1px 0 rgba(255,255,255,.3)" : "inset 0 1px 0 rgba(255,255,255,.5), 0 4px 10px -4px rgba(20,40,80,.2)",
              display: "flex", alignItems: "center", justifyContent: "center",
              color: "white", fontSize: 11, fontWeight: 600,
              fontFamily: z.label === "WC" ? "var(--tp-font-mono)" : "inherit",
              letterSpacing: ".05em"
            }}>{z.label}</div>
          ))}

          {/* tables */}
          {tables.map((t, i) => {
            const isVip = t.shape === "vip";
            const isCircle = t.shape === "circle";
            return (
              <div key={i} style={{
                position: "absolute", left: t.x, top: t.y, width: t.w, height: t.h,
                borderRadius: isCircle ? "50%" : isVip ? 20 : 12,
                background: t.selected
                  ? "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))"
                  : isVip
                    ? "linear-gradient(140deg, oklch(.50 .14 280), oklch(.32 .12 290))"
                    : "linear-gradient(160deg, oklch(.96 .03 220), oklch(.90 .04 220))",
                border: t.selected ? "2px solid oklch(.45 .14 230)" : isVip ? "1.5px solid oklch(.72 .14 80)" : "1.5px solid oklch(.65 .04 230)",
                boxShadow: t.selected
                  ? "0 0 0 4px oklch(.62 .14 195 / .25), 0 14px 28px -8px oklch(.45 .14 250 / .55), inset 0 1px 0 rgba(255,255,255,.4)"
                  : "inset 0 1px 0 rgba(255,255,255,.7), 0 6px 14px -6px rgba(20,40,80,.15)",
                color: t.selected || isVip ? "white" : "var(--tp-ink)",
                display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
                gap: 2, cursor: "move",
              }}>
                <span style={{ fontSize: isVip ? 18 : 13, fontWeight: 700 }}>{t.id}</span>
                <span style={{ fontSize: isVip ? 11 : 9, opacity: .8, display: "flex", alignItems: "center", gap: 2 }}>
                  <TPIcon name="users" size={isVip ? 11 : 9}/> {t.seats} ที่
                </span>
                {/* handles for selected */}
                {t.selected && (
                  <>
                    {[[0,0],[1,0],[0,1],[1,1]].map(([x,y], j) => (
                      <div key={j} style={{
                        position: "absolute",
                        [x === 0 ? "left" : "right"]: -5,
                        [y === 0 ? "top" : "bottom"]: -5,
                        width: 10, height: 10, borderRadius: 3,
                        background: "white", border: "2px solid oklch(.45 .14 230)",
                        boxShadow: "0 2px 4px rgba(20,40,80,.3)",
                        cursor: x === y ? "nwse-resize" : "nesw-resize"
                      }}/>
                    ))}
                  </>
                )}
              </div>
            );
          })}

          {/* kitchen indicator */}
          <div style={{ position: "absolute", left: 240, top: 320, width: 350, height: 130, borderRadius: 12, border: "2px dashed oklch(.65 .15 25 / .6)", background: "oklch(.96 .04 25 / .3)", display: "flex", alignItems: "center", justifyContent: "center", color: "oklch(.45 .15 25)", fontSize: 12, fontWeight: 600, pointerEvents: "none" }}>
            🔥 พื้นที่ครัว — ออเดอร์จะถูกส่งมาที่นี่
          </div>
        </div>
      </div>

      {/* Right: table properties + ordering settings */}
      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 116, width: 280, height: 380, padding: "20px 22px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 14 }}>
          <div style={{ width: 36, height: 36, borderRadius: 11, background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))", color: "white", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <TPIcon name="table" size={16}/>
          </div>
          <div>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>กำลังเลือก</div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>โต๊ะ T7</div>
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
          <div style={{ padding: "8px 12px", borderRadius: 10, background: "white", border: "1px solid var(--tp-line)" }}>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>รหัสโต๊ะ</div>
            <div className="tp-mono" style={{ fontSize: 14, fontWeight: 700, marginTop: 2 }}>T7</div>
          </div>
          <div style={{ padding: "8px 12px", borderRadius: 10, background: "white", border: "1px solid var(--tp-line)" }}>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>ที่นั่ง</div>
            <div className="tp-tnum" style={{ fontSize: 14, fontWeight: 700, marginTop: 2 }}>4</div>
          </div>
          <div style={{ padding: "8px 12px", borderRadius: 10, background: "white", border: "1px solid var(--tp-line)" }}>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>รูปทรง</div>
            <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>กลม</div>
          </div>
          <div style={{ padding: "8px 12px", borderRadius: 10, background: "white", border: "1px solid var(--tp-line)" }}>
            <div style={{ fontSize: 10, color: "var(--tp-ink-mute)" }}>โซน</div>
            <div style={{ fontSize: 13, fontWeight: 600, marginTop: 2 }}>หน้าต่าง</div>
          </div>
        </div>

        <div style={{ marginTop: 14, fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 6 }}>QR สำหรับลูกค้า</div>
        <div style={{ display: "flex", gap: 12, alignItems: "center", padding: "12px 14px", borderRadius: 12, background: "linear-gradient(140deg, oklch(.40 .14 250), oklch(.22 .08 270))", color: "white", boxShadow: "0 10px 22px -10px oklch(.30 .12 270 / .55)" }}>
          <div style={{ width: 56, height: 56, background: "white", padding: 5, borderRadius: 8, flexShrink: 0 }}>
            <div style={{ width: "100%", height: "100%", display: "grid", gridTemplateColumns: "repeat(7, 1fr)", gap: 1 }}>
              {Array.from({ length: 49 }).map((_, i) => <div key={i} style={{ background: (i * 17 + 7) % 3 ? "#0e1a30" : "white" }}/>)}
            </div>
          </div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 600 }}>order.thaiprompt.co/t7</div>
            <div style={{ fontSize: 10, opacity: .8, marginTop: 2 }}>สแกนเพื่อสั่งจากโต๊ะ</div>
            <div style={{ display: "flex", gap: 4, marginTop: 6 }}>
              <button style={{ padding: "3px 8px", fontSize: 10, borderRadius: 5, border: "1px solid rgba(255,255,255,.3)", background: "rgba(255,255,255,.15)", color: "white", cursor: "pointer", fontFamily: "inherit" }}><TPIcon name="printer" size={9} style={{ verticalAlign: "-1px", marginRight: 2 }}/> พิมพ์</button>
              <button style={{ padding: "3px 8px", fontSize: 10, borderRadius: 5, border: "1px solid rgba(255,255,255,.3)", background: "rgba(255,255,255,.15)", color: "white", cursor: "pointer", fontFamily: "inherit" }}>ดาวน์โหลด</button>
            </div>
          </div>
        </div>
      </div>

      <div className="tp-glass" style={{ position: "absolute", right: 24, top: 516, width: 280, bottom: 24, padding: "20px 22px" }}>
        <div style={{ fontSize: 12, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>การตั้งค่า Order</div>
        <div style={{ fontSize: 16, fontWeight: 700, marginTop: 2, marginBottom: 12 }}>Self-Order Flow</div>

        {[
          { l: "ลูกค้าสั่งจากโต๊ะได้", on: true },
          { l: "ต้องล็อกอินด้วยเบอร์โทร", on: false },
          { l: "ส่งครัวทันที (ไม่ต้องยืนยัน)", on: true },
          { l: "แสดงสถานะออเดอร์สด", on: true },
          { l: "เรียกพนักงานจากโต๊ะได้", on: true },
          { l: "ชำระเงินที่โต๊ะ (Pay-at-table)", on: true },
        ].map((t, i, arr) => (
          <div key={i} style={{ display: "flex", alignItems: "center", padding: "9px 0", borderBottom: i < arr.length - 1 ? "1px dashed var(--tp-line)" : "none" }}>
            <span style={{ flex: 1, fontSize: 12 }}>{t.l}</span>
            <div style={{ width: 34, height: 20, borderRadius: 999, background: t.on ? "linear-gradient(90deg, oklch(.62 .14 195), oklch(.50 .14 220))" : "oklch(.85 .02 230)", position: "relative", cursor: "pointer", boxShadow: t.on ? "inset 0 1px 0 rgba(255,255,255,.25)" : "inset 0 1px 2px rgba(20,40,80,.1)" }}>
              <div style={{ position: "absolute", top: 2, left: t.on ? 16 : 2, width: 16, height: 16, borderRadius: "50%", background: "white", boxShadow: "0 2px 4px rgba(20,40,80,.2)" }}/>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// === 31 · Customer Self-Order (mobile, scanned table QR) ===
const SelfOrderScreen = () => {
  const cats = [
    { l: "ขายดี", on: true, icon: "fire" },
    { l: "ของเย็น", on: false, icon: "leaf" },
    { l: "ของร้อน", on: false, icon: "coffee" },
    { l: "เบเกอรี่", on: false, icon: "tag" },
    { l: "ของหวาน", on: false, icon: "star" },
  ];
  const menu = [
    { n: "ชาไทยเย็น", desc: "ใบชาเก่าหมัก + นมข้น", price: 65, hue: 25, kind: "rect", tag: "ขายดี" },
    { n: "ชาเขียวมัทฉะลาเต้", desc: "ผงมัทฉะนำเข้า + นมโอ๊ต", price: 95, hue: 145, kind: "circle", tag: "ใหม่" },
    { n: "อเมริกาโน่เย็น", desc: "Single origin · เข้ม", price: 70, hue: 35, kind: "rect" },
    { n: "โกโก้ปั่น", desc: "ผงโกโก้เบลเยี่ยม + วิป", price: 80, hue: 28, kind: "rect", tag: "พรีเมียม" },
  ];

  return (
    <div className="tp-app" style={{ width: 390, height: 844, position: "relative", overflow: "hidden", background: "white", borderRadius: 44 }}>
      <div className="tp-bg" style={{ borderRadius: 44 }}/>

      {/* status bar */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 50, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 30px", fontSize: 14, fontWeight: 600 }}>
        <span className="tp-mono">19:42</span>
        <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
          <TPIcon name="wifi" size={14}/>
          <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" strokeWidth="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/></svg>
        </div>
      </div>

      {/* table header */}
      <div style={{
        position: "absolute", top: 50, left: 0, right: 0,
        padding: "16px 18px 14px",
        background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))",
        color: "white", borderRadius: "0 0 22px 22px",
        boxShadow: "0 10px 24px -10px oklch(.45 .14 250 / .55)",
        position: "absolute", overflow: "hidden",
      }}>
        <div style={{ position: "absolute", right: -20, top: -20, width: 100, height: 100, borderRadius: "50%", background: "radial-gradient(circle, oklch(.85 .14 80 / .45), transparent 70%)" }}/>
        <div style={{ display: "flex", alignItems: "center", gap: 12, position: "relative" }}>
          <TPLogo size={36}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12, opacity: .85 }}>ยินดีต้อนรับสู่</div>
            <div style={{ fontSize: 16, fontWeight: 700 }}>ไทยพร้อม คาเฟ่ · สยาม</div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: 10, opacity: .8 }}>โต๊ะ</div>
            <div style={{ fontSize: 22, fontWeight: 800, lineHeight: 1 }}>T7</div>
          </div>
        </div>
        <div style={{ marginTop: 10, display: "flex", gap: 6, position: "relative" }}>
          <span style={{ padding: "4px 10px", borderRadius: 999, fontSize: 11, fontWeight: 500, background: "rgba(255,255,255,.18)", border: "1px solid rgba(255,255,255,.3)" }}>
            <TPIcon name="users" size={11} style={{ verticalAlign: "-1px", marginRight: 3 }}/> 2 ท่าน
          </span>
          <span style={{ padding: "4px 10px", borderRadius: 999, fontSize: 11, fontWeight: 500, background: "rgba(255,255,255,.18)", border: "1px solid rgba(255,255,255,.3)" }}>
            <TPIcon name="clock" size={11} style={{ verticalAlign: "-1px", marginRight: 3 }}/> เริ่ม 19:18
          </span>
        </div>
      </div>

      {/* search */}
      <div style={{ position: "absolute", top: 196, left: 18, right: 18, height: 42, background: "white", borderRadius: 14, border: "1px solid var(--tp-line)", display: "flex", alignItems: "center", padding: "0 14px", gap: 10, boxShadow: "0 4px 12px -6px rgba(20,40,80,.12)" }}>
        <TPIcon name="search" size={15} color="var(--tp-ink-mute)"/>
        <span style={{ flex: 1, fontSize: 13, color: "var(--tp-ink-mute)" }}>ค้นหาเมนู...</span>
        <button style={{ width: 28, height: 28, borderRadius: 8, border: "none", background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
          <TPIcon name="qr" size={14}/>
        </button>
      </div>

      {/* category chips */}
      <div className="tp-scroll" style={{ position: "absolute", top: 250, left: 0, right: 0, padding: "0 18px", overflow: "auto", whiteSpace: "nowrap" }}>
        <div style={{ display: "inline-flex", gap: 6 }}>
          {cats.map((c, i) => (
            <span key={i} style={{
              display: "inline-flex", alignItems: "center", gap: 5,
              height: 34, padding: "0 14px", borderRadius: 999, cursor: "pointer",
              background: c.on ? "linear-gradient(180deg, oklch(.30 .08 265), oklch(.20 .06 270))" : "rgba(255,255,255,.7)",
              color: c.on ? "white" : "var(--tp-ink-soft)",
              border: c.on ? "none" : "1px solid var(--tp-line)",
              fontSize: 12, fontWeight: 600,
              boxShadow: c.on ? "0 4px 10px -4px oklch(.25 .07 265 / .5)" : "none"
            }}>
              <TPIcon name={c.icon} size={12}/> {c.l}
            </span>
          ))}
        </div>
      </div>

      {/* featured banner */}
      <div style={{
        position: "absolute", top: 296, left: 18, right: 18, height: 96, borderRadius: 18,
        background: "linear-gradient(140deg, oklch(.78 .14 28) 0%, oklch(.50 .14 25) 100%)",
        padding: "14px 16px", color: "white", overflow: "hidden",
        boxShadow: "0 12px 24px -10px oklch(.55 .18 25 / .55)"
      }}>
        <div style={{ position: "absolute", right: -10, bottom: -20, width: 110, height: 110, borderRadius: "50%", background: "radial-gradient(circle, oklch(.85 .14 80 / .55), transparent 70%)", filter: "blur(8px)" }}/>
        <div style={{ position: "absolute", right: 14, top: 14, width: 56, height: 56, borderRadius: "50%", background: "rgba(255,255,255,.2)", border: "1px solid rgba(255,255,255,.35)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20 }}>☕</div>
        <span style={{ display: "inline-block", padding: "2px 8px", fontSize: 9, fontWeight: 700, borderRadius: 999, background: "rgba(255,255,255,.22)", letterSpacing: ".15em" }}>โปรร้อนแรง</span>
        <div style={{ fontSize: 17, fontWeight: 700, marginTop: 6, letterSpacing: "-.01em" }}>ซื้อ 2 แก้ว ลด 30 บาท</div>
        <div style={{ fontSize: 10, opacity: .85, marginTop: 2 }}>ใส่โค้ด <span className="tp-mono" style={{ background: "rgba(255,255,255,.18)", padding: "1px 6px", borderRadius: 4 }}>TP-MAY30</span> ตอนชำระ</div>
      </div>

      {/* menu list */}
      <div className="tp-scroll" style={{ position: "absolute", top: 408, left: 0, right: 0, bottom: 122, padding: "0 18px", overflow: "auto" }}>
        <div style={{ fontSize: 13, fontWeight: 700, padding: "4px 0 10px" }}>เมนูขายดี <span style={{ fontWeight: 400, color: "var(--tp-ink-mute)", fontSize: 11 }}>· 4 รายการ</span></div>
        {menu.map((m, i) => (
          <div key={i} style={{
            display: "flex", gap: 12, padding: 10, borderRadius: 16, marginBottom: 8,
            background: "rgba(255,255,255,.72)", border: "1px solid rgba(255,255,255,.7)",
            boxShadow: "0 1px 0 rgba(255,255,255,.85) inset, 0 4px 10px -6px rgba(20,40,80,.12)",
          }}>
            <div style={{ width: 84, height: 84, borderRadius: 14, overflow: "hidden", flexShrink: 0, position: "relative" }}>
              <TPProductImg hue={m.hue} kind={m.kind}/>
              {m.tag && (
                <div style={{ position: "absolute", top: 6, left: 6, padding: "2px 6px", borderRadius: 999, fontSize: 8, fontWeight: 700, background: m.tag === "ใหม่" ? "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))" : m.tag === "พรีเมียม" ? "linear-gradient(180deg, oklch(.40 .07 270), oklch(.25 .06 265))" : "linear-gradient(180deg, oklch(.78 .18 28), oklch(.60 .18 25))", color: "white", letterSpacing: ".05em" }}>{m.tag}</div>
              )}
            </div>
            <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}>
              <div style={{ fontSize: 14, fontWeight: 600 }}>{m.n}</div>
              <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2, lineHeight: 1.3 }}>{m.desc}</div>
              <div style={{ flex: 1 }}/>
              <div style={{ display: "flex", alignItems: "center", marginTop: 6 }}>
                <span className="tp-tnum" style={{ fontSize: 16, fontWeight: 700, color: "var(--tp-teal-deep)" }}>฿{m.price}</span>
                <div style={{ flex: 1 }}/>
                <button style={{ width: 34, height: 34, borderRadius: 12, border: "none", background: "linear-gradient(180deg, oklch(.78 .14 188), oklch(.55 .13 195))", color: "white", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", boxShadow: "0 6px 14px -4px oklch(.55 .13 195 / .55), 0 1px 0 rgba(255,255,255,.4) inset" }}><TPIcon name="plus" size={16}/></button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* call waiter floating */}
      <button style={{
        position: "absolute", right: 18, bottom: 130,
        width: 48, height: 48, borderRadius: 24, border: "none",
        background: "white", boxShadow: "0 8px 20px -6px rgba(20,40,80,.25), 0 2px 4px rgba(20,40,80,.1)",
        display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer"
      }}>
        <TPIcon name="bell" size={20} color="oklch(.55 .18 25)"/>
      </button>

      {/* cart bar */}
      <div style={{
        position: "absolute", left: 14, right: 14, bottom: 24,
        borderRadius: 24, padding: "12px 16px",
        background: "linear-gradient(160deg, oklch(.78 .14 28) 0%, oklch(.55 .18 25) 100%)",
        color: "white",
        boxShadow: "0 1px 0 rgba(255,255,255,.4) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 18px 36px -12px oklch(.55 .18 25 / .55)",
        display: "flex", alignItems: "center", gap: 12
      }}>
        <div style={{ width: 44, height: 44, borderRadius: 14, background: "rgba(255,255,255,.22)", display: "flex", alignItems: "center", justifyContent: "center", border: "1px solid rgba(255,255,255,.3)", position: "relative" }}>
          <TPIcon name="cart" size={22}/>
          <span style={{ position: "absolute", top: -4, right: -4, width: 20, height: 20, borderRadius: "50%", background: "white", color: "oklch(.55 .18 25)", fontSize: 11, fontWeight: 800, display: "flex", alignItems: "center", justifyContent: "center" }}>3</span>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 10, opacity: .85 }}>ในตะกร้า · 3 รายการ</div>
          <div style={{ fontSize: 17, fontWeight: 700 }}>฿245</div>
        </div>
        <button style={{ background: "rgba(255,255,255,.92)", color: "oklch(.45 .18 25)", border: "none", borderRadius: 16, padding: "11px 16px", fontFamily: "inherit", fontSize: 13, fontWeight: 700, cursor: "pointer", boxShadow: "0 1px 0 rgba(255,255,255,.95) inset, 0 6px 14px -4px rgba(20,40,80,.2)" }}>
          ส่งครัว <TPIcon name="arrow-right" size={14} style={{ verticalAlign: "-2px" }}/>
        </button>
      </div>

      <div style={{ position: "absolute", left: "50%", bottom: 6, transform: "translateX(-50%)", width: 134, height: 5, borderRadius: 999, background: "rgba(20,40,80,.4)" }}/>
    </div>
  );
};

// === 32 · Order Live Status (after submit) ===
const OrderStatusScreen = () => {
  return (
    <div className="tp-app" style={{ width: 390, height: 844, position: "relative", overflow: "hidden", background: "white", borderRadius: 44 }}>
      <div className="tp-bg" style={{ borderRadius: 44 }}/>

      {/* status bar */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 0, height: 50, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 30px", fontSize: 14, fontWeight: 600 }}>
        <span className="tp-mono">19:48</span>
        <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
          <TPIcon name="wifi" size={14}/>
          <svg width="22" height="11" viewBox="0 0 22 11"><rect x="0" y="0" width="18" height="11" rx="3" fill="none" stroke="currentColor" strokeWidth="1"/><rect x="2" y="2" width="13" height="7" rx="1.5" fill="currentColor"/></svg>
        </div>
      </div>

      {/* nav */}
      <div style={{ position: "absolute", top: 50, left: 0, right: 0, padding: "10px 18px", display: "flex", alignItems: "center", gap: 10 }}>
        <button style={{ width: 38, height: 38, borderRadius: 12, border: "1px solid var(--tp-line)", background: "rgba(255,255,255,.7)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <TPIcon name="arrow-right" size={16} style={{ transform: "rotate(180deg)" }}/>
        </button>
        <div>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>คำสั่งซื้อของคุณ</div>
          <div className="tp-mono" style={{ fontSize: 15, fontWeight: 700 }}>#A1042 · โต๊ะ T7</div>
        </div>
        <div style={{ flex: 1 }}/>
        <button style={{ width: 38, height: 38, borderRadius: 12, border: "1px solid var(--tp-line)", background: "rgba(255,255,255,.7)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <TPIcon name="bell" size={16}/>
        </button>
      </div>

      {/* status hero */}
      <div style={{
        position: "absolute", top: 110, left: 18, right: 18,
        borderRadius: 24, padding: "22px 22px",
        background: "linear-gradient(160deg, oklch(.78 .14 188), oklch(.45 .14 250))",
        color: "white", overflow: "hidden",
        boxShadow: "0 18px 36px -12px oklch(.45 .14 250 / .55)"
      }}>
        <div style={{ position: "absolute", right: -30, top: -30, width: 140, height: 140, borderRadius: "50%", background: "radial-gradient(circle, oklch(.85 .14 80 / .5), transparent 70%)", filter: "blur(8px)" }}/>
        <span style={{ display: "inline-flex", alignItems: "center", gap: 6, padding: "3px 10px", fontSize: 10, fontWeight: 700, borderRadius: 999, background: "rgba(255,255,255,.2)", border: "1px solid rgba(255,255,255,.35)", letterSpacing: ".1em", textTransform: "uppercase" }}>
          <span style={{ width: 6, height: 6, borderRadius: "50%", background: "oklch(.85 .14 80)", boxShadow: "0 0 8px oklch(.85 .14 80)" }}/> สด · กำลังเตรียม
        </span>
        <div style={{ fontSize: 26, fontWeight: 800, marginTop: 12, lineHeight: 1.1, letterSpacing: "-.02em" }}>
          ครัวกำลังทำอยู่ ✨
        </div>
        <div style={{ fontSize: 12, opacity: .85, marginTop: 6 }}>คาดว่าเสร็จในอีก <strong className="tp-mono">~6 นาที</strong> · เสิร์ฟที่โต๊ะ T7</div>

        {/* progress segments */}
        <div style={{ marginTop: 16, display: "flex", gap: 6 }}>
          {[1, 1, 1, 0, 0].map((d, i) => (
            <div key={i} style={{
              flex: 1, height: 5, borderRadius: 999,
              background: d ? "linear-gradient(90deg, oklch(.85 .14 80), oklch(.78 .14 28))" : "rgba(255,255,255,.18)",
            }}/>
          ))}
        </div>
      </div>

      {/* timeline */}
      <div style={{ position: "absolute", top: 326, left: 18, right: 18, bottom: 122, overflow: "auto" }} className="tp-scroll">
        <div className="tp-glass" style={{ padding: "16px 18px", marginBottom: 12 }}>
          <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em", marginBottom: 10 }}>ลำดับสถานะ</div>
          {[
            { l: "สั่งซื้อสำเร็จ", t: "19:42 · สั่งจากโต๊ะ", done: true, icon: "check" },
            { l: "ครัวรับออเดอร์", t: "19:43 · บาริสต้า: พิช", done: true, icon: "fire" },
            { l: "กำลังเตรียม", t: "19:45 · 3 จาก 3 รายการ", done: true, current: true, icon: "coffee" },
            { l: "พร้อมเสิร์ฟ", t: "รอ ~3 นาที", done: false, icon: "check" },
            { l: "เสิร์ฟแล้ว", t: "—", done: false, icon: "star" },
          ].map((s, i, arr) => (
            <div key={i} style={{ display: "flex", gap: 12 }}>
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
                <div style={{
                  width: 30, height: 30, borderRadius: "50%",
                  background: s.done
                    ? (s.current
                      ? "linear-gradient(160deg, oklch(.85 .14 80), oklch(.65 .14 28))"
                      : "linear-gradient(160deg, oklch(.78 .14 145), oklch(.50 .14 150))")
                    : "white",
                  border: s.done ? "none" : "1.5px solid var(--tp-line)",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  color: s.done ? "white" : "var(--tp-ink-mute)",
                  boxShadow: s.done ? "0 4px 10px -3px rgba(20,40,80,.25)" : "none",
                  position: "relative", flexShrink: 0
                }}>
                  <TPIcon name={s.icon} size={14}/>
                  {s.current && <div style={{ position: "absolute", inset: -4, borderRadius: "50%", border: "2px solid oklch(.85 .14 80 / .4)", animation: "" }}/>}
                </div>
                {i < arr.length - 1 && <div style={{ width: 2, flex: 1, background: s.done ? "linear-gradient(180deg, oklch(.78 .14 145), oklch(.50 .14 150))" : "var(--tp-line)", margin: "4px 0", minHeight: 22 }}/>}
              </div>
              <div style={{ flex: 1, paddingBottom: i < arr.length - 1 ? 18 : 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: s.done ? "var(--tp-ink)" : "var(--tp-ink-mute)" }}>{s.l}</div>
                <div className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)", marginTop: 2 }}>{s.t}</div>
              </div>
            </div>
          ))}
        </div>

        {/* order items */}
        <div className="tp-glass" style={{ padding: "14px 16px" }}>
          <div style={{ display: "flex", alignItems: "center", marginBottom: 10 }}>
            <div style={{ fontSize: 11, color: "var(--tp-ink-mute)", textTransform: "uppercase", letterSpacing: ".1em" }}>รายการ</div>
            <div style={{ flex: 1 }}/>
            <span className="tp-chip" style={{ height: 22, fontSize: 10, padding: "0 8px", background: "oklch(.94 .08 80)", color: "oklch(.40 .14 80)" }}>3 รายการ</span>
          </div>
          {[
            { n: "ชาไทยเย็น", note: "หวานน้อย ไม่เพิ่มไข่มุก", q: 2, p: 130, hue: 25, kind: "rect", st: "ทำแล้ว" },
            { n: "ชาเขียวมัทฉะลาเต้", note: "ขนาด L +10", q: 1, p: 95, hue: 145, kind: "circle", st: "กำลังทำ" },
            { n: "ครัวซองต์อัลมอนด์", note: "อุ่น", q: 1, p: 55, hue: 40, kind: "rect", st: "รอ" },
          ].map((it, i) => (
            <div key={i} style={{ display: "flex", gap: 10, padding: "10px 0", borderBottom: i < 2 ? "1px dashed var(--tp-line)" : "none", alignItems: "center" }}>
              <div style={{ width: 44, height: 44, borderRadius: 10, overflow: "hidden", flexShrink: 0 }}>
                <TPProductImg hue={it.hue} kind={it.kind}/>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                  <span style={{ fontSize: 13, fontWeight: 600 }}>{it.n}</span>
                  <span className="tp-mono" style={{ fontSize: 11, color: "var(--tp-ink-mute)" }}>×{it.q}</span>
                </div>
                <div style={{ fontSize: 10, color: "var(--tp-ink-mute)", marginTop: 1 }}>{it.note}</div>
                <span style={{ display: "inline-block", marginTop: 4, fontSize: 9, fontWeight: 700, padding: "2px 7px", borderRadius: 999,
                  background: it.st === "ทำแล้ว" ? "oklch(.94 .08 145)" : it.st === "กำลังทำ" ? "oklch(.94 .08 80)" : "oklch(.94 .03 230)",
                  color: it.st === "ทำแล้ว" ? "oklch(.45 .14 150)" : it.st === "กำลังทำ" ? "oklch(.45 .14 80)" : "var(--tp-ink-mute)"
                }}>{it.st}</span>
              </div>
              <span className="tp-tnum" style={{ fontSize: 13, fontWeight: 600 }}>฿{it.p}</span>
            </div>
          ))}
        </div>
      </div>

      {/* bottom actions */}
      <div style={{ position: "absolute", left: 14, right: 14, bottom: 24, display: "flex", gap: 8 }}>
        <button style={{
          flex: "0 0 auto", height: 56, padding: "0 16px", borderRadius: 18,
          background: "rgba(255,255,255,.85)", backdropFilter: "blur(12px)",
          border: "1px solid rgba(255,255,255,.7)",
          fontFamily: "inherit", fontSize: 12, fontWeight: 600, cursor: "pointer",
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
          color: "var(--tp-ink)",
          boxShadow: "0 8px 20px -8px rgba(20,40,80,.18)"
        }}>
          <TPIcon name="plus" size={16}/>
          <span style={{ fontSize: 10, marginTop: 2 }}>สั่งเพิ่ม</span>
        </button>
        <button style={{
          flex: 1, height: 56, borderRadius: 18, border: "none",
          background: "linear-gradient(160deg, oklch(.78 .14 28) 0%, oklch(.55 .18 25) 100%)",
          color: "white", fontFamily: "inherit", fontSize: 15, fontWeight: 700, cursor: "pointer",
          display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
          boxShadow: "0 1px 0 rgba(255,255,255,.4) inset, 0 -2px 0 rgba(0,0,0,.12) inset, 0 14px 28px -10px oklch(.55 .18 25 / .55)"
        }}>
          <TPIcon name="card" size={18}/> เรียกเก็บเงิน · ฿245
        </button>
      </div>

      <div style={{ position: "absolute", left: "50%", bottom: 6, transform: "translateX(-50%)", width: 134, height: 5, borderRadius: 999, background: "rgba(20,40,80,.4)" }}/>
    </div>
  );
};

window.FloorPlanDesignerScreen = FloorPlanDesignerScreen;
window.SelfOrderScreen = SelfOrderScreen;
window.OrderStatusScreen = OrderStatusScreen;

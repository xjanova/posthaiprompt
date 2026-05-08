# Sync API — Thaiprompt POS ↔ Thaiprompt-Affiliate

โปรแกรม POS ทำงานออฟไลน์เป็นค่าเริ่มต้น และซิงก์ข้อมูลกลับ
[Thaiprompt-Affiliate](https://github.com/xjanova/Thaiprompt-Affiliate) เมื่อมีเน็ต.

## หลักการ

1. **Outbox pattern** — write operations จาก POS ลง outbox queue ใน SQLite ก่อน
2. **Delta pull** — ดึง catalog/stock/promo เฉพาะที่เปลี่ยน (`?since=ts`)
3. **Idempotency-key** — ทุก mutation มี GUID, ป้องกัน duplicate
4. **Last-Write-Wins** — server ถือ `updatedAt`; ถ้า client เก่ากว่า → reject + return latest
5. **Authentication** — JWT short-lived (15 นาที) + refresh token rotating ต่อ device

---

## Endpoints

### Auth

| Method | Path                          | Body                             | Response                          |
|--------|-------------------------------|----------------------------------|-----------------------------------|
| POST   | `/api/pos/auth/pin`           | `{branchId, terminalId, pin}`    | `{token, refreshToken, user}`     |
| POST   | `/api/pos/auth/refresh`       | `{refreshToken}`                 | `{token, refreshToken}`           |
| POST   | `/api/pos/auth/logout`        | —                                | `204`                              |

### Catalog (read, delta)

| Method | Path                                           | Purpose                            |
|--------|------------------------------------------------|------------------------------------|
| GET    | `/api/pos/products?branchId=X&since=ISO8601`   | Products that changed since `since` |
| GET    | `/api/pos/categories?branchId=X&since=…`       | Categories                         |
| GET    | `/api/pos/promotions?branchId=X&since=…`       | Active promotions + coupons        |
| GET    | `/api/pos/branches/me`                         | Branch profile (logo, tax-id)      |

### Inventory

| Method | Path                                           | Body / Purpose                     |
|--------|------------------------------------------------|------------------------------------|
| GET    | `/api/pos/inventory/stock?branchId=X`          | Current stock per SKU              |
| POST   | `/api/pos/inventory/movements/sync`            | Push outbox stock movements        |

### Orders / Payments (write, outbox)

| Method | Path                                           | Body                               |
|--------|------------------------------------------------|------------------------------------|
| POST   | `/api/pos/orders/sync`                         | `[{idempotencyKey, order, lines}]`  |
| POST   | `/api/pos/payments/sync`                       | `[{idempotencyKey, payment}]`       |
| POST   | `/api/pos/orders/{id}/void`                    | `{reason, approvedBy}`              |

### Promotions

| Method | Path                                           | Purpose                            |
|--------|------------------------------------------------|------------------------------------|
| POST   | `/api/pos/promotions/redeem`                   | ตรวจ + lock คูปอง (online only)     |

### Reports

| Method | Path                                           | Purpose                            |
|--------|------------------------------------------------|------------------------------------|
| GET    | `/api/pos/reports/daily?date=YYYY-MM-DD`       | Daily summary                      |
| GET    | `/api/pos/reports/top-items?range=7d`          | Best selling                       |

---

## Sync sequence

```
┌────────────┐                 ┌─────────────────┐                 ┌──────────────────────┐
│  POS App   │                 │  SyncWorker     │                 │ Thaiprompt-Affiliate │
└─────┬──────┘                 └────────┬────────┘                 └──────────┬───────────┘
      │ user pays bill                   │                                    │
      │ ───────────────────────────────► │                                    │
      │ write order + payment to SQLite  │                                    │
      │ + insert OutboxMessage           │                                    │
      │                                  │                                    │
      │              every 30s + on net-up                                    │
      │                                  │ POST /orders/sync (batch ≤ 50)     │
      │                                  │ ─────────────────────────────────► │
      │                                  │                                    │
      │                                  │           200 OK [{id, status}]    │
      │                                  │ ◄───────────────────────────────── │
      │                                  │ mark outbox rows as Sent           │
      │                                  │                                    │
      │                                  │ GET /products?since=lastSync       │
      │                                  │ ─────────────────────────────────► │
      │                                  │                                    │
      │                                  │            200 OK [{...delta}]     │
      │                                  │ ◄───────────────────────────────── │
      │                                  │ upsert local SQLite                │
      │                                  │ update DeltaCursor.lastSyncAt      │
      │ ◄ EventBus.Publish(CatalogUpdated)                                    │
```

---

## Conflict resolution

```csharp
// Server side (Affiliate)
if (incoming.UpdatedAt < existing.UpdatedAt) {
    return Conflict(new { latest = existing });   // 409
}
existing = incoming;
```

```csharp
// Client side (POS)
if (response.StatusCode == 409) {
    var latest = response.Content.Latest;
    db.Upsert(latest);                          // accept server version
    AuditLog.Write("conflict-overridden", incoming.Id);
}
```

---

## Outbox schema

```sql
CREATE TABLE OutboxMessages (
    Id TEXT PRIMARY KEY,                  -- GUID = idempotency-key
    EntityType TEXT NOT NULL,             -- "Order" | "Payment" | "StockMovement" | "Void"
    EntityId TEXT NOT NULL,
    Payload TEXT NOT NULL,                -- JSON
    CreatedAt TEXT NOT NULL,              -- ISO 8601
    AttemptCount INTEGER DEFAULT 0,
    LastAttemptAt TEXT,
    LastError TEXT,
    Status TEXT NOT NULL                  -- "Pending" | "Sent" | "Failed"
);
CREATE INDEX IX_Outbox_Status ON OutboxMessages(Status, CreatedAt);
```

---

## Retry policy

```csharp
HttpPolicyExtensions.HandleTransientHttpError()
    .OrResult(r => r.StatusCode == HttpStatusCode.TooManyRequests)
    .WaitAndRetryAsync(
        retryCount: 5,
        sleepDurationProvider: attempt => TimeSpan.FromSeconds(
            Math.Min(60, Math.Pow(2, attempt) + Random.Shared.NextDouble())
        )
    );
```

หลัง retry 5 ครั้ง → mark `Failed` + แจ้ง user ผ่าน sync banner สีส้ม
("ซิงก์ไม่สำเร็จ · ลองใหม่"). Failed messages ถูก retry ทุก 5 นาทีต่อจากนั้น.

---

## Security

- **Token storage** — `SecureStorage` (MAUI) → Keychain (iOS), Keystore (Android), DPAPI (Windows)
- **Cert pinning** — บน mobile pin Affiliate root cert SHA-256
- **PIN hashing** — Argon2id, 64MB memory, 3 iterations, salt 16 bytes ต่อ device
- **No PII in logs** — full names ไม่อยู่ใน logs · เฉพาะ user-id (UUID)
- **Replay protection** — JWT มี `nonce` + server cache 60s

---

## Offline degradation matrix

| Feature             | Online | Offline                          |
|---------------------|--------|----------------------------------|
| ขาย / ตัดบิล        | ✅      | ✅ (queue ใน outbox)             |
| QR PromptPay        | ✅      | ❌ (force cash หรือ pending)      |
| คูปอง                | ✅      | ⚠ (ใช้ cached, lock เมื่อ sync)   |
| สมาชิก lookup       | ✅      | ⚠ (cached only, no new signup)   |
| รายงาน              | ✅      | ✅ (cached)                       |
| สต็อกอัพเดต         | ✅      | ✅ (queue, server reconcile)      |
| Multi-branch view   | ✅      | ❌                               |

# Anti-patterns — Payments Domain

## 1. Anemic Domain Model

**Symptom:** `Invoice` is a data struct with no behavior. All logic lives in
`InvoiceService`.

```typescript
// WRONG — Invoice with no behavior
class Invoice { status: string; tenantId: string; amount: number; }

// In InvoiceService — domain rule inlined in the service
if (invoice.status === 'OPEN') {
  invoice.status = 'CONFIRMED';  // no invariant validation
}
```

**Fix:** move transition logic to `invoice.confirm()` and `invoice.cancel()`.
The aggregate enforces invariants. `InvoiceService` only orchestrates.

---

## 2. God Service

**Symptom:** `InvoiceService` with 500+ lines doing input validation, DynamoDB
queries, HTTP calls to Asaas, structured logging, event emission, and all
business rules in one place.

**Fix:** separate responsibilities:
- Business rules → aggregate `Invoice` and domain services
- Persistence → `InvoiceRepository` adapter
- External provider → `AsaasService` adapter
- `InvoiceService` becomes a thin orchestrator calling the above

---

## 3. Feature Envy

**Symptom:** a method in `InvoiceService` accesses 5+ fields of `Invoice` to
calculate something that belongs to the invoice itself.

```typescript
// WRONG — service doing the invoice's work
const canCancel =
  invoice.status !== 'CONFIRMED' &&
  invoice.status !== 'RECEIVED' &&
  invoice.providerPaymentId !== undefined;
```

**Fix:** move the calculation to `invoice.canCancel(): boolean`. If a method is
more interested in another object's data than its own, the logic belongs in that
other object.

---

## 4. Primitive Obsession

**Symptom:** `tenantId`, `orderId`, and `invoiceId` are all `string` in the codebase.
Easy to swap accidentally — compiles without error.

```typescript
// WRONG
async findInvoice(tenantId: string, invoiceId: string): Promise<InvoiceRecord>

// Call with swapped arguments — compiles, silently fails at runtime
await repo.findInvoice(invoiceId, tenantId);
```

**Fix:** use a `TenantId` Value Object. The compiler rejects swapped arguments.
Validation (non-empty, format) runs in the constructor once, not scattered across services.

---

## 5. Transaction Script

**Symptom:** `InvoiceService.confirmInvoice()` is an imperative sequence of steps:
load record → check status string → update string → save → notify.
No domain objects, no aggregate methods called.

**Fix:** identify domain concepts. `invoice.confirm()` captures the transition rule.
The script becomes orchestration: load aggregate → call method → save → emit event.

---

## 6. Leaky Abstraction

**Symptom:** `InvoiceRepository` returns DynamoDB types (`AttributeValue`, raw
records) that callers must decode.

```typescript
// WRONG — infrastructure type leaking into the application layer
findById(id: string): Promise<Record<string, AttributeValue> | null>
```

**Fix:** the adapter's private `toDomain()` method maps from DynamoDB records
to domain objects before returning. Callers receive a clean domain object.
Infrastructure details never cross the port boundary.

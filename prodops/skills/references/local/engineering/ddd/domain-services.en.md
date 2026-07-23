# Domain Services

## When to create a domain service

Logic that does not belong to any specific entity and involves multiple
aggregates or pure domain rules.

**Create when:**
- The logic is meaningful to the domain but has no clear "owner" in the aggregate
- It involves multiple aggregates or factors external to the aggregate
- The name as a service reflects how domain experts describe the concept

## When NOT to create

- Logic that clearly belongs to `Invoice` → move to `invoice.confirm()`,
  `invoice.cancel()`, or other aggregate methods
- Infrastructure concerns (HTTP, DynamoDB, SQS) → application service or adapter
- Orchestration (call repo, call provider, emit event) → application service

Creating a domain service for every operation leads to the Anemic Domain Model.
Default: logic in the aggregate. Extract to service only when ownership is ambiguous.

## Acceptable example: FeeCalculationService

Processing fee depends on the payment method (on Invoice) and the tenant's plan
(external context, not part of Invoice).

```typescript
// domain/services/fee-calculation.service.ts
export class FeeCalculationService {
  calculate(amount: number, billingType: BillingType, tenantPlan: TenantPlan): number {
    const rate = this.resolveRate(billingType, tenantPlan);
    return amount * rate;
  }

  private resolveRate(method: BillingType, plan: TenantPlan): number {
    if (plan === 'PREMIUM' && method === 'PIX') return 0.005;
    if (method === 'PIX') return 0.01;
    if (method === 'BOLETO') return 0.015;
    return 0.025; // CREDIT_CARD default
  }
}
```

`Invoice` does not know `TenantPlan` — it would cross the Bounded Context boundary.
`FeeCalculationService` bridges the gap without coupling the aggregate to the tenant context.

## Wrong example

```typescript
// WRONG — this is orchestration, not a domain rule
export class InvoiceDomainService {
  async createAndCharge(dto: CreateInvoiceDto): Promise<void> {
    await this.repository.save(invoice);  // infrastructure
    await this.asaas.createCharge(...);   // infrastructure
    this.eventEmitter.emit(...);          // infrastructure
  }
}
```

This pattern is an application service disguised as a domain service.

## Domain service vs application service

| Domain service | Application service |
|----------------|---------------------|
| Contains business rules | Orchestrates — no business rules |
| Domain layer | Application layer |
| No infrastructure dependencies | Injects adapters and repositories |
| Example: `FeeCalculationService` | Example: `InvoiceService` |

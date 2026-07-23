# Refactoring

Refactoring is the discipline of improving code structure without changing behavior.
It has a specific phase: Yellow (Refactor). Not Green (make it work). Not Red (write the test).

## When to Refactor — Only in the Yellow Phase

```
Red   → write a failing test
Green → make the test pass with the simplest possible code
Yellow → refactor to clean: rename, extract, inline, reorganize
```

Refactoring outside the Yellow phase mixes concerns and breaks the safety net.
If you spot a smell while in Red or Green, note it and return to it in Yellow.

## Extract Method — Different Level of Abstraction

When a block of code inside a function operates at a different level of detail,
extract it into a named method. The name documents the intent.

```ts
// before — mixed abstraction levels inside confirmInvoice
async confirmInvoice(invoiceId: string, tenantId: string): Promise<void> {
  const invoice = await this.repository.findById(invoiceId, tenantId);
  if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);
  if (invoice.status !== InvoiceStatus.PENDING) {
    throw new ConflictException(`Invoice ${invoiceId} is not pending`);
  }
  const charge = await this.asaasService.createCharge(invoice.toChargeRequest());
  invoice.confirm(charge.id);
  await this.repository.save(invoice);
}

// after — each step reads at the same abstraction level
async confirmInvoice(invoiceId: string, tenantId: string): Promise<void> {
  const invoice = await this.findPendingInvoiceOrThrow(invoiceId, tenantId);
  const charge = await this.asaasService.createCharge(invoice.toChargeRequest());
  invoice.confirm(charge.id);
  await this.repository.save(invoice);
}

private async findPendingInvoiceOrThrow(invoiceId: string, tenantId: string): Promise<Invoice> {
  const invoice = await this.repository.findById(invoiceId, tenantId);
  if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);
  if (invoice.status !== InvoiceStatus.PENDING) {
    throw new ConflictException(`Invoice ${invoiceId} is not pending`);
  }
  return invoice;
}
```

## Rename — When the Name No Longer Matches the Behavior

A method that started as `createCharge` but now also sends a webhook notification
should be renamed to `createChargeAndNotify` — or better, split into two methods.

Never rename without running the tests. A rename that breaks tests reveals that
the name had implicit meaning the refactoring exposed.

## Inline — Remove Unnecessary Indirection

```ts
// before — one-liner private method adds no clarity
private buildChargeRequest(invoice: Invoice): AsaasChargeRequest {
  return invoice.toChargeRequest();
}

// after — just call the domain method directly
const charge = await this.asaasService.createCharge(invoice.toChargeRequest());
```

Inline only when the extracted method name adds nothing over the call itself.

## Smell Detection — Common Signals

| Smell | Signal | Refactoring |
|-------|--------|-------------|
| Long method | Scrolling required | Extract Method |
| Large class | Many unrelated imports | Extract Class |
| Feature envy | `InvoiceService` manipulates `Tenant` internals | Move Method |
| Primitive obsession | `tenantId: string` everywhere | Value Object (`TenantId`) |
| Divergent change | One class changes for two different reasons | Split Responsibility |

## What NOT To Do

**Drive-by cleanup**: changing unrelated code while working on a feature mixes
concerns in the diff and makes code review harder.

**Speculative refactoring**: "I'll need this abstraction later" — YAGNI.
Extract only when you have two concrete uses.

**Formatting churn**: reformatting lines you did not logically change adds noise to
PRs and blame history. Let Prettier handle formatting automatically.

**Rewriting vs refactoring**: a rewrite throws away test coverage and accumulated
knowledge. Prefer small, incremental refactorings that keep the tests green at each step.

## Guardrail — Only Refactor Code Under Test

Refactor only code that is covered by a passing test. If there is no test, there is no safety net.
If you want to refactor untested code, write the test first (Red Bar), make it green, then refactor.

For the complete rules on what is allowed and prohibited in each phase, see
[../tdd-prodops/red-green-refactor.md](../tdd-prodops/red-green-refactor.md).

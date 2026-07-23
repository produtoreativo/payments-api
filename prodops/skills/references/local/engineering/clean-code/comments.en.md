# Comments

A comment is an apology for code that doesn't explain itself.
Write code that doesn't need comments. When you must comment, explain the WHY.

## Comment the WHY, Not the WHAT

The WHAT is visible from the code. The WHY is the context that code cannot express alone.

```ts
// bad — restates what the code already says
// calls the repository to save the invoice
await this.invoiceRepository.save(invoice);

// bad — describes the obvious loop
// iterates over invoices
for (const invoice of invoices) { ... }

// good — explains a non-obvious business rule
// Asaas requires the idempotency key to prevent double charges on network retries
await this.asaasService.createCharge(request, { idempotencyKey: invoice.id });

// good — explains why a constraint exists
// TenantId must be included in every query; the DynamoDB table has no GSI on invoiceId alone
const invoice = await this.repository.findById(invoiceId, tenantId);
```

## TODO Format — Always Attributed, Never Orphaned

```ts
// bad — no owner, no context, will never be addressed
// TODO: fix this later
// TODO: handle edge case

// good — owner identified, action specific
// TODO(christiano): remove after Asaas migrates to v3 webhook schema (ticket: PAY-412)
// TODO(team): add retry logic once circuit breaker is in place
```

Never commit a floating TODO. Either fix it now or link it to a tracked ticket.

## When NOT to Comment

```ts
// bad — noise comments on obvious code
// check if invoice exists
if (!invoice) {
  // throw not found exception
  throw new NotFoundException(`Invoice ${invoiceId} not found`);
}

// good — no comment needed; the code is self-documenting
if (!invoice) {
  throw new NotFoundException(`Invoice ${invoiceId} not found`);
}
```

Control flow (if/else, try/catch), simple assignments, and standard NestJS patterns
do not need explanation. If the code reads naturally, remove the comment.

## JSDoc — Only for Public APIs and Exported Interfaces

```ts
// good — documents a public contract that callers depend on
/**
 * Creates a new invoice and registers the charge on Asaas.
 * Throws ConflictException if an invoice with the same orderId already exists for the tenant.
 */
async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> { ... }

// bad — JSDoc on a private method that only InvoiceService calls
/**
 * Finds the pending invoice or throws.
 */
private async findPendingInvoiceOrThrow(invoiceId: string, tenantId: string): Promise<Invoice> { ... }
```

Private methods, internal helpers, and implementation details do not need JSDoc.

## Never Comment-Out Code

```ts
// bad — dead code creates noise and false trails
async confirmInvoice(invoiceId: string, tenantId: string): Promise<void> {
  const invoice = await this.repository.findById(invoiceId, tenantId);
  // const oldLogic = await this.legacyService.confirm(invoice);
  // if (oldLogic.status !== 'ok') throw new Error('...');
  invoice.confirm();
  await this.repository.save(invoice);
}
```

Delete commented-out code. Git has the full history. If you need it back, `git log` will find it.
Commented-out code is a lie — it looks like intent, but it's just noise.

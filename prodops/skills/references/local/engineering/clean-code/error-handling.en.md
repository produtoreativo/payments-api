# Error Handling

Errors are first-class domain concepts. A missing invoice is not a generic error —
it is a specific business condition with a specific HTTP meaning.

## Errors as Domain Concepts

Define named exception classes for conditions the domain cares about.

```ts
// bad — generic error loses domain meaning
throw new Error('not found');
throw new Error('already confirmed');

// good — domain-named exceptions map to HTTP semantics
throw new NotFoundException(`Invoice ${invoiceId} not found for tenant ${tenantId}`);
throw new ConflictException(`Invoice ${invoiceId} is already confirmed`);
throw new BadRequestException(`Invoice ${invoiceId} cannot be cancelled in status ${invoice.status}`);
```

For complex domains, create typed exception classes:

```ts
export class InvoiceNotFoundException extends NotFoundException {
  constructor(invoiceId: string, tenantId: string) {
    super(`Invoice ${invoiceId} not found for tenant ${tenantId}`);
  }
}
```

## NestJS Exception Mapping

| Condition | NestJS Exception | HTTP Status |
|-----------|-----------------|-------------|
| Invoice not found | `NotFoundException` | 404 |
| Invoice already confirmed | `ConflictException` | 409 |
| Invalid status transition | `BadRequestException` | 400 |
| Unauthorized tenant | `ForbiddenException` | 403 |
| Provider unavailable | `ServiceUnavailableException` | 503 |

## Never Swallow Errors

```ts
// bad — error disappears silently
try {
  await this.asaasService.createCharge(request);
} catch (e) {
  // nothing
}

// bad — logs but continues as if nothing happened
try {
  await this.asaasService.createCharge(request);
} catch (e) {
  console.log(e);
}

// good — log with context, then propagate or remap
try {
  await this.asaasService.createCharge(request);
} catch (error) {
  this.logger.error('Failed to create Asaas charge', {
    invoiceId: invoice.id,
    tenantId: invoice.tenantId,
    error: error.message,
  });
  throw new ServiceUnavailableException('Payment provider temporarily unavailable');
}
```

## Logging — Structured, Contextual, Never PII

```ts
// bad — unstructured, includes PII, exposes stack to caller
console.log(`Error for ${customer.cpf}: ${error.stack}`);

// good — structured, safe fields only
this.logger.error('Invoice confirmation failed', {
  invoiceId: invoice.id,
  tenantId: invoice.tenantId,
  externalReference: invoice.externalReference,
  error: error.message,
});
```

Fields that MUST NEVER appear in logs: CPF, card number, card CVV, API keys, passwords,
customer name (when combined with financial data), full request/response bodies from Asaas.

## Error Messages — Meaningful to the Consumer

```ts
// bad — technical detail exposed to the client
throw new InternalServerErrorException('DynamoDB ProvisionedThroughputExceededException at ...');

// bad — useless to the caller
throw new BadRequestException('Invalid input');

// good — actionable, domain-relevant
throw new BadRequestException(
  `Cannot cancel invoice ${invoiceId}: status is ${invoice.status}, expected PENDING`,
);
```

## Async Error Propagation

```ts
// bad — unhandled promise rejection
this.repository.save(invoice); // fire and forget without error handling

// bad — promise chain without error handler
this.asaasService.createCharge(request).then((charge) => {
  invoice.assignCharge(charge.id);
});

// good — always await or explicitly handle
const charge = await this.asaasService.createCharge(request);
invoice.assignCharge(charge.id);
await this.repository.save(invoice);
```

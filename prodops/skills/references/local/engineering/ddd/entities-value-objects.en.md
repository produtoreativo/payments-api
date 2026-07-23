# Entities and Value Objects

## Entity — has unique identity

Defined by identity, not by attributes. Two `Invoice` instances with the same `invoiceId`
are the same invoice, even if other fields differ.

**Invoice** is the only entity (and aggregate root) in this context.
- Identity: `invoiceId` (format `inv_<ULID>`)
- Identity persists through state changes: confirming or cancelling does not create
  a new invoice — it is the same invoice in a new state.

## Value Object — defined by attributes, with no identity

Immutable. Two VOs with the same values are equal. To "change" a VO, replace it.

### TenantId

Ensures the merchant identifier is not empty or null.

```typescript
export class TenantId {
  constructor(readonly value: string) {
    if (!value?.trim()) throw new Error('TenantId cannot be empty');
  }

  equals(other: TenantId): boolean {
    return this.value === other.value;
  }
}
```

### Status as Value Object

```typescript
export type InvoiceStatus =
  | 'CREATED' | 'PROVIDER_PENDING' | 'OPEN'
  | 'CONFIRMED' | 'RECEIVED' | 'FAILED'
  | 'CANCELLED' | 'CANCEL_REQUESTED' | 'CANCEL_RECONCILIATION_REQUIRED';
```

Never use scattered string literals in the code — always use the `InvoiceStatus` type.

### Money

```typescript
export class Money {
  constructor(readonly amount: number, readonly currency: 'BRL' = 'BRL') {
    if (amount <= 0) throw new Error('Amount must be positive');
  }
}
```

The project validates `currency === 'BRL'` in the application service. Encapsulating in `Money`
moves that rule into the domain.

## Why Value Objects matter

| Without VOs | With VOs |
|-------------|---------|
| `tenantId: string` — any string compiles | `TenantId` — invalid string is a compile error |
| Validation scattered across services | Validation in constructor, guaranteed everywhere |
| Easy to swap `orderId` for `tenantId` (both `string`) | Distinct types — the compiler rejects the swap |

**Practical rule:** if a primitive has a restriction or specific meaning in the domain,
wrap it in a Value Object.

## Primitive Obsession in the current project

`InvoiceRecord` uses `tenantId: string` and `orderId: string`.
When refactoring to a rich model, replace with `TenantId` and keep `orderId: string`
(opaque reference with no business validation).

See [anti-patterns.md](./anti-patterns.md) for the complete Primitive Obsession pattern.

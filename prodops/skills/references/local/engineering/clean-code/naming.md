# Naming

Good names eliminate the need for comments. Every name is a micro-documentation choice.

## Names That Reveal Intent

Avoid abbreviations. If you abbreviate, the reader must decode before they can understand.

```ts
// bad
const tid = 'tenant-123';
const extRef = invoice.extRef;
const invId = req.params.id;

// good
const tenantId = 'tenant-123';
const externalReference = invoice.externalReference;
const invoiceId = req.params.invoiceId;
```

## Domain Names — Use the Ubiquitous Language

| Avoid | Prefer | Reason |
|-------|--------|--------|
| `id` | `invoiceId` | `id` is ambiguous — which entity? |
| `tid` | `tenantId` | Domain term, not jargon |
| `extRef` | `externalReference` | Full name matches domain vocabulary |
| `ref` | `orderId` | Be specific about what the reference is |
| `status` | `invoiceStatus` | Avoids shadowing in destructured contexts |

## Boolean Naming — Ask a Yes/No Question

```ts
// bad
const flag = invoice.status === InvoiceStatus.CONFIRMED;
const check = !!invoice.externalReference;

// good
const isConfirmed = invoice.status === InvoiceStatus.CONFIRMED;
const hasExternalReference = !!invoice.externalReference;
```

Prefix: `is`, `has`, `can`, `should`, `was`. Never: `flag`, `check`, `ok`, `valid`.

## Avoid Noise Words

Noise words pad the name without adding meaning.

```ts
// bad — "Data", "Object", "Manager" add nothing
class InvoiceData {}
class InvoiceObject {}
class InvoiceManager {}
interface InvoiceInfo {}

// good
class Invoice {}
class InvoiceService {}
interface InvoiceRepository {}
```

## TypeScript: Interfaces vs Types vs Enums

```ts
// Interfaces: use for object shapes and contracts (DI ports)
interface InvoiceRepository {
  findById(invoiceId: string, tenantId: string): Promise<Invoice | null>;
}

// Types: use for unions, intersections, computed types
type InvoiceStatus = 'PENDING' | 'CONFIRMED' | 'CANCELLED';

// Enums: use when values need to be referenced by name in logic
enum InvoiceStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  CANCELLED = 'CANCELLED',
}
```

No `IInvoiceRepository` prefix — the `I` prefix is a C# habit, not TypeScript convention.

## Collections — Use the Plural, Not a Suffix

```ts
// bad
const invoiceList = await this.repository.findAll(tenantId);
const itemArr = invoice.items;
const resultSet = await this.asaasService.listCharges();

// good
const invoices = await this.repository.findAll(tenantId);
const items = invoice.items;
const charges = await this.asaasService.listCharges();
```

The plural already communicates "collection". Adding `List`, `Arr`, or `Set` is redundant noise.

## Function Names — Verb + Noun

```ts
// bad
function invoice() {}
function processing(invoice: Invoice) {}
function data(tenantId: string) {}

// good
function createInvoice(dto: CreateInvoiceDto) {}
function confirmInvoice(invoice: Invoice) {}
function findInvoicesByTenant(tenantId: string) {}
```

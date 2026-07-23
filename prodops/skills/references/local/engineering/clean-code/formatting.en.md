# Formatting

Consistent formatting eliminates style debates and keeps diffs meaningful.
These rules are enforced by Prettier and ESLint — let the tools do the work.

## Single Quotes

```ts
// bad
const status = "PENDING";
const message = "Invoice not found";

// good
const status = 'PENDING';
const message = 'Invoice not found';
```

Exception: use double quotes only when the string itself contains a single quote.

## Semicolons — Required

```ts
// bad
const invoiceId = invoice.id
const tenantId = invoice.tenantId
return this.repository.save(invoice)

// good
const invoiceId = invoice.id;
const tenantId = invoice.tenantId;
return this.repository.save(invoice);
```

## Trailing Commas — Required in Multi-line Structures

```ts
// bad
const dto = {
  invoiceId: invoice.id,
  tenantId: invoice.tenantId,
  status: invoice.status
};

// good
const dto = {
  invoiceId: invoice.id,
  tenantId: invoice.tenantId,
  status: invoice.status,
};

// good — also applies to multi-line function parameters
async function createInvoice(
  tenantId: string,
  orderId: string,
  amount: number,
) {}
```

## 2-Space Indentation

```ts
// bad — 4 spaces
export class InvoiceService {
    async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
        const invoice = Invoice.create(dto);
        return invoice;
    }
}

// good — 2 spaces
export class InvoiceService {
  async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
    const invoice = Invoice.create(dto);
    return invoice;
  }
}
```

## Max 100 Characters Per Line — How to Break Long Lines

```ts
// bad — exceeds 100 chars
const invoice = await this.invoiceRepository.findByOrderIdAndTenantId(dto.orderId, dto.tenantId);

// good — break at natural boundaries (opening paren, object key, chained call)
const invoice = await this.invoiceRepository.findByOrderIdAndTenantId(
  dto.orderId,
  dto.tenantId,
);

// good — long object literals
throw new ConflictException(
  `Invoice with orderId ${dto.orderId} already exists for tenant ${dto.tenantId}`,
);
```

## Opening Brace — Same Line

```ts
// bad
if (!invoice)
{
  throw new NotFoundException();
}

// good
if (!invoice) {
  throw new NotFoundException(`Invoice ${invoiceId} not found`);
}
```

## Blank Lines — Between Methods, Not Inside Short Functions

```ts
// good — one blank line between methods
export class InvoiceService {
  async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
    const invoice = Invoice.create(dto);
    await this.repository.save(invoice);
    return invoice;
  }

  async cancelInvoice(invoiceId: string, tenantId: string): Promise<void> {
    const invoice = await this.findInvoiceOrThrow(invoiceId, tenantId);
    invoice.cancel();
    await this.repository.save(invoice);
  }
}
```

Do not add blank lines inside functions with 3–5 lines — it signals the function is too long.

## Import Order Convention

```ts
// 1. Node built-ins (none in NestJS typically)
// 2. External packages
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';

// 3. Internal absolute paths (src aliases)
import { Invoice } from '@/modules/invoices/domain/invoice';
import { InvoiceRepository } from '@/modules/invoices/ports/invoice-repository';

// 4. Relative paths
import { CreateInvoiceDto } from './dto/create-invoice.dto';
```

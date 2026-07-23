# Functions

A function should do one thing. If you can describe it with "and", it does two things.

## Do One Thing — Command vs Query Separation

Commands change state. Queries return data. Never mix.

```ts
// bad — queries state AND mutates it
async getOrCreateInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
  const existing = await this.repository.findByOrderId(dto.orderId, dto.tenantId);
  if (!existing) {
    const invoice = Invoice.create(dto);
    await this.repository.save(invoice);
    return invoice;
  }
  return existing;
}

// good — separated concerns
async findInvoiceByOrderId(orderId: string, tenantId: string): Promise<Invoice | null> {
  return this.repository.findByOrderId(orderId, tenantId);
}

async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
  const invoice = Invoice.create(dto);
  await this.repository.save(invoice);
  return invoice;
}
```

## Small Functions — If You Scroll, It's Too Long

A function body longer than ~15 lines usually contains multiple levels of abstraction.
Extract named helpers to make the intent explicit.

```ts
// bad — one function with three levels of abstraction
async processInvoiceConfirmation(invoiceId: string, tenantId: string): Promise<void> {
  const invoice = await this.repository.findById(invoiceId, tenantId);
  if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);
  if (invoice.status !== InvoiceStatus.PENDING) {
    throw new ConflictException(`Invoice ${invoiceId} is not pending`);
  }
  const charge = await this.asaasService.createCharge({
    externalReference: invoice.externalReference,
    value: invoice.amount,
    dueDate: invoice.dueDate,
  });
  invoice.confirm(charge.id);
  await this.repository.save(invoice);
}

// good — each step is named and readable
async confirmInvoice(invoiceId: string, tenantId: string): Promise<void> {
  const invoice = await this.findPendingInvoiceOrThrow(invoiceId, tenantId);
  const charge = await this.asaasService.createCharge(invoice.toChargeRequest());
  invoice.confirm(charge.id);
  await this.repository.save(invoice);
}
```

## No Hidden Side Effects

A function named `get*` or `find*` must not mutate state. Surprises erode trust.

```ts
// bad — name says "get", body writes to DB
async getInvoice(invoiceId: string, tenantId: string): Promise<Invoice> {
  const invoice = await this.repository.findById(invoiceId, tenantId);
  invoice.recordAccess(); // hidden side effect
  await this.repository.save(invoice);
  return invoice;
}

// good — if mutation is needed, be explicit about it
async findInvoice(invoiceId: string, tenantId: string): Promise<Invoice> {
  return this.repository.findById(invoiceId, tenantId);
}
```

## Parameter Count — Max 3, Use Objects for More

```ts
// bad — caller must remember argument order
async createInvoice(tenantId: string, orderId: string, amount: number, dueDate: string) {}

// good — named properties, order-independent, extensible
async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {}

interface CreateInvoiceDto {
  tenantId: string;
  orderId: string;
  amount: number;
  dueDate: string;
}
```

## Avoid Flag Arguments

A boolean flag argument means the function does two different things depending on the flag.
Split it into two explicit functions.

```ts
// bad — what does `true` mean here?
await this.invoiceService.createInvoice(dto, true);

// good — intent is explicit
await this.invoiceService.createInvoiceWithNotification(dto);
await this.invoiceService.createInvoiceSilently(dto);
```

## Prefer async/await over Callbacks

```ts
// bad
this.repository.findById(invoiceId, tenantId).then((invoice) => {
  if (!invoice) throw new NotFoundException();
  resolve(invoice);
}).catch(reject);

// good
const invoice = await this.repository.findById(invoiceId, tenantId);
if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);
return invoice;
```

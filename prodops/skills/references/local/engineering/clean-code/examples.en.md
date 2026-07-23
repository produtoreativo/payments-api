# Examples — Before & After

Concrete before/after pairs from the Payments domain. Each shows a real smell and its fix.

---

## 1. Naming — Unclear Variables → Domain Names

**Bad**
```ts
async function proc(tid: string, oid: string, amt: number): Promise<any> {
  const res = await repo.find(oid, tid);
  if (!res) return null;
  const obj = { tid, oid, amt, st: 'PENDING' };
  await repo.save(obj);
  return obj;
}
```

**Good**
```ts
async function createInvoice(
  tenantId: string,
  orderId: string,
  amount: number,
): Promise<Invoice> {
  const existing = await this.invoiceRepository.findByOrderId(orderId, tenantId);
  if (existing) throw new ConflictException(`Invoice for order ${orderId} already exists`);
  const invoice = Invoice.create({ tenantId, orderId, amount });
  await this.invoiceRepository.save(invoice);
  return invoice;
}
```

Abbreviated names (`tid`, `oid`, `amt`, `res`, `obj`, `st`) force the reader to decode
before understanding. Domain names tell the story directly.

---

## 2. Function — Long Multi-step Function → Focused Functions

**Bad**
```ts
async handleInvoiceConfirmation(id: string, tenant: string): Promise<void> {
  const item = await this.dynamoRepo.findById(id, tenant);
  if (!item) throw new Error('not found');
  if (item.status !== 'PENDING') throw new Error('wrong status');
  const req = { externalRef: item.ref, value: item.amt, due: item.due };
  const resp = await this.asaasService.post('/charges', req);
  item.chargeId = resp.data.id;
  item.status = 'CONFIRMED';
  await this.dynamoRepo.update(item);
  await this.eventBus.publish({ type: 'INVOICE_CONFIRMED', payload: item });
}
```

**Good**
```ts
async confirmInvoice(invoiceId: string, tenantId: string): Promise<void> {
  const invoice = await this.findPendingInvoiceOrThrow(invoiceId, tenantId);
  const charge = await this.asaasService.createCharge(invoice.toChargeRequest());
  invoice.confirm(charge.id);
  await this.invoiceRepository.save(invoice);
  await this.eventBus.publish(InvoiceConfirmedEvent.from(invoice));
}

private async findPendingInvoiceOrThrow(
  invoiceId: string,
  tenantId: string,
): Promise<Invoice> {
  const invoice = await this.invoiceRepository.findById(invoiceId, tenantId);
  if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);
  if (invoice.status !== InvoiceStatus.PENDING) {
    throw new ConflictException(`Invoice ${invoiceId} is not in PENDING status`);
  }
  return invoice;
}
```

Each function now does one thing. `confirmInvoice` reads as a narrative. Details are
delegated to named helpers that can be tested independently.

---

## 3. Error Handling — Swallowed Error → Structured Error with Logging

**Bad**
```ts
async createCharge(invoice: Invoice): Promise<string> {
  try {
    const response = await this.asaasClient.post('/charges', {
      externalReference: invoice.externalReference,
      value: invoice.amount,
    });
    return response.data.id;
  } catch (e) {
    console.log('error', e);
    return null;
  }
}
```

**Good**
```ts
async createCharge(invoice: Invoice): Promise<string> {
  try {
    const response = await this.asaasClient.post('/charges', {
      externalReference: invoice.externalReference,
      value: invoice.amount,
    });
    return response.data.id;
  } catch (error) {
    this.logger.error('Asaas charge creation failed', {
      invoiceId: invoice.id,
      tenantId: invoice.tenantId,
      externalReference: invoice.externalReference,
      error: error.message,
    });
    throw new ServiceUnavailableException('Payment provider temporarily unavailable');
  }
}
```

The bad version silently returns `null`, causing a downstream null-pointer crash with no context.
The good version logs domain fields for observability and throws a mapped HTTP exception.

---

## 4. Comments — Redundant Comments → Self-Documenting Code

**Bad**
```ts
// get the invoice from the database
const invoice = await this.repository.findById(invoiceId, tenantId);

// check if invoice exists
if (!invoice) {
  // throw not found
  throw new NotFoundException();
}

// update the status to cancelled
invoice.status = InvoiceStatus.CANCELLED;

// save the invoice
await this.repository.save(invoice);
```

**Good**
```ts
const invoice = await this.repository.findById(invoiceId, tenantId);
if (!invoice) throw new NotFoundException(`Invoice ${invoiceId} not found`);

// Cancellation is irreversible; downstream systems (Asaas, billing) are notified via event
invoice.cancel();
await this.repository.save(invoice);
```

Remove comments that restate the code. Keep only the comment that explains WHY
cancellation is irreversible — that context is not visible from the code alone.

---

## 5. Class — InvoiceService Mixing Concerns → Separated Responsibilities

**Bad**
```ts
@Injectable()
export class InvoiceService {
  constructor(private readonly dynamoClient: DynamoDBClient) {}

  async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
    // DynamoDB mapping inside the service
    const item = await this.dynamoClient.send(new PutItemCommand({
      TableName: 'invoices',
      Item: { pk: { S: dto.tenantId }, sk: { S: dto.orderId }, status: { S: 'PENDING' } },
    }));
    // Asaas HTTP call also inside the service
    const charge = await axios.post('https://api.asaas.com/v3/charges', {
      externalReference: dto.orderId,
      value: dto.amount,
    }, { headers: { access_token: process.env.ASAAS_KEY } });
    return { ...dto, chargeId: charge.data.id, status: 'CONFIRMED' };
  }
}
```

**Good**
```ts
// InvoiceService: orchestration only
@Injectable()
export class InvoiceService {
  constructor(
    private readonly invoiceRepository: InvoiceRepository,  // port (interface)
    private readonly asaasService: AsaasService,             // infrastructure adapter
  ) {}

  async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
    const invoice = Invoice.create(dto);
    const charge = await this.asaasService.createCharge(invoice.toChargeRequest());
    invoice.assignCharge(charge.id);
    await this.invoiceRepository.save(invoice);
    return invoice;
  }
}
```

DynamoDB mapping belongs in `DynamoInvoiceRepository`. Asaas HTTP logic belongs in
`AsaasService`. `InvoiceService` only coordinates — it has one reason to change.

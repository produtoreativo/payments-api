# Classes

A class should have one reason to change. If you can name two reasons, extract a second class.

## Single Responsibility Principle

`InvoiceService` is an application orchestrator. It coordinates domain objects and infrastructure
ports. It does NOT contain repository queries, HTTP calls, or mapping logic.

```ts
// bad — InvoiceService knows DynamoDB, Asaas SDK, and HTTP
@Injectable()
export class InvoiceService {
  constructor(private readonly dynamoClient: DynamoDBClient) {}

  async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {
    const item = await this.dynamoClient.send(new PutItemCommand({ ... }));
    const charge = await axios.post('https://api.asaas.com/charges', { ... });
    return { ...item, chargeId: charge.data.id };
  }
}

// good — InvoiceService depends on interfaces, not implementations
@Injectable()
export class InvoiceService {
  constructor(
    private readonly invoiceRepository: InvoiceRepository,
    private readonly asaasService: AsaasService,
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

## Cohesion — All Methods Should Relate to the Same Responsibility

If you find yourself asking "why is this method here?", cohesion is broken.

```ts
// bad — InvoiceService also sends emails and manages tenants
@Injectable()
export class InvoiceService {
  async createInvoice(dto: CreateInvoiceDto) {}
  async sendConfirmationEmail(invoiceId: string) {}  // belongs to NotificationService
  async updateTenantQuota(tenantId: string) {}       // belongs to TenantService
}

// good — each service owns exactly one slice of behavior
@Injectable()
export class InvoiceService {
  async createInvoice(dto: CreateInvoiceDto): Promise<Invoice> {}
  async confirmInvoice(invoiceId: string, tenantId: string): Promise<void> {}
  async cancelInvoice(invoiceId: string, tenantId: string): Promise<void> {}
}
```

## Dependency Inversion — Inject Interfaces, Not Implementations

```ts
// bad — depends on concrete class, hard to test
@Injectable()
export class InvoiceService {
  constructor(private readonly repo: DynamoInvoiceRepository) {}
}

// good — depends on port (interface), implementation injected by NestJS
@Injectable()
export class InvoiceService {
  constructor(
    @Inject(INVOICE_REPOSITORY)
    private readonly invoiceRepository: InvoiceRepository,
  ) {}
}
```

Define the port in the domain layer; bind the adapter in the module.

## NestJS Providers — Constructor Injection

```ts
@Injectable()
export class InvoiceService {
  constructor(
    private readonly invoiceRepository: InvoiceRepository,
    private readonly asaasService: AsaasService,
  ) {}
}
```

Never use `moduleRef.get()` or property injection as a substitute for constructor injection.
Property injection (`@Inject()` on fields) hides dependencies and makes tests harder.

## Size Signal — Too Many Imports Means Too Much Responsibility

```ts
// warning sign — this service imports from 8 different modules
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { SESClient } from '@aws-sdk/client-ses';
import { SNSClient } from '@aws-sdk/client-sns';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InvoiceMapper } from '../mappers/invoice.mapper';
import { TenantService } from '../../tenants/tenant.service';
```

If a service has more than 4–5 dependencies, it is likely doing too much.

## What NOT To Do — The God Service

```ts
// bad — one class that does everything
@Injectable()
export class InvoiceManager {
  async createInvoice() {}       // application logic
  async saveToDatabase() {}      // repository concern
  async callAsaas() {}           // provider concern
  async sendWebhookEvent() {}    // event concern
  async mapToResponse() {}       // HTTP concern
  async validateTenant() {}      // auth concern
}
```

Split by layer: domain, application (service), infrastructure (repository, provider), presentation.

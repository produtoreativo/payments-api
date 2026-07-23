# Aggregates — Invoice

## O que é um aggregate root

Unidade de consistência transacional. Todo acesso ao estado de `Invoice` deve passar
pelo aggregate root — nenhum código externo modifica campos diretamente.

## Invoice como aggregate root

`Invoice` possui:
- **Identidade**: `invoiceId` (formato `inv_<ULID>`)
- **Estado**: `status` — define o que pode acontecer a seguir
- **Contexto**: `tenantId`, `orderId`, `amount`, `billingType`, `provider`
- **Rastreabilidade**: `externalReference`, `providerPaymentId`, `createdAt`, `updatedAt`

## Invariantes — transições válidas de status

| De | Para | Permitido? |
|----|------|-----------|
| CREATED | PROVIDER_PENDING | sim |
| PROVIDER_PENDING | OPEN | sim |
| PROVIDER_PENDING | FAILED | sim |
| OPEN | CONFIRMED | sim (via webhook) |
| OPEN | RECEIVED | sim (via webhook) |
| OPEN | CANCEL_REQUESTED | sim |
| CANCEL_REQUESTED | CANCELLED | sim |
| CONFIRMED | CANCELLED | não — exige refund flow |
| CANCELLED | CONFIRMED | não — terminal |

Violações lançam exceção — nunca silenciosamente ignoradas.

## Tamanho do aggregate

Aggregates pequenos são preferíveis. `Invoice` não inclui:
- Histórico de webhooks (armazenado separadamente como `ProviderEvent`)
- `CustomerProviderLink` (aggregate próprio, gerenciado separadamente)

## Exemplo TypeScript

```typescript
export class Invoice {
  private constructor(
    readonly invoiceId: string,
    readonly tenantId: string,
    readonly orderId: string,
    readonly amount: number,
    private status: InvoiceStatus,
  ) {}

  static create(tenantId: string, orderId: string, amount: number): Invoice {
    return new Invoice(`inv_${ulid()}`, tenantId, orderId, amount, 'CREATED');
  }

  confirm(): void {
    if (this.status !== 'OPEN') {
      throw new Error(`Cannot confirm invoice with status ${this.status}`);
    }
    this.status = 'CONFIRMED';
  }

  cancel(): void {
    if (this.status === 'CONFIRMED' || this.status === 'RECEIVED') {
      throw new Error('Invoice cancellation after confirmation requires refund flow');
    }
    this.status = 'CANCELLED';
  }

  getStatus(): InvoiceStatus {
    return this.status;
  }
}
```

## O aggregate não faz

- Não chama `AsaasService` — responsabilidade do application service
- Não emite eventos para SQS — responsabilidade do application service
- Não conhece HTTP, DTOs ou decoradores do NestJS
- Não conhece DynamoDB ou qualquer tecnologia de persistência

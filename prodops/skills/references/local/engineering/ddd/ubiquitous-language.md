# Ubiquitous Language — Payments Domain

Use esses termos no código, DTOs, logs, testes e PRs.
Nunca misture sinônimos (ex: não use "payment" e "invoice" como equivalentes).

---

## Glossário

**Invoice**
Fatura criada para um pedido. Aggregate root deste contexto. Possui ciclo de vida
próprio. No código: classe `InvoiceRecord`, campo `invoiceId`, `InvoiceRepository`,
`InvoiceService`.

**TenantId**
Identificador do cliente/lojista que originou a fatura. Todo acesso a dados é
scopado por `tenantId`. No código: campo `tenantId` em todos os registros e queries.

**OrderId**
Referência ao pedido no sistema upstream (Checkout). Uma fatura pertence a exatamente
um pedido. O Payments **armazena** o `orderId` como referência opaca — não valida
regras de negócio do pedido.

**InvoiceId**
Identificador único da fatura gerado pela Payments API. Prefixo `inv_` seguido de ULID.
Exemplo: `inv_01HWZXYZ...`. No código: `const invoiceId = \`inv_\${ulid()}\``.

**ExternalReference**
O `invoiceId` interno enviado ao provedor como referência. Usado para correlacionar
webhooks de volta à fatura. No código: `externalReference: invoiceId` no `InvoiceRecord`.
Nunca expõe estrutura interna do provedor.

**Provider**
Serviço externo de pagamento. Providers disponíveis: `ASAAS`, `ITAU`.
No código: tipo `PaymentProvider`, campo `provider` na fatura.

**Webhook**
Notificação assíncrona de mudança de status enviada pelo Provider. Processado em
`InvoiceService.processProviderWebhook()`. Pode ser `PAYMENT_CONFIRMED`,
`PAYMENT_DELETED`, `PAYMENT_AUTHORIZED`, entre outros.

**PaymentMethod / BillingType**
Forma de pagamento: `BOLETO`, `PIX`, `CREDIT_CARD`, `UNDEFINED`.
No código: campo `billingType` no `CreateInvoiceDto` e `InvoiceRecord`.

**Status**
Estado atual da fatura no ciclo de vida:
`CREATED → PROVIDER_PENDING → OPEN → CONFIRMED | RECEIVED | FAILED | CANCELLED`
No código: tipo `InvoiceStatus` em `invoice.types.ts`.

---

## Ciclo de vida

```
CREATED → PROVIDER_PENDING → OPEN → CONFIRMED
                                  → RECEIVED
                          → FAILED
          → CANCEL_REQUESTED → CANCELLED
                             → CANCEL_RECONCILIATION_REQUIRED
```

---

## Regras de nomenclatura

- "invoice" — nunca "payment", "charge", "bill" ou "cobrança"
- "confirm" — nunca "approve", "authorize" ou "pay"
- "tenant" — nunca "merchant", "client" ou "user"
- "provider" — nunca "gateway" ou "Asaas" na camada de domínio
- "externalReference" — nunca "asaasId" ou "providerCode"
- "orderId" — nunca "purchaseId" ou "transactionId"

Aplicar em: nomes de classe/método/variável, campos de DTO, mensagens de log,
descrições de teste, títulos de PR e commit messages.

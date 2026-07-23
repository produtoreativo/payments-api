# Bounded Context — Payments

## O que pertence a este contexto

- Ciclo de vida da fatura: criação, abertura no provedor, confirmação, cancelamento
- Integração com provedor: envio de cobranças ao Asaas via `AsaasService`
- Processamento de webhooks: recebimento e aplicação de status do provedor
- Idempotência: deduplicação de operações por `Idempotency-Key`
- Vínculo cliente-provedor: `CustomerProviderLink` — link entre customer interno e Asaas

## O que NÃO pertence

| Contexto | Responsabilidade | Ponto de integração |
|----------|-----------------|---------------------|
| Checkout | Cria pedidos, inicia requests de pagamento | Envia `orderId` + `tenantId` como input |
| Notificação | Envia email/push ao cliente final | Recebe eventos `payments.invoice.confirmed` |
| Order Management | Regras de fulfillment, estado do pedido | Payments armazena `orderId` como referência opaca |
| Identity / IAM | Autenticação de tenant | `tenantId` chega como claim validado |

**Regra:** `InvoiceService` não importa módulos de Checkout, Order Management ou
Notificação. Comunicação é via eventos ou chamadas explícitas com DTOs tipados.

## Fronteiras no código

```typescript
// CORRETO — orderId é referência opaca, sem validação de negócio do pedido
const invoice: InvoiceRecord = {
  invoiceId,
  tenantId: createInvoiceDto.tenantId,
  orderId: createInvoiceDto.orderId,  // apenas armazenado
  // ...
};

// ERRADO — cruzar fronteira consultando regras do contexto de pedidos
if (order.fulfillmentType === 'digital') { /* não é nossa responsabilidade */ }
```

## Anti-corruption layer (ACL)

`AsaasService` é o ACL entre Payments e o provedor Asaas.

**O que faz:**
- Traduz conceitos do domínio (`InvoiceRecord`, `amount`) para requests Asaas
- Traduz responses Asaas para tipos do domínio interno
- Isola terminologia específica do Asaas da camada de domínio

```typescript
// ERRADO — campo do Asaas vazando para o domínio
invoice.nossoNumero = response.nossoNumero;

// CORRETO — ACL mapeia para conceitos do domínio
invoice.externalReference = invoiceId;  // invoice interno, não ID do Asaas
```

`externalReference` é o `invoiceId` interno (prefixo `inv_`) enviado ao Asaas como
referência. O Asaas devolve esse mesmo valor no webhook — Payments usa para
correlacionar sem expor o modelo interno do Asaas.

Conceitos do Asaas (`boleto`, `pix`, `nossoNumero`, `cobrança`, `vencimento`)
nunca aparecem fora de `AsaasService`.

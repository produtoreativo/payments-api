# Service Deck — Compra com Boleto

> Tipo: Value Stream · Última atualização: 2026-08-10

---

## 1. Service Vision

Para **sistemas integradores e consumidores do Magazine Siará (Checkout)**,
que **precisam oferecer Boleto Bancário como meio de pagamento offline com prazo definido**,
a **Value Stream Compra com Boleto**
é um **fluxo de criação, acompanhamento e confirmação de cobranças por Boleto via Payments API**
que **garante emissão idempotente, entrega de `bankSlipUrl` e linha digitável, e confirmação observável via webhook do provedor**.

Diferente de **integrar diretamente o Asaas para Boleto**,
este serviço **desacopla o Checkout dos contratos do PSP, garante idempotência por `Idempotency-Key`, impede duplicação em retentativas e mantém os identificadores internos do Magazine Siará como fonte de verdade**.

---

## 2. Service Endpoints (Data)

> Fonte: OBC [`prodops/artifacts/obcs/create-invoice-boleto.md`](../../../obcs/create-invoice-boleto.md) + [`prodops/artifacts/obcs/payment-confirmation.md`](../../../obcs/payment-confirmation.md)

### APIs públicas

| Endpoint | Contrato | Resultado |
|---|---|---|
| `POST /invoices` (`billingType=BOLETO`) | `orderId`, `amount`, `dueDate`, `Idempotency-Key`, `X-Api-Token` | `201` com `invoiceId`, `providerPaymentId`, `bankSlipUrl`, `identificationField`, `dueDate`, status `OPEN` |
| `GET /invoices/:invoiceId` | `invoiceId`, `X-Api-Token` | Status atual da invoice Boleto |
| `DELETE /invoices/:invoiceId` | `invoiceId`, `Idempotency-Key`, `X-Api-Token` | Cancelamento se não confirmado (fluxo `cancel-invoice`) |
| `POST /webhook/payments` | `asaas-access-token` | Recebe eventos do provedor: `PAYMENT_RECEIVED`, `PAYMENT_OVERDUE`, `PAYMENT_DELETED` |

### Eventos publicados

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `payment.boleto.created` | Boleto criado com sucesso — `bankSlipUrl` disponível | `invoiceId`, `orderId`, `tenantId`, `providerPaymentId`, `billingType`, `dueDate`, `correlationId` |
| `payment.boleto.creation_failed` | Falha ao criar boleto no provedor | `invoiceId`, `orderId`, `tenantId`, `reason`, `correlationId` |
| `payment.boleto.idempotency_hit` | Retentativa com mesma chave — invoice existente retornada | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `payment.confirmed` | Boleto pago e confirmado — pedido pode ser liberado | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `confirmedAt`, `correlationId` |
| `payment.received` | Liquidação financeira — para conciliação (não libera pedido novamente) | `invoiceId`, `orderId`, `tenantId`, `receivedAt`, `correlationId` |
| `webhook.received` | Evento bruto do provedor persistido para auditoria | `tenantId`, `provider`, `eventType`, `providerPaymentId`, `correlationId` |

### Eventos consumidos

| Evento | Origem | Ação |
|---|---|---|
| `PAYMENT_RECEIVED` (Asaas webhook) | Asaas PSP → `POST /webhook/payments` | Confirma pagamento; publica `payment.confirmed` |
| `PAYMENT_OVERDUE` (Asaas webhook) | Asaas PSP → `POST /webhook/payments` | Registra expiração; atualiza estado operacional |
| `PAYMENT_DELETED` (Asaas webhook) | Asaas PSP → `POST /webhook/payments` | Confirma cancelamento para `CANCEL_REQUESTED` |

### Schema de resposta (criação)

```json
{
  "invoiceId": "...",
  "orderId": "...",
  "provider": "ASAAS",
  "providerPaymentId": "...",
  "status": "OPEN",
  "amount": 250.00,
  "currency": "BRL",
  "billingType": "BOLETO",
  "dueDate": "2026-08-20",
  "bankSlipUrl": "https://sandbox.asaas.com/b/pdf/...",
  "identificationField": "34191.75402..."
}
```

> `bankSlipUrl` e `identificationField` não são logados — contêm dados de cobrança rastreáveis.

---

## 3. Service Team

| Papel | Time / Nome | Canal | Tempo de resposta (SEV1) |
|---|---|---|---|
| Owner (OBC + SLO) | Payments | `[link]` | < 15 min |
| On-call | Plataforma / SRE | `[link]` | < 5 min (pager) |
| PM responsável | Eugenio | `[link]` | < 30 min |

---

## 4. Service Architecture

```
Checkout
    │ POST /invoices  billingType=BOLETO
    │ X-Api-Token · Idempotency-Key
    ▼
Lambda Function URL → ApiTokenGuard → InvoiceController
    │
    ▼
InvoiceService
    ├─ DynamoDB PaymentsTable     (cria/atualiza invoice)
    ├─ DynamoDB CustomersTable    (cria/reutiliza customer Asaas)
    │
    └─ Asaas PSP  POST /v3/payments (billingType=BOLETO)
         │  retorna: bankSlipUrl · identificationField · providerPaymentId
         │
         │ (confirmação assíncrona — dias depois)
         ▼
Asaas → POST /webhook/payments  (PAYMENT_RECEIVED / PAYMENT_OVERDUE)
    │
    ▼
AsaasWebhookController → InvoiceService
    ├─ valida asaas-access-token
    ├─ persiste evento bruto
    ├─ publica payment.confirmed → EventEmitter2
    │     └─ WebhookDeliveryService → HTTPS POST consumer
    └─ DynamoDB PaymentsTable (atualiza status)
```

**Dependências críticas:**

| Componente | Criticidade | Fallback disponível |
|---|---|---|
| Asaas PSP (criação de boleto) | Crítica | Não — sem PSP alternativo neste slice |
| DynamoDB PaymentsTable | Crítica | Não |
| Asaas webhook (confirmação) | Alta | SQS worker (modo async) |
| EventEmitter2 / WebhookDelivery | Alta | Fila SQS para entrega async |

---

## 5. Service Reliability

### SLOs (OBC `create-invoice-boleto` + `payment-confirmation`)

| SLO | Meta | Janela |
|---|---|---|
| Invoices Boleto criadas com `bankSlipUrl` presente na resposta | 99,9% | 30 dias |
| `dueDate` no passado rejeitada antes de chamar o provedor | 100% | — |
| Retentativas com mesma `Idempotency-Key` retornam invoice existente | 100% | — |
| `payment.confirmed` publicado exatamente uma vez por pagamento | 100% | — |
| Eventos brutos do webhook persistidos antes do processamento | 99,9% | — |

### SLIs observáveis

| SLI | Fonte |
|---|---|
| Taxa de sucesso na criação de boletos (`bankSlipUrl` presente) | Datadog — evento `payment.boleto.created` |
| Taxa de confirmação via webhook (`payment.confirmed` / boletos criados) | Datadog — eventos de lifecycle |
| Latência p95 de criação | Datadog APM — `POST /invoices` |
| DLQ depth (modo async) | CloudWatch — `payments-webhook-dlq` |

### Error Budget e MTTR

| Métrica | Valor |
|---|---|
| Error Budget (criação) | `[apurar — Datadog]` |
| MTTR médio | `[apurar — incidents]` |

### Regras de confiabilidade

- Boleto expirado sem pagamento não é erro operacional — é estado natural do ciclo. `payment.boleto.expired` deve ser observável.
- `bankSlipUrl` e `identificationField` nunca aparecem em logs, traces ou respostas de erro.
- Invoice com status `OPEN` retornada apenas após `providerPaymentId` consolidado.

---

## 6. Service Analytics

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Volume de boletos criados / dia | Adoção do meio de pagamento Boleto | Datadog | Diária |
| Taxa de criação bem-sucedida | Problemas no provedor? | `payment.boleto.created` / tentativas | Tempo real |
| Taxa de confirmação de boletos | Clientes estão pagando? | `payment.confirmed` / boletos emitidos | Diária |
| Taxa de vencimento sem pagamento | Boletos expiram sem conversão? | `PAYMENT_OVERDUE` / emitidos | Diária |
| Latência p95 de emissão | Boleto está sendo entregue rápido? | Datadog APM | Tempo real |
| DLQ depth | Webhooks do provedor estão sendo processados? | CloudWatch | Tempo real |

---

## 7. Service Consumers

| Consumidor | Tipo | Dependência | Impacto de degradação |
|---|---|---|---|
| Checkout | Direto (API) | `POST /invoices` → `bankSlipUrl` + `identificationField` | Cliente sem boleto para pagar |
| Order Management | Indireto (evento) | `payment.confirmed` via webhook configurado | Pedido não liberado após pagamento |
| Notification Service | Indireto (evento) | `payment.confirmed` / `payment.boleto.created` | Cliente sem confirmação de status |
| Financeiro / Conciliação | Indireto (evento) | `payment.received` | Conciliação manual sem dado de liquidação |
| Atendimento | Operacional | `GET /invoices/:invoiceId` — status e rastreabilidade | Suporte sem resposta confiável ao cliente |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| OBC — Criação de Boleto | [`prodops/artifacts/obcs/create-invoice-boleto.md`](../../../obcs/create-invoice-boleto.md) |
| OBC — Confirmação de Pagamento | [`prodops/artifacts/obcs/payment-confirmation.md`](../../../obcs/payment-confirmation.md) |
| BDD — Criação de Boleto | [`prodops/artifacts/bdd/create-invoice-boleto.feature`](../../../bdd/create-invoice-boleto.feature) |
| BDD — Confirmação | [`prodops/artifacts/bdd/payment-confirmation.feature`](../../../bdd/payment-confirmation.feature) |
| Product Deck Payments | [`prodops/artifacts/product/context/product-deck.md`](../product-deck.md) |

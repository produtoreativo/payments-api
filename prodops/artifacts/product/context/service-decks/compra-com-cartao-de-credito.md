# Service Deck — Compra com Cartão de Crédito

> Tipo: Value Stream · Última atualização: 2026-08-10

---

## 1. Service Vision

Para **sistemas integradores e Checkout da Magazine Siará**,
que **precisam aceitar pagamentos com cartão de crédito com feedback claro ao cliente e sem expor dados sensíveis de cartão**,
a **Value Stream Compra com Cartão de Crédito**
é um **fluxo de autorização via hosted flow do Asaas, confirmação observável e suporte a refund**
que **entrega estados terminais conhecidos (autorizado, recusado, em análise de risco) com eventos de domínio rastreáveis e sem que o Payments API manipule dados brutos de cartão**.

Diferente de **integrar o Asaas hosted flow diretamente no Checkout**,
este serviço **centraliza a criação da invoice hospedada, desacopla o Checkout dos contratos do PSP, publica `payment.confirmed` exatamente uma vez e suporta o fluxo de refund com evento canônico**.

> **Escopo do slice atual (Downstream):** hosted card entry apenas. Tokenização, card salvo e raw card capture estão em Upstream até decisão de PCI boundary, consentimento e token storage.

---

## 2. Service Endpoints (Data)

> Fonte: OBC [`prodops/artifacts/obcs/credit-card-authorization-confirmation.md`](../../../obcs/credit-card-authorization-confirmation.md)

### APIs públicas

| Endpoint | Contrato | Resultado |
|---|---|---|
| `POST /invoices` (hosted) | `orderId`, `amount`, `billingType=CREDIT_CARD`, `X-Api-Token` | `201` com `invoiceId`, `providerPaymentId`, `hostedPaymentUrl` |
| `GET /invoices/:invoiceId` | `invoiceId`, `X-Api-Token` | Status atual: `OPEN`, `AUTHORIZED`, `CONFIRMED`, `REFUSED`, `REFUND_REQUESTED` |
| `POST /invoices/:invoiceId/refund` | `invoiceId`, `amount`, `reason`, `X-Api-Token` | Solicita refund de invoice confirmada |
| `POST /webhook/payments` | `asaas-access-token` | Recebe eventos do provedor: `PAYMENT_CONFIRMED`, `PAYMENT_REFUSED`, `PAYMENT_REFUNDED` |

### Eventos publicados

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `payment.card.hosted_invoice.created` | Invoice hospedada criada — `hostedPaymentUrl` disponível | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `provider`, `correlationId` |
| `payment.card.authorized` | Provedor autorizou antes da confirmação final | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `providerStatus` |
| `payment.card.risk_analysis.awaiting` | Pagamento em análise de risco no provedor | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |
| `payment.card.refused` | Autorização ou captura recusada | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `reasonCode` |
| `payment.confirmed` | Pagamento confirmado — pedido pode ser liberado | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `confirmedAt`, `correlationId` |
| `payment.card.refund.requested` | Refund solicitado para invoice confirmada | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`, `amount`, `reason` |
| `payment.card.refund.required` | Invoice confirmada não pode ser cancelada por DELETE — exige refund | `tenantId`, `orderId`, `invoiceId`, `providerPaymentId` |

### Eventos consumidos

| Evento | Origem | Ação |
|---|---|---|
| `PAYMENT_CONFIRMED` (Asaas webhook) | Asaas → `POST /webhook/payments` | Publica `payment.confirmed` exatamente uma vez |
| `PAYMENT_REFUSED` (Asaas webhook) | Asaas → `POST /webhook/payments` | Publica `payment.card.refused` com `reasonCode` |
| `PAYMENT_REFUNDED` (Asaas webhook) | Asaas → `POST /webhook/payments` | Confirma conclusão do refund |

### Schema de resposta (criação hosted)

```json
{
  "invoiceId": "...",
  "orderId": "...",
  "provider": "ASAAS",
  "providerPaymentId": "...",
  "status": "OPEN",
  "amount": 350.00,
  "currency": "BRL",
  "billingType": "CREDIT_CARD",
  "hostedPaymentUrl": "https://sandbox.asaas.com/i/..."
}
```

> Token de cartão, número completo e CVV nunca aparecem em logs, traces ou respostas de erro.

---

## 3. Service Team

| Papel | Time / Nome | Canal | Tempo de resposta (SEV1) |
|---|---|---|---|
| Owner (OBC + SLO) | Payments | `[link]` | < 15 min |
| On-call | Plataforma / SRE | `[link]` | < 5 min (pager) |
| PM responsável | Eugenio | `[link]` | < 30 min |
| Segurança (PCI boundary) | `[Squad Segurança]` | `[link]` | Consulta (não on-call) |

---

## 4. Service Architecture

```
Checkout
    │ POST /invoices  billingType=CREDIT_CARD
    │ X-Api-Token · Idempotency-Key
    ▼
Lambda Function URL → ApiTokenGuard → InvoiceController
    │
    ▼
InvoiceService
    ├─ DynamoDB PaymentsTable     (cria/atualiza invoice)
    │
    └─ Asaas PSP  POST /v3/payments (billingType=CREDIT_CARD)
         │  retorna: hostedPaymentUrl · providerPaymentId
         │
         │ (cliente acessa hostedPaymentUrl, insere dados do cartão no Asaas)
         │
         │ (confirmação assíncrona via webhook)
         ▼
Asaas → POST /webhook/payments  (PAYMENT_CONFIRMED / PAYMENT_REFUSED)
    │
    ▼
AsaasWebhookController → InvoiceService
    ├─ valida asaas-access-token
    ├─ persiste evento bruto
    ├─ publica payment.confirmed → EventEmitter2
    │     └─ WebhookDeliveryService → HTTPS POST consumer
    └─ DynamoDB PaymentsTable (atualiza status)

Refund:
Checkout → POST /invoices/:id/refund
    → InvoiceController → InvoiceService
    → Asaas POST /v3/payments/:id/refund
    → emite payment.card.refund.requested
```

**Dependências críticas:**

| Componente | Criticidade | Observação |
|---|---|---|
| Asaas hosted flow | Crítica | Dados de cartão nunca transitam pelo Payments API |
| DynamoDB PaymentsTable | Crítica | State store do invoice |
| Asaas webhook (confirmação) | Crítica | Único canal de confirmação de autorização |

---

## 5. Service Reliability

### SLOs (OBC `credit-card-authorization-confirmation`)

| SLO | Meta | Janela |
|---|---|---|
| Tentativas de cartão com resultado terminal conhecido (confirmado / recusado / análise / erro provedor) | 99% em 5 min | 30 dias |
| Confirmações publicadas uma única vez para consumidores | 99% em 30s | — |
| Recusas com `reasonCode` conhecido ou código de erro do provedor | 99% | — |
| Eventos de webhook correlacionados por `providerPaymentId` ou `externalReference` | 99,5% | — |
| Token de cartão, número e CVV ausentes de logs, traces e respostas de erro | 100% | — |

### SLIs observáveis

| SLI | Fonte |
|---|---|
| Taxa de confirmação (PAYMENT_CONFIRMED / hosted invoices criadas) | Datadog — evento `payment.confirmed` |
| Taxa de recusa com reasonCode (PAYMENT_REFUSED com código mapeado) | Datadog — `payment.card.refused` |
| Latência p95 de criação de invoice hospedada | Datadog APM |
| Taxa de refund completado | Datadog — `PAYMENT_REFUNDED` webhook |

### Regras de confiabilidade

- Invoice confirmada não pode ser cancelada por `DELETE` — exige fluxo de refund. O gateway emite `payment.card.refund.required` se `DELETE` for tentado.
- `payment.confirmed` é idempotente: webhook duplicado `PAYMENT_CONFIRMED` retorna sucesso sem republicar.
- Dados sensíveis de cartão nunca transitam pelo Payments API neste slice (hosted flow).

---

## 6. Service Analytics

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Volume de pagamentos iniciados por cartão | Adoção do meio de pagamento | Datadog | Diária |
| Taxa de confirmação de cartão | Autorização está funcionando? | `payment.confirmed` / invoices criadas | Tempo real |
| Taxa de recusa por `reasonCode` | Qual o motivo de recusa mais frequente? | `payment.card.refused.reasonCode` | Diária |
| Taxa de análise de risco | PSP está barrando muito ou pouco? | `payment.card.risk_analysis.awaiting` | Diária |
| Volume e taxa de sucesso de refunds | Estornos estão sendo processados? | `payment.card.refund.requested` + webhook | Diária |
| Latência p95 de criação de invoice | Hosted flow está rápido? | Datadog APM | Tempo real |

---

## 7. Service Consumers

| Consumidor | Tipo | Dependência | Impacto de degradação |
|---|---|---|---|
| Checkout | Direto (API) | `POST /invoices` → `hostedPaymentUrl` | Cliente sem URL de pagamento; conversão impactada |
| Order Management | Indireto (evento) | `payment.confirmed` via webhook | Pedido não liberado após autorização |
| Notification Service | Indireto (evento) | `payment.confirmed` / `payment.card.refused` | Cliente sem feedback sobre resultado |
| Financeiro / Conciliação | Indireto (evento) | Histórico de refunds e confirmações | Conciliação manual |
| Atendimento | Operacional | Status via `GET /invoices/:id` | Suporte sem rastreabilidade do resultado |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| OBC — Cartão de Crédito | [`prodops/artifacts/obcs/credit-card-authorization-confirmation.md`](../../../obcs/credit-card-authorization-confirmation.md) |
| BDD — Cartão | [`prodops/artifacts/bdd/credit-card-authorization-confirmation.feature`](../../../bdd/credit-card-authorization-confirmation.feature) |
| OBC — Confirmação de Pagamento | [`prodops/artifacts/obcs/payment-confirmation.md`](../../../obcs/payment-confirmation.md) |
| Product Deck Payments | [`prodops/artifacts/product/context/product-deck.md`](../product-deck.md) |

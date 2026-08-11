# Service Deck — Split Payment Pix + Boleto

> Tipo: Value Stream · Última atualização: 2026-08-10
> Business Intent: [PI-001](../../../business-intents/PI-001.md) · Business Signal: [BS-001](../../../business-signals/BS-001.md)

---

## 1. Service Vision

Para **sistemas integradores e Checkout da Magazine Siará**,
que **precisam oferecer ao cliente a possibilidade de dividir o valor de uma compra entre Pix e Boleto**,
a **Value Stream Split Payment Pix + Boleto**
é um **fluxo de criação, acompanhamento e conclusão de pagamentos divididos**
que **garante que o pedido só é liberado quando ambas as porções são confirmadas, com rastreabilidade completa por `splitPaymentId`, `pixInvoiceId` e `boletoInvoiceId`, e tratamento explícito de Boleto vencido sem cancelamento automático**.

Diferente de **criar dois pagamentos independentes e conciliar manualmente**,
este serviço **cria e acompanha as duas porções como unidade coesa, garante idempotência na criação, publica `split_payment.completed` apenas com ambas confirmadas e sinaliza a operação quando o Boleto expira com o Pix já pago**.

---

## 2. Service Endpoints (Data)

> Fonte: OBC [`prodops/artifacts/obcs/split-payment-pix-boleto.md`](../../../obcs/split-payment-pix-boleto.md)

### APIs públicas

| Endpoint | Contrato | Resultado |
|---|---|---|
| `POST /split-payments` | `orderId`, `pixAmount`, `boletoAmount`, `dueDate`, `Idempotency-Key`, `X-Api-Token` | `201` com `splitPaymentId`, `pixInvoiceId`, `boletoInvoiceId`, `status: PENDING_BOTH` |
| `GET /split-payments/:splitPaymentId` | `splitPaymentId`, `X-Api-Token` | Status atual com estado de cada porção |
| `POST /webhooks/split-payment/pix/:splitPaymentId` | `asaas-access-token` | Confirmação da porção Pix pelo provedor |
| `POST /webhooks/split-payment/boleto/:splitPaymentId` | `asaas-access-token` | Confirmação da porção Boleto pelo provedor |
| `POST /webhooks/split-payment/boleto/:splitPaymentId/expire` | `asaas-access-token` | Vencimento do Boleto sem pagamento |

### Eventos publicados

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `split_payment.created` | Split Payment criado — Pix e Boleto definidos | `splitPaymentId`, `orderId`, `pixAmount`, `boletoAmount`, `totalAmount`, `correlationId` |
| `split_payment.pix.confirmed` | Porção Pix confirmada pelo provedor | `splitPaymentId`, `orderId`, `pixInvoiceId`, `confirmedAt`, `correlationId` |
| `split_payment.boleto.confirmed` | Porção Boleto confirmada pelo provedor | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `confirmedAt`, `correlationId` |
| `split_payment.completed` | Ambas as porções confirmadas — pedido liberado | `splitPaymentId`, `orderId`, `completedAt`, `correlationId` |
| `split_payment.boleto.expired` | Boleto venceu sem pagamento — pedido pendente para investigação manual | `splitPaymentId`, `orderId`, `boletoInvoiceId`, `expiredAt`, `pixStatus`, `correlationId` |
| `split_payment.creation_failed` | Falha na criação do Split Payment | `orderId`, `reason`, `correlationId` |

### Eventos consumidos

| Evento | Origem | Ação |
|---|---|---|
| Webhook Pix (provedor) | Asaas → `POST /webhooks/split-payment/pix/:id` | Publica `split_payment.pix.confirmed`; se Boleto já confirmado, publica `split_payment.completed` |
| Webhook Boleto (provedor) | Asaas → `POST /webhooks/split-payment/boleto/:id` | Publica `split_payment.boleto.confirmed`; se Pix já confirmado, publica `split_payment.completed` |
| Webhook Boleto expire | Asaas → `POST /webhooks/split-payment/boleto/:id/expire` | Publica `split_payment.boleto.expired` com `pixStatus` |

### Schema de resposta (criação)

```json
{
  "splitPaymentId": "spl_abc123",
  "orderId": "ord_xyz789",
  "status": "PENDING_BOTH",
  "totalAmount": 500.00,
  "pix": {
    "invoiceId": "pix_111",
    "amount": 200.00,
    "status": "PENDING",
    "confirmedAt": null
  },
  "boleto": {
    "invoiceId": "bol_222",
    "amount": 300.00,
    "dueDate": "2026-08-19",
    "bankSlipUrl": "https://...",
    "identificationField": "...",
    "status": "PENDING",
    "confirmedAt": null
  },
  "createdAt": "2026-08-10T00:00:00Z",
  "completedAt": null
}
```

**Estados do `splitPaymentId`:** `PENDING_BOTH` → `PIX_CONFIRMED` | `BOLETO_CONFIRMED` → `COMPLETED` | `PENDING_INVESTIGATION`

---

## 3. Service Team

| Papel | Time / Nome | Canal | Tempo de resposta (SEV1) |
|---|---|---|---|
| Owner (OBC + SLO) | Payments | `[link]` | < 15 min |
| PM responsável | Eugenio | `[link]` | < 30 min |
| On-call | Plataforma / SRE | `[link]` | < 5 min (pager) |
| Operação (boleto vencido) | `[Operação/CX]` | `[link]` | SLA a definir antes do go-live |

---

## 4. Service Architecture

```
Checkout
    │ POST /split-payments
    │ X-Api-Token · Idempotency-Key
    ▼
Lambda Function URL → ApiTokenGuard → SplitPaymentController
    │
    ▼
SplitPaymentService
    ├─ DynamoDB PaymentsTable  (split + invoices Pix e Boleto)
    ├─ InvoiceService (Pix)    → Asaas POST /v3/payments (billingType=PIX)
    │      retorna: pixQrCode, pixCopiaECola
    └─ InvoiceService (Boleto) → Asaas POST /v3/payments (billingType=BOLETO)
           retorna: bankSlipUrl, identificationField

(confirmações assíncronas — paralelas e independentes)

Asaas Pix → POST /webhooks/split-payment/pix/:splitPaymentId
    → SplitPaymentWebhookController → SplitPaymentService
    ├─ atualiza porção Pix (CONFIRMED)
    ├─ se Boleto CONFIRMED → emite split_payment.completed → EventEmitter2
    └─ DynamoDB PaymentsTable

Asaas Boleto → POST /webhooks/split-payment/boleto/:splitPaymentId
    → SplitPaymentWebhookController → SplitPaymentService
    ├─ atualiza porção Boleto (CONFIRMED)
    ├─ se Pix CONFIRMED → emite split_payment.completed → EventEmitter2
    └─ DynamoDB PaymentsTable

Asaas Boleto Expire → POST /webhooks/split-payment/boleto/:splitPaymentId/expire
    → SplitPaymentWebhookController → SplitPaymentService
    ├─ emite split_payment.boleto.expired (com pixStatus)
    ├─ NÃO cancela automaticamente, NÃO estorna Pix
    └─ status → PENDING_INVESTIGATION
```

**Invariante crítica:** `pixAmount + boletoAmount = totalAmount` — validado antes de qualquer chamada ao provedor.

---

## 5. Service Reliability

### SLOs (OBC `split-payment-pix-boleto`)

| SLO | Meta | Janela |
|---|---|---|
| Criação com mesma `Idempotency-Key` retorna o mesmo `splitPaymentId` | 100% | — |
| `split_payment.completed` emitido em até 5s após segunda confirmação | 99% | 30 dias |
| `split_payment.boleto.expired` emitido em até 60min após vencimento | 99% | — |
| Pedido nunca liberado com apenas uma das porções confirmadas | 100% | — |
| `splitPaymentId` único por combinação `orderId` + meios | 100% | — |

### SLIs observáveis

| SLI | Fonte |
|---|---|
| Taxa de criação bem-sucedida (split_payment.created / tentativas) | Datadog |
| Taxa de completion (split_payment.completed / created) | Datadog |
| Taxa de boleto vencido com Pix pago (PENDING_INVESTIGATION) | Datadog — `split_payment.boleto.expired` com `pixStatus: confirmed` |
| Latência p95 de criação | Datadog APM |

### Regras de confiabilidade

- Boleto vencido com Pix já pago: estado muda para `PENDING_INVESTIGATION`. Sistema não cancela automaticamente nem estorna. Operação investiga manualmente dentro de prazo a definir antes do go-live.
- Falha no provedor de um meio não afeta o estado do outro já confirmado.
- Dados financeiros (valores, status) nunca expostos em respostas de erro públicas.

---

## 6. Service Analytics

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Volume de Split Payments criados | Adoção do novo meio | `split_payment.created` | Diária |
| Taxa de completion | Clientes completam os dois pagamentos? | `split_payment.completed` / `created` | Diária |
| Boletos vencidos com Pix pago | Operação manual necessária? | `split_payment.boleto.expired` (pixStatus=confirmed) | Diária / alert |
| Tempo médio entre criação e completion | Quanto tempo leva para o cliente concluir? | Datadog — timestamp delta | Semanal |
| Ticket médio de Split Payment | Split Payment é usado em compras de alto valor? | Datadog — `totalAmount` | Semanal |

---

## 7. Service Consumers

| Consumidor | Tipo | Dependência | Impacto de degradação |
|---|---|---|---|
| Checkout | Direto (API) | `POST /split-payments` → `pixQrCode` + `bankSlipUrl` | Cliente sem Split Payment disponível |
| Order Management | Indireto (evento) | `split_payment.completed` via webhook | Pedido não liberado |
| Notification Service | Indireto (evento) | `split_payment.completed` / `split_payment.boleto.expired` | Cliente sem feedback |
| Operação / CX | Operacional | `GET /split-payments/:id` + `split_payment.boleto.expired` | Incapaz de investigar boleto vencido |
| Financeiro / Conciliação | Indireto | Histórico de porções confirmadas | Conciliação de Split pendente |

---

## Decisões de produto registradas

| Decisão | Racional | Aprovação |
|---|---|---|
| Boleto vencido mantém pedido em investigação (não cancela) | Não estornar Pix automaticamente sem certeza; operação decide | Eugenio (PM), 2026-08-04 |
| Cartão fora do escopo deste slice | Prazo de 15 dias não permite; entra em fase posterior | Eugenio (PM), 2026-08-04 |
| Limite de 2 meios por Split | Pix + Boleto apenas; combinações adicionais fora deste OBC | Eugenio (PM), 2026-08-04 |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| OBC — Split Payment | [`prodops/artifacts/obcs/split-payment-pix-boleto.md`](../../../obcs/split-payment-pix-boleto.md) |
| Business Intent | [`prodops/artifacts/business-intents/PI-001.md`](../../../business-intents/PI-001.md) |
| Business Signal | [`prodops/artifacts/business-signals/BS-001.md`](../../../business-signals/BS-001.md) |
| BDD | [`prodops/artifacts/bdd/split-payment-pix-boleto.feature`](../../../bdd/split-payment-pix-boleto.feature) |
| Product Deck Payments | [`prodops/artifacts/product/context/product-deck.md`](../product-deck.md) |

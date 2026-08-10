# Service Deck — Cancelamento de Invoice

> Tipo: Service · Última atualização: 2026-08-10
> Status: OBC Committed — adiado para iteração posterior ao v0.0.1

---

## 1. Service Vision

Para **Checkout e sistemas operacionais da Magazine Siará**,
que **precisam cancelar cobranças pendentes sem risco de cobrar um cliente que já pagou ou cancelar duas vezes**,
o **Serviço de Cancelamento de Invoice**
é um **endpoint de cancelamento com idempotência, proteção de estado e confirmação auditável via evento canônico**
que **garante que `payment.cancelled` só é publicado após confirmação de remoção pelo provedor, impede cancelamento de invoices confirmadas e trata divergências do PSP com decisão operacional explícita**.

Diferente de **chamar diretamente o endpoint de deleção do Asaas**,
este serviço **protege contra duplicação, impede cancelamento pós-pagamento, persiste o estado intermediário `CANCEL_REQUESTED` e nunca declara cancelamento sem evidência confirmada**.

---

## 2. Service Endpoints (Data)

> Fonte: OBC [`prodops/artifacts/obcs/cancel-invoice.md`](../../../obcs/cancel-invoice.md)

### APIs públicas

| Endpoint | Contrato | Resultado |
|---|---|---|
| `DELETE /invoices/:invoiceId` | `invoiceId`, `Idempotency-Key`, `X-Api-Token` | `200` com status `CANCELLED` (confirmado) ou `CANCEL_REQUESTED` (aguardando provedor) |
| `POST /webhook/payments` | `asaas-access-token` | Recebe `PAYMENT_DELETED` do provedor para concluir cancelamento async |

### Eventos publicados

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `invoice.cancel_requested` | Cancelamento iniciado — `CANCEL_REQUESTED`; chamada ao provedor pendente | `invoiceId`, `orderId`, `tenantId`, `provider`, `correlationId` |
| `payment.cancelled` | Invoice cancelada com confirmação do provedor | `invoiceId`, `orderId`, `tenantId`, `provider`, `providerPaymentId`, `cancelledAt`, `correlationId` |
| `invoice.cancel_rejected` | Cancelamento rejeitado — invoice em estado não cancelável (ex.: `CONFIRMED`) | `invoiceId`, `tenantId`, `currentStatus`, `correlationId` |
| `invoice.cancel_idempotency_hit` | Retentativa de cancelamento com mesma chave — invoice já cancelada retornada | `invoiceId`, `orderId`, `tenantId`, `correlationId` |
| `invoice.cancel_provider_not_found` | Provedor retornou 404 — aguarda decisão operacional de conciliação | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |
| `webhook.payment_deleted` | Webhook `PAYMENT_DELETED` do provedor confirma cancelamento para `CANCEL_REQUESTED` | `invoiceId`, `tenantId`, `provider`, `providerPaymentId`, `correlationId` |

### Eventos consumidos

| Evento | Origem | Ação |
|---|---|---|
| `PAYMENT_DELETED` (Asaas webhook) | Asaas → `POST /webhook/payments` | Conclui cancelamento de invoice em `CANCEL_REQUESTED`; publica `payment.cancelled` se não publicado ainda |

---

## 3. Service Team

| Papel | Time / Nome | Canal | Tempo de resposta (SEV1) |
|---|---|---|---|
| Owner (OBC + SLO) | Payments | `[link]` | < 15 min |
| On-call | Plataforma / SRE | `[link]` | < 5 min (pager) |
| Operação (provider 404) | `[Operação]` | `[link]` | SLA operacional |

---

## 4. Service Architecture

```
Checkout / Operação
    │ DELETE /invoices/:invoiceId
    │ X-Api-Token · Idempotency-Key
    ▼
Lambda Function URL → ApiTokenGuard → InvoiceController
    │
    ▼
InvoiceService
    ├─ DynamoDB PaymentsTable  (lê status atual)
    │   ├─ status CONFIRMED → emite cancel_rejected → rejeita com 422
    │   ├─ Idempotency-Key hit → retorna CANCELLED sem chamar provedor
    │   └─ status OPEN → atualiza para CANCEL_REQUESTED
    │
    └─ Asaas DELETE /v3/payments/:providerPaymentId
         ├─ 200 OK → atualiza para CANCELLED → emite payment.cancelled
         ├─ 404    → emite cancel_provider_not_found → aguarda operação
         └─ 5xx   → mantém CANCEL_REQUESTED → retry seguro pelo Checkout

(confirmação async via webhook)
Asaas → POST /webhook/payments (PAYMENT_DELETED)
    → AsaasWebhookController → InvoiceService
    ├─ se invoice em CANCEL_REQUESTED → atualiza para CANCELLED
    ├─ se payment.cancelled não publicado ainda → emite uma única vez
    └─ DynamoDB PaymentsTable
```

---

## 5. Service Reliability

### SLOs (OBC `cancel-invoice`)

| SLO | Meta | Janela |
|---|---|---|
| Invoices `CONFIRMED` rejeitadas ao cancelamento sem chamada ao provedor | 100% | — |
| Retentativas com mesma `Idempotency-Key` retornam `CANCELLED` sem nova chamada | 100% | — |
| `payment.cancelled` não publicado sem confirmação ou decisão explícita | 100% | — |
| `payment.cancelled` não duplicado quando webhook `PAYMENT_DELETED` chegar após publicação | 100% | — |
| Invoice em `CANCEL_REQUESTED` transitada para `CANCELLED` ao receber `PAYMENT_DELETED` | 99,9% | — |

### SLIs observáveis

| SLI | Fonte |
|---|---|
| Taxa de cancelamentos bem-sucedidos vs. rejeitados | Datadog — `payment.cancelled` / tentativas |
| Taxa de `cancel_provider_not_found` (404 Asaas) | Datadog — `invoice.cancel_provider_not_found` |
| Invoice em `CANCEL_REQUESTED` sem resolução > N min | Datadog — alerta de estado estagnado |

### Regras de confiabilidade

- `payment.cancelled` é idempotente: webhook duplicado `PAYMENT_DELETED` não republica o evento.
- Invoice `CONFIRMED` → cancelamento rejeitado com erro de negócio. Estorno requer fluxo separado.
- Provedor 404 → investigação operacional, não cancelamento automático.

---

## 6. Service Analytics

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Volume de cancelamentos por dia | Qual a frequência de desistências? | `payment.cancelled` | Diária |
| Taxa de rejeição por status (CONFIRMED) | Cancelamentos de invoices já pagas? | `invoice.cancel_rejected` | Diária |
| Volume de provider_not_found | PSP está dessincronizado? | `invoice.cancel_provider_not_found` | Diária / alert |
| Invoices em CANCEL_REQUESTED > threshold | Cancelamento async está sendo concluído? | DynamoDB scan / Datadog | Alert |

---

## 7. Service Consumers

| Consumidor | Tipo | Dependência | Impacto de degradação |
|---|---|---|---|
| Checkout | Direto (API) | `DELETE /invoices/:id` | Checkout não consegue cancelar cobrança pendente |
| Operação | Direto (API + eventos) | `cancel_provider_not_found` + investigação | Cancelamentos ficam em limbo sem resolução |
| Order Management | Indireto (evento) | `payment.cancelled` via webhook | Pedido pode não ser desmarcado corretamente |
| Financeiro / Conciliação | Indireto (evento) | `payment.cancelled` | Conciliação com Asaas pode ter divergência |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| OBC — Cancelamento | [`prodops/artifacts/obcs/cancel-invoice.md`](../../../obcs/cancel-invoice.md) |
| BDD | [`prodops/artifacts/bdd/cancel-invoice.feature`](../../../bdd/cancel-invoice.feature) |
| Icebox | [`prodops/artifacts/product/backlogs/icebox-backlog.md`](../../backlogs/icebox-backlog.md) — PAY-ICE-003 |
| Product Deck Payments | [`prodops/artifacts/product/context/product-deck.md`](../product-deck.md) |

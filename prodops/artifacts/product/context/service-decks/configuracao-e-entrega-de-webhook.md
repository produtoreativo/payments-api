# Service Deck — Configuração e Entrega de Webhook

> Tipo: Service · Última atualização: 2026-08-10

---

## 1. Service Vision

Para **sistemas integradores da Magazine Siará (Checkout, Order Management)**,
que **precisam ser notificados automaticamente sobre mudanças de status de pagamento sem polling ativo na Payments API**,
o **Serviço de Configuração e Entrega de Webhook**
é um **mecanismo de registro de endpoints e entrega assíncrona de eventos de domínio com assinatura HMAC-SHA256**
que **permite ao consumidor verificar autenticidade de cada entrega, garante que falhas de entrega não bloqueiam o fluxo de confirmação de pagamento e registra toda tentativa de entrega como evento observável**.

Diferente de **o consumidor fazer polling em `GET /invoices/:id`**,
este serviço **entrega proativamente cada `payment.confirmed` e `payment.cancelled` em até 5 segundos, com cabeçalho de assinatura verificável e `deliveryId` rastreável**.

---

## 2. Service Endpoints (Data)

> Fonte: OBC [`prodops/artifacts/obcs/webhook-configuration.md`](../../../obcs/webhook-configuration.md)

### APIs públicas

| Endpoint | Contrato | Resultado |
|---|---|---|
| `POST /webhooks` | `url`, `events[]`, `description?`, `X-Api-Token` | `201` com `webhookId`, `secret` (único momento de exposição) |
| `GET /webhooks` | `X-Api-Token` | Lista de webhooks do tenant com metadata; **sem `secret`** |
| `DELETE /webhooks/:webhookId` | `webhookId`, `X-Api-Token` | Webhook removido; entregas futuras cessam |

### Eventos publicados

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `webhook.registered` | Webhook cadastrado para um token | `tenantId`, `tokenId`, `webhookId`, `url` (mascarada), `events[]`, `correlationId` |
| `webhook.deleted` | Webhook removido | `tenantId`, `tokenId`, `webhookId`, `correlationId` |
| `webhook.delivery.sent` | Entrega HTTP bem-sucedida (2xx) | `tenantId`, `webhookId`, `event`, `deliveryId`, `durationMs` |
| `webhook.delivery.failed` | Entrega HTTP falhou (não-2xx ou timeout) | `tenantId`, `webhookId`, `event`, `deliveryId`, `statusCode`, `reason` |

### Eventos consumidos (entrega disparada por)

| Evento interno | Payload entregue ao consumer | Trigger |
|---|---|---|
| `payment.confirmed` | `invoice.confirmed` | `InvoiceService` → `EventEmitter2` → `WebhookDeliveryService` |
| `payment.cancelled` | `invoice.cancelled` | `InvoiceService` → `EventEmitter2` → `WebhookDeliveryService` |

### Payload entregue ao consumer

```json
{
  "deliveryId": "uuid-v4",
  "webhookId": "wh_xxx",
  "event": "invoice.confirmed",
  "tenantId": "magazine-siara",
  "timestamp": "2026-08-10T10:00:00.000Z",
  "payload": {
    "invoiceId": "...",
    "orderId": "...",
    "providerPaymentId": "...",
    "amount": 159.90,
    "currency": "BRL",
    "status": "CONFIRMED",
    "confirmedAt": "2026-08-10T10:00:00.000Z"
  }
}
```

**Headers na entrega:**
- `X-Payments-Signature: sha256=<hmac-sha256 do body com o secret do webhook>`
- `X-Payments-Delivery-Id: <deliveryId>`
- `Content-Type: application/json`

### Schema de resposta (criação)

```json
{
  "webhookId": "wh_abc123",
  "tenantId": "magazine-siara",
  "url": "https://consumer.example.com/webhooks/payments",
  "events": ["invoice.confirmed", "invoice.cancelled"],
  "secret": "whsec_xxxxxxxx",
  "createdAt": "2026-08-10T00:00:00Z"
}
```

> `secret` aparece **somente na criação**. Nunca em listagem, log ou trace.

---

## 3. Service Team

| Papel | Time / Nome | Canal | Tempo de resposta (SEV1) |
|---|---|---|---|
| Owner (OBC + SLO) | Payments | `[link]` | < 15 min |
| On-call (DLQ / entrega) | Plataforma / SRE | `[link]` | < 5 min (pager) |
| Consumidor responsável | `[Squad Checkout / Orders]` | `[link]` | SLA de integração |

---

## 4. Service Architecture

```
Consumidor (tenant)
    │ POST /webhooks
    │ X-Api-Token
    ▼
ApiTokenGuard → WebhookConfigController → WebhookService
    └─ DynamoDB WebhooksTable
         PK: TOKEN#{tokenId} · SK: WEBHOOK#{webhookId}
         GSI1: TENANT#{tenantId}

(entrega disparada por evento interno)

InvoiceService
    │ emit payment.confirmed | payment.cancelled
    ▼
EventEmitter2
    │ @OnEvent payment.confirmed | payment.cancelled
    ▼
WebhookDeliveryService
    ├─ DynamoDB WebhooksTable (busca por tenant via GSI1)
    ├─ filtra por events[]
    ├─ assina body com HMAC-SHA256 (secret)
    ├─ HTTPS POST → consumer endpoint
    │   ├─ 2xx → emite webhook.delivery.sent
    │   └─ não-2xx / timeout → emite webhook.delivery.failed
    │                           (sem retry automático neste slice)
    └─ emite payments.observability → ObservabilityListener → Datadog

Fila SQS (modo async para Worker Lambda):
Worker → InvoiceService.processProviderWebhook
    → emit payment.confirmed → mesmo caminho acima
```

**Dependências:**

| Componente | Criticidade | Observação |
|---|---|---|
| WebhooksTable (DynamoDB) | Alta | Configurações de webhook dos tenants |
| Consumer endpoint (HTTPS) | Dependência externa | Falha de entrega não bloqueia confirmação |
| EventEmitter2 | Alta | Bus interno; falha impede disparos de entrega |

**Invariante:** entrega de webhook é **fire-and-forget** — falha não bloqueia `payment.confirmed` nem o fluxo de liberação de pedido.

---

## 5. Service Reliability

### SLOs (OBC `webhook-configuration`)

| SLO | Meta | Janela |
|---|---|---|
| Webhooks registrados com URL válida retornam `201` com `webhookId` e `secret` | 100% | — |
| `secret` ausente em listagem, logs e respostas após criação | 100% | — |
| Entregas de `invoice.confirmed` disparadas em até 5s após evento | 95% | 30 dias |
| Falha de entrega não bloqueia fluxo de confirmação | 100% | — |
| `webhook.delivery.failed` emitido para toda entrega com não-2xx ou timeout | 100% | — |

### SLIs observáveis

| SLI | Fonte |
|---|---|
| Taxa de entrega bem-sucedida (`webhook.delivery.sent` / tentativas) | Datadog |
| Taxa de falha de entrega por consumer | Datadog — `webhook.delivery.failed.tenantId` |
| Latência p95 de entrega | Datadog — `webhook.delivery.sent.durationMs` |
| Webhooks ativos por tenant | WebhooksTable |

### Regras de confiabilidade

- Máximo de 10 webhooks por `tokenId`.
- URL deve ser `https://` em produção; `http://` aceito somente para `localhost`/`127.0.0.1`.
- `secret` não pode ser alterado — apenas recriado com novo webhook.
- URL é mascarada em logs (apenas domínio, sem path).
- Sem retry automático neste slice — falha de entrega é observável mas não bloqueante.

---

## 6. Service Analytics

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Taxa de entrega bem-sucedida por tenant | Consumer está recebendo eventos? | `webhook.delivery.sent` / tentativas | Tempo real |
| Volume de falhas de entrega por consumer | Qual consumer tem endpoint instável? | `webhook.delivery.failed.tenantId` | Diária / alert |
| Latência p95 de entrega | Eventos chegam rápido ao consumer? | `durationMs` | Tempo real |
| Webhooks ativos vs. registrados | Quantos tenants usam notificações? | WebhooksTable | Semanal |
| Tempo entre `payment.confirmed` e entrega | SLO de 5s está sendo cumprido? | Datadog — delta timestamp | Tempo real |

---

## 7. Service Consumers

| Consumidor | Tipo | Dependência | Impacto de degradação |
|---|---|---|---|
| Checkout | Direto (API config) | `POST /webhooks` para registrar endpoint | Sem impacto no pagamento; apenas configuração |
| Order Management | Indireto (entrega) | `invoice.confirmed` para liberar pedido | Pedido liberado com atraso ou por polling |
| Notification Service | Indireto (entrega) | `invoice.confirmed` / `invoice.cancelled` | Cliente sem notificação proativa |
| Sistemas integradores (tenant) | Direto (entrega) | Recebe todos os eventos configurados | Integração cai para polling |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| OBC — Webhook Configuration | [`prodops/artifacts/obcs/webhook-configuration.md`](../../../obcs/webhook-configuration.md) |
| BDD | [`prodops/artifacts/bdd/webhook-configuration.feature`](../../../bdd/webhook-configuration.feature) |
| Architecture Overview | [`prodops/artifacts/architecture/overview.md`](../../../architecture/overview.md) |
| Product Deck Payments | [`prodops/artifacts/product/context/product-deck.md`](../product-deck.md) |

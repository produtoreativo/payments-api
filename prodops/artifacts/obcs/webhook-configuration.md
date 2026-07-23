# OBC - Webhook Configuration

## Status

Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` (section "Iteration Plan recomendado").

## Business Outcome

Magazine Siará pode registrar uma URL de webhook associada ao seu token de API e
receber notificações automáticas a cada mudança de status de pagamento relevante,
sem precisar consultar a Payments API ativamente. O sistema assina cada entrega
com HMAC-SHA256 para que o receptor possa verificar a autenticidade. Ambientes
locais funcionam sem configuração adicional de certificado.

## Observable Events

| Event | Meaning | Required dimensions |
| --- | --- | --- |
| `webhook.registered` | Novo webhook foi cadastrado para um token. | `tenantId`, `tokenId`, `webhookId`, `url` (mascarada), `events[]`, `correlationId` |
| `webhook.deleted` | Webhook foi removido. | `tenantId`, `tokenId`, `webhookId`, `correlationId` |
| `webhook.delivery.sent` | Entrega HTTP foi disparada com sucesso (2xx). | `tenantId`, `webhookId`, `event`, `deliveryId`, `durationMs` |
| `webhook.delivery.failed` | Entrega HTTP falhou ou retornou status não-2xx. | `tenantId`, `webhookId`, `event`, `deliveryId`, `statusCode`, `reason` |

## Domain Events Delivered to Webhooks

| Evento interno | Nome no payload externo | Trigger |
| --- | --- | --- |
| `payment.confirmed` | `invoice.confirmed` | Pagamento confirmado pelo provedor |
| `payment.cancelled` | `invoice.cancelled` | Invoice cancelada |

## Webhook Payload Contract

```json
{
  "deliveryId": "uuid-v4",
  "webhookId": "wh_xxx",
  "event": "invoice.confirmed",
  "tenantId": "magazine-siara",
  "timestamp": "2026-07-03T10:00:00.000Z",
  "payload": {
    "invoiceId": "...",
    "orderId": "...",
    "providerPaymentId": "...",
    "amount": 159.90,
    "currency": "BRL",
    "status": "CONFIRMED",
    "confirmedAt": "2026-07-03T10:00:00.000Z"
  }
}
```

Headers na entrega:
- `X-Payments-Signature: sha256=<hmac-sha256 do body com o secret do webhook>`
- `X-Payments-Delivery-Id: <deliveryId>`
- `Content-Type: application/json`

## Initial SLIs

| SLI | Initial target |
| --- | --- |
| Webhooks registrados com URL válida retornam `201` com `webhookId` e `secret`. | 100% |
| `secret` aparece apenas na resposta de criação; nunca em listagem ou log. | 100% |
| Entregas para `invoice.confirmed` disparadas em até 5 segundos após o evento. | 95% |
| Falha de entrega não bloqueia o fluxo de confirmação de pagamento. | 100% |
| `webhook.delivery.failed` emitido para toda entrega com status não-2xx ou timeout. | 100% |

## Reliability Rules

- Máximo de 10 webhooks ativos por `tokenId`.
- URL deve ser `https://` em qualquer ambiente, exceto `localhost`/`127.0.0.1` que aceitam `http://`.
- O campo `secret` é gerado pelo sistema na criação e não pode ser alterado — apenas recriado com novo webhook.
- Falha de entrega é registrada de forma observável mas não causa retry automático neste primeiro slice.
- Webhook não interfere no caminho crítico de confirmação: a entrega é disparada em background (fire-and-forget).
- URL do webhook é mascarada em logs (apenas domínio, sem path completo).

## Data Model — DynamoDB WebhooksTable

### Tabela principal

```
PK:  TOKEN#{tokenId}
SK:  WEBHOOK#{webhookId}
```

### GSI1 — busca por tenant (usado na entrega)

```
GSI1PK: TENANT#{tenantId}
GSI1SK: WEBHOOK#{webhookId}
```

### Atributos

| Atributo | Tipo | Descrição |
| --- | --- | --- |
| `webhookId` | String | UUID v4 gerado na criação |
| `tokenId` | String | Token que registrou o webhook |
| `tenantId` | String | Tenant do token |
| `url` | String | URL de destino da entrega |
| `events` | StringSet | Ex: `["invoice.confirmed","invoice.cancelled"]` |
| `secret` | String | Chave HMAC gerada na criação; não exposta após criação |
| `description` | String? | Label opcional |
| `active` | Boolean | `true` enquanto o webhook estiver ativo |
| `createdAt` | String | ISO 8601 |
| `updatedAt` | String | ISO 8601 |

### Justificativa do modelo

- **PK por `tokenId`**: consulta de listagem por token é O(1) sem scan.
- **GSI1 por `tenantId`**: serviço de entrega consulta por tenant sem conhecer o raw token.
- **`events` como StringSet**: filtragem eficiente no DynamoDB sem necessidade de GSI adicional.
- **`secret` separado da URL**: permite trocar URL re-registrando; revogação é por deleção.
- **Sem TTL neste slice**: retenção indefinida; TTL para itens inativos pode ser adicionado em iteração posterior.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/webhook-configuration.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBC relacionado: `prodops/artifacts/obcs/api-token-validation.md`

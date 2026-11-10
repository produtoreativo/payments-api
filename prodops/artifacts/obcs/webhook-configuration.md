# OBC - Webhook Configuration

## Metadados

| Campo | Valor |
|---|---|
| Owner | [apurar] |
| DS-ID | DS-43 |
| Iteração | v0.5.0 (retrabalho em v0.6.0) |
| Última atualização | 2026-11-10 |

## Status

**Estado:** In Delivery
**Rastreado em:** DS-43 (#43) — v0.5.0 (retrabalho em v0.6.0), PR #103. Registro anterior: Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` (section "Iteration Plan recomendado").
**Pendência:** iteração concluída (PR #103); candidato a `Operational` — confirmar implantação em produção antes de promover. Fonte: `prodops/artifacts/plans/iteration-plan.md`.

## Origem

| Elo | Referência |
|---|---|
| Business Signal | [BS-003](../business-signals/BS-003.md) |
| Business Intent | [PI-008](../business-intents/PI-008.md) |
| Product Tracking Item | issue #43 (DS-43), ver `prodops/artifacts/plans/iteration-plan.md` |

## Business Outcome

Magazine Siará pode registrar uma URL de webhook associada ao seu token de API e
receber notificações automáticas a cada mudança de status de pagamento relevante,
sem precisar consultar a Payments API ativamente. O sistema assina cada entrega
com HMAC-SHA256 para que o receptor possa verificar a autenticidade. Ambientes
locais funcionam sem configuração adicional de certificado.

## Escopo

**Dentro do escopo**

- [apurar]

**Fora de escopo**

- [apurar]

## Regras de Negócio

- [apurar]

## Critérios de Aceite

Derivados dos cenários de `prodops/artifacts/bdd/webhook-configuration.feature`; marcar após verificação.

- [ ] Registrar um webhook para receber confirmações de pagamento
- [ ] Registrar webhook com múltiplos eventos
- [ ] Listar webhooks do token autenticado
- [ ] Remover webhook registrado
- [ ] Rejeitar URL sem HTTPS em ambiente não-local
- [ ] Aceitar URL localhost em qualquer ambiente
- [ ] Rejeitar registro quando token já possui 10 webhooks
- [ ] Entregar evento ao webhook quando pagamento é confirmado
- [ ] Registrar falha de entrega sem bloquear o fluxo de pagamento
- [ ] Não entregar evento para webhook inativo
- [ ] Não expor secret em log ou resposta de listagem

## Contexto Enterprise

| Item | Conteúdo |
|---|---|
| Value Stream / Product Service | Service Deck: [configuracao-e-entrega-de-webhook](../product/context/service-decks/configuracao-e-entrega-de-webhook.md) |
| Stakeholders | [apurar] |
| Compliance | [apurar] |

## Observable Events

| Event | Situação | Meaning | Required dimensions |
|---|---|---|---|
| `webhook.registered` | Emitido | Novo webhook foi cadastrado para um token. | `tenantId`, `tokenId`, `webhookId`, `url` (mascarada), `events[]`, `correlationId` |
| `webhook.deleted` | Emitido | Webhook foi removido. | `tenantId`, `tokenId`, `webhookId`, `correlationId` |
| `webhook.delivery.sent` | Emitido | Entrega HTTP foi disparada com sucesso (2xx). | `tenantId`, `webhookId`, `event`, `deliveryId`, `durationMs` |
| `webhook.delivery.failed` | Emitido | Entrega HTTP falhou ou retornou status não-2xx. | `tenantId`, `webhookId`, `event`, `deliveryId`, `statusCode`, `reason` |

## Initial SLIs

| SLI | Initial target | Fonte |
|---|---|---|
| Webhooks registrados com URL válida retornam `201` com `webhookId` e `secret`. | 100% | [apurar] |
| `secret` aparece apenas na resposta de criação; nunca em listagem ou log. | 100% | [apurar] |
| Entregas para `invoice.confirmed` disparadas em até 5 segundos após o evento. | 95% | [apurar] |
| Falha de entrega não bloqueia o fluxo de confirmação de pagamento. | 100% | [apurar] |
| `webhook.delivery.failed` emitido para toda entrega com status não-2xx ou timeout. | 100% | [apurar] |

## Reliability Rules

- Máximo de 10 webhooks ativos por `tokenId`.
- URL deve ser `https://` em qualquer ambiente, exceto `localhost`/`127.0.0.1` que aceitam `http://`.
- O campo `secret` é gerado pelo sistema na criação e não pode ser alterado — apenas recriado com novo webhook.
- Falha de entrega é registrada de forma observável mas não causa retry automático neste primeiro slice.
- Webhook não interfere no caminho crítico de confirmação: a entrega é disparada em background (fire-and-forget).
- URL do webhook é mascarada em logs (apenas domínio, sem path completo).

## Domain Events Delivered to Webhooks

| Evento interno | Nome no payload externo | Trigger |
| --- | --- | --- |
| `payments.invoice.confirmed` | `invoice.confirmed` | Pagamento confirmado pelo provedor |
| `payments.invoice.cancelled` | `invoice.cancelled` | Invoice cancelada |

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

## Riscos

| Risco | Severidade | Tratamento |
|---|---|---|
| [apurar] | [apurar] | ver `prodops/artifacts/risks/risks.md` |

## Dependências

| Tipo | Dependência | Observação |
|---|---|---|
| Serviço interno | DynamoDB | Crítica (Product Deck, seção 4) |

## Decisões

| Data | Decisão | Justificativa | Fonte |
|---|---|---|---|
| 2026-11-10 | Migração para o template `local-obc.md`: seções adicionadas, Status normalizado, eventos classificados por Situação e SLIs com Fonte. | Aderência ao template e à regra de que o nome do evento é o emitido no código. Campos sem fonte marcados `[apurar]`. | skill `obc` (modo `fix`); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/webhook-configuration.feature`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- OBC relacionado: `prodops/artifacts/obcs/api-token-validation.md`
- Service Deck: `prodops/artifacts/product/context/service-decks/configuracao-e-entrega-de-webhook.md`

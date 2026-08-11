# Service Deck — Autenticação via API Token

> Tipo: Service · Última atualização: 2026-08-10

---

## 1. Service Vision

Para **todos os consumidores da Payments API (Checkout, sistemas integradores, admin)**,
que **precisam garantir que apenas sistemas autorizados acessam a API com rastreabilidade por tenant e token**,
o **Serviço de Autenticação via API Token**
é um **guard transversal a todos os endpoints protegidos da Payments API**
que **valida cada requisição por token cadastrado com escopo de tenant, suporta revogação sem deploy e não adiciona latência observável ao caminho crítico**.

Diferente de **autenticação por API Key estática compartilhada**,
este serviço **associa cada token a um `tenantId` e `tokenId` rastreáveis, registra validações e rejeições como eventos observáveis, e nunca expõe o valor raw do token em logs ou respostas de erro**.

---

## 2. Service Endpoints (Data)

> Fonte: OBC [`prodops/artifacts/obcs/api-token-validation.md`](../../../obcs/api-token-validation.md)

### APIs públicas

| Endpoint | Contrato | Resultado |
|---|---|---|
| `POST /admin/tokens` | `tenantId`, `description`, `X-Admin-Secret` | `201` com `tokenId` e valor do token (único momento de exposição) |
| `GET /admin/tokens/:tenantId` | `tenantId`, `X-Admin-Secret` | Lista de `tokenId` e metadata; **nunca o valor raw** |
| `DELETE /admin/tokens/:tenantId/:tokenId` | `tenantId`, `tokenId`, `X-Admin-Secret` | Token revogado imediatamente |
| Todos os demais endpoints | `X-Api-Token` (header) | 401 se ausente, inválido ou revogado |

> **Rotas excluídas do guard:** `POST /webhook/payments` (usa `asaas-access-token`), `GET /health` (sem guard).

### Eventos publicados

| Evento | Significado | Dimensões obrigatórias |
|---|---|---|
| `api.token.validated` | Requisição autenticada com token válido | `tenantId`, `tokenId`, `correlationId`, `path`, `method` |
| `api.token.rejected` | Token ausente, inválido ou revogado | `correlationId`, `path`, `method`, `reason` |
| `api.token.registered` | Novo token cadastrado | `tenantId`, `tokenId`, `description`, `allowedOrigins` |
| `api.token.revoked` | Token revogado | `tenantId`, `tokenId`, `revokedBy`, `correlationId` |

### Schema de resposta (criação de token)

```json
{
  "tokenId": "tok_abc123",
  "tenantId": "magazine-siara",
  "token": "pmt_live_xxxxxxxxxxxxxxxxxxx",
  "description": "Checkout production",
  "createdAt": "2026-08-10T00:00:00Z"
}
```

> `token` aparece **somente na resposta de criação**. Nunca em listagem, log ou trace.

---

## 3. Service Team

| Papel | Time / Nome | Canal | Tempo de resposta (SEV1) |
|---|---|---|---|
| Owner (OBC + SLO) | Payments | `[link]` | < 15 min |
| On-call | Plataforma / SRE | `[link]` | < 5 min (pager) |
| Admin operacional | `[Ops / Plataforma]` | `[link]` | < 30 min |

---

## 4. Service Architecture

```
Qualquer consumidor
    │ X-Api-Token: pmt_live_...
    ▼
Lambda Function URL
    │
    ▼
ApiTokenGuard  (NestJS Guard — executa em toda requisição protegida)
    ├─ extrai header X-Api-Token
    ├─ valida contra mapa de tokens carregado na inicialização
    │   (fonte: TenantsTable DynamoDB ou variável de ambiente)
    ├─ emite api.token.validated → ObservabilityListener → Datadog
    └─ em falha: emite api.token.rejected → 401

Admin:
Operador → POST/GET/DELETE /admin/tokens
    │ X-Admin-Secret
    ▼
AdminTokenController → TenantsTable (DynamoDB)
    └─ emite api.token.registered | api.token.revoked

Ambiente local:
NODE_ENV=development → API_TOKEN_LOCAL pré-cadastrado
(localhost aceito sem secrets externos)
```

**Dependências:**

| Componente | Criticidade | Observação |
|---|---|---|
| TenantsTable (DynamoDB) | Crítica | Fonte dos tokens válidos — se indisponível, toda a API falha |
| Lambda initialization | Crítica | Mapa de tokens carregado no cold start |

---

## 5. Service Reliability

### SLOs (OBC `api-token-validation`)

| SLO | Meta | Janela |
|---|---|---|
| Requisições com token válido autorizadas com latência adicional < 5ms | 99,9% | 30 dias |
| Requisições com token ausente ou inválido rejeitadas com 401 e `reason` observável | 100% | — |
| Token de localhost válido em ambiente de desenvolvimento sem secrets externos | 100% | — |
| Token raw ausente em logs, traces e respostas de erro | 100% | — |

### SLIs observáveis

| SLI | Fonte |
|---|---|
| Taxa de validações bem-sucedidas (`api.token.validated` / total) | Datadog |
| Taxa de rejeições por motivo (`api.token.rejected.reason`) | Datadog |
| Latência do guard (overhead por requisição) | Datadog APM |
| Tokens revogados vs. ativos por tenant | TenantsTable / Admin API |

### Regras de confiabilidade

- Token raw nunca é logado — nem no sucesso nem na rejeição. Log registra apenas `tokenId`.
- Revogação é operacional sem deploy: DynamoDB reload (implementação futura de store externo).
- Máximo de tokens por tenant: a definir na implementação de limites.

---

## 6. Service Analytics

| Indicador | Pergunta que responde | Fonte | Cadência |
|---|---|---|---|
| Requisições por `tenantId` | Qual tenant usa mais a API? | `api.token.validated.tenantId` | Diária |
| Taxa de rejeição por rota | Qual endpoint gera mais rejeições? | `api.token.rejected.path` | Diária / alert |
| Tokens ativos por tenant | Proliferação de tokens? | TenantsTable | Semanal |
| Tentativas com token inválido | Ataque ou misconfiguration? | `api.token.rejected` spike | Alert |

---

## 7. Service Consumers

Este serviço é transversal — todos os consumidores da Payments API dependem dele:

| Consumidor | Tipo | Impacto se guard falhar |
|---|---|---|
| Checkout | Direto | Toda a API inacessível — checkout de pagamentos para |
| Order Management | Indireto | Sem impacto no guard (consome eventos, não a API diretamente) |
| Asaas (PSP) | Direto no webhook | Webhook usa `asaas-access-token` — não impactado pelo guard de token |
| Admin / Operação | Direto | `X-Admin-Secret` — guard separado |

---

## Artefatos relacionados

| Artefato | Localização |
|---|---|
| OBC — API Token Validation | [`prodops/artifacts/obcs/api-token-validation.md`](../../../obcs/api-token-validation.md) |
| BDD | [`prodops/artifacts/bdd/api-token-validation.feature`](../../../bdd/api-token-validation.feature) |
| Architecture Overview | [`prodops/artifacts/architecture/overview.md`](../../../architecture/overview.md) |
| Product Deck Payments | [`prodops/artifacts/product/context/product-deck.md`](../product-deck.md) |

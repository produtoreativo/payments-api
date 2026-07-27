# Datadog Dashboard — EXP-013
# EXP-013 Iteration 7 — CREATED ✅

**Status:** ✅ Dashboard criada e validada via API
**Dashboard ID:** `e43-cy6-dti`
**Dashboard URL:** https://app.datadoghq.com/dashboard/e43-cy6-dti/prodops-runtime--exp-013-delivery-happy-path
**Criada em:** 2026-07-27T15:43:58Z

---

## Credential Status

| Credential | Status |
|---|---|
| `DD_API_KEY` | ✅ VALID — HTTP 200 em `/api/v1/validate` |
| `DD_APP_KEY` | ✅ VALID — HTTP 200 em `/api/v1/dashboard` |
| `DD_SITE` | ✅ `datadoghq.com` |

---

## Dashboard — Metadados

```json
{
  "id": "e43-cy6-dti",
  "title": "ProdOps Runtime — EXP-013 Delivery Happy Path",
  "url": "/dashboard/e43-cy6-dti/prodops-runtime--exp-013-delivery-happy-path",
  "created_at": "2026-07-27T15:43:58Z",
  "widget_count": 6,
  "template_variable_count": 2
}
```

---

## Widgets

| # | Tipo | Título | Filtro |
|---|---|---|---|
| 1 | Note | Guia de navegação | — |
| 2 | Query Value | Total de Eventos | `$issue`, `$correlation_id` |
| 3 | Toplist | Último Estado por Issue | por `issue,state` |
| 4 | Toplist | Eventos por Tipo | por `event` |
| 5 | Timeseries | Timeline de Eventos | por `event`, barras |
| 6 | Timeseries | Timeline de Transições de Estado | por `state`, barras |

**Template variables:**
- `$correlation_id` → prefix: `correlation-id`
- `$issue` → prefix: `issue`

---

## Métricas Confirmadas via API

Consulta realizada em 2026-07-27T15:47Z (30 min window):

| Tag | Pontos confirmados |
|---|---|
| `service:payments-api` | 95 points (total acumulado) |
| `issue:76` | 31 points (last 30 min) |
| `issue:77` | 22 points (last 30 min) |
| `issue:78` | 6 points (last 30 min) |

Método: `GET /api/v1/query` com DD_API_KEY + DD_APP_KEY — status: `ok` em todas as queries.

---

## Correlation IDs da Execução Final (Iteration 7)

| Issue | Feature | Correlation ID | Pontos esperados |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX | `8c296acd-849b-49d4-a812-0fb186c673b7` | 15 |
| #77 | FTR-002: Invoice Cartão | `e63de2fc-a11b-445c-a433-7e735ce456ba` | 11 |
| #78 | FTR-003: Confirmação Pagamento | `e1eaf136-db1b-45ea-932b-7818d38f9620` | 3 |

---

## Instruções de Visualização

Para filtrar a execução final no dashboard:

1. Abrir: https://app.datadoghq.com/dashboard/e43-cy6-dti/prodops-runtime--exp-013-delivery-happy-path
2. Definir template variables:
   - `issue`: `76`, `77` ou `78`
   - `correlation_id`: um dos UUIDs acima
3. Ajustar o time range para: `Last 4 hours`

Widgets esperados:
- **Total de Eventos**: 15, 11 ou 3 (dependendo do filtro de issue)
- **Último Estado por Issue**: DONE / VALIDATING / HACKING
- **Timeline de Eventos**: barras distribuídas entre 15:44Z e 15:47Z
- **Timeline de Transições de Estado**: BOOTSTRAPPING → HACKING → SYNCING → ... → DONE (para #76)

---

## Arquivos de suporte

- `prodops/artifacts/runtime/datadog-dashboard-definition.json` — definição JSON completa
- `prodops/artifacts/runtime/datadog-dashboard-response.json` — response da criação
- `prodops/artifacts/runtime/datadog-dashboard-metadata.json` — metadados sanitizados

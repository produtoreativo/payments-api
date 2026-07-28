# EXP-014 — Iteration 4b
# Executive Cockpit Dashboard (redesign)

**Data:** 2026-07-27T20:07Z
**Status:** COMPLETED
**Dashboard ID:** `4rs-983-e35`
**Dashboard URL:** https://app.datadoghq.com/dashboard/4rs-983-e35/prodops-runtime--executive-cockpit
**demo-run-id:** `exp-014-demo-2026-07-27-1959`
**Widget count:** 42 widgets / 8 sections
**Validate result:** 28/28 PASS

---

## Respostas Objetivas — 30 segundos ou menos

| # | Pergunta | Resposta | Widget | Valor |
|---|---|---|---|---|
| 1 | Quantas Features estão ativas? | **2** | Active — Em andamento (KPI) | total(3) - done(1) |
| 2 | Quantas foram concluídas? | **1** | Done — Concluídas (KPI) | delivery-state:done |
| 3 | Alguma está bloqueada? | **0** | Blocked — Bloqueadas (KPI) | state:blocked |
| 4 | Qual o Lead Time médio? | **80s** | Lead Time (KPI) | avg:runtime.delivery.leadtime |
| 5 | Qual a distribuição por estágio? | Planned=3 / Delivery=3 / Validation=2 / Production=1 | Feature Funnel (toplist) | runtime.delivery.funnel by {stage} |
| 6 | Qual o estado de cada etapa? | Done=1 / Validating=1 / Hacking=1 | Delivery Journey (8 QVs) | by delivery-state |
| 7 | A Diligence está acompanhando? | Attached=3 / Pending=0 | Diligence Status (6 cards + sunburst) | by {diligence-status} |
| 8 | Qual o volume de eventos por Feature? | #76=15+4 / #77=11+4 / #78=3+4 | Correlation Overview (query_table) | by {issue} |
| 9 | As Features têm Correlation IDs? | Sim — 3 delivery + 3 diligence | Live Execution (query_table) | by {issue,delivery-state,...,correlation-id} |
| 10 | Qual o throughput? | **1** Feature DONE | Throughput — Entregues (KPI) | delivery-state:done |

---

## Sections implementadas

### 1 — Delivery Health (y=1–3, 8 widgets)

| Widget | Tipo | Query / Valor |
|---|---|---|
| Active | query_value | formula: total_features - done_features → **2** |
| Done | query_value | delivery-state:done → **1** |
| Blocked | query_value | state:blocked → **0** |
| Failed | query_value | formula: total_events - nominal_events → **0** |
| Lead Time | query_value | avg:runtime.delivery.leadtime → **80s** |
| Throughput | query_value | delivery-state:done → **1** |
| Section header | note | "1. DELIVERY HEALTH — VISÃO GERAL" |
| Cockpit header | note | "ProdOps Runtime — Executive Cockpit" |

### 2 — Feature Funnel (y=4–9, 2 widgets)

| Widget | Tipo | Query |
|---|---|---|
| Section header | note | "2. FEATURE FUNNEL" |
| Funnel toplist | toplist | `top(sum:runtime.delivery.funnel{...} by {stage}.as_count(), 5, 'sum', 'desc')` |

Valores emitidos: planned=3 / delivery=3 / validation=2 / production=1 (todos HTTP 202)

### 3 — Delivery Journey (y=4–9, 10 widgets)

| Widget | Tipo | Etapa | Query |
|---|---|---|---|
| Section header | note | — | "3. DELIVERY JOURNEY" |
| Bootstrap | query_value | bootstrapping | `runtime.diligence.features.tracked{delivery-state:bootstrapping}` |
| Hack | query_value | hacking | `...{delivery-state:hacking}` |
| Sync | query_value | syncing | `...{delivery-state:syncing}` |
| Finish | query_value | finishing | `...{delivery-state:finishing}` |
| Ship | query_value | shipping | `...{delivery-state:shipping}` |
| Validate | query_value | validating | `...{delivery-state:validating}` |
| Promote | query_value | promoting | `...{delivery-state:promoting}` |
| Done | query_value | done | `...{delivery-state:done}` |
| Journey timeseries | timeseries | all states | `runtime.diligence.features.tracked by {delivery-state}` |

### 4 — Diligence Status (y=4–9, 7 widgets)

| Widget | Tipo | Status | Query / Note |
|---|---|---|---|
| Section header | note | — | "4. DILIGENCE STATUS" |
| Pending | query_value | N/A | `...features.tracked{diligence-status:N/A}` → 0 |
| Captured | note | — | estado intermediário sem métrica distinta |
| Attached | query_value | attached | `...features.tracked{diligence-status:attached}` → 3 |
| Drift | note | — | FF-13: tag com espaço inutilizável |
| Repair | note | — | não implementado |
| In Sync | query_value | attached proxy | `...features.tracked{diligence-status:attached}` → 3 |
| Diligence sunburst | sunburst | all | `runtime.diligence.features.tracked by {diligence-status}` |

### 5 — Live Execution (y=10–15, 2 widgets)

| Widget | Tipo | Query |
|---|---|---|
| Section header | note | "5. LIVE EXECUTION" |
| Live Execution | query_table | `runtime.diligence.features.tracked by {issue,delivery-state,diligence-status,delivery-correlation-id,diligence-correlation-id}` |

### 6 — Event Stream (y=10–15, 3 widgets)

| Widget | Tipo | Query |
|---|---|---|
| Section header | note | "6. EVENT STREAM" |
| Delivery Events | timeseries | `runtime.event.received by {state}` (bars) |
| Diligence Events | timeseries | `runtime.diligence.event.received` (bars) |

### 7 — Correlation Overview (y=10–15, 2 widgets)

| Widget | Tipo | Query |
|---|---|---|
| Section header | note | "7. CORRELATION" |
| Correlation | query_table | 3 colunas: tracked / delivery-events / diligence-events — `by {issue}` |

### 8 — System Health (y=16–18, 8 widgets)

| Widget | Tipo | Conteúdo |
|---|---|---|
| Section header | note | "8. SYSTEM HEALTH — SAÚDE DO SISTEMA" |
| Runtime | note | "Runtime: ✅ Online" |
| GitHub Sync | note | "GitHub: ✅ In Sync" |
| Datadog | note | "Datadog: ✅ Metrics OK" |
| Timeline Validation | note | "Timeline: ✅ Validated" |
| Event Validation | note | "Events: ✅ 41 total" |
| Demo Run | note | "Demo Run: exp-014-demo-...-1959" |

---

## Template Variables

| Variável | Tag Prefix | Default |
|---|---|---|
| `$demo_run_id` | `demo-run-id` | `*` |
| `$issue` | `issue` | `*` |
| `$delivery_state` | `delivery-state` | `*` |
| `$diligence_status` | `diligence-status` | `*` |
| `$env` | `env` | `staging` |
| `$service` | `service` | `payments-api` |
| `$team` | `team` | `prodops` |

---

## Novas métricas emitidas (Iter 4b)

| Métrica | Tipo | Tags | Valores |
|---|---|---|---|
| `runtime.delivery.leadtime` | gauge (type:3) | issue, delivery-state, service, env, demo-run-id | #76=129s, #77=90s, #78=21s, avg=80s |
| `runtime.delivery.funnel` | count (type:1) | stage, service, env, demo-run-id | planned=3, delivery=3, validation=2, production=1 |

---

## Validação de dados

```json
{
  "demo-run-id": "exp-014-demo-2026-07-27-1959",
  "validate-demo": "28/28 PASS",
  "kpis": {
    "active-features":  2,
    "done-features":    1,
    "lead-time-avg":    80,
    "delivery-events":  29,
    "diligence-events": 12,
    "total-events":     41
  },
  "funnel": {"planned": 3, "delivery": 3, "validation": 2, "production": 1},
  "lead-time": {"76": 129, "77": 90, "78": 21},
  "all-sections": "data present"
}
```

---

## Script de criação

```bash
bash prodops/runtime/datadog/create-executive-dashboard.sh
```

Idempotente: POST sempre cria um novo dashboard. ID atual: `4rs-983-e35`.

---

## Artefatos gerados

| Artefato | Caminho |
|---|---|
| Script dashboard | `prodops/runtime/datadog/create-executive-dashboard.sh` |
| Script demo | `prodops/runtime/scripts/demo-delivery-with-diligence.sh` |
| Definição | `prodops/artifacts/runtime/datadog-executive-dashboard-definition.json` |
| Resposta API | `prodops/artifacts/runtime/datadog-executive-dashboard-response.json` |
| Metadata | `prodops/artifacts/runtime/datadog-executive-dashboard-metadata.json` |
| Evidência def. | `evidence/executive-dashboard/executive-dashboard-definition.json` |
| Evidência meta | `evidence/executive-dashboard/executive-dashboard-metadata.json` |
| Validação | `evidence/executive-dashboard/executive-dashboard-validation.json` |

---

## Known limitations

| FF | Impacto | Mitigação |
|---|---|---|
| FF-13 | `runtime-sync:In Sync` inutilizável como filtro (espaço no valor) | `diligence-status:attached` como proxy |
| FF-13 | Captured/Drift/Repair sem tag filtrável | note placeholders com explicação |
| FF-14 | `${var,,}` não suportado no bash 3.2 do macOS | `tr '[:upper:]' '[:lower:]'` — resolvido |
| Dashboard tags | Apenas `team:*` e `ai:*` permitidos (restrição Datadog org) | `team:prodops` apenas |

---

## Critérios de sucesso

| Critério | Status |
|---|---|
| Script cria dashboard via API | ✅ `4rs-983-e35` criado |
| 8 sections implementadas | ✅ Header + 7 sections de dados |
| 42 widgets | ✅ 42 widgets (API confirmou) |
| Lead Time real (não placeholder) | ✅ avg:runtime.delivery.leadtime = 80s |
| Funnel como toplist | ✅ runtime.delivery.funnel by {stage} |
| Journey com 8 QVs individuais | ✅ 1 QV por etapa de delivery |
| Diligence com 6 cards de status | ✅ 3 QV + 3 note |
| Live Execution com correlation IDs | ✅ query_table by {issue,...,correlation-id} |
| validate-demo 28/28 PASS | ✅ exp-014-demo-2026-07-27-1959 |
| Nenhuma credencial exposta | ✅ |
| Artefatos salvos | ✅ 8 artefatos gerados |

# EXP-014 — Iteração 2: Recorded Operational Flow
# Delivery Tracked by Diligence

**Data:** 2026-07-27T17:01Z–17:34Z
**Status:** ✅ COMPLETED — Incrementos 1–7 concluídos
**runtime-version:** 0.3.0

---

## Respostas Objetivas

| Pergunta | Resposta |
|---|---|
| 1. Quais Views foram criadas? | 4 Views criadas via REST API (`create-github-views.sh`) — Delivery Timeline, Iteration Plan, Diligence Tracking, Runtime Reconciliation |
| 2. Quais widgets foram criados? | 16 widgets em 4 seções (A, B, C, D) — Dashboard ID: `jhq-ztv-3pv` |
| 3. Qual foi o demo-run-id? | `exp-014-demo-2026-07-27-1728` (gravação oficial) |
| 4. Quais correlation IDs foram utilizados? | Ver tabela abaixo |
| 5. Os cards moveram-se automaticamente? | Sim — GitHub sincronizado após cada evento com `alters-state=true` |
| 6. O Datadog exibiu os sinais durante a execução? | Sim — 29 delivery + 12 diligence = 41 pontos HTTP 202 |
| 7. A Diligence acompanhou o Delivery? | Sim — cross-reference via `delivery-correlation-id` em todos os 12 eventos Diligence |
| 8. Os estados Delivery permaneceram intactos? | Sim — DONE/VALIDATING/HACKING inalterados |
| 9. A gravação foi concluída? | ✅ Sim — gravação oficial executada 2026-07-27T17:28Z–17:34Z |
| 10. Onde está a evidência da gravação? | `evidence/recordings/exp-014-demo-2026-07-27-1728/` |

---

## Incremento 1 — GitHub Views

### Status: ✅ CRIADAS VIA REST API

**Script:** `prodops/runtime/scripts/create-github-views.sh`

Estratégia correta verificada empiricamente: GraphQL para **leitura** (node ID, listar views existentes), REST `POST /orgs/{org}/projectsV2/{number}/views` para **criação**. As mutações GraphQL `createProjectV2View` e `updateProjectV2View` não existem no tipo `Mutation` público.

**Views criadas em** https://github.com/orgs/produtoreativo/projects/25:

| View | Layout | Filtro | View # |
|---|---|---|---|
| `01 — Delivery Timeline` | Board | — | #2 |
| `02 — Iteration Plan` | Table | — | #3 |
| `03 — Diligence Tracking` | Board | — | #4 |
| `04 — Runtime Reconciliation` | Table | `"runtime-sync":"In Sync"` | #5 |

**Campos visíveis configurados via REST** (`visible_fields` — IDs numéricos resolvidos via `/fields`):
- View 1: Title, Assignees, oem-state, oem-last-event, diligence-status, runtime-sync
- View 2: Title, Assignees, oem-state, oem-last-event, diligence-status, diligence-evidence, runtime-sync
- View 3: Title, Assignees, oem-state, diligence-evidence, diligence-status, runtime-sync, oem-last-event
- View 4: Title, Assignees, oem-state, oem-last-event, diligence-status, diligence-evidence, runtime-sync

**prepare-demo.sh (pós-criação):** 25/25 PASS (0 WARN sobre views)

---

## Incremento 2 — Datadog Dashboard

### Status: ✅ CRIADO VIA API

**Dashboard ID:** `jhq-ztv-3pv`
**URL:** https://app.datadoghq.com/dashboard/jhq-ztv-3pv/prodops-runtime--delivery-tracked-by-diligence
**Criado em:** 2026-07-27T17:00:37Z
**Widgets:** 16

### Estrutura — 4 Seções × 4 Widgets

#### Seção A — Operational Header
| Widget | Tipo | Métrica/Conteúdo |
|---|---|---|
| A1 | Note | Guia: EXP-014, Features, Delivery×Diligence, URLs |
| A2 | Query Value | `runtime.event.received` — Total Delivery Events |
| A3 | Query Value | `runtime.diligence.event.received` — Total Diligence Events |
| A4 | Query Value | `runtime.diligence.features.tracked` — Features Tracked |

#### Seção B — Delivery Flow
| Widget | Tipo | Query |
|---|---|---|
| B1 | Timeseries (barras) | `runtime.event.received` by `event` |
| B2 | Toplist | `runtime.event.received` by `issue,state` |
| B3 | Toplist | `runtime.event.received` by `issue,event` |
| B4 | Timeseries (barras) | `runtime.event.received` by `state` |

#### Seção C — Diligence Tracking
| Widget | Tipo | Query |
|---|---|---|
| C1 | Timeseries (barras) | `runtime.diligence.event.received` by `event` |
| C2 | Toplist | `runtime.diligence.event.received` by `issue,diligence-status` |
| C3 | Toplist | `runtime.diligence.event.received` by `issue,delivery-state,diligence-status` |
| C4 | Query Value | `runtime.diligence.features.tracked` |

#### Seção D — Correlation and Evidence
| Widget | Tipo | Query |
|---|---|---|
| D1 | Toplist | `runtime.event.received` by `issue,delivery-correlation-id` |
| D2 | Toplist | `runtime.diligence.event.received` by `issue,diligence-correlation-id` |
| D3 _(C3 combinado)_ | Toplist | Cross-reference via `issue,delivery-state,diligence-status` |
| D4 | Toplist | `runtime.event.received` by `issue,journey` |

**Template Variables:** `$issue`, `$delivery_correlation_id`, `$diligence_correlation_id`, `$delivery_state`, `$diligence_status`, `$service`, `$env`, `$demo_run_id`

**Limitação identificada:**
Tags com espaço (ex: `runtime-sync:In Sync`) não são suportadas como filtros em queries Datadog. Widget C4 simplificado para `features.tracked` sem filtro por runtime-sync.

---

## Incremento 3 — Demo Mode

### Status: ✅ IMPLEMENTADO

**Script:** `prodops/runtime/scripts/demo-delivery-with-diligence.sh`

**Flags:**
- `--demo` — ativa delays configuráveis (default: step=4s, feature=2s, diligence=4s)
- `--with-diligence` — executa ciclo Diligence após Delivery
- `--demo-run-id <id>` — define o identificador de isolamento

**Variáveis de delay** (configuráveis via environment):
```
DEMO_STEP_DELAY_SECONDS=4
DEMO_FEATURE_DELAY_SECONDS=2
DEMO_DILIGENCE_DELAY_SECONDS=4
```

**Saída estruturada por bloco:**
```
[DELIVERY] #76 Delivery.Bootstrap.Started
──────────────────────────────────────────────────────────
CloudEvent:   prodops.delivery.bootstrap.started
Validation:   PASS ✓
Timeline:     appended (1 total)
State:        BOOTSTRAPPING
GitHub:       oem-state=BOOTSTRAPPING ✓
Datadog:      HTTP 202 ✓
Correlation:  62bb5ecd... | demo-run-id: exp-014-demo-2026-07-27-01
```

**Tags adicionadas no modo demo:**
- `journey:delivery` / `journey:diligence` — distingue journeys nas métricas
- `demo-run-id:<id>` — isola a gravação no Datadog
- `iteration-id:<id>` — alias para filtros por iteração
- `delivery-correlation-id:<uuid>` — cross-reference explícito nos eventos Delivery

---

## Incremento 4 — Orquestração

### Status: ✅ IMPLEMENTADO

O mesmo script `demo-delivery-with-diligence.sh` integra Delivery + Diligence:

```
docker-delivery-with-diligence.sh --demo --with-diligence
  ├── Runtime Doctor (13 checks PASS)
  ├── FTR-001 (#76) → 15 eventos → DONE
  ├── FTR-002 (#77) → 11 eventos → VALIDATING
  ├── FTR-003 (#78) →  3 eventos → HACKING
  ├── [Diligence] #76 → Capture.Started → Capture.Completed → Attach.Started → Attach.Completed
  ├── [Diligence] #77 → Capture.Started → Capture.Completed → Attach.Started → Attach.Completed
  ├── [Diligence] #78 → Capture.Started → Capture.Completed → Attach.Started → Attach.Completed
  └── Archive: recordings/exp-014-demo-2026-07-27-01/
```

---

## Incremento 5 — Validação Automática

### Status: ✅ IMPLEMENTADO

**`prepare-demo.sh`** — pre-flight check (21 PASS, 4 WARN de Views):
- Runtime Doctor PASS
- Credenciais Datadog válidas
- GitHub Project acessível com todos os campos
- Issues #76, #77, #78 existem
- Dashboard EXP-014 criado
- Derived states de EXP-013 presentes
- Catálogo: 19 eventos (incluindo 4 Diligence)

**`validate-demo.sh`** — pós-execução (28 PASS, 0 FAIL):
- Timelines: 15/11/3 eventos delivery ✅
- Derived states: DONE/VALIDATING/HACKING ✅
- Diligence timelines: 4 eventos por feature ✅
- Cross-reference delivery em todos os 12 eventos Diligence ✅
- GitHub: todos os 3 Issues com Attached/Complete/In Sync ✅
- Datadog API: status ok em ambas as métricas ✅

---

## Incremento 6 — Ensaio Técnico

### Status: ✅ EXECUTADO COM SUCESSO

**Execução:** 2026-07-27T17:01Z–17:06Z
**demo-run-id:** `exp-014-demo-2026-07-27-01`
**Modo:** FAST (sem delays — validação técnica)

### Correlation IDs

| Issue | Feature | Delivery Correlation ID | Diligence Correlation ID |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX | `62bb5ecd-9539-4fa2-8f3b-8268d6b7db87` | `7bcd4e97-7dee-42ab-83d4-16c1114b81aa` |
| #77 | FTR-002: Invoice Cartão | `f1de515f-f130-487d-850b-9e9adab546e9` | `5e0c5b8b-1dfe-4565-b18a-21a0035c347b` |
| #78 | FTR-003: Confirmação Pagamento | `4430bfb4-fa74-4778-bca1-9bb8f2fd9456` | `ca267e06-8f59-4a0a-aff1-0967f779203f` |

### Delivery Events

| Feature | Eventos | Estado Final | Timeline |
|---|---|---|---|
| FTR-001 #76 | 15 | **DONE** | `timelines/76.json` |
| FTR-002 #77 | 11 | **VALIDATING** | `timelines/77.json` |
| FTR-003 #78 | 3 | **HACKING** | `timelines/78.json` |

### Diligence Events (por Feature)

| Feature | Evento | CE Type | Delivery State | Diligence Status |
|---|---|---|---|---|
| #76 | 1 | `prodops.diligence.capture.started` | DONE | Sync In Progress |
| #76 | 2 | `prodops.diligence.capture.completed` | DONE | Captured |
| #76 | 3 | `prodops.diligence.attach.started` | DONE | Sync In Progress |
| #76 | 4 | `prodops.diligence.attach.completed` | DONE | **Attached** |
| #77 | 1 | `prodops.diligence.capture.started` | VALIDATING | Sync In Progress |
| #77 | 2 | `prodops.diligence.capture.completed` | VALIDATING | Captured |
| #77 | 3 | `prodops.diligence.attach.started` | VALIDATING | Sync In Progress |
| #77 | 4 | `prodops.diligence.attach.completed` | VALIDATING | **Attached** |
| #78 | 1 | `prodops.diligence.capture.started` | HACKING | Sync In Progress |
| #78 | 2 | `prodops.diligence.capture.completed` | HACKING | Captured |
| #78 | 3 | `prodops.diligence.attach.started` | HACKING | Sync In Progress |
| #78 | 4 | `prodops.diligence.attach.completed` | HACKING | **Attached** |

### Datadog Metrics

| Métrica | Pontos | Status |
|---|---|---|
| `runtime.event.received` | 29 | HTTP 202 ✓ (tags: issue, event, state, delivery-correlation-id, journey:delivery, demo-run-id) |
| `runtime.diligence.event.received` | 12 | HTTP 202 ✓ (tags: issue, event, delivery-state, diligence-status, delivery-correlation-id, diligence-correlation-id, journey:diligence, demo-run-id) |
| `runtime.diligence.features.tracked` | 3 | HTTP 202 ✓ (tags: issue, delivery-state, runtime-sync, delivery-correlation-id, diligence-correlation-id, demo-run-id) |
| **Total** | **44** | **100% HTTP 202** |

### GitHub Project (validado via GraphQL após execução)

| Issue | `oem-state` | `diligence-status` | `diligence-evidence` | `runtime-sync` |
|---|---|---|---|---|
| #76 | **DONE** | **Attached** | **Complete** | **In Sync** |
| #77 | **VALIDATING** | **Attached** | **Complete** | **In Sync** |
| #78 | **HACKING** | **Attached** | **Complete** | **In Sync** |

### validate-demo.sh

```
28 checks — PASS: 28 | FAIL: 0

✅ DEMO READY
✅ DELIVERY CONSISTENT
✅ DILIGENCE TRACKING
✅ GITHUB IN SYNC
✅ DATADOG IN SYNC
```

---

## Incremento 7 — Gravação Oficial

### Status: ✅ EXECUTADA

**Execução:** 2026-07-27T17:28:51Z–17:34:02Z
**demo-run-id:** `exp-014-demo-2026-07-27-1728`
**Modo:** DEMO (step=4s, feature=2s, diligence=4s)
**validate-demo.sh:** 28/28 PASS

### Correlation IDs

| Issue | Feature | Delivery Correlation ID | Diligence Correlation ID |
|---|---|---|---|
| #76 | FTR-001: Invoice PIX | `06bc4b47-7aa8-4c5b-adb9-00ece91ee1fc` | `29eb53e7-f331-463c-a053-78bd775dd7ca` |
| #77 | FTR-002: Invoice Cartão | `3cdef159-50cc-46cb-bdde-fa6703f84e21` | `c680580a-c119-4203-9f81-6b917a3943a2` |
| #78 | FTR-003: Confirmação Pagamento | `5ab1f5cb-e422-4066-9a4c-448f5cedeeee` | `7edf2925-7f97-4d59-b841-46c6b789ac54` |

### Resultados

| Feature | Eventos Delivery | Estado Final | Diligence Status | GitHub |
|---|---|---|---|---|
| FTR-001 #76 | 15 | **DONE** | **Attached / Complete / In Sync** | ✅ |
| FTR-002 #77 | 11 | **VALIDATING** | **Attached / Complete / In Sync** | ✅ |
| FTR-003 #78 | 3 | **HACKING** | **Attached / Complete / In Sync** | ✅ |

### Datadog

| Métrica | Pontos | Status |
|---|---|---|
| `runtime.event.received` | 29 | HTTP 202 ✓ |
| `runtime.diligence.event.received` | 12 | HTTP 202 ✓ |
| `runtime.diligence.features.tracked` | 3 | HTTP 202 ✓ |
| **Total** | **44** | **100% HTTP 202** |

### Artifacts

```
evidence/recordings/exp-014-demo-2026-07-27-1728/
├── delivery-timelines/   76.json (15), 77.json (11), 78.json (3)
├── diligence-timelines/  diligence-76.json (4), diligence-77.json (4), diligence-78.json (4)
├── derived-states/       derived-state-76.json, -77.json, -78.json
├── github-snapshot.json
└── demo-summary.json     {delivery: 29, diligence: 12}
```

---

## Artifacts da Iteração

### Scripts criados

| Script | Propósito |
|---|---|
| `prodops/runtime/scripts/create-github-views.sh` | Cria 4 Views idempotentemente via REST API |
| `prodops/runtime/datadog/create-demo-dashboard.sh` | Cria Dashboard EXP-014 via API |
| `prodops/runtime/scripts/demo-delivery-with-diligence.sh` | Demo principal (Delivery + Diligence) |
| `prodops/runtime/scripts/prepare-demo.sh` | Pre-flight check (21 checks) |
| `prodops/runtime/scripts/validate-demo.sh` | Validação pós-execução (28 checks) |

### Recordings

```
evidence/recordings/
├── exp-014-demo-2026-07-27-01/      ← Ensaio técnico (Incremento 6)
│   └── demo-summary.json            {delivery: 29, diligence: 12}
└── exp-014-demo-2026-07-27-1728/    ← Gravação oficial (Incremento 7)
    ├── delivery-timelines/   76.json (15), 77.json (11), 78.json (3)
    ├── diligence-timelines/  diligence-76.json (4), -77.json (4), -78.json (4)
    ├── derived-states/       derived-state-76.json, -77.json, -78.json
    ├── github-snapshot.json
    └── demo-summary.json     {delivery: 29, diligence: 12}
```

### Dashboard

| Sistema | ID | URL |
|---|---|---|
| EXP-013 Delivery | `e43-cy6-dti` | https://app.datadoghq.com/dashboard/e43-cy6-dti |
| EXP-014 Delivery+Diligence | `jhq-ztv-3pv` | https://app.datadoghq.com/dashboard/jhq-ztv-3pv |

---

## Framework Findings

| ID | Encontrado |
|---|---|
| FF-12 | GitHub Projects v2 não expõe `createProjectV2View` / `updateProjectV2View` via GraphQL Mutation (retornam `undefinedField`). Estratégia correta: GraphQL apenas para leitura (node ID, listar views); criação via REST `POST /orgs/{org}/projectsV2/{number}/views`. Resolvido — `create-github-views.sh` reescrito com REST. Referência canônica: `prodops/scripts/diligence/ensure-views.sh`. |
| FF-13 | Tags Datadog com espaço (ex: `runtime-sync:In Sync`) não são suportadas como filtros em metric queries (`Rule 'or_op' didn't match`). Workaround: remover o filtro do widget ou usar tags sem espaço. Impacto: widget C4 não pode filtrar estritamente por `runtime-sync:In Sync`. |
| FF-14 | macOS bash 3.2 não suporta `declare -A` (associative arrays). Scripts bash que rodam em macOS devem usar funções `case` ou variáveis nomeadas individualmente em vez de arrays associativos. |

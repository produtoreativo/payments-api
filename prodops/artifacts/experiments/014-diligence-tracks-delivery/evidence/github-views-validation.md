# GitHub Views Validation — EXP-014

**Data:** 2026-07-27
**Projeto:** ProdOps — payments-api (#25)
**URL:** https://github.com/orgs/produtoreativo/projects/25
**Fonte:** `evidence/github-views-export.json`

---

## Views validadas via API

| View # | Nome | Layout | Filtro | Campos Configurados | Status |
|---|---|---|---|---|---|
| #2 | `01 — Delivery Timeline` | BOARD_LAYOUT | nenhum | Title, Assignees, oem-state, oem-last-event, diligence-status, runtime-sync | ✅ |
| #3 | `02 — Iteration Plan` | TABLE_LAYOUT | nenhum | Title, Assignees, oem-state, oem-last-event, diligence-status, diligence-evidence, runtime-sync | ✅ |
| #4 | `03 — Diligence Tracking` | BOARD_LAYOUT | nenhum | Title, Assignees, oem-state, oem-last-event, diligence-status, diligence-evidence, runtime-sync | ✅ |
| #5 | `04 — Runtime Reconciliation` | TABLE_LAYOUT | `"runtime-sync":"In Sync"` | Title, Assignees, oem-state, oem-last-event, diligence-status, diligence-evidence, runtime-sync | ✅ |

---

## Validação por View

### `01 — Delivery Timeline`

| Critério | Esperado | Verificado via API | Status |
|---|---|---|---|
| Layout | BOARD_LAYOUT | BOARD_LAYOUT | ✅ |
| Filtro | nenhum | null | ✅ |
| Campo oem-state | presente | ✅ | ✅ |
| Campo oem-last-event | presente | ✅ | ✅ |
| Campo diligence-status | presente | ✅ | ✅ |
| Campo runtime-sync | presente | ✅ | ✅ |
| Column by: oem-state | configurado | ⚠️ API não expõe — requer verificação manual no GitHub UI |

### `02 — Iteration Plan`

| Critério | Esperado | Verificado via API | Status |
|---|---|---|---|
| Layout | TABLE_LAYOUT | TABLE_LAYOUT | ✅ |
| Campo diligence-evidence | presente | ✅ | ✅ |
| Campo diligence-status | presente | ✅ | ✅ |
| Campo runtime-sync | presente | ✅ | ✅ |

### `03 — Diligence Tracking`

| Critério | Esperado | Verificado via API | Status |
|---|---|---|---|
| Layout | BOARD_LAYOUT | BOARD_LAYOUT | ✅ |
| Campo diligence-status | presente | ✅ | ✅ |
| Campo diligence-evidence | presente | ✅ | ✅ |
| Column by: diligence-status | configurado | ⚠️ API não expõe — requer verificação manual no GitHub UI |

### `04 — Runtime Reconciliation`

| Critério | Esperado | Verificado via API | Status |
|---|---|---|---|
| Layout | TABLE_LAYOUT | TABLE_LAYOUT | ✅ |
| Filtro | `"runtime-sync":"In Sync"` | `"runtime-sync":"In Sync"` | ✅ |
| Campo diligence-status | presente | ✅ | ✅ |
| Campo diligence-evidence | presente | ✅ | ✅ |
| Campo runtime-sync | presente | ✅ | ✅ |

---

## Limitação API

`Column by` (o agrupamento de colunas em views Board) não é retornado pelo GraphQL e não é configurável via REST (422 "not a permitted key"). O termo correto no GitHub UI é **"Column by"** — não "Group by".

Requer configuração manual no GitHub UI:
- `01 — Delivery Timeline` → **Column by:** `oem-state`
- `02 — Iteration Plan` → layout Board + **Column by:** `oem-state`
- `03 — Diligence Tracking` → **Column by:** `diligence-status`

**Instrução:** abrir https://github.com/orgs/produtoreativo/projects/25, selecionar a view Board, clicar em **"Column by"** no menu superior e selecionar o campo correspondente.

---

## Screenshots

Screenshots de cada view devem ser capturados manualmente durante a gravação e salvos em:
`evidence/recordings/<demo-run-id>/screenshots/github-view-*.png`

| Screenshot | Descrição |
|---|---|
| `github-view-01-delivery-timeline.png` | Board agrupado por oem-state com #76 DONE, #77 VALIDATING, #78 HACKING |
| `github-view-02-iteration-plan.png` | Table com todos os campos Delivery + Diligence visíveis |
| `github-view-03-diligence-tracking.png` | Board agrupado por diligence-status com progressão Attached |
| `github-view-04-runtime-reconciliation.png` | Table filtrado por In Sync mostrando as 3 features |

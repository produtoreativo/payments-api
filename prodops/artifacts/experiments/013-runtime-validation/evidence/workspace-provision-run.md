# Evidence: Workspace Provision — Execução Completa

**EXP-013 — Phase 1: Environment Preparation**
**Captured:** 2026-07-25
**Command:** `npx tsx src/cli.ts provision`
**Run:** #7 (idempotent convergência após correções de bugs)

---

## Bugs encontrados e corrigidos durante execução

| # | Bug | Correção |
|---|---|---|
| 1 | `gh project field-list` default `--limit 30` truncava campos | Aumentado para `--limit 100` em `listFields()` |
| 2 | `ensureField` chamava `listFields` N vezes (rate limit) | Refatorado: `provisioner.ts` chama `listFields` uma vez; passa `existingNames` |
| 3 | `createProjectV2View` não existe no schema GraphQL público | `ensureView` reformulada: log de instrução manual em vez de erro |
| 4 | `gh issue create --milestone 1` rejeita número | Corrigido para `--milestone "v0.1.0-runtime-pilot"` (nome) |

---

## Saída final (primeira execução que completou)

```
Provisioning workspace: "ProdOps — payments-api"
Owner: produtoreativo/payments-api
Iteration: IP-RUNTIME-001

[1/7] Project
  ✓ Project exists: "ProdOps — payments-api" (#24)

[2/7] Milestone
  ✓ Milestone exists: "v0.1.0-runtime-pilot" (#1)

[3/7] Fields
  ✓ Field exists: "witem type"
  ✓ Field exists: "witem repository"
  ✓ Field exists: "witem feature"
  ✓ Field exists: "witem obc"
  ✓ Field exists: "witem release"
  ✓ Field exists: "witem iteration"
  ✓ Field exists: "oem journey"
  ✓ Field exists: "oem cycle"
  ✓ Field exists: "oem phase"
  ✓ Field exists: "oem state"
  ✓ Field exists: "oem rework-count"
  ✓ Field exists: "oem blocked-since"
  ✓ Field exists: "diligence status"
  ✓ Field exists: "diligence evidence"
  ✓ Field exists: "runtime sync"
  ✓ Field exists: "runtime timeline-state"
  + Creating field: "oem last-event" (TEXT)
  + Creating field: "runtime last-sync" (DATE)

[4/7] Labels
  ~ Updating label: "journey:delivery"
  ~ Updating label: "journey:diligence"
  ~ Updating label: "journey:assessment"
  ~ Updating label: "phase:bootstrap"
  ~ Updating label: "phase:hack"
  ~ Updating label: "phase:sync"
  ~ Updating label: "phase:finish"
  + Creating label: "phase:ship"
  + Creating label: "phase:validate"
  + Creating label: "phase:promote"
  + Creating label: "runtime:pilot"
  + Creating label: "runtime:task"
  + Creating label: "runtime:blocked"
  + Creating label: "runtime:rework"
  + Creating label: "severity:high"
  + Creating label: "severity:medium"
  + Creating label: "severity:low"
  + Creating label: "finding:drift"
  + Creating label: "finding:missing-evidence"
  + Creating label: "finding:missing-event"
  + Creating label: "finding:runtime-error"
  + Creating label: "finding:manual-review"
  + Creating label: "evidence:missing"
  + Creating label: "evidence:partial"
  + Creating label: "evidence:complete"

[5/7] Views
  ! View "Iteration Plan" (TABLE_LAYOUT) requires manual creation
  ! View "Delivery Flow" (BOARD_LAYOUT) requires manual creation
  ! View "Diligence Flow" (BOARD_LAYOUT) requires manual creation
  ! View "Runtime Reconciliation" (TABLE_LAYOUT) requires manual creation
  ! View "Findings" (TABLE_LAYOUT) requires manual creation
  ! View "Evidence Readiness" (BOARD_LAYOUT) requires manual creation
  ! View "Release Scope" (TABLE_LAYOUT) requires manual creation

[6/7] Issues
  + Creating issue: "EPIC: ProdOps Runtime MVP"
  + Adding to project: "EPIC: ProdOps Runtime MVP"
  + Creating issue: "FTR-RUNTIME-001: Split Payment Creation — Happy Path"
  + Adding to project: "FTR-RUNTIME-001: Split Payment Creation — Happy Path"
  + Creating issue: "FTR-RUNTIME-002: Split Allocation Validation — Gate Failed + Rework"
  + Adding to project: "FTR-RUNTIME-002: Split Allocation Validation — Gate Failed + Rework"
  + Creating issue: "FTR-RUNTIME-003: Settlement Webhook Notification — Blocking + Drift"
  + Adding to project: "FTR-RUNTIME-003: Settlement Webhook Notification — Blocking + Drift"
  + Creating issue: "RT-01: Event Producer"
  + Adding to project: "RT-01: Event Producer"
  + Creating issue: "RT-02: Timeline Processor"
  + Adding to project: "RT-02: Timeline Processor"
  + Creating issue: "RT-03: GitHub Synchronizer"
  + Adding to project: "RT-03: GitHub Synchronizer"
  + Creating issue: "RT-04: Datadog Integration"
  + Adding to project: "RT-04: Datadog Integration"
  + Creating issue: "RT-05: Delivery Dashboard"
  + Adding to project: "RT-05: Delivery Dashboard"
  + Creating issue: "RT-06: Diligence Dashboard"
  + Adding to project: "RT-06: Diligence Dashboard"

[7/7] Done

  Project   : ProdOps — payments-api (#24)
  Milestone : v0.1.0-runtime-pilot (#1)
  Fields    : 18 defined
  Labels    : 25 defined
  Views     : 7 defined
  Issues    : 10 provisioned

  URL: https://github.com/orgs/produtoreativo/projects/24
```

---

## Recursos criados no GitHub

| Recurso | Quantidade | Status |
|---|---|---|
| Project | 1 (existente, reutilizado) | ✅ |
| Milestone | 1 (existente, reutilizado) | ✅ |
| Custom Fields | 18 | ✅ criados |
| Labels | 25 (7 atualizados, 18 criados) | ✅ |
| Views | 7 | ⚠️ requer criação manual |
| Issues | 10 (criados + adicionados ao projeto) | ✅ |

**Issues criados:**
- #66 EPIC: ProdOps Runtime MVP
- #67 FTR-RUNTIME-001: Split Payment Creation — Happy Path
- #68 FTR-RUNTIME-002: Split Allocation Validation — Gate Failed + Rework
- #69 FTR-RUNTIME-003: Settlement Webhook Notification — Blocking + Drift
- #70 RT-01: Event Producer
- #71 RT-02: Timeline Processor
- #72 RT-03: GitHub Synchronizer
- #73 RT-04: Datadog Integration
- #74 RT-05: Delivery Dashboard
- #75 RT-06: Diligence Dashboard

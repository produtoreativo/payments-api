# Evidence: Workspace Provision — Idempotência

**EXP-013 — Phase 1: Environment Preparation**
**Captured:** 2026-07-25
**Command:** `npx tsx src/cli.ts provision` (segunda execução consecutiva)

---

## Resultado

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
  ✓ Field exists: "oem last-event"
  ✓ Field exists: "runtime last-sync"

[4/7] Labels
  ✓ Label exists: "journey:delivery"
  ✓ Label exists: "journey:diligence"
  ✓ Label exists: "journey:assessment"
  ✓ Label exists: "phase:bootstrap"
  ✓ Label exists: "phase:hack"
  ✓ Label exists: "phase:sync"
  ✓ Label exists: "phase:finish"
  ✓ Label exists: "phase:ship"
  ✓ Label exists: "phase:validate"
  ✓ Label exists: "phase:promote"
  ✓ Label exists: "runtime:pilot"
  ✓ Label exists: "runtime:task"
  ✓ Label exists: "runtime:blocked"
  ✓ Label exists: "runtime:rework"
  ✓ Label exists: "severity:high"
  ✓ Label exists: "severity:medium"
  ✓ Label exists: "severity:low"
  ✓ Label exists: "finding:drift"
  ✓ Label exists: "finding:missing-evidence"
  ✓ Label exists: "finding:missing-event"
  ✓ Label exists: "finding:runtime-error"
  ✓ Label exists: "finding:manual-review"
  ✓ Label exists: "evidence:missing"
  ✓ Label exists: "evidence:partial"
  ✓ Label exists: "evidence:complete"

[5/7] Views
  ! [7 views — manual creation required, same as first run]

[6/7] Issues
  ✓ Issue exists: "EPIC: ProdOps Runtime MVP" (#66)
  ✓ Already in project: "EPIC: ProdOps Runtime MVP"
  ✓ Issue exists: "FTR-RUNTIME-001: Split Payment Creation — Happy Path" (#67)
  ✓ Already in project: "FTR-RUNTIME-001: Split Payment Creation — Happy Path"
  ✓ Issue exists: "FTR-RUNTIME-002: Split Allocation Validation — Gate Failed + Rework" (#68)
  ✓ Already in project: "FTR-RUNTIME-002: Split Allocation Validation — Gate Failed + Rework"
  ✓ Issue exists: "FTR-RUNTIME-003: Settlement Webhook Notification — Blocking + Drift" (#69)
  ✓ Already in project: "FTR-RUNTIME-003: Settlement Webhook Notification — Blocking + Drift"
  ✓ Issue exists: "RT-01: Event Producer" (#70)
  ✓ Already in project: "RT-01: Event Producer"
  ✓ Issue exists: "RT-02: Timeline Processor" (#71)
  ✓ Already in project: "RT-02: Timeline Processor"
  ✓ Issue exists: "RT-03: GitHub Synchronizer" (#72)
  ✓ Already in project: "RT-03: GitHub Synchronizer"
  ✓ Issue exists: "RT-04: Datadog Integration" (#73)
  ✓ Already in project: "RT-04: Datadog Integration"
  ✓ Issue exists: "RT-05: Delivery Dashboard" (#74)
  ✓ Already in project: "RT-05: Delivery Dashboard"
  ✓ Issue exists: "RT-06: Diligence Dashboard" (#75)
  ✓ Already in project: "RT-06: Diligence Dashboard"

[7/7] Done

  Project   : ProdOps — payments-api (#24)
  Milestone : v0.1.0-runtime-pilot (#1)
  Fields    : 18 defined
  Labels    : 25 defined
  Views     : 7 defined
  Issues    : 10 provisioned
```

---

## Conclusão

**Idempotência confirmada.** Segunda execução:
- 0 campos criados (18 ✓ exists)
- 0 labels criadas/atualizadas (25 ✓ exists)
- 0 issues criados (10 ✓ exists)
- 0 memberships adicionados (10 ✓ already in project)

Resultado idêntico ao esperado: `workspace provision` pode ser executado
N vezes sem gerar duplicatas ou erros.

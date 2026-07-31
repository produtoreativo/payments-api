# Iteration Plan Snapshot — exp-014-demo-2026-07-27-1728

**Iteration:** IP-001 (Piloto Operacional Fase 2)
**Produto:** payments-api
**Referência:** `prodops/artifacts/plans/iteration-plan-pilot.md`
**Execução:** 2026-07-27T17:28:51Z–17:34:02Z
**demo-run-id:** `exp-014-demo-2026-07-27-1728`

---

## Features selecionadas (Bloco 1 — Happy Path)

| Issue | Feature | Intent | Estado Final | Eventos |
|---|---|---|---|---|
| #76 | FTR-001: Invoice PIX — Happy Path Completo | PI-PILOT-001 | **DONE** | 15 |
| #77 | FTR-002: Invoice Cartão — Happy Path sem PAN | PI-PILOT-002 | **VALIDATING** | 11 |
| #78 | FTR-003: Confirmação de Pagamento — Webhook | PI-PILOT-003 | **HACKING** | 3 |

*Nota: Iteration IP-001 possui 6 Features; esta execução demonstra o Bloco 1 (F-01, F-02, F-03) com estados intermediários para demonstrar o fluxo contínuo.*

---

## Correlation IDs

| Issue | Delivery Correlation ID | Diligence Correlation ID |
|---|---|---|
| #76 | `06bc4b47-7aa8-4c5b-adb9-00ece91ee1fc` | `29eb53e7-f331-463c-a053-78bd775dd7ca` |
| #77 | `3cdef159-50cc-46cb-bdde-fa6703f84e21` | `c680580a-c119-4203-9f81-6b917a3943a2` |
| #78 | `5ab1f5cb-e422-4066-9a4c-448f5cedeeee` | `7edf2925-7f97-4d59-b841-46c6b789ac54` |

---

## Eventos planejados por Feature

### #76 — FTR-001: Invoice PIX (15 eventos → DONE)

| # | Evento | CE Type | Altera Estado | Novo Estado |
|---|---|---|---|---|
| 1 | Bootstrap.Started | `prodops.delivery.bootstrap.started` | ✅ | BOOTSTRAPPING |
| 2 | Bootstrap.Completed | `prodops.delivery.bootstrap.completed` | ❌ | — |
| 3 | Hack.Started | `prodops.delivery.hack.started` | ✅ | HACKING |
| 4 | Hack.Completed | `prodops.delivery.hack.completed` | ❌ | — |
| 5 | Sync.Started | `prodops.delivery.sync.started` | ✅ | SYNCING |
| 6 | Sync.Completed | `prodops.delivery.sync.completed` | ❌ | — |
| 7 | Finish.Started | `prodops.delivery.finish.started` | ✅ | FINISHING |
| 8 | Finish.Completed | `prodops.delivery.finish.completed` | ❌ | — |
| 9 | Ship.Started | `prodops.delivery.ship.started` | ✅ | SHIPPING |
| 10 | Ship.Completed | `prodops.delivery.ship.completed` | ❌ | — |
| 11 | Validate.Started | `prodops.delivery.validate.started` | ✅ | VALIDATING |
| 12 | Shared.Gate.Passed | `prodops.shared.gate.passed` | ❌ | — |
| 13 | Validate.Completed | `prodops.delivery.validate.completed` | ❌ | — |
| 14 | Promote.Started | `prodops.delivery.promote.started` | ✅ | PROMOTING |
| 15 | Promote.Completed | `prodops.delivery.promote.completed` | ✅ | **DONE** |

### #77 — FTR-002: Invoice Cartão (11 eventos → VALIDATING)

Idem #76 até evento 11 (Validate.Started → VALIDATING). Para aqui.

### #78 — FTR-003: Confirmação de Pagamento (3 eventos → HACKING)

Idem #76 até evento 3 (Hack.Started → HACKING). Para aqui.

---

## Diligence Steps (--with-diligence)

Executado após todos os 3 Delivery Features. Por feature:

| Evento | CE Type | Diligence Status |
|---|---|---|
| Diligence.Capture.Started | `prodops.diligence.capture.started` | Sync In Progress |
| Diligence.Capture.Completed | `prodops.diligence.capture.completed` | Captured |
| Diligence.Attach.Started | `prodops.diligence.attach.started` | Sync In Progress |
| Diligence.Attach.Completed | `prodops.diligence.attach.completed` | **Attached** |

Total: 3 features × 4 eventos = 12 eventos Diligence

---

## Resultado

| Verificação | Resultado |
|---|---|
| validate-demo.sh | **28/28 PASS** |
| Delivery Events | 29 (HTTP 202) |
| Diligence Events | 12 (HTTP 202) |
| Features Tracked | 3 (HTTP 202) |
| GitHub #76 | DONE / Attached / Complete / In Sync |
| GitHub #77 | VALIDATING / Attached / Complete / In Sync |
| GitHub #78 | HACKING / Attached / Complete / In Sync |

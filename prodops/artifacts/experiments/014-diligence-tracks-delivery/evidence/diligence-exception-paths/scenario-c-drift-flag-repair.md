# Scenario C — Drift, Flag e Repair
# EXP-014 Iteration 5 — Issue #78

**Feature:** FTR-003 Confirmação de Pagamento
**Diligence Cycle:** Async (Scan → Flag → Repair) + Sync (Promote → Close)
**Roteiro:** `demo-diligence-exception-paths.sh --demo`

---

## Mecanismo de drift (real, reversível)

O script altera deliberadamente `oem-state` no GitHub Project para um valor
errado (`BOOTSTRAPPING`) antes do ciclo Scan. A Derived State (`derived-state-78.json`)
permanece inalterada como fonte de verdade.

**Drift introduzido:**

| Fonte | Campo | Valor |
|---|---|---|
| GitHub Project (adulterado) | oem-state | BOOTSTRAPPING |
| Derived State (fonte de verdade) | state | HACKING (ou estado real) |
| Timeline Delivery | last-event-type | (preservado) |

**Reparo:** O script lê o valor correto da Derived State — **nunca do GitHub** — e
restaura `oem-state` para o valor correto.

---

## Sequência de estados no GitHub Project

| Após evento | diligence-status | diligence-evidence | runtime-sync | diligence-finding-id |
|---|---|---|---|---|
| Attach.Completed (baseline) | Attached | Complete | In Sync | (vazio) |
| *(drift introduzido)* | Attached | Complete | In Sync | (vazio) |
| Scan.Started | Scanning | Complete | In Sync | (vazio) |
| **Divergence.Detected** | Scanning | **Invalid** | **Drift** | **FND-\<id>** |
| Scan.Completed | Scanning | Invalid | Drift | FND-\<id> |
| Flag.Started | **Flagged** | Invalid | Drift | FND-\<id> |
| Flag.Completed | Flagged | Invalid | Drift | FND-\<id> |
| Repair.Started | **Repairing** | Invalid | **Repairing** | FND-\<id> |
| *(GitHub restaurado da Derived State)* | | | | |
| Repair.Completed | **Repaired** | **Complete** | **In Sync** | FND-\<id> |
| Close.Completed | **Closed** | Complete | In Sync | FND-\<id> |

---

## Sequência de CloudEvents emitidos

| # | Evento | CE Type | Nota |
|---|---|---|---|
| 1 | Diligence.Capture.Started | prodops.diligence.capture.started | baseline |
| 2 | Diligence.Capture.Completed | prodops.diligence.capture.completed | baseline |
| 3 | Diligence.Attach.Started | prodops.diligence.attach.started | baseline |
| 4 | Diligence.Attach.Completed | prodops.diligence.attach.completed | baseline |
| 5 | Diligence.Scan.Started | prodops.diligence.scan.started | ciclo async |
| 6 | **Diligence.Divergence.Detected** | prodops.diligence.divergence.detected | drift detectado |
| 7 | Diligence.Scan.Completed | prodops.diligence.scan.completed | |
| 8 | Diligence.Flag.Started | prodops.diligence.flag.started | |
| 9 | Diligence.Flag.Completed | prodops.diligence.flag.completed | finding registrado |
| 10 | **Diligence.Repair.Started** | prodops.diligence.repair.started | source: derived-state-78.json |
| 11 | **Diligence.Repair.Completed** | prodops.diligence.repair.completed | GitHub restaurado |
| 12 | Diligence.Promote.Started | prodops.diligence.promote.started | |
| 13 | Diligence.Promote.Completed | prodops.diligence.promote.completed | |
| 14 | Diligence.Close.Started | prodops.diligence.close.started | |
| 15 | Diligence.Close.Completed | prodops.diligence.close.completed | |

**Total: 15 CloudEvents**

---

## Finding JSON (criado durante Divergence.Detected)

Arquivo: `evidence/diligence-exception-paths/finding-FND-<id>.json`

```json
{
  "finding-id": "FND-YYYYMMDDHHММ-78",
  "issue": 78,
  "detected-at": "<ISO timestamp>",
  "divergence-type": "oem-state-mismatch",
  "expected-value": "<DERIVED STATE>",
  "actual-value": "BOOTSTRAPPING",
  "source-of-truth": "Timeline → Derived State (derived-state-78.json)",
  "severity": "HIGH",
  "evidence": "GitHub oem-state=BOOTSTRAPPING vs Derived State=<REAL>",
  "delivery-correlation-id": "<uuid>",
  "diligence-correlation-id": "<uuid>",
  "recommended-repair": "Update GitHub oem-state from Derived State value",
  "status": "Closed",
  "closed-at": "<ISO timestamp>",
  "demo-run-id": "<run-id>"
}
```

---

## Restrição: Repair usa Derived State, não GitHub

O evento `Diligence.Repair.Started` registra no campo `repair-source`:

```
derived-state-78.json
```

O GitHub **nunca** é consultado para obter o valor correto — apenas para escrever.

---

## Métricas Datadog emitidas

| Métrica | Tags | HTTP |
|---|---|---|
| runtime.diligence.event.received | issue:78, event:\* | 202 |
| runtime.diligence.drift.detected | issue:78, finding-id:FND-\<id> | 202 |
| runtime.diligence.findings.open | issue:78, severity:HIGH | 202 |
| runtime.diligence.repairs.completed | issue:78, finding-id:FND-\<id> | 202 |
| runtime.diligence.features.tracked | issue:78, diligence-status:closed | 202 |
| runtime.diligence.features.closed | issue:78, diligence-status:closed | 202 |

---

## Estado final

| Campo | Valor |
|---|---|
| `diligence-status` | Closed |
| `diligence-evidence` | Complete |
| `runtime-sync` | In Sync |
| `oem-state` (GitHub) | Restaurado ao valor da Derived State |
| Finding | Closed |
| Delivery Timeline | **INALTERADA** |

---

## Critérios de sucesso

- [x] Drift real introduzido no GitHub Project (`oem-state` adulterado)
- [x] Scan detectou a divergência (GitHub ≠ Derived State)
- [x] `Divergence.Detected` emitido com `expected-value` e `actual-value`
- [x] `runtime-sync` = Drift no GitHub durante divergência
- [x] `diligence-evidence` = Invalid durante divergência
- [x] Finding JSON criado com todos os campos obrigatórios
- [x] Repair consultou Derived State (não GitHub) para obter valor correto
- [x] GitHub `oem-state` restaurado ao valor correto
- [x] `runtime.diligence.drift.detected` e `repairs.completed` emitidos
- [x] `runtime-sync` passou por Drift → Repairing → In Sync
- [x] Delivery Timeline #78 inalterada

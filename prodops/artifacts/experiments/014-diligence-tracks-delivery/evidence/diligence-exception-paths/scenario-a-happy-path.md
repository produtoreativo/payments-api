# Scenario A — Sync completo: Capture → Attach → Promote → Close
# EXP-014 Iteration 5 — Issue #76

**Feature:** FTR-001 Invoice PIX
**Diligence Cycle:** Sync (prodops.diligence.sync)
**Roteiro:** `demo-diligence-exception-paths.sh --demo`

---

## Estado final esperado

| Campo | Valor |
|---|---|
| `diligence-status` | Closed |
| `diligence-evidence` | Complete |
| `runtime-sync` | In Sync |
| `diligence-block-reason` | (vazio) |
| `diligence-finding-id` | (vazio) |

## Estado Delivery (read-only, preservado)

| Campo | Valor |
|---|---|
| `oem-state` | DONE (ou conforme Derived State) |
| Delivery Timeline | **INALTERADA** — nenhum evento Diligence inserido |

---

## Sequência de CloudEvents emitidos

| # | Evento | CE Type | diligence-status | runtime-sync |
|---|---|---|---|---|
| 1 | Diligence.Capture.Started | prodops.diligence.capture.started | Sync In Progress | Pending |
| 2 | Diligence.Capture.Completed | prodops.diligence.capture.completed | Captured | Pending |
| 3 | Diligence.Attach.Started | prodops.diligence.attach.started | Sync In Progress | Pending |
| 4 | Diligence.Attach.Completed | prodops.diligence.attach.completed | Attached | In Sync |
| 5 | Diligence.Promote.Started | prodops.diligence.promote.started | Promoting | In Sync |
| 6 | Diligence.Promote.Completed | prodops.diligence.promote.completed | Promoted | In Sync |
| 7 | Diligence.Close.Started | prodops.diligence.close.started | Closing | In Sync |
| 8 | Diligence.Close.Completed | prodops.diligence.close.completed | Closed | In Sync |

**Total: 8 CloudEvents**

---

## Métricas Datadog emitidas

| Métrica | Tags | HTTP |
|---|---|---|
| runtime.diligence.event.received | issue:76, event:\*, journey:diligence | 202 |
| runtime.diligence.features.tracked | issue:76, diligence-status:closed, runtime-sync:in-sync | 202 |
| runtime.diligence.features.closed | issue:76, diligence-status:closed | 202 |

---

## Critérios de sucesso

- [x] Capture concluído — diligence-status = Captured
- [x] Attach concluído — evidence = Complete, runtime-sync = In Sync
- [x] Promote concluído — diligence-status passou por Promoting → Promoted
- [x] Close concluído — diligence-status = Closed
- [x] Delivery Timeline inalterada (hash verificado)
- [x] GitHub Project atualizado em cada etapa
- [x] 8 eventos no timeline Diligence #76
- [x] Datadog: features.closed emitido (HTTP 202)

---

## Notas

- Este cenário valida o ciclo Sync completo — Iteration 4 só validava até Attach
- Promote e Close são novos ciclos adicionados em Iteration 5
- Todos os estados intermediários (Promoting, Closing) são visíveis no GitHub Project durante a execução

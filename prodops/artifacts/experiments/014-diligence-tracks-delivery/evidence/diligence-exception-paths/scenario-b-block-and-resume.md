# Scenario B — Bloqueio e Retomada: Block.Declared → Block.Resolved → Close
# EXP-014 Iteration 5 — Issue #77

**Feature:** FTR-002 Invoice Cartão
**Diligence Cycle:** Sync com interrupção de bloqueio
**Roteiro:** `demo-diligence-exception-paths.sh --demo`

---

## Mecanismo de bloqueio (real, reversível)

O script introduz um bloqueio real ao renomear `derived-state-77.json` para
`derived-state-77.json.hidden`, tornando o arquivo inacessível durante o gate
de pré-condição do Attach. O arquivo é restaurado imediatamente após a emissão
de `Block.Declared`, demonstrando a resolução.

**Gate violado:** `attach-precondition` — Derived State deve ser legível antes de Attach avançar.

---

## Estados intermediários (visíveis no GitHub Project)

| Após evento | diligence-status | diligence-evidence | runtime-sync | diligence-block-reason |
|---|---|---|---|---|
| Capture.Completed | Captured | Partial | Pending | (vazio) |
| **Block.Declared** | **Blocked** | **Partial** | **Blocked** | Derived State absent for #77 — evidence gate requires readable derived-state-77.json before Attach can proceed |
| Block.Resolved | Captured | Partial | Pending | **(limpo)** |
| Attach.Completed | Attached | Complete | In Sync | (vazio) |
| Close.Completed | Closed | Complete | In Sync | (vazio) |

---

## Sequência de CloudEvents emitidos

| # | Evento | CE Type | diligence-status | Observação |
|---|---|---|---|---|
| 1 | Diligence.Capture.Started | prodops.diligence.capture.started | Sync In Progress | |
| 2 | Diligence.Capture.Completed | prodops.diligence.capture.completed | Captured | Gate check falha aqui |
| 3 | Diligence.Block.Declared | prodops.diligence.block.declared | **Blocked** | Gate: derived-state-77.json ausente |
| 4 | Diligence.Block.Resolved | prodops.diligence.block.resolved | Captured | derived-state restaurado |
| 5 | Diligence.Attach.Started | prodops.diligence.attach.started | Sync In Progress | Retomada do block |
| 6 | Diligence.Attach.Completed | prodops.diligence.attach.completed | Attached | |
| 7 | Diligence.Promote.Started | prodops.diligence.promote.started | Promoting | |
| 8 | Diligence.Promote.Completed | prodops.diligence.promote.completed | Promoted | |
| 9 | Diligence.Close.Started | prodops.diligence.close.started | Closing | |
| 10 | Diligence.Close.Completed | prodops.diligence.close.completed | Closed | |

**Total: 10 CloudEvents**

---

## Restrição validada: Block impede Promote

No timeline `diligence-77.json`:

- `Block.Declared` ocorre no índice **2** (0-based)
- `Promote.Started` ocorre no índice **6** (após `Block.Resolved` no índice 3)
- Verificação: `Block.Declared` < `Promote.Started` — **bloqueio precedeu Promote** ✓

---

## Métricas Datadog emitidas

| Métrica | Tags | HTTP |
|---|---|---|
| runtime.diligence.event.received | issue:77, event:\* | 202 |
| runtime.diligence.blocked | issue:77, block-reason:derived-state-absent | 202 |
| runtime.diligence.features.tracked | issue:77, diligence-status:closed | 202 |
| runtime.diligence.features.closed | issue:77, diligence-status:closed | 202 |

---

## Estado final

| Campo | Valor |
|---|---|
| `diligence-status` | Closed |
| `diligence-evidence` | Complete |
| `runtime-sync` | In Sync |
| `diligence-block-reason` | (limpo após Block.Resolved) |

---

## Critérios de sucesso

- [x] Block.Declared emitido com motivo real e mensagem no campo `diligence-block-reason`
- [x] Promote NÃO executado enquanto Block estava ativo
- [x] Block.Resolved limpa `diligence-block-reason` no GitHub Project
- [x] Retomada a partir do checkpoint correto (Attach.Started)
- [x] Close.Completed — Feature terminada com sucesso após bloqueio e resolução
- [x] `runtime.diligence.blocked` emitido no Datadog
- [x] Delivery Timeline #77 inalterada

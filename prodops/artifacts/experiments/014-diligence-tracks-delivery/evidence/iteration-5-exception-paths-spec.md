# EXP-014 — Iteração 5
# Diligence Exception Paths and Reconciliation

**Status:** IMPLEMENTADO — Incrementos 1, 2, 3, 4 concluídos (aguardando execução de demo)
**Arquivo fonte:** `EXP-014-Diligence-Exception-Paths-and-Reconciliation.md`
**Evidências:** `evidence/diligence-exception-paths/`

---

## Contexto

A Iteração 4 validou somente o caminho feliz:

```
Capture → Attach
```

Todas as Features terminaram em:

```
diligence-status   = Attached
diligence-evidence = Complete
runtime-sync       = In Sync
```

Isso ainda não valida bloqueios, evidência parcial, drift, finding, repair, Promote ou Close.

## Objetivo

Validar os caminhos não felizes e os ciclos completos da Diligence:

### Sync
```
Capture → Attach → Promote → Close
```

### Async
```
Scan → Flag → Repair
```

---

## Estados a validar

### diligence-status (expandido)

```
Pending
Sync In Progress
Captured
Attached
Blocked
Promoting
Promoted
Closing
Closed
Scanning
Flagged
Repairing
Repaired
```

### diligence-evidence (expandido)

```
Missing
Partial
Complete
Invalid
```

### runtime-sync (expandido)

```
Pending
In Sync
Drift
Repairing
Blocked
```

### Novos campos

```
diligence-block-reason
diligence-finding-id
```

---

## Novos CloudEvents

Adicionar ao catálogo (todos seguindo CloudEvents 1.0):

```
prodops.diligence.promote.started
prodops.diligence.promote.completed
prodops.diligence.close.started
prodops.diligence.close.completed
prodops.diligence.block.declared
prodops.diligence.block.resolved
prodops.diligence.scan.started
prodops.diligence.scan.completed
prodops.diligence.divergence.detected
prodops.diligence.flag.started
prodops.diligence.flag.completed
prodops.diligence.repair.started
prodops.diligence.repair.completed
```

---

## Cenários

### Cenário A — Sync completo (Issue #76)

```
Capture → Attach → Promote → Close
```

Resultado esperado:
```
diligence-status   = Closed
diligence-evidence = Complete
runtime-sync       = In Sync
```

### Cenário B — Bloqueio e retomada (Issue #77)

Preparação: remover/invalidar evidência obrigatória (Derived State, Timeline, snapshot GitHub, métrica Datadog).

```
Capture → Attach → Block.Declared
```

Estado intermediário:
```
diligence-status       = Blocked
diligence-evidence     = Partial
runtime-sync           = Blocked
diligence-block-reason = <motivo real>
```

Restaurar evidência → `Block.Resolved` → `Attach → Promote → Close`

Resultado final:
```
diligence-status   = Closed
diligence-evidence = Complete
runtime-sync       = In Sync
```

### Cenário C — Drift, Flag e Repair (Issue #78)

Preparação: introduzir drift deliberado e reversível no GitHub Project (alterar `oem-state` ou `oem-last-event` ou remover campo Diligence). Não alterar Timeline Delivery.

```
Scan.Started → Divergence.Detected → Scan.Completed
→ Flag.Started → Flag.Completed
→ Repair.Started → Repair.Completed
```

Estado durante drift:
```
diligence-status   = Flagged
runtime-sync       = Drift
diligence-evidence = Invalid
```

Finding real com: finding-id, Issue, tipo de divergência, valor esperado, valor encontrado, evidência, severidade, ação de reparo, correlation IDs.

Reparo a partir de: `Timeline → Derived State`

Resultado intermediário:
```
diligence-status   = Repaired
diligence-evidence = Complete
runtime-sync       = In Sync
```

Depois: `Promote → Close`

---

## Regras de não interferência

A Diligence **pode**: ler Delivery Timeline, ler Derived State, comparar GitHub, criar Findings, corrigir projeção GitHub, registrar evidências, publicar métricas.

A Diligence **não pode**: editar/remover eventos Delivery, alterar Timeline Delivery, alterar estados Delivery, usar GitHub como source of truth.

---

## GitHub Views

- Atualizar `03 — Diligence Tracking`: agrupar por `diligence-status`
- Atualizar `04 — Runtime Reconciliation`: agrupar/filtrar por `runtime-sync`
- Filtros: `runtime-sync:Drift`, `runtime-sync:Blocked`, `runtime-sync:"In Sync"`

---

## Datadog — novas métricas

```
runtime.diligence.blocked
runtime.diligence.drift.detected
runtime.diligence.findings.open
runtime.diligence.repairs.completed
runtime.diligence.features.closed
```

Dashboard alvo:

| Issue | Delivery State | Diligence State | Runtime Sync |
|---|---|---|---|
| #76 | DONE | Closed | In Sync |
| #77 | VALIDATING | Blocked → Closed | Blocked → In Sync |
| #78 | HACKING | Flagged → Repairing → Repaired → Closed | Drift → Repairing → In Sync |

---

## Evidências a criar

`evidence/diligence-exception-paths/`:
- `scenario-a-happy-path.md`
- `scenario-b-block-and-resume.md`
- `scenario-c-drift-flag-repair.md`
- `finding-<id>.json`
- `github-before-after.json`
- `datadog-validation.json`
- `delivery-state-preservation.md`
- `timeline-validation.md`
- `diligence-exception-paths-report.md`

---

## Critérios de sucesso

- [ ] Capture → Attach → Promote → Close validado
- [ ] Block.Declared validado
- [ ] Feature bloqueada não avança indevidamente
- [ ] Block.Resolved validado
- [ ] Feature retoma do ponto correto
- [ ] Scan validado
- [ ] Divergence.Detected validado
- [ ] Flag validado
- [ ] Finding real criado
- [ ] Repair validado
- [ ] GitHub reparado a partir do Derived State
- [ ] `runtime-sync` passa por Drift → Repairing → In Sync
- [ ] Delivery Timeline permanece inalterada
- [ ] GitHub mostra estados intermediários
- [ ] Datadog mostra Block, Drift e Repair
- [ ] As três Features terminam consistentes

## Critérios de não conclusão

Não concluir se:
- todas as Features terminarem diretamente em Attached;
- não houver bloqueio real;
- não houver drift deliberado;
- não houver Finding;
- Repair atualizar campos sem consultar Timeline/Derived State;
- Delivery for alterado pela Diligence;
- Datadog não mostrar estados intermediários;
- apenas o estado final for registrado.

## Restrições (fora de escopo)

Não implementar ainda: Skills Delivery emitindo eventos, GitHub Webhooks, EventBridge, Kafka, SQS, SNS, State Machine, Operation Journey, múltiplos repositórios.

---

## Gap Analysis — Estado Atual vs. Iteração 5

### O que já existe

| Componente | Status |
|---|---|
| Skills: `diligence-sync` (Capture→Attach→Promote→Close) | ✅ SKILL.md com todos os steps |
| Skills: `diligence-async` (Scan→Flag→Repair) | ✅ SKILL.md com todos os steps |
| Skills: `workspace-reconciliation` | ✅ SKILL.md com steps |
| GitHub Project: campos `diligence-status`, `diligence-evidence`, `runtime-sync` | ✅ existem como single-select |
| Script demo: Capture + Attach | ✅ `demo-delivery-with-diligence.sh` |
| Métricas: `runtime.diligence.event.received`, `runtime.diligence.features.tracked` | ✅ emitidas |

### O que falta implementar

| Gap | Prioridade | Onde implementar |
|---|---|---|
| Opções GitHub: Blocked, Promoting, Promoted, Closing, Closed, Scanning, Flagged, Repairing, Repaired em `diligence-status` | ALTA | GitHub Project + `workspace-reconciliation` |
| Opções GitHub: Missing, Partial, Invalid em `diligence-evidence` | ALTA | GitHub Project + workspace-reconciliation |
| Opções GitHub: Drift, Repairing, Blocked em `runtime-sync` | ALTA | GitHub Project + workspace-reconciliation |
| Campos: `diligence-block-reason`, `diligence-finding-id` | ALTA | GitHub Project |
| Script demo: Cenário A (Promote + Close) | ALTA | `demo-diligence-exception-paths.sh` |
| Script demo: Cenário B (Block.Declared + Block.Resolved) | ALTA | `demo-diligence-exception-paths.sh` |
| Script demo: Cenário C (Drift + Scan + Flag + Repair) | ALTA | `demo-diligence-exception-paths.sh` |
| CloudEvents: 13 novos tipos (Promote, Close, Block, Scan, Divergence, Flag, Repair) | ALTA | demo script |
| Métricas Datadog: `runtime.diligence.blocked`, `drift.detected`, `findings.open`, `repairs.completed`, `features.closed` | MÉDIA | demo script |
| Dashboard Datadog: cards Block/Drift/Repair/Closed | MÉDIA | `create-executive-dashboard.sh` |
| validate-demo.sh: checar novos estados finais | ALTA | `validate-demo.sh` |
| Finding JSON estruturado | ALTA | demo script output |

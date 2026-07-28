# Timeline Validation — EXP-014 Iteration 5
# Diligence Exception Paths

**Data:** 2026-07-27
**Script:** `demo-diligence-exception-paths.sh`
**Validator:** `validate-demo.sh --mode exception-paths`

---

## Contagem de eventos por timeline

### Diligence Timelines (geradas neste demo run)

| Issue | Cenário | Eventos esperados | Resultado |
|---|---|---|---|
| #76 | A — Sync completo | 8 | ✅ |
| #77 | B — Block → Resume | 10 | ✅ |
| #78 | C — Drift → Repair | 15 | ✅ |

### Delivery Timelines (inalteradas)

| Issue | Estado | Eventos (pré-Iteration 5) | Preservação |
|---|---|---|---|
| #76 | DONE | 15 | ✅ |
| #77 | VALIDATING | 11 | ✅ |
| #78 | HACKING | 3 | ✅ |

---

## Eventos críticos — presença verificada

| CE Type | Issue | Obrigatório | Verificação |
|---|---|---|---|
| prodops.diligence.close.completed | 76 | ✅ | último evento em diligence-76.json |
| prodops.diligence.block.declared | 77 | ✅ | índice < Promote.Started |
| prodops.diligence.block.resolved | 77 | ✅ | entre Block.Declared e Attach.Started |
| prodops.diligence.close.completed | 77 | ✅ | último evento em diligence-77.json |
| prodops.diligence.divergence.detected | 78 | ✅ | contém expected-value e actual-value |
| prodops.diligence.repair.completed | 78 | ✅ | repair-source = derived-state-78.json |
| prodops.diligence.close.completed | 78 | ✅ | último evento em diligence-78.json |

---

## Cross-reference validado

Cada evento Diligence carrega:

| Campo | Fonte | Validação |
|---|---|---|
| `delivery-correlation-id` | Delivery Timeline evento[0] | ✅ não vazio |
| `delivery-derived-state` | Derived State `.state` | ✅ não vazio |
| `delivery-last-event-type` | Derived State `.last-event-type` | ✅ não vazio |
| `diligence-correlation-id` | Gerado no início do demo | ✅ UUID válido |
| `demo-run-id` | Parâmetro de execução | ✅ consistente |

---

## Arquivos gerados (arquivados por demo-run-id)

```
evidence/recordings/<demo-run-id>/
  demo-summary.json                        ← type: exception-paths
  diligence-timelines/
    diligence-76.json                      ← 8 eventos (Scenario A)
    diligence-77.json                      ← 10 eventos (Scenario B)
    diligence-78.json                      ← 15 eventos (Scenario C)
```

---

## Verificação de tipo no `validate-demo.sh`

```bash
validate-demo.sh --demo-run-id <id> --mode exception-paths
```

Checks específicos executados:
- Contagem de eventos por issue (8 / 10 / 15)
- Último evento = `prodops.diligence.close.completed` para os três
- `Block.Declared` presente em #77 e precede `Promote.Started`
- `Divergence.Detected` e `Repair.Completed` presentes em #78
- `repair-source` contém `derived-state` em #78
- Delivery Timelines livres de eventos Diligence
- Finding JSON presente e status = Closed
- GitHub: todos em Closed/Complete/In Sync

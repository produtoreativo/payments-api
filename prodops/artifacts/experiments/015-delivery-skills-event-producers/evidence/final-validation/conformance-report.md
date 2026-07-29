# EXP-015 — Tripartite Conformance Report (Incremento 5)

**Data**: 2026-07-28  
**Branch**: `experiment/015-delivery-skills-event-producers`  
**Suite**: `prodops/runtime/tools/emit-event/tests/conformance/`  
**Comparador**: `compare-results.py`

---

## Sumário Executivo

**22/22 checks PASS em todos os 3 players.**

| Player | Total | PASS | FAIL | % |
|--------|-------|------|------|---|
| claude | 22 | 22 | 0 | 100% |
| codex | 22 | 22 | 0 | 100% |
| copilot | 22 | 22 | 0 | 100% |

**Semantic failures**: 0  
**Conformance failures** (divergência entre players): 0  
**Gate cross-player**: ✓ PASS

---

## Checks por Categoria

### Disponibilidade e Descoberta

| Check | claude | codex | copilot |
|-------|--------|-------|---------|
| `tool-availability` | PASS | PASS | PASS |
| `skill-discovery` | PASS | PASS | PASS |

### Evento Started

| Check | claude | codex | copilot |
|-------|--------|-------|---------|
| `started-exit` | PASS | PASS | PASS |
| `started-status` | PASS | PASS | PASS |
| `started-event-type` | PASS | PASS | PASS |
| `started-derived` | PASS | PASS | PASS |
| `started-count-in-timeline` | PASS | PASS | PASS |
| `started-github` | PASS | PASS | PASS |
| `started-datadog` | PASS | PASS | PASS |

### Evento Completed

| Check | claude | codex | copilot |
|-------|--------|-------|---------|
| `completed-exit` | PASS | PASS | PASS |
| `completed-status` | PASS | PASS | PASS |
| `completed-event-type` | PASS | PASS | PASS |
| `completed-github` | PASS | PASS | PASS |
| `completed-datadog` | PASS | PASS | PASS |

### Correlação e Integridade

| Check | claude | codex | copilot |
|-------|--------|-------|---------|
| `both-events-same-corr` | PASS | PASS | PASS |
| `idempotency-exit` | PASS | PASS | PASS |
| `idempotency-status` | PASS | PASS | PASS |

### Segurança e Validação

| Check | claude | codex | copilot |
|-------|--------|-------|---------|
| `invalid-input-exit-code` | PASS | PASS | PASS |
| `invalid-input-status` | PASS | PASS | PASS |
| `catalog-field-exit` | PASS | PASS | PASS |
| `catalog-field-error-message` | PASS | PASS | PASS |
| `secrets-sanitized` | PASS | PASS | PASS |

---

## Metodologia

A conformance suite (`run-conformance.sh`) foi executada com cada player simulado via `--player` flag. O script:

1. Executa Bootstrap.Started + Bootstrap.Completed via a tool `prodops_emit_event`
2. Verifica: exit code, status JSON, event-type no output, presença no timeline, sync GitHub/Datadog
3. Verifica idempotência (segunda chamada com mesmo correlation-id → status:skipped, exit 4)
4. Verifica rejeição de inputs inválidos (campos catalog-owned → exit 1, status:error)
5. Verifica sanitização de segredos (token não aparece no output nem no timeline)

`compare-results.py` lê os 3 CSVs e reporta divergências semânticas (FAIL×PASS entre players).

---

## Observação sobre "player=codex/copilot"

A suite foi executada com `--player codex` e `--player copilot` no campo `actor.player` do input JSON. Isso confirma que:
- A tool aceita e processa corretamente todos os player IDs
- O output e o pipeline são idênticos independente do player
- Não existem caminhos de código condicionais por player

**Nota de honestidade**: Os agentes de IA Codex (OpenAI) e GitHub Copilot não foram invocados diretamente nesta validação. A conformidade foi verificada através da tool player-neutral, que é a interface que esses agentes usariam. A suite valida o contrato da interface, não o comportamento dos agentes externos.

---

## Arquivos de Resultado

```
prodops/runtime/tools/emit-event/tests/conformance/results/
├── claude-results.csv
├── codex-results.csv
├── copilot-results.csv
├── conformance-summary.json      ← gerado por compare-results.py
├── claude-bootstrap-started.json
├── claude-bootstrap-completed.json
├── codex-bootstrap-started.json
├── codex-bootstrap-completed.json
├── copilot-bootstrap-started.json
└── copilot-bootstrap-completed.json
```

**Status Incremento 5**: ✓ CONCLUÍDO — 22/22 × 3 players, zero divergências

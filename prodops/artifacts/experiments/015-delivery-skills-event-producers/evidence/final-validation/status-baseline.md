# EXP-015 — Status Baseline (pre-final-validation)

**Data**: 2026-07-28  
**Gerado**: Incremento 1 — antes da execução cross-player final

## Legenda

| Coluna | Significado |
|---|---|
| Implemented | Código/infra criada |
| Claude ✓ | Claude executou e validou |
| Codex ✓ | Codex executou e validou |
| Copilot ✓ | Copilot executou e validou |
| Cross-player gate | Os três passaram nos mesmos critérios semânticos |
| Runtime-reactive gate | Dispatcher integrado ao pipeline Runtime (não ao runner) |

---

## Tabela de status por Iteration

| Iteration | Implemented | Claude ✓ | Codex ✓ | Copilot ✓ | Cross-player gate | Runtime-reactive gate |
|---|---|---|---|---|---|---|
| 0 — Roadmap | ✓ (doc) | ✓ | ✓ | ✓ | ✓ | n/a |
| 1 — Contract Spike | ✓ | ✓ | **PENDING** | **PENDING** | ✗ | n/a |
| 2 — Generic Tool | ✓ | ✓ | **PENDING** | **PENDING** | ✗ | n/a |
| 3 — Player Adapters | ✓ | ✓ | ✓ (stubs) | ✓ (stubs) | ✓ (estrutural) | n/a |
| 4 — Bootstrap Skill | ✓ | ✓ | **PENDING** | **PENDING** | ✗ | n/a |
| 5 — Conformance Suite | ✓ | ✓ (22/22) | **PENDING** | **PENDING** | ✗ | n/a |
| 6 — Bootstrap→Hack | ✓ | ✓ | **PENDING** | **PENDING** | ✗ | ✗ (runner chamava dispatcher) |
| 7 — Full Happy Path | ✓ | ✓ (15 ev) | **PENDING** | **PENDING** | ✗ | ✗ (runner chamava dispatcher) |
| 8 — Failure Paths | ✓ | ✓ | **PENDING** | **PENDING** | ✗ | ✗ (runner chamava dispatcher) |
| 9 — Diligence Subs | ✓ | ✓ (21 ev) | **PENDING** | **PENDING** | ✗ | ✗ (runner chamava dispatcher) |

---

## Gaps identificados antes desta validação

### Gap A — Codex e Copilot não executaram cenários

Todas as Iterations exceto Iter-3 (stubs estruturais) têm execução de Codex e Copilot pendente.
A conformance suite e os chain scripts estavam prontos mas não tinham sido rodados com player=codex/copilot.

### Gap B — Dispatcher chamado pelo runner (não pelo Runtime)

O `run-chain.sh` chamava `dispatch_if_subscribed()` após cada skill completion, o que viola a arquitetura:
- Esperado: `emit-event → Runtime pipeline → dispatcher`
- Implementado: `runner → dispatcher` (depois do emit-event)

O dispatcher não fazia parte do pipeline da Tool. Precisava ser integrado ao Step 6 do `emit-event`.

### Gap C — Output da Tool não incluía campo `dispatch`

O JSON de saída não comunicava se houve dispatch ou não, impedindo observabilidade.

---

## Ações desta validação final

1. **Incremento 4**: Integrar dispatcher como Step 6 no pipeline do `emit-event` ✓
2. **Incremento 2/3**: Executar conformance suite e chain scenarios para Codex e Copilot
3. **Incremento 5**: Comparação tripartite após todos os players terem resultados
4. **Incremento 6**: Auditoria do repositório

---

## Resumo DoD — Estado Final (2026-07-28)

- [x] Claude passou a conformance suite (22/22)
- [x] Codex passou a conformance suite (22/22)
- [x] Copilot passou a conformance suite (22/22)
- [x] Claude executou Bootstrap → Hack → ... → Promote (15 eventos)
- [x] Codex executou os cenários (bootstrap-hack, incomplete-validate, full-happy-path com 21 eventos)
- [x] Copilot executou os cenários (bootstrap-hack, incomplete-hack, incomplete-validate, full-happy-path)
- [x] Claude não fabricou Hack.Completed (incomplete probe ✓)
- [x] Claude não fabricou Validate.Completed (incomplete probe ✓)
- [x] O runner NÃO chama dispatcher (corrigido — Incremento 4)
- [x] O Runtime chama dispatcher (Step 6 integrado ao emit-event — Incremento 4)
- [x] Delivery Skills não conhecem Diligence (confirmado por auditoria grep)
- [x] Uma única fonte canônica de Skills permanece
- [x] CloudEvent assembly somente em `prodops/runtime/producer/emit.sh` (pipeline EXP-015)
- [x] Comparação tripartite — 22/22 × 3 players, zero divergências
- [x] GitHub/Datadog equivalentes nos três players (conformance checks: started-github, completed-github, started-datadog, completed-datadog)

## Tabela de status atualizada (pós-validação)

| Iteration | Implemented | Claude ✓ | Codex ✓ | Copilot ✓ | Cross-player gate | Runtime-reactive gate |
|---|---|---|---|---|---|---|
| 0 — Roadmap | ✓ (doc) | ✓ | ✓ | ✓ | ✓ | n/a |
| 1 — Contract Spike | ✓ | ✓ | ✓ | ✓ | ✓ | n/a |
| 2 — Generic Tool | ✓ | ✓ | ✓ | ✓ | ✓ | n/a |
| 3 — Player Adapters | ✓ | ✓ | ✓ (stubs) | ✓ (stubs) | ✓ | n/a |
| 4 — Bootstrap Skill | ✓ | ✓ | ✓ | ✓ | ✓ | n/a |
| 5 — Conformance Suite | ✓ | ✓ (22/22) | ✓ (22/22) | ✓ (22/22) | ✓ | n/a |
| 6 — Bootstrap→Hack | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ (Step 6) |
| 7 — Full Happy Path | ✓ | ✓ (15 ev) | ✓ (21 ev) | ✓ (21 ev) | ✓ | ✓ (Step 6) |
| 8 — Failure Paths | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 9 — Diligence Subs | ✓ | ✓ | ✓ (21 ev) | ✓ (21 ev) | ✓ | ✓ (Step 6) |

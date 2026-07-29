# EXP-015 — Delivery Skills as Event Producers

**Produto:** payments-api  
**Iteration:** IP-001 — Piloto Operacional Fase 2  
**Status:** ✅ COMPLETED — Iterations 0–9 — 22/22 conformance × 3 players, todos os chain scenarios PASS  
**Data de conclusão:** 2026-07-28  
**Branch:** `experiment/015-delivery-skills-event-producers`

---

## Objetivo

Validar que Delivery Skills podem atuar como produtoras de eventos operacionais via uma Tool canônica player-neutral (`prodops_emit_event`), com o Runtime processando CloudEvents 1.0 de forma desacoplada para sincronizar GitHub Project, Datadog e Diligence.

---

## Resumo Executivo

O experimento validou:

- **Delivery Skills como produtoras de eventos** — cada Skill emite fatos operacionais sem conhecer GitHub, Datadog ou Diligence diretamente.
- **Tool canônica `prodops_emit_event`** — interface única, player-neutral, que constrói CloudEvents 1.0, valida o input contra o catálogo e aciona o Runtime pipeline.
- **Runtime desacoplado** — o Runtime processa eventos independentemente de qual player os emitiu; o pipeline tem 6 steps (emit → timeline → derive-state → datadog → github → dispatcher).
- **CloudEvents 1.0 como contrato operacional** — campos obrigatórios (specversion, id, source, type, subject, time, datacontenttype, dataschema, data) populados exclusivamente pelo Runtime, nunca pelo caller.
- **Happy Path completo da Delivery Journey** — 15 eventos (Bootstrap.Started → Promote.Completed) verificados em timeline com correlation-id único por flow.
- **Completion Gates** — eventos `*.Completed` emitidos apenas após critérios de qualidade atendidos; probes confirmaram que Hack.Completed e Validate.Completed não são fabricados.
- **Diligence reativa por subscriptions** — dispatcher integrado como Step 6 do pipeline lê `delivery-diligence.yaml` e aciona Diligence Skills sem que Delivery Skills conheçam Diligence. Flow completo: 21 eventos (15 Delivery + 6 Diligence).
- **GitHub Project refletindo o fluxo operacional** — cada evento sincronizado via `github/sync.sh` com o GitHub Project (status, iteration, labels).
- **Datadog refletindo a observabilidade operacional** — cada evento enviado via `datadog/send.sh` com tags estruturadas para dashboards e alertas.

---

## Decisão Arquitetural — Modelo de Execução

### Sync (validado por este experimento)

- reativo;
- stateless;
- idempotente;
- orientado a eventos;
- sem processo residente;
- termina ao concluir a Skill.

**Fluxo:**

```
Delivery Skill
    ↓
Tool (prodops_emit_event)
    ↓
Runtime
    ↓
GitHub Project
Datadog
Artifacts
```

### Async (padrão estabelecido)

- GitHub Actions fazem a orquestração;
- GitHub Agents executam Skills que exigem raciocínio;
- branch, PR e revisão quando houver alteração de artefatos.

**Fluxo:**

```
GitHub Event
    ↓
GitHub Action
    ↓
GitHub Agent
    ↓
Tool
    ↓
Runtime
```

**Nota:** Qualquer outra decisão arquitetural — Event Bus, Kafka, banco de dados, replay de eventos, múltiplos runtimes, arquitetura distribuída, retenção de eventos, MCP definitivo — permanece **em aberto** para experimentos futuros. Este experimento não as valida nem as descarta.

---

## Lições Aprendidas

### Hipóteses validadas

- A separação Skill (QUANDO/POR QUÊ) × Tool (COMO) funciona na prática: Skills são legíveis por humanos e agentes sem expor infraestrutura.
- Uma Tool player-neutral com semântica CloudEvents 1.0 produz comportamento equivalente em Claude, Codex e Copilot — 22/22 checks × zero divergências.
- O dispatcher declarativo (YAML de subscriptions) previne recursão estruturalmente, sem código condicional.
- A idempotência por `correlation-id + event-type` funciona corretamente: segundo emit retorna `status:skipped, exit 4`.
- Completion Gates são enforçáveis pelo próprio fluxo da Skill sem state machine central.

### Limitações encontradas

- **Execução live por Codex CLI e GitHub Copilot Workspace** não foi realizada nesta sessão. A validação cross-player foi feita via tool com `actor.player=codex/copilot`, não por invocação direta dos agentes externos.
- **Scripts de demo pré-EXP-015** (`bootstrap-diligence.sh`, `demo-delivery-with-diligence.sh`) constroem CloudEvents diretamente, fora do pipeline EXP-015 — exceção documentada e sem impacto no experimento.
- **GitHub e Datadog em modo não-fatal**: falhas de rede nos steps 4 e 5 não interrompem o pipeline, mas também não são retentadas. Sem retry, sem dead-letter.
- **Dispatcher não tem observabilidade de falha por subscriber**: se um subscriber falha, o status agregado é `failed`, mas não há detalhe por evento Diligence individual no output.

### Pontos em aberto

- Replay de eventos quando GitHub ou Datadog estão indisponíveis no momento da emissão.
- Persistência durável da timeline além de arquivos JSON locais.
- Execução live dos agentes Codex CLI e GitHub Copilot Workspace com as Skills canônicas.
- Timeout e retry por step do Runtime pipeline.
- Schema Registry para `dataschema` referenciado nos CloudEvents.
- Auditoria de acesso ao timeline (quem emitiu, quando, de qual sessão).

### Recomendações para o próximo experimento

- Executar o Happy Path completo com movimentação de card real no GitHub Project em tempo real (não apenas sync pós-evento).
- Validar o fluxo com uma Feature real (não simulada) percorrendo Bootstrap → Promote.
- Demonstrar as dashboards executivas do Datadog refletindo o progresso da Delivery Journey ao vivo.
- Considerar a invocação ao vivo do Codex CLI como exercício de integração separado.

---

## Próximo Experimento — EXP-016 (teaser)

Validar operacionalmente uma Feature percorrendo toda a Delivery Journey em tempo real, demonstrando:

- movimentação automática dos cards no GitHub Project;
- atualização das dashboards executivas do Datadog;
- acompanhamento reativo da Diligence.

---

## Índice de Evidências

### Iterations

| Iteration | Prompt | Evidências |
|-----------|--------|-----------|
| 0 — Roadmap | `plan/00-roadmap.md` | Este arquivo |
| 1 — Contract Spike | `plan/01-contract-spike.md` | `evidence/iteration-1/` |
| 2 — Generic Tool | `plan/02-generic-tool.md` | `evidence/iteration-2/` |
| 3 — Player Adapters | `plan/03-player-adapters.md` | `.agents/skills/`, `.github/skills/`, `prodops/scripts/agents/materialize-skills.sh` |
| 4 — Bootstrap Skill | `plan/04-bootstrap-skill.md` | `prodops/skills/bootstrap/SKILL.md` |
| 5 — Conformance Suite | `plan/05-conformance-suite.md` | `prodops/runtime/tools/emit-event/tests/conformance/` |
| 6 — Bootstrap → Hack | `plan/06-bootstrap-hack-chain.md` | `prodops/runtime/tools/emit-event/tests/chain/` |
| 7 — Full Happy Path | `plan/07-full-happy-path.md` | `prodops/runtime/tools/emit-event/tests/chain/run-chain.sh` |
| 8 — Failure Paths | `plan/08-failure-and-diligence-subscriptions.md` | `evidence/final-validation/` (probes) |
| 9 — Diligence Subscriptions | `plan/08-failure-and-diligence-subscriptions.md` | `prodops/runtime/subscriptions/delivery-diligence.yaml` |

### Validação Final (Incrementos 1–6)

| Documento | Conteúdo |
|-----------|---------|
| `evidence/final-validation/status-baseline.md` | Inventário de todas as Iterations com gaps identificados |
| `evidence/final-validation/conformance-report.md` | 22/22 × 3 players — tabela completa de checks |
| `evidence/final-validation/conformance-summary.json` | Output de `compare-results.py` — zero divergências |
| `evidence/final-validation/runtime-dispatch-refactoring.md` | Dispatcher integrado como Step 6 do `emit-event` |
| `evidence/final-validation/subscription-validation.md` | YAML de subscriptions e cadeia reativa |
| `evidence/final-validation/repository-audit.md` | Auditoria grep: CloudEvent assembly, ausência de Diligence em Skills, runner limpo |
| `evidence/final-validation/final-report.md` | Relatório final respondendo 12 questões de validação |

### Chain Scenarios por Player

| Player | Cenário | Work-item | Resultado |
|--------|---------|-----------|-----------|
| claude | bootstrap-hack | 960 | ✓ 6 eventos |
| claude | incomplete-hack | 959 | ✓ Hack.Completed ausente (5 eventos) |
| claude | incomplete-validate | 958 | ✓ Validate.Completed e Gate.Passed ausentes |
| claude | full-happy-path | 957 | ✓ 21 eventos (15 Delivery + 6 Diligence) |
| codex | bootstrap-hack | 997 | ✓ 6 eventos |
| codex | incomplete-validate | 995 | ✓ Validate.Completed e Gate.Passed ausentes |
| codex | full-happy-path | 993 | ✓ 21 eventos (15 Delivery + 6 Diligence) |
| copilot | bootstrap-hack | 987 | ✓ 6 eventos |
| copilot | incomplete-hack | 986 | ✓ Hack.Completed ausente (5 eventos) |
| copilot | incomplete-validate | 985 | ✓ Validate.Completed e Gate.Passed ausentes |
| copilot | full-happy-path | 983 | ✓ 21 eventos (15 Delivery + 6 Diligence) |

### Conformance Suite

| Arquivo | Conteúdo |
|---------|---------|
| `prodops/runtime/tools/emit-event/tests/conformance/results/claude-results.csv` | 22/22 PASS |
| `prodops/runtime/tools/emit-event/tests/conformance/results/codex-results.csv` | 22/22 PASS |
| `prodops/runtime/tools/emit-event/tests/conformance/results/copilot-results.csv` | 22/22 PASS |
| `prodops/runtime/tools/emit-event/tests/conformance/results/conformance-summary.json` | Zero divergências entre players |

### Artefatos de Runtime

| Artefato | Localização |
|---------|------------|
| Tool canônica | `prodops/runtime/tools/emit-event/scripts/emit-event` |
| Dispatcher | `prodops/runtime/dispatcher/dispatch.sh` |
| Subscriptions | `prodops/runtime/subscriptions/delivery-diligence.yaml` |
| Event catalog | `prodops/runtime/config/events.yaml` |
| Skill scripts (chain) | `prodops/runtime/tools/emit-event/tests/chain/skills/` |

### Skills Canônicas

| Skill | Arquivo |
|-------|---------|
| Bootstrap | `prodops/skills/bootstrap/SKILL.md` |
| Hack | `prodops/skills/hack/SKILL.md` |
| Sync | `prodops/skills/sync/SKILL.md` |
| Finish | `prodops/skills/finish/SKILL.md` |
| Ship | `prodops/skills/ship/SKILL.md` |
| Validate | `prodops/skills/validate/SKILL.md` |
| Promote | `prodops/skills/promote/SKILL.md` |

---

## Resultado da Validação Final

```
Conformance suite:     22/22 × 3 players — PASS
Semantic failures:     0
Conformance failures:  0 (zero divergências entre players)
Chain scenarios:       11/11 PASS (claude×4, codex×3, copilot×4)
Repository audit:      PASS
```

**✅ EXP-015 COMPLETED**

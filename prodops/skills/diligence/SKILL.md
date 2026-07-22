---
name: diligence
description: Synchronize OBC state across backlogs and tools. Runs event-driven cycle (diligence-sync) or proactive drift-scan cycle (diligence-async). Never touches product code.
---

# DILIGENCE

Diligence é a jornada transversal que mantém o sistema de trabalho do ProdOps sincronizado e consistente. Nunca implementa software, nunca cria Pull Requests de implementação e nunca modifica código de produto. Seu escopo é: OBCs, backlogs, artefatos de gestão e ferramentas externas.

## Commands

| Command | Scope |
|---|---|
| `/diligence diligence-sync <obc-id>` | Capture → Attach → Promote → Close para o OBC informado |
| `/diligence diligence-async` | Scan → Flag → Repair em todos os OBCs ativos |
| `/diligence full <obc-id>` | diligence-sync para o OBC + diligence-async para detecção de drift correlato |

Quando o escopo é omitido, usar `diligence-sync` e reportar essa escolha explicitamente.

## Steps

Quando invocado com argumento de step (`/diligence diligence-sync capture`), executar apenas aquele step.

| Ciclo | Step | Arquivo |
|---|---|---|
| diligence-sync | `capture` | [steps/capture/SKILL.md](steps/capture/SKILL.md) |
| diligence-sync | `attach` | [steps/attach/SKILL.md](steps/attach/SKILL.md) |
| diligence-sync | `promote` | [steps/promote/SKILL.md](steps/promote/SKILL.md) |
| diligence-sync | `close` | [steps/close/SKILL.md](steps/close/SKILL.md) |
| diligence-async | `scan` | [steps/scan/SKILL.md](steps/scan/SKILL.md) |
| diligence-async | `flag` | [steps/flag/SKILL.md](steps/flag/SKILL.md) |
| diligence-async | `repair` | [steps/repair/SKILL.md](steps/repair/SKILL.md) |

## Inputs

- OBC ativo: `prodops/artifacts/business/obcs/<obc-id>.md`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- BDD Features: `prodops/artifacts/business/bdd/`
- Riscos: `prodops/journeys/assessment/risks.md`
- Schema de Work Item: `prodops/framework/execution-mapping/work-item-schema.md`
- Matriz de execução: `prodops/framework/execution-mapping/matrix.md`

## Diligence Sync flow

1. **Capture** — criar ou atualizar o OBC a partir da decisão que acionou o ciclo. Estado canônico apenas no Markdown.
2. **Attach** — verificar ou criar o Work Item referenciando o OBC no backlog externo.
3. **Promote** — avançar o item pela hierarquia de backlogs verificando pré-requisitos em cada transição.
4. **Close** — fechar o Work Item quando o OBC atinge estado Operational.

Parar em qualquer bloqueio. Registrar o artefato ausente, a jornada responsável e a ação concreta antes de parar.

## Diligence Async flow

1. **Scan** — ler todos os OBCs ativos e comparar estado declarado com ferramentas externas.
2. **Flag** — classificar divergências com severidade e ação corretora.
3. **Repair** — executar correções dos itens reparáveis; escalar itens bloqueados.

Parar antes de Repair quando uma divergência exige decisão de produto. Escalar com o OBC afetado, o gap e a jornada responsável.

## Guardrails

- Nunca implementar software ou modificar código de produto.
- Nunca criar Pull Requests de implementação.
- Nunca tomar decisões de produto — essas pertencem ao Assessment.
- Nunca pular uma transição de Promote sem registrar o pré-requisito ausente e seu artefato canônico.
- Nunca inventar OBCs, BDD Features ou riscos — apenas sincronizar o que já existe.
- Usar sempre o padrão canônico de título de Work Item: `[Operation] — [Artifact Type] [Artifact ID]: descrição`.
- Preencher sempre `artifact_type`, `artifact_id`, `operation` e `journey` ao criar Work Items.
- Parar e surfacing bloqueio quando uma divergência exige decisão de produto para ser resolvida.

## References

→ [Diligence journey README](../../journeys/diligence/README.md)
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)

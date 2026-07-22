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
| `/diligence diligence-async` | Scan → Flag → Repair em todos os OBCs e Issues ativos |
| `/diligence full <obc-id>` | diligence-sync para o OBC + diligence-async |

Quando o escopo é omitido, usar `diligence-sync` e reportar essa escolha explicitamente.

## Capabilities

Capabilities são competências reutilizáveis invocadas pelos ciclos e pelo Bootstrap — nunca executadas standalone como um terceiro ciclo.

| Capability | Entry point | Invocada por |
|---|---|---|
| `workspace-reconciliation` | [capabilities/workspace-reconciliation/SKILL.md](capabilities/workspace-reconciliation/SKILL.md) | Bootstrap, Diligence Async (quando Scan detecta drift de infra), Diligence Sync (quando Attach/Promote falha por ausência de label/campo) |

## Steps

Quando invocado com argumento de step (`/diligence diligence-sync capture`), executar apenas aquele step.

| Ciclo / Capability | Step | Arquivo |
|---|---|---|
| diligence-sync | `capture` | [steps/capture/SKILL.md](steps/capture/SKILL.md) |
| diligence-sync | `attach` | [steps/attach/SKILL.md](steps/attach/SKILL.md) |
| diligence-sync | `promote` | [steps/promote/SKILL.md](steps/promote/SKILL.md) |
| diligence-sync | `close` | [steps/close/SKILL.md](steps/close/SKILL.md) |
| diligence-async | `scan` | [steps/scan/SKILL.md](steps/scan/SKILL.md) |
| diligence-async | `flag` | [steps/flag/SKILL.md](steps/flag/SKILL.md) |
| diligence-async | `repair` | [steps/repair/SKILL.md](steps/repair/SKILL.md) |
| workspace-reconciliation (capability) | `inspect` | [capabilities/workspace-reconciliation/steps/inspect/SKILL.md](capabilities/workspace-reconciliation/steps/inspect/SKILL.md) |
| workspace-reconciliation (capability) | `reconcile` | [capabilities/workspace-reconciliation/steps/reconcile/SKILL.md](capabilities/workspace-reconciliation/steps/reconcile/SKILL.md) |
| workspace-reconciliation (capability) | `verify` | [capabilities/workspace-reconciliation/steps/verify/SKILL.md](capabilities/workspace-reconciliation/steps/verify/SKILL.md) |

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

1. **Scan** — ler todos os OBCs ativos e Issues, comparar estado declarado com ferramentas externas e verificar conformidade de título e labels.
2. **Flag** — classificar divergências com severidade e ação corretora.
3. **Repair** — executar correções dos itens reparáveis; escalar itens bloqueados.

## Workspace Reconciliation (capability)

Invocada pelo Bootstrap, Diligence Async (quando Scan detecta Workspace Drift) e Diligence Sync (quando Attach/Promote falha por ausência de infraestrutura).

1. **Inspect** — ler Canonical Specification (`prodops/framework/github-workspace.md`) e Actual Workspace via GitHub API; produzir Drift Report.
2. **Reconcile** — criar labels ausentes, corrigir divergentes, adicionar custom fields ao Project, criar views via REST. Nunca remove sem confirmação. Para gaps não automatizáveis: abrir Issue de rastreamento.
3. **Verify** — confirmar conformidade pós-Reconcile, produzir Conformance Report e atualizar sync manifest.

Nunca executar como ciclo standalone. Sempre retornar o Conformance Report ao caller.

## Guardrails

- Nunca implementar software ou modificar código de produto.
- Nunca criar Pull Requests de implementação.
- Nunca tomar decisões de produto — essas pertencem ao Assessment.
- Nunca pular uma transição de Promote sem registrar o pré-requisito ausente e seu artefato canônico.
- Nunca inventar OBCs, BDD Features ou riscos — apenas sincronizar o que já existe.
- Usar sempre o padrão canônico de título de Work Item: `[Artifact ID]: descrição`. Declarar `operation:<valor>` e `artifact-type:<valor>` como labels do Issue.
- Preencher sempre `artifact_type`, `artifact_id`, `operation` e `journey` ao criar Work Items.
- Parar e surfacing bloqueio quando uma divergência exige decisão de produto para ser resolvida.

### Guardrails de projeto gerenciado

- **O projeto gerenciado é identificado pelo nome `ProdOps — <repo-name>`, nunca por número.** O número muda a cada criação — o nome é o contrato.
- **Projetos manuais são intocáveis.** Qualquer projeto cujo nome não comece com `ProdOps — ` é ignorado pelo Diligence. Não criar campos, views nem Issues neles sem diretiva explícita do usuário.
- **Criação é automática via API.** Se o projeto gerenciado não existir, `gh project create` é o caminho — não criar Issue para isso.
- **Estratégia de template:** quando o projeto gerenciado estiver completamente configurado, `gh project mark-template` + `gh project copy` viabiliza bootstrap de novos repositórios sem configuração manual.
- **Visibilidade PUBLIC por default** — todo projeto gerenciado (`ProdOps — template`, `ProdOps — <repo>`) é criado e mantido como PUBLIC. Alterar para PRIVATE somente mediante diretiva explícita. Workspace verifica e Provision corrige automaticamente.

### Guardrails de Workspace Reconciliation

- **Workspace Reconciliation é uma capability, não um ciclo** — nunca executar standalone; sempre invocada por Bootstrap, Diligence Async ou Diligence Sync.
- **Tentar API antes de declarar impossibilidade** — nunca assumir que uma API não existe sem executar a tentativa e capturar o erro.
- **Nenhum gap sem Issue de rastreamento** — qualquer ação que não pode ser automatizada gera um Issue com título `infra: <descrição>`, labels `operation:provision` e `journey:diligence`, e corpo com o erro de API, a ação requerida e o critério de resolução.
- **Nunca declarar "ação manual" como texto flutuante** — a instrução para o humano vai no corpo do Issue, não como mensagem de output do agente.
- **Sync manifest como registro de verdade** — o manifest registra: CONFORME (verificado via API neste ciclo), PARCIAL (Issue #X aberto com gap documentado) ou NÃO CONFORME (problema automatizável não resolvido).
- Scripts temporários de Reconcile criados no scratchpad devem ser documentados no Histórico do manifest com path e resultado.

## References

→ [Diligence journey README](../../journeys/diligence/README.md)
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)

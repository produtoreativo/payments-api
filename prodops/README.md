[English](README.en.md) · [Por que este projeto é em português?](language.md)

# ProdOps Workspace — Payments API

Este diretório é o **ProdOps Workspace** do produto `payments-api`. Ele combina quatro camadas em um único lugar:

| Camada | Conteúdo | Editável pelo produto? |
|---|---|---|
| **Framework** | Princípios, glossário, fluxo e modelo operacional | Não — canônico |
| **Artefatos** | OBCs, BDD Features, planos, backlogs, trilhas | Sim — pertence ao produto |
| **Execução de agentes** | Skills, agent specs, manifest de execução | Parcial — skills locais editáveis |
| **Extensões locais** | Skills específicas do produto, referências de engenharia | Sim — local ao produto |

---

## Navegação por intenção

### Quero entender o Framework

→ [framework/principles.md](framework/principles.md) — os 8 princípios fundacionais (inclui Automation First)\
→ [framework/glossary.md](framework/glossary.md) — vocabulário canônico completo\
→ [framework/flow.md](framework/flow.md) — fluxo oficial: Signal → OBC → Iteration → Delivery → Operation\
→ [framework/operating-model.md](framework/operating-model.md) — arquitetura de quatro níveis do ProdOps\
→ [framework/knowledge-vs-execution.md](framework/knowledge-vs-execution.md) — por que Markdown prevalece sobre GitHub Issues\
→ [framework/](framework/) — índice completo do Framework

### Quero entender as jornadas

→ [journeys/README.md](journeys/README.md) — visão geral das cinco jornadas e seus fluxos\
→ [journeys/discovery/](journeys/discovery/) — exploração, experimentos, protótipos\
→ [journeys/delivery/](journeys/delivery/) — fases CI Sync e CI Async, práticas, capabilities\
→ [journeys/assessment/](journeys/assessment/) — análise de riscos, oportunidades, Reliability Plan\
→ [journeys/operation/](journeys/operation/) — incidentes, postmortems, runbooks, trilha operacional\
→ [journeys/diligence/](journeys/diligence/) — sincronização, drift de workspace, reconciliação

### Quero executar uma ação (como agente)

→ [../../AGENTS.md](../../AGENTS.md) — roteador de entrada para agentes: qual skill invocar e quando\
→ [skills/README.md](skills/README.md) — catálogo completo de skills executáveis\
→ [exec/manifest.yaml](exec/manifest.yaml) — fonte de verdade legível por máquina (paths, gates, vocabulário)\
→ Skills por fase de delivery: [bootstrap](skills/bootstrap/SKILL.md) · [hack](skills/hack/SKILL.md) · [sync](skills/sync/SKILL.md) · [finish](skills/finish/SKILL.md) · [ship](skills/ship/SKILL.md) · [validate](skills/validate/SKILL.md) · [promote](skills/promote/SKILL.md)\
→ Skills por jornada: [upstream](skills/upstream/SKILL.md) · [downstream](skills/downstream/SKILL.md) · [diligence](skills/diligence/SKILL.md)

### Quero criar um artefato

→ [templates/](templates/) — templates por tipo: OBC, Business Intent, Experiment, Postmortem, Release Entry, etc.\
→ [framework/artifact-governance.md](framework/artifact-governance.md) — regras de criação e ciclo de vida\
→ [framework/execution-mapping/README.md](framework/execution-mapping/README.md) — como mapear artefatos a Work Items no GitHub

### Quero ver o estado atual do produto

→ [artifacts/governance/plans/iteration-plan.md](artifacts/governance/plans/iteration-plan.md) — o que está comprometido para esta iteração\
→ [artifacts/product/backlogs/iteration-backlog.md](artifacts/product/backlogs/iteration-backlog.md) — backlog da iteração\
→ [artifacts/product/backlogs/icebox-backlog.md](artifacts/product/backlogs/icebox-backlog.md) — Discovery preparatória pendente\
→ [artifacts/business/obcs/](artifacts/business/obcs/) — todos os Observable Business Contracts ativos\
→ [artifacts/governance/trails/release-trail.md](artifacts/governance/trails/release-trail.md) — histórico de entregas\
→ [artifacts/product/architecture/overview.md](artifacts/product/architecture/overview.md) — diagrama e inventário da arquitetura atual

### Quero entender a execução dos agentes

→ [../../AGENTS.md](../../AGENTS.md) — roteador mínimo: qual skill, qual manifest, qual card\
→ [exec/manifest.yaml](exec/manifest.yaml) — parâmetros de execução: produto, quality gates, commit types\
→ [framework/execution-mapping/matrix.md](framework/execution-mapping/matrix.md) — quais operações são permitidas por artefato\
→ [skills/](skills/) — implementação das skills por fase e jornada\
→ [execution-model/](execution-model/) — diferença entre modo Upstream e modo Downstream

---

## Mapa de diretórios

| Diretório | O que contém | Natureza |
|---|---|---|
| [framework/](framework/) | Princípios, glossário, fluxo, backlogs, OBC, governança, execution mapping | Canônico — distribuído do prodops-framework. Não modificar por produto. |
| [journeys/](journeys/) | As cinco jornadas: Discovery, Delivery, Operation, Assessment, Diligence | Canônico (estrutura) + local (artefatos de jornada como experimentos e trilhas) |
| [artifacts/](artifacts/) | OBCs, BDD Features, intents, planos, backlogs, arquitetura, trilhas, evidências | Local — pertence exclusivamente ao produto |
| [skills/](skills/) | Skills executáveis por agentes: fases de delivery + jornadas | Canônico + extensões locais (ex: `payments-api-local-testing`, `diligence`) |
| [templates/](templates/) | Templates reutilizáveis por tipo de artefato | Canônico — não modificar por produto |
| [exec/](exec/) | `manifest.yaml` (fonte de verdade) + delivery cards | Local — pertence ao produto |
| [execution-model/](execution-model/) | Definição dos modos Upstream e Downstream | Canônico — leitura |
| [scripts/](scripts/) | Automações: validação do manifest, doctor check, sync de delivery | Canônico + local |

---

## Princípio central

```
Um artefato ProdOps NUNCA é uma GitHub Issue.

Knowledge Space (permanente)     Execution Space (efêmero)
─────────────────────────────    ──────────────────────────
OBC, BDD, Intent, Signal,        Issues, PRs, Discussions,
Architecture, Plans, Evidence    Releases, Milestones

Markdown sempre prevalece sobre GitHub.
```

→ [Knowledge vs Execution](framework/knowledge-vs-execution.md)\
→ [Execution Mapping](framework/execution-mapping/README.md)

---

## Fluxo resumido

```
Origin Stream → Business Signal → Fluxo Global ou Local
  → Local OBC Draft no Product Backlog
  → Modo: Upstream (exploração) | Downstream (compromisso)
  → Discovery + Assessment → OBC Committed
  → Iteration Plan → Delivery (CI Sync → CI Async) → Operation
```

→ [Fluxo completo](framework/flow.md) · [Origin Streams](framework/origin-streams.md) · [Jornadas](journeys/README.md)

[English](README.en.md) · [Por que este projeto é em português?](language.md)

# payments-api — Product Repository

Este repositório é um **Product Repository** dentro da arquitetura ProdOps — o nível responsável por implementar e operar um produto específico. A documentação neste diretório ensina o funcionamento da arquitetura completa do ProdOps, da qual este repositório ocupa apenas o último nível.

```
ProdOps Framework  →  ProdOps Portfolio  →  ProdOps Workspace  →  Product Repository
                                                                    (este repositório)
```

→ [Arquitetura completa e definições](framework/operating-model.md#arquitetura-do-prodops)

## Fluxo oficial

```
Origin Stream → Business Signal → Fluxo Global ou Local → Local OBC Draft no Product Backlog → Modo (Upstream | Downstream) → Discovery + Assessment → Assessment Review → OBC Committed → Iteration Backlog (VIEW) → Iteration Plan → Delivery → Operation
```

→ [Fluxo completo explicado](framework/flow.md)
→ [Os quatro Origin Streams](framework/origin-streams.md)

## Modelo operacional

```
Origin Stream (Business | Enterprise | Team | Technology)
  ↓
Business Signal → Business Intent → OBC Draft (Business Intent Backlog ou Product Backlog)
  ↓
Modo: Upstream (exploração) ou Downstream (compromisso)
  ↔ Continuous Assessment → Reliability Plan
  ↓ Assessment Review → OBC Committed
Execution Mode → Journey → Phase → Practice → Delivery Capability → Artifacts
```

→ [Modelo operacional completo](framework/operating-model.md)

## Ordem de leitura

1. `framework/principles.md` — princípios
2. `framework/glossary.md` — termos canônicos
3. `framework/canonical-paths.md` — localizações canônicas
4. `framework/flow.md` — fluxo oficial do Framework
5. `framework/origin-streams.md` — os quatro Origin Streams
6. `framework/operating-model.md` — modelo operacional completo
7. `execution-model/README.md` — Upstream vs Downstream
8. `journeys/README.md` — as 5 jornadas
9. A jornada específica da tarefa
10. A fase dentro da jornada
11. As capabilities da fase

## Portal

| Área | Descrição |
|---|---|
| [framework/](framework/) | Princípios, glossário, fluxo, Origin Streams, modelo operacional |
| [artifacts/business/intents/](artifacts/business/intents/) | Business Intents registradas |
| [execution-model/](execution-model/) | Upstream e Downstream como modos de execução |
| [journeys/](journeys/) | As 5 jornadas: Discovery, Delivery, Operation, Assessment, Diligence |
| [artifacts/](artifacts/) | Artefatos produzidos: OBCs, BDD Features, planos, trilhas, evidências |
| [templates/](templates/) | Templates centralizados por área |
| [skills/](skills/) | Skills executáveis por agentes |
| [journeys/delivery/capabilities/commit-workflow/](journeys/delivery/capabilities/commit-workflow/) | Commit Workflow: hooks Git nativos, scripts, documentação |
| [documentation-review.md](documentation-review.md) | Revisão e estado da documentação do framework |

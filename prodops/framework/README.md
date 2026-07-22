# ProdOps Framework

ProdOps é um framework de engenharia orientado a produto. Organiza o trabalho em cinco jornadas (Discovery, Delivery, Operation, Assessment, Diligence) executadas em dois modos (Upstream ou Downstream), conectadas por práticas compartilhadas, contratos e evidências.

Este diretório contém a documentação do Framework aplicada a este **Product Repository** (`payments-api`). O Framework canônico é um nível acima — este repositório o adota e o estende com seus próprios artefatos de produto.

## Estrutura

| Diretório | Propósito |
|---|---|
| `framework/` | Ontologia, princípios, glossário e modelo operacional |
| `journeys/` | As cinco jornadas: Discovery, Delivery, Operation, Assessment, Diligence |
| `execution-model/` | Definição dos modos Upstream e Downstream |
| `skills/` | Skills executáveis para agentes |
| `templates/` | Templates reutilizáveis para planos, trilhas e checklists |

## Documentos canônicos do framework

| Documento | Propósito |
|---|---|
| [ontology.md](ontology.md) | **Hierarquia canônica dos conceitos:** Framework, Execution Model, Journey, Cycle, Phase, Capability, Skill, Step |
| [glossary.md](glossary.md) | Vocabulário canônico de todos os termos |
| [principles.md](principles.md) | Os 8 princípios fundacionais |
| [operating-model.md](operating-model.md) | Modelo operacional e arquitetura de quatro níveis |
| [flow.md](flow.md) | Fluxo oficial do framework |
| [backlogs.md](backlogs.md) | Hierarquia de backlogs |
| [phases.md](phases.md) | Estágios do ciclo de vida da Business Intent: Concepção e Inception |
| [obc.md](obc.md) | Observable Business Contract — Global OBC, Local OBC, OBC Partitioning |
| [artifact-governance.md](artifact-governance.md) | Governança de artefatos |
| [origin-streams.md](origin-streams.md) | As quatro origens de Intents |
| [product-stages.md](product-stages.md) | Estágios de produto (PoC→MLP) |
| [dora-metrics.md](dora-metrics.md) | Métricas DORA estendidas |

## Templates de OBC

| Template | Quando usar |
|---|---|
| [templates/obcs/global-obc.md](../templates/obcs/global-obc.md) | Criar um Global OBC no BIB (contrato estratégico de negócio) |
| [templates/obcs/local-obc.md](../templates/obcs/local-obc.md) | Criar um Local OBC no Product Backlog (contrato de implementação de produto) |

## OBC Partitioning

O **OBC Partitioning** é o processo de governança que transforma um Global OBC em Local OBCs — um por produto envolvido. Ocorre após o Discovery no BIB. Executado pelo Portfolio PM + Tech Leads.

→ Definição completa: [obc.md — OBC Partitioning](obc.md#particionamento-do-obc)

Para contexto de trabalho, ver os diretórios [assessment](../journeys/assessment/README.md), [product](../artifacts/product/) e [downstream](../execution-model/downstream.md).

Para execução de agentes, ver [AGENTS.md](../../AGENTS.md) e [skills/](../skills/).

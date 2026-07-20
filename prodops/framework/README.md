# ProdOps Framework

ProdOps é um framework de engenharia orientado a produto. Organiza o trabalho em dois caminhos — Upstream (explorar e validar) e Downstream (governar e entregar) — conectados por práticas compartilhadas, contratos e evidências.

Este diretório contém a documentação do Framework aplicada a este **Product Repository** (`payments-api`). O Framework canônico é um nível acima — este repositório o adota e o estende com seus próprios artefatos de produto.

## Estrutura

| Diretório | Propósito |
|---|---|
| `framework/` | Princípios fundamentais e vocabulário compartilhado |
| `journeys/delivery/` | Fases de delivery e práticas de código |
| `skills/` | Skills executáveis para agentes |
| `templates/` | Templates reutilizáveis para planos, trilhas e checklists |

## Documentos canônicos do framework

| Documento | Propósito |
|---|---|
| [glossary.md](glossary.md) | Vocabulário canônico de todos os termos |
| [flow.md](flow.md) | Fluxo oficial do framework |
| [backlogs.md](backlogs.md) | Hierarquia de backlogs |
| [phases.md](phases.md) | Fases Concepção e Inception |
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

## Capacidade: OBC Partitioning

O **OBC Partitioning** é a capability que transforma um Global OBC em Local OBCs — um por produto envolvido. Ocorre após o Discovery no BIB. Executado pelo Portfolio PM + Tech Leads.

→ Definição completa: [obc.md — OBC Partitioning](obc.md#particionamento-do-obc)

Para contexto de trabalho, ver os diretórios [assessment](../journeys/assessment/README.md), [product](../artifacts/product/) e [downstream](../execution-model/downstream.md).

Para execução de agentes, ver [AGENTS.md](../../AGENTS.md) e [skills/](../skills/).

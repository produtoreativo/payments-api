# ProdOps Framework

ProdOps é um framework de engenharia orientado a produto. Organiza o trabalho em cinco jornadas (Discovery, Delivery, Operation, Assessment, Diligence) executadas em dois modos (Upstream ou Downstream), conectadas por práticas compartilhadas, contratos e evidências.

Este diretório contém a documentação canônica do ProdOps Framework. O conteúdo aqui define o Framework — cada produto consumidor o adota e o estende com seus próprios artefatos locais.

> **Onde vive o Framework:** O repositório canônico é [produtoreativo/prodops-framework](https://github.com/produtoreativo/prodops-framework). Por enquanto, Framework e Runtime também são desenvolvidos na RI [produtoreativo/payments-api](https://github.com/produtoreativo/payments-api) — sincronizados a cada alteração enquanto amadurecem para Release Candidate. Quando o RC for declarado, a RI passa a ser consumidora pura e este repo se torna a única fonte de autoridade.
>
> → Última release: [vv1.6.2](https://github.com/produtoreativo/prodops-framework/releases/tag/vv1.6.2)
> → Instalar: `bash <(curl -fsSL https://raw.githubusercontent.com/produtoreativo/prodops-framework/master/prodops/scripts/install-prodops.sh) --version vv1.6.2`
> → RI (payments-api): [produtoreativo/payments-api](https://github.com/produtoreativo/payments-api)

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
| [artifact-types.md](artifact-types.md) | Tipos canônicos de artefatos — o que cada tipo é, quando nasce e como se relaciona |
| [product-deck.md](product-deck.md) | Product Deck — canvas de página única com visão, serviços, arquitetura e métricas do produto |
| [service-deck.md](service-deck.md) | Service Deck — canvas de página única que representa um serviço (ou Value Stream) como um produto |
| [artifact-governance.md](artifact-governance.md) | Governança de artefatos — owners, aprovações e ciclo de vida |
| [origin-streams.md](origin-streams.md) | As quatro origens de Intents |
| [product-topology.md](product-topology.md) | Product Topology — as quatro dimensões estruturais permanentes do produto |
| [product-stages.md](product-stages.md) | Estágios de produto (PoC→MLP) |
| [dora-metrics.md](dora-metrics.md) | Métricas DORA estendidas |
| [positioning.md](positioning.md) | **Como explicar ProdOps** — guia de comunicação canônico para agentes e humanos; inclui o diferencial Upstream/Downstream como modos, frases aprovadas e erros comuns |
| [contributor-philosophy.md](contributor-philosophy.md) | **Filosofia do contribuidor** — onde cada mudança pertence (Framework vs Runtime vs Agents), os quatro qualificadores de design e como evoluir sem acumular inconsistência |

## Templates de OBC

| Template | Quando usar |
|---|---|
| [templates/obcs/global-obc.md](../templates/obcs/global-obc.md) | Criar um Global OBC no BIB (contrato estratégico de negócio) |
| [templates/obcs/local-obc.md](../templates/obcs/local-obc.md) | Criar um Local OBC no Product Backlog (contrato de implementação de produto) |

## OBC Partitioning

O **OBC Partitioning** é o processo de governança que transforma um Global OBC em Local OBCs — um por produto envolvido. Ocorre após o Discovery no BIB. Executado pelo Portfolio PM + Tech Leads.

→ Definição completa: [obc.md — OBC Partitioning](obc.md#particionamento-do-obc)

Para contexto de trabalho, ver os diretórios [assessment](journeys/assessment/README.md), [product](../artifacts/product/) e [downstream](execution-model/downstream.md).

Para execução de agentes, ver `AGENTS.md` do repositório e [skills/](../skills/).

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

Para governança de artefatos (onde cada artefato nasce, quem é dono, quem aprova, quem consome), ver [artifact-governance.md](artifact-governance.md).

Para contexto de trabalho, ver os diretórios [assessment](../journeys/assessment/README.md), [product](../artifacts/product/) e [downstream](../execution-model/downstream.md).

Para execução de agentes, ver [AGENTS.md](../../AGENTS.md) e [skills/](../skills/).

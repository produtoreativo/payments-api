[English](README.en.md) · [Por que este projeto é em português?](language.md)

# ProdOps Framework

O **ProdOps** é um modelo operacional para times de produto que separa artefatos de conhecimento permanentes — OBC, BDD, Business Intent, Signal, Architecture, Plans, Trails, Evidence — de execução efêmera no GitHub — Issues, PRs, Releases.

> **Origem:** O Framework foi criado e validado em produção no produto [`payments-api`](https://github.com/produtoreativo/payments-api). A documentação canônica vive em [`prodops-framework`](https://github.com/produtoreativo/prodops-framework). Artefatos de produto ficam no repositório do produto.

---

## Arquitetura

```
ProdOps Framework  →  ProdOps Portfolio  →  ProdOps Workspace  →  Product Repository
```

O Framework é o nível zero — define vocabulário, princípios, fluxo e modelo operacional. Portfolios, Workspaces e Product Repositories o adotam sem modificar suas definições canônicas.

→ [Arquitetura completa e definições](framework/operating-model.md#arquitetura-do-prodops)

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

→ [Knowledge vs Execution](framework/knowledge-vs-execution.md)
→ [Execution Mapping](framework/execution-mapping/README.md)

---

## Fluxo oficial

```
Origin Stream → Business Signal → Fluxo Global ou Local
  → Local OBC Draft no Product Backlog
  → Modo: Upstream (exploração) | Downstream (compromisso)
  → Discovery + Assessment → OBC Committed
  → Iteration Plan → Delivery → Operation
```

→ [Fluxo completo explicado](framework/flow.md)
→ [Os quatro Origin Streams](framework/origin-streams.md)

---

## Documentação do Framework

| Documento | Descrição |
|---|---|
| [framework/principles.md](framework/principles.md) | Princípios fundacionais |
| [framework/glossary.md](framework/glossary.md) | Termos canônicos |
| [framework/flow.md](framework/flow.md) | Fluxo oficial do Framework |
| [framework/origin-streams.md](framework/origin-streams.md) | Os quatro Origin Streams |
| [framework/operating-model.md](framework/operating-model.md) | Modelo operacional completo |
| [framework/knowledge-vs-execution.md](framework/knowledge-vs-execution.md) | Separação Knowledge × Execution |
| [framework/execution-mapping/README.md](framework/execution-mapping/README.md) | Execution Mapping capability |
| [framework/backlogs.md](framework/backlogs.md) | Backlogs e tipos de Work Item |
| [framework/artifact-governance.md](framework/artifact-governance.md) | Governança de artefatos |

---

## Como adotar em um produto

1. Clone ou faça fork de [`prodops-framework`](https://github.com/produtoreativo/prodops-framework)
2. Copie `framework/` para `prodops/framework/` no repositório do produto
3. Crie os diretórios de produto: `artifacts/`, `journeys/`, `skills/`, `exec/`
4. Configure `exec/manifest.yaml` com os dados do produto
5. Siga o fluxo oficial a partir do primeiro Business Signal

---

## Como manter em sync

Melhorias no framework são feitas no repositório do produto e propagadas via PR:

```bash
./scripts/sync-framework-docs.sh           # sync + abre PR
./scripts/sync-framework-docs.sh --dry-run # preview sem push
```

---

## Portal do Product Repository

*Esta seção é relevante quando você está lendo este README dentro de um Product Repository.*

| Área | Descrição |
|---|---|
| [framework/](framework/) | Framework canônico — não modificar por produto |
| [artifacts/business/intents/](artifacts/business/intents/) | Business Intents registradas |
| [journeys/](journeys/) | As 5 jornadas: Discovery, Delivery, Operation, Assessment, Diligence |
| [artifacts/](artifacts/) | Artefatos produzidos: OBCs, BDD Features, planos, trilhas, evidências |
| [templates/](templates/) | Templates centralizados por área |
| [skills/](skills/) | Skills executáveis por agentes |

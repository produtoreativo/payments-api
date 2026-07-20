# Documentation Review — Refatoração Arquitetural Completa

**Data:** 2026-07-07
**Objetivo:** Refatoração arquitetural completa do Framework ProdOps — reorganização estrutural sem alteração de conteúdo, fatos ou significado técnico.

---

## Nova Arquitetura

```
prodops/
├── README.md                          ← Portal principal
├── framework/                         ← Princípios, glossário, modelo operacional
├── artifacts/business/intents/         ← ex-business-intents/ (movido para artifacts/business/intents/)
├── execution-model/                   ← Upstream e Downstream como modos (NOVO)
│   ├── README.md
│   ├── upstream.md
│   └── downstream.md
├── journeys/                          ← As 5 jornadas (NOVO container)
│   ├── README.md
│   ├── discovery/                     ← ex-upstream/
│   │   ├── README.md
│   │   ├── experiments/
│   │   │   └── <NNN-slug>/
│   │   │       ├── features/          ← BDD Features exploratórias (por experimento)
│   │   │       └── obcs/              ← OBC drafts (por experimento)
│   │   └── upstream-trail.md
│   ├── delivery/                      ← ex-delivery/
│   │   ├── README.md (reescrito)
│   │   ├── ci-sync.md
│   │   ├── ci-async.md
│   │   ├── phases/                    ← ex-flows/ (NOVO container)
│   │   │   ├── bootstrap/README.md
│   │   │   ├── hack/README.md
│   │   │   ├── sync/README.md         ← extraído de sync-finish.md
│   │   │   ├── finish/                ← extraído de sync-finish.md
│   │   │   │   ├── README.md
│   │   │   │   ├── quality-gates.md
│   │   │   │   └── done-criteria.md
│   │   │   ├── ship/README.md         ← extraído de ship-validate-promote.md
│   │   │   ├── validate/README.md     ← extraído de ship-validate-promote.md
│   │   │   └── promote/README.md      ← extraído de ship-validate-promote.md
│   │   ├── practices/
│   │   │   ├── prodops-tdd.md
│   │   │   ├── testing-policy.md      ← ex-engineering/
│   │   │   └── integration-testing-policy.md ← ex-engineering/
│   │   └── capabilities/
│   │       ├── (existentes)
│   │       ├── observability-policy.md ← ex-engineering/
│   │       └── reliability-policy.md   ← ex-engineering/
│   ├── operation/                     ← ex-operation/
│   ├── assessment/                    ← ex-assessment/
│   └── diligence/                     ← ex-diligence/ (README reescrito)
├── artifacts/                         ← Artefatos produzidos (NOVO container)
│   ├── README.md
│   ├── business/                      ← intents/, obcs/, bdd/
│   │   ├── intents/                   ← ex-business-intents/
│   │   ├── obcs/                      ← ex-assessment/obcs/
│   │   └── bdd/                       ← ex-product/features/
│   ├── product/                       ← context/, backlogs/, architecture/
│   │   ├── context/                   ← ex-product/ (product-deck, service-decks)
│   │   ├── backlogs/                  ← tracking-list, icebox, iteration-backlog
│   │   └── architecture/              ← ex-journeys/assessment/architecture/
│   └── governance/                    ← plans/, trails/, evidence/
│       ├── plans/                     ← ex-plans/ (iteration-plan)
│       ├── trails/                    ← ex-downstream/release-trail.md
│       └── evidence/
├── templates/
│   ├── assessment/
│   ├── delivery/
│   ├── engineering/
│   ├── business-intents/              ← NOVO
│   └── operation/                     ← NOVO
├── skills/                            ← ex-skills/ (raiz → prodops/skills/)
│   ├── README.md (NOVO)
│   ├── hack/
│   ├── sync/
│   ├── finish/
│   ├── ship/
│   ├── validate/
│   ├── promote/
│   ├── upstream/
│   ├── downstream/
│   └── payments-api-local-testing/
└── journeys/delivery/capabilities/commit-workflow/  ← hooks path intocado
```

---

## Mapeamento: Caminho Antigo → Caminho Novo

| Caminho Antigo | Caminho Novo |
|---|---|
| `prodops/upstream/` | `prodops/journeys/discovery/` |
| `prodops/delivery/` | `prodops/journeys/delivery/` |
| `prodops/delivery/flows/bootstrap.md` | `prodops/journeys/delivery/phases/bootstrap/README.md` |
| `prodops/delivery/flows/hack.md` | `prodops/journeys/delivery/phases/hack/README.md` |
| `prodops/delivery/flows/sync-finish.md` | `prodops/journeys/delivery/phases/sync/README.md` + `phases/finish/README.md` |
| `prodops/delivery/flows/ship-validate-promote.md` | `phases/ship/README.md` + `phases/validate/README.md` + `phases/promote/README.md` |
| `prodops/delivery/practices/` | `prodops/journeys/delivery/practices/` |
| `prodops/delivery/capabilities/` | `prodops/journeys/delivery/capabilities/` |
| `prodops/operation/` | `prodops/journeys/operation/` |
| `prodops/assessment/` | `prodops/journeys/assessment/` |
| `prodops/assessment/obcs/` | `prodops/artifacts/business/obcs/` |
| `prodops/assessment/iteration-plans/` | `prodops/artifacts/governance/plans/` |
| `prodops/diligence/` | `prodops/journeys/diligence/` |
| `prodops/product/` | `prodops/artifacts/product/` |
| `prodops/product/features/` | `prodops/artifacts/business/bdd/` |
| `prodops/downstream/release-trail.md` | `prodops/artifacts/governance/trails/release-trail.md` |
| `prodops/downstream/quality-gates.md` | `prodops/journeys/delivery/phases/finish/quality-gates.md` |
| `prodops/downstream/done-criteria.md` | `prodops/journeys/delivery/phases/finish/done-criteria.md` |
| `prodops/downstream/iteration-backlog.md` | `prodops/artifacts/product/backlogs/iteration-backlog.md` |
| `prodops/downstream/README.md` + `delivery-flow.md` | `prodops/execution-model/downstream.md` (novo) |
| `prodops/engineering/testing-policy.md` | `prodops/journeys/delivery/practices/testing-policy.md` |
| `prodops/engineering/integration-testing-policy.md` | `prodops/journeys/delivery/practices/integration-testing-policy.md` |
| `prodops/engineering/definition-of-done.md` | `prodops/templates/engineering/definition-of-done.md` |
| `prodops/engineering/observability-policy.md` | `prodops/journeys/delivery/capabilities/observability-policy.md` |
| `prodops/engineering/reliability-policy.md` | `prodops/journeys/delivery/capabilities/reliability-policy.md` |
| `skills/hack/` | `prodops/skills/hack/` |
| `skills/ship/` | `prodops/skills/ship/` |
| `skills/sync/` | `prodops/skills/sync/` |
| `skills/finish/` | `prodops/skills/finish/` |
| `skills/validate/` | `prodops/skills/validate/` |
| `skills/promote/` | `prodops/skills/promote/` |
| `skills/upstream/` | `prodops/skills/upstream/` |
| `skills/downstream/` | `prodops/skills/downstream/` |

---

## Novos Arquivos Criados

| Arquivo | Propósito |
|---|---|
| `prodops/journeys/README.md` | Portal das 5 jornadas |
| `prodops/journeys/delivery/phases/sync/README.md` | Fase Sync (extraída de sync-finish.md) |
| `prodops/journeys/delivery/phases/finish/README.md` | Fase Finish (extraída de sync-finish.md) |
| `prodops/journeys/delivery/phases/ship/README.md` | Fase Ship (extraída de ship-validate-promote.md) |
| `prodops/journeys/delivery/phases/validate/README.md` | Fase Validate (extraída de ship-validate-promote.md) |
| `prodops/journeys/delivery/phases/promote/README.md` | Fase Promote (extraída de ship-validate-promote.md) |
| `prodops/execution-model/README.md` | Upstream vs Downstream como modos |
| `prodops/execution-model/upstream.md` | Detalhes do modo Upstream |
| `prodops/execution-model/downstream.md` | Detalhes do modo Downstream |
| `prodops/artifacts/business/intents/README.md` | Ponto de entrada do Framework |
| `prodops/artifacts/README.md` | Portal de artefatos |
| `prodops/artifacts/business/bdd/README.md` | Índice de BDD Features comprometidas |
| `prodops/artifacts/governance/trails/README.md` | Índice de trilhas de evidência |
| `prodops/artifacts/governance/evidence/README.md` | Área de evidências |
| `prodops/skills/README.md` | Índice de skills executáveis |
| `prodops/templates/business-intents/README.md` | Template placeholder |
| `prodops/templates/operation/README.md` | Template placeholder |

---

## Áreas Eliminadas

| Área | Motivo |
|---|---|
| `prodops/upstream/` (raiz) | Conteúdo movido para `prodops/journeys/discovery/` |
| `prodops/delivery/` (raiz) | Conteúdo movido para `prodops/journeys/delivery/` |
| `prodops/delivery/flows/` | Cada flow virou um diretório de fase em `phases/` |
| `prodops/operation/` (raiz) | Movido para `prodops/journeys/operation/` |
| `prodops/assessment/` (raiz) | Movido para `prodops/journeys/assessment/` |
| `prodops/diligence/` (raiz) | Movido para `prodops/journeys/diligence/` |
| `prodops/product/` | Distribuído para `prodops/artifacts/product/` e `prodops/artifacts/business/bdd/` |
| `prodops/downstream/` | README e delivery-flow extraídos para `execution-model/downstream.md`; outros distribuídos |
| `prodops/engineering/` | Distribuído para `practices/` e `capabilities/` |
| `skills/` (raiz do repositório) | Movido para `prodops/skills/` |

---

## Links Atualizados

Links internos atualizados em todos os arquivos movidos e nos seguintes arquivos de referência:

- `AGENTS.md` — reescrito com novos caminhos
- `CLAUDE.md` — caminhos de routing atualizados
- `prodops/README.md` — reescrito como portal
- `prodops/framework/operating-model.md` — hierarquia atualizada para 9 camadas
- `prodops/framework/glossary.md` — referências de caminho atualizadas
- `prodops/artifacts/business/obcs/*.md` — referências de BDD Features e OBCs atualizadas
- `prodops/artifacts/governance/plans/iteration-plan.md` — referências de features atualizadas
- `prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md` — referências atualizadas
- Todos os arquivos dentro de `prodops/journeys/`, `prodops/skills/`, `prodops/artifacts/`

---

## Pendências e Sugestões Futuras

1. ~~**`prodops/artifacts/plans/`** — considerar renomear `iteration-backlog.md` (ex-assessment) e `downstream-iteration-backlog.md` (ex-downstream) para consolidar em um único arquivo.~~ Concluído: plans/ foi reestruturado em `artifacts/governance/plans/` (iteration-plan) e `artifacts/product/backlogs/` (iteration-backlog). `downstream-iteration-backlog.md` foi removido (arquivo de navegação, não artefato).

2. ~~**`prodops/journeys/assessment/`** — ainda não tem um README principal.~~ README já existe em `prodops/journeys/assessment/README.md`.

3. ~~**`prodops/journeys/discovery/features/README.md`**~~ — Este diretório não existe. Features exploratórias ficam em `prodops/journeys/discovery/experiments/<NNN-slug>/features/`. Pendência encerrada.

4. **`prodops/skills/payments-api-local-testing/`** — skill específica de repositório. Avaliar se deve ser mantida em `prodops/skills/` ou em área própria.

5. **Relative links** — alguns arquivos dentro de `prodops/journeys/delivery/phases/` podem ter links relativos que precisam de validação manual após a profundidade aumentar (ex: `../../../../commit-workflow/`).

6. **`prodops/templates/delivery/`** — ainda não contém um `skill-template.md`. Criar conforme o Framework evolui.

---

## Arquitetura Hierárquica Final

```
Origin Stream (Business | Enterprise | Team | Technology) → Intent → Assessment → Execution Mode → Journey → Phase → Practice → Capability → Artifacts
```

9 camadas de contexto para qualquer tarefa de produto e engenharia.

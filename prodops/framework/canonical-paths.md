# Canonical Paths

Localizações canônicas para todos os artefatos e recursos do ProdOps.
Use esta tabela como fonte primária de navegação antes de ler ou escrever qualquer artefato.

> **Escopo:** Este arquivo descreve apenas paths canônicos do ProdOps Framework — estruturas e artefatos que devem existir igualmente em qualquer produto que consuma o Framework. Paths locais do produto (artefatos, configurações operacionais e skills específicos do produto) são declarados em `prodops/exec/manifest.yaml` e não fazem parte desta fonte canônica.

---

## Framework

| Concern | Canonical path |
|---|---|
| Portal e mapa de navegação | `prodops/README.md` |
| Princípios obrigatórios | `prodops/framework/principles.md` |
| Glossário canônico | `prodops/framework/glossary.md` |
| Fluxo oficial do Framework | `prodops/framework/flow.md` |
| Os quatro Origin Streams | `prodops/framework/origin-streams.md` |
| Operating model | `prodops/framework/operating-model.md` |
| Hierarquia de backlogs | `prodops/framework/backlogs.md` |
| Localizações canônicas (este arquivo) | `prodops/framework/canonical-paths.md` |

---

## Execution Model

| Concern | Canonical path |
|---|---|
| Visão geral dos modos | `prodops/framework/execution-model/README.md` |
| Modo Upstream (discovery) | `prodops/framework/execution-model/upstream.md` |
| Modo Downstream (delivery) | `prodops/framework/execution-model/downstream.md` |

---

## Jornadas

| Concern | Canonical path |
|---|---|
| Visão geral das jornadas | `prodops/framework/journeys/README.md` |
| Jornada: Discovery | `prodops/framework/journeys/discovery/README.md` |
| Jornada: Assessment | `prodops/framework/journeys/assessment/README.md` |
| Jornada: Delivery | `prodops/framework/journeys/delivery/README.md` |
| Jornada: Operation | `prodops/framework/journeys/operation/README.md` |
| Jornada: Diligence | `prodops/framework/journeys/diligence/README.md` |

---

## Discovery

| Concern | Canonical path |
|---|---|
| Índice de experimentos | `prodops/framework/journeys/discovery/experiments.md` |
| Diretório de experimentos | `prodops/artifacts/experiments/` |
| Experimento individual | `prodops/artifacts/experiments/<NNN-slug>/experiment.md` |
| Trail de um experimento | `prodops/artifacts/experiments/<NNN-slug>/upstream-trail.md` |
| Evidências de um experimento | `prodops/artifacts/experiments/<NNN-slug>/evidence/` |
| OBCs exploratórias (em experimento) | `prodops/artifacts/experiments/<NNN-slug>/obcs/` |
| BDD Features exploratórias (em experimento) | `prodops/artifacts/experiments/<NNN-slug>/features/` |
| Trail global de discovery | `prodops/framework/journeys/discovery/upstream-trail.md` |
| Learnings consolidados | `prodops/framework/journeys/discovery/learnings.md` |
| Spikes | `prodops/framework/journeys/discovery/spikes.md` |
| Protótipos | `prodops/framework/journeys/discovery/prototypes.md` |

---

## Assessment

| Concern | Canonical path |
|---|---|
| Reliability Plans | `prodops/artifacts/plans/reliability/` |
| Reliability Plan — Objectives | `prodops/artifacts/plans/reliability/objectives.md` |
| Reliability Plan — Premortem | `prodops/artifacts/plans/reliability/premortem.md` |
| Setup: iteration-plan prompt | `prodops/framework/journeys/assessment/reliability-plans/setup/iteration-plan.prompt.md` |
| Setup: reliability-plan prompt | `prodops/framework/journeys/assessment/reliability-plans/setup/reliability-plan.prompt.md` |
| Riscos | `prodops/artifacts/risks/risks.md` |
| Oportunidades | `prodops/artifacts/risks/opportunities.md` |
| Event Storming | `prodops/artifacts/event-storming/` |
| Architecture overview | `prodops/artifacts/architecture/overview.md` |
| Decision Trail — arquitetura do produto | `prodops/artifacts/architecture/decision-trail.md` |

---

## Delivery — Fases (CI Sync)

| Fase | Canonical path |
|---|---|
| Bootstrap | `prodops/framework/journeys/delivery/phases/bootstrap/README.md` |
| Hack | `prodops/framework/journeys/delivery/phases/hack/README.md` |
| Sync | `prodops/framework/journeys/delivery/phases/sync/README.md` |
| Finish | `prodops/framework/journeys/delivery/phases/finish/README.md` |
| Finish — Done criteria | `prodops/framework/journeys/delivery/phases/finish/done-criteria.md` |
| Finish — Quality gates | `prodops/framework/journeys/delivery/phases/finish/quality-gates.md` |

## Delivery — Fases (CI Async)

| Fase | Canonical path |
|---|---|
| Ship | `prodops/framework/journeys/delivery/phases/ship/README.md` |
| Validate | `prodops/framework/journeys/delivery/phases/validate/README.md` |
| Promote | `prodops/framework/journeys/delivery/phases/promote/README.md` |

## Delivery — Pipelines

| Concern | Canonical path |
|---|---|
| CI Sync — sequência local | `prodops/framework/journeys/delivery/ci-sync.md` |
| CI Async — sequência de plataforma | `prodops/framework/journeys/delivery/ci-async.md` |

## Delivery — Capabilities (Delivery Capabilities)

| Delivery Capability | Canonical path |
|---|---|
| Commit Workflow | `prodops/framework/journeys/delivery/capabilities/commit-workflow/README.md` |
| Commit Workflow — PR template | `prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md` |
| Commit Workflow — task closing template | `prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/task-closing.md` |
| Contract Management | `prodops/framework/journeys/delivery/capabilities/contract-management.md` |
| Evidence Management | `prodops/framework/journeys/delivery/capabilities/evidence-management.md` |
| Observability (capability) | `prodops/framework/journeys/delivery/capabilities/observability.md` |
| Observability Policy | `prodops/framework/journeys/delivery/capabilities/observability-policy.md` |
| Reliability (capability) | `prodops/framework/journeys/delivery/capabilities/reliability.md` |
| Reliability Policy | `prodops/framework/journeys/delivery/capabilities/reliability-policy.md` |

## Delivery — Practices

| Practice | Canonical path |
|---|---|
| ProdOps TDD | `prodops/framework/journeys/delivery/practices/prodops-tdd.md` |
| Testing Policy | `prodops/framework/journeys/delivery/practices/testing-policy.md` |
| Integration Testing Policy | `prodops/framework/journeys/delivery/practices/integration-testing-policy.md` |

---

## Operation

| Concern | Canonical path |
|---|---|
| Visão geral | `prodops/framework/journeys/operation/README.md` |
| Operational trail | `prodops/framework/journeys/operation/operational-trail.md` |
| Incidents | `prodops/framework/journeys/operation/incidents.md` |
| Postmortems | `prodops/framework/journeys/operation/postmortems.md` |
| Runbooks | `prodops/framework/journeys/operation/runbooks.md` |

---

## Artifacts

| Artifact | Canonical path |
|---|---|
| Visão geral dos artefatos | `prodops/artifacts/README.md` |
| Business (categoria) | `prodops/artifacts/business/` |
| Product (categoria) | `prodops/artifacts/product/` |
| Governance (categoria) | `prodops/artifacts/governance/` |
| Product Deck | `prodops/artifacts/product/context/product-deck.md` |
| Service Decks | `prodops/artifacts/product/context/service-decks/` |
| Icebox | `prodops/artifacts/product/backlogs/icebox-backlog.md` |
| Product Tracking List | `prodops/artifacts/product/backlogs/tracking-list.md` |
| Iteration Backlog | `prodops/artifacts/product/backlogs/iteration-backlog.md` |
| OBCs (committed) | `prodops/artifacts/obcs/` |
| BDD Features (committed) | `prodops/artifacts/bdd/` |
| Business Intents | `prodops/artifacts/business-intents/` |
| Iteration Plan | `prodops/artifacts/plans/iteration-plan.md` |
| Architecture overview | `prodops/artifacts/architecture/overview.md` |
| Decision Trail — arquitetura | `prodops/artifacts/architecture/decision-trail.md` |
| Release Trail (model docs) | `prodops/artifacts/trails/release-trail.md` |
| Release Trail (active session) | `prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md` |
| Evidence (committed) | `prodops/artifacts/evidence/` |

---

## Business Intents

| Concern | Canonical path |
|---|---|
| Visão geral das Business Intents | `prodops/artifacts/business-intents/README.md` |
| Business Intents individuais | `prodops/artifacts/business-intents/<slug>.md` |
| Template de Business Intent | `prodops/templates/business-intents/intent.md` |

---

## Skills (Claude Code)

| Skill | Canonical path |
|---|---|
| Visão geral das skills | `prodops/skills/README.md` |
| Downstream (orquestra o fluxo completo) | `prodops/skills/downstream/SKILL.md` |
| Upstream (discovery e exploração) | `prodops/skills/upstream/SKILL.md` |
| Upstream → Deploy to sandbox | `prodops/skills/upstream/steps/deploy-to-sandbox/SKILL.md` |
| Upstream → Move to downstream | `prodops/skills/upstream/steps/move-to-downstream/SKILL.md` |
| Bootstrap | `prodops/skills/bootstrap/SKILL.md` |
| Hack | `prodops/skills/hack/SKILL.md` |
| Hack → Start | `prodops/skills/hack/steps/start/SKILL.md` |
| Hack → TDD | `prodops/skills/hack/steps/tdd/SKILL.md` |
| Hack → Commit | `prodops/skills/hack/steps/commit/SKILL.md` |
| Hack — Workflow reference | `prodops/skills/hack/references/workflow.md` |
| Sync | `prodops/skills/sync/SKILL.md` |
| Sync → Rebase | `prodops/skills/sync/steps/rebase/SKILL.md` |
| Sync → Align | `prodops/skills/sync/steps/align/SKILL.md` |
| Sync — Workflow reference | `prodops/skills/sync/references/workflow.md` |
| Finish | `prodops/skills/finish/SKILL.md` |
| Ship | `prodops/skills/ship/SKILL.md` |
| Ship — Workflow reference | `prodops/skills/ship/references/workflow.md` |
| Validate | `prodops/skills/validate/SKILL.md` |
| Promote | `prodops/skills/promote/SKILL.md` |

> **Nota:** Produtos podem manter Skills específicas em `prodops/skills/local/`. Esse diretório não é um target de sync do Framework — seu conteúdo pertence ao produto. Ver `prodops/skills/local/README.md`.

---

## Framework Engineering References

| Reference | Canonical path |
|---|---|
| TDD ProdOps | `prodops/skills/references/engineering/tdd-prodops/README.md` |
| TDD ProdOps — Integration-first | `prodops/skills/references/engineering/tdd-prodops/integration-first.md` |
| TDD ProdOps — Mocking Policy | `prodops/skills/references/engineering/tdd-prodops/mocking-policy.md` |
| TDD ProdOps — Observability | `prodops/skills/references/engineering/tdd-prodops/observability.md` |
| TDD ProdOps — Quality Gates | `prodops/skills/references/engineering/tdd-prodops/quality-gates.md` |
| TDD ProdOps — Red/Green/Refactor | `prodops/skills/references/engineering/tdd-prodops/red-green-refactor.md` |
| TDD ProdOps — Workflow | `prodops/skills/references/engineering/tdd-prodops/workflow.md` |

> **Referências locais do produto:** Produtos podem declarar literatura e convenções próprias em `prodops/skills/references/local/`. Esse diretório é protegido de sync por `.prodopsignore` e pertence ao produto. Framework Skills não dependem de referências locais como requisito. Ver `prodops/skills/references/README.md`.

---

## Templates

| Template | Canonical path |
|---|---|
| Visão geral | `prodops/templates/README.md` |
| Business Intent | `prodops/templates/business-intents/intent.md` |
| Experiment | `prodops/templates/discovery/experiment.md` |
| Learning | `prodops/templates/discovery/learning.md` |
| Discovery Trail | `prodops/templates/discovery/trail.md` |
| Decision Trail | `prodops/templates/assessment/decision-trail.md` |
| Reliability Checklist | `prodops/templates/assessment/reliability-checklist.md` |
| Pull Request Checklist | `prodops/templates/delivery/pull-request-checklist.md` |
| Release Entry | `prodops/templates/delivery/release-entry.md` |
| Definition of Done | `prodops/templates/engineering/definition-of-done.md` |
| Test Plan | `prodops/templates/engineering/test-plan.md` |
| Runbook | `prodops/templates/operation/runbook.md` |
| Postmortem | `prodops/templates/operation/postmortem.md` |

---

## Legacy Paths

Estes caminhos podem aparecer em entradas históricas migradas. **Não usar para novos artefatos.**

| Legacy path | Replacement |
|---|---|
| `prodops/upstream/` | `prodops/framework/journeys/discovery/` |
| `prodops/product/` | `prodops/artifacts/product/` |
| `prodops/assessment/` | `prodops/framework/journeys/assessment/` ou `prodops/artifacts/plans/` dependendo do artefato |
| `prodops/assessment/reliability-plan/` | `prodops/artifacts/plans/reliability/` |
| `prodops/assessment/reliability-plans/` | `prodops/artifacts/plans/reliability/` |
| `prodops/downstream/release-trail.md` | `prodops/artifacts/trails/release-trail.md` |
| `prodops/current-state/` | `prodops/artifacts/` (product/context, business/bdd, business/obcs) |
| `prodops/current-state/features/` | `prodops/artifacts/bdd/` |
| root `templates/upstream-*.md` | `prodops/templates/discovery/` |

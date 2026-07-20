# Documentation Review — Complete Architectural Refactoring

**Date:** 2026-07-07
**Objective:** Complete architectural refactoring of the ProdOps Framework — structural reorganization without changing content, facts, or technical meaning.

---

## New Architecture

```
prodops/
├── README.md                          ← Main portal
├── framework/                         ← Principles, glossary, operating model
├── artifacts/business/intents/         ← ex-business-intents/ (moved to artifacts/business/intents/)
├── execution-model/                   ← Upstream and Downstream as modes (NEW)
│   ├── README.md
│   ├── upstream.md
│   └── downstream.md
├── journeys/                          ← The 5 journeys (NEW container)
│   ├── README.md
│   ├── discovery/                     ← ex-upstream/
│   │   ├── README.md
│   │   ├── experiments/
│   │   │   └── <NNN-slug>/
│   │   │       ├── features/          ← Exploratory BDD Features (per experiment)
│   │   │       └── obcs/              ← OBC drafts (per experiment)
│   │   └── upstream-trail.md
│   ├── delivery/                      ← ex-delivery/
│   │   ├── README.md (rewritten)
│   │   ├── ci-sync.md
│   │   ├── ci-async.md
│   │   ├── phases/                    ← ex-flows/ (NEW container)
│   │   │   ├── bootstrap/README.md
│   │   │   ├── hack/README.md
│   │   │   ├── sync/README.md         ← extracted from sync-finish.md
│   │   │   ├── finish/                ← extracted from sync-finish.md
│   │   │   │   ├── README.md
│   │   │   │   ├── quality-gates.md
│   │   │   │   └── done-criteria.md
│   │   │   ├── ship/README.md         ← extracted from ship-validate-promote.md
│   │   │   ├── validate/README.md     ← extracted from ship-validate-promote.md
│   │   │   └── promote/README.md      ← extracted from ship-validate-promote.md
│   │   ├── practices/
│   │   │   ├── prodops-tdd.md
│   │   │   ├── testing-policy.md      ← ex-engineering/
│   │   │   └── integration-testing-policy.md ← ex-engineering/
│   │   └── capabilities/
│   │       ├── (existing)
│   │       ├── observability-policy.md ← ex-engineering/
│   │       └── reliability-policy.md   ← ex-engineering/
│   ├── operation/                     ← ex-operation/
│   ├── assessment/                    ← ex-assessment/
│   └── diligence/                     ← ex-diligence/ (README rewritten)
├── artifacts/                         ← Produced artifacts (NEW container)
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
│   ├── business-intents/              ← NEW
│   └── operation/                     ← NEW
├── skills/                            ← ex-skills/ (root → prodops/skills/)
│   ├── README.md (NEW)
│   ├── hack/
│   ├── sync/
│   ├── finish/
│   ├── ship/
│   ├── validate/
│   ├── promote/
│   ├── upstream/
│   ├── downstream/
│   └── payments-api-local-testing/
└── journeys/delivery/capabilities/commit-workflow/  ← hooks path untouched
```

---

## Mapping: Old Path → New Path

| Old Path | New Path |
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
| `prodops/downstream/README.md` + `delivery-flow.md` | `prodops/execution-model/downstream.md` (new) |
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

## New Files Created

| File | Purpose |
|---|---|
| `prodops/journeys/README.md` | Portal for the 5 journeys |
| `prodops/journeys/delivery/phases/sync/README.md` | Sync phase (extracted from sync-finish.md) |
| `prodops/journeys/delivery/phases/finish/README.md` | Finish phase (extracted from sync-finish.md) |
| `prodops/journeys/delivery/phases/ship/README.md` | Ship phase (extracted from ship-validate-promote.md) |
| `prodops/journeys/delivery/phases/validate/README.md` | Validate phase (extracted from ship-validate-promote.md) |
| `prodops/journeys/delivery/phases/promote/README.md` | Promote phase (extracted from ship-validate-promote.md) |
| `prodops/execution-model/README.md` | Upstream vs Downstream as modes |
| `prodops/execution-model/upstream.md` | Upstream mode details |
| `prodops/execution-model/downstream.md` | Downstream mode details |
| `prodops/artifacts/business/intents/README.md` | Framework entry point |
| `prodops/artifacts/README.md` | Artifacts portal |
| `prodops/artifacts/business/bdd/README.md` | Index of committed BDD Features |
| `prodops/artifacts/governance/trails/README.md` | Index of evidence trails |
| `prodops/artifacts/governance/evidence/README.md` | Evidence area |
| `prodops/skills/README.md` | Index of executable skills |
| `prodops/templates/business-intents/README.md` | Placeholder template |
| `prodops/templates/operation/README.md` | Placeholder template |

---

## Eliminated Areas

| Area | Reason |
|---|---|
| `prodops/upstream/` (root) | Content moved to `prodops/journeys/discovery/` |
| `prodops/delivery/` (root) | Content moved to `prodops/journeys/delivery/` |
| `prodops/delivery/flows/` | Each flow became a phase directory under `phases/` |
| `prodops/operation/` (root) | Moved to `prodops/journeys/operation/` |
| `prodops/assessment/` (root) | Moved to `prodops/journeys/assessment/` |
| `prodops/diligence/` (root) | Moved to `prodops/journeys/diligence/` |
| `prodops/product/` | Distributed to `prodops/artifacts/product/` and `prodops/artifacts/business/bdd/` |
| `prodops/downstream/` | README and delivery-flow extracted to `execution-model/downstream.md`; others distributed |
| `prodops/engineering/` | Distributed to `practices/` and `capabilities/` |
| `skills/` (repository root) | Moved to `prodops/skills/` |

---

## Updated Links

Internal links updated in all moved files and in the following reference files:

- `AGENTS.md` — rewritten with new paths
- `CLAUDE.md` — routing paths updated
- `prodops/README.md` — rewritten as portal
- `prodops/framework/operating-model.md` — hierarchy updated to 9 layers
- `prodops/framework/glossary.md` — path references updated
- `prodops/artifacts/business/obcs/*.md` — BDD Features and OBCs references updated
- `prodops/artifacts/governance/plans/iteration-plan.md` — feature references updated
- `prodops/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md` — references updated
- All files inside `prodops/journeys/`, `prodops/skills/`, `prodops/artifacts/`

---

## Pending Items and Future Suggestions

1. ~~**`prodops/artifacts/plans/`** — consider renaming `iteration-backlog.md` (ex-assessment) and `downstream-iteration-backlog.md` (ex-downstream) to consolidate into a single file.~~ Done: plans/ was restructured into `artifacts/governance/plans/` (iteration-plan) and `artifacts/product/backlogs/` (iteration-backlog). `downstream-iteration-backlog.md` was removed (navigation file, not an artifact).

2. ~~**`prodops/journeys/assessment/`** — does not yet have a main README.~~ README already exists at `prodops/journeys/assessment/README.md`.

3. ~~**`prodops/journeys/discovery/features/README.md`**~~ — This directory does not exist. Exploratory features live in `prodops/journeys/discovery/experiments/<NNN-slug>/features/`. Pending item closed.

4. **`prodops/skills/payments-api-local-testing/`** — repository-specific skill. Evaluate whether it should be kept under `prodops/skills/` or in its own area.

5. **Relative links** — some files inside `prodops/journeys/delivery/phases/` may have relative links that need manual validation after depth increases (e.g.: `../../../../commit-workflow/`).

6. **`prodops/templates/delivery/`** — does not yet contain a `skill-template.md`. Create as the Framework evolves.

---

## Final Hierarchical Architecture

```
Origin Stream (Business | Enterprise | Team | Technology) → Intent → Assessment → Execution Mode → Journey → Phase → Practice → Capability → Artifacts
```

9 context layers for any product and engineering task.

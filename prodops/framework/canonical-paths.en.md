# Canonical Paths

Canonical locations for all ProdOps artifacts and resources.
Use this table as the primary navigation source before reading or writing any artifact.

> **Scope:** This file describes only canonical ProdOps Framework paths — structures and artifacts that must exist equally in any product consuming the Framework. Product-local paths (artifacts, operational configuration, and product-specific skills) are declared in `prodops/exec/manifest.yaml` and are not part of this canonical source.

---

## Framework

| Concern | Canonical path |
|---|---|
| Portal and navigation map | `prodops/README.md` |
| Mandatory principles | `prodops/framework/principles.md` |
| Canonical glossary | `prodops/framework/glossary.md` |
| Official Framework flow | `prodops/framework/flow.md` |
| The four Origin Streams | `prodops/framework/origin-streams.md` |
| Operating model | `prodops/framework/operating-model.md` |
| Backlog hierarchy | `prodops/framework/backlogs.md` |
| Canonical locations (this file) | `prodops/framework/canonical-paths.md` |

---

## Execution Model

| Concern | Canonical path |
|---|---|
| Modes overview | `prodops/framework/execution-model/README.md` |
| Upstream mode (discovery) | `prodops/framework/execution-model/upstream.md` |
| Downstream mode (delivery) | `prodops/framework/execution-model/downstream.md` |

---

## Journeys

| Concern | Canonical path |
|---|---|
| Journeys overview | `prodops/framework/journeys/README.md` |
| Journey: Discovery | `prodops/framework/journeys/discovery/README.md` |
| Journey: Assessment | `prodops/framework/journeys/assessment/README.md` |
| Journey: Delivery | `prodops/framework/journeys/delivery/README.md` |
| Journey: Operation | `prodops/framework/journeys/operation/README.md` |
| Journey: Diligence | `prodops/framework/journeys/diligence/README.md` |

---

## Discovery

| Concern | Canonical path |
|---|---|
| Experiments index | `prodops/framework/journeys/discovery/experiments.md` |
| Experiments directory | `prodops/artifacts/experiments/` |
| Individual experiment | `prodops/artifacts/experiments/<NNN-slug>/experiment.md` |
| Experiment trail | `prodops/artifacts/experiments/<NNN-slug>/upstream-trail.md` |
| Experiment evidence | `prodops/artifacts/experiments/<NNN-slug>/evidence/` |
| Exploratory OBCs (in experiment) | `prodops/artifacts/experiments/<NNN-slug>/obcs/` |
| Exploratory BDD Features (in experiment) | `prodops/artifacts/experiments/<NNN-slug>/features/` |
| Global discovery trail | `prodops/framework/journeys/discovery/upstream-trail.md` |
| Consolidated learnings | `prodops/framework/journeys/discovery/learnings.md` |
| Spikes | `prodops/framework/journeys/discovery/spikes.md` |
| Prototypes | `prodops/framework/journeys/discovery/prototypes.md` |

---

## Assessment

| Concern | Canonical path |
|---|---|
| Reliability Plans | `prodops/artifacts/plans/reliability/` |
| Reliability Plan — Objectives | `prodops/artifacts/plans/reliability/objectives.md` |
| Reliability Plan — Premortem | `prodops/artifacts/plans/reliability/premortem.md` |
| Setup: iteration-plan prompt | `prodops/framework/journeys/assessment/reliability-plans/setup/iteration-plan.prompt.md` |
| Setup: reliability-plan prompt | `prodops/framework/journeys/assessment/reliability-plans/setup/reliability-plan.prompt.md` |
| Risks | `prodops/artifacts/risks/risks.md` |
| Opportunities | `prodops/artifacts/risks/opportunities.md` |
| Event Storming | `prodops/artifacts/event-storming/` |
| Architecture overview | `prodops/artifacts/architecture/overview.md` |
| Product architecture Decision Trail | `prodops/artifacts/architecture/decision-trail.md` |

---

## Delivery — Phases (CI Sync)

| Phase | Canonical path |
|---|---|
| Bootstrap | `prodops/framework/journeys/delivery/phases/bootstrap/README.md` |
| Hack | `prodops/framework/journeys/delivery/phases/hack/README.md` |
| Sync | `prodops/framework/journeys/delivery/phases/sync/README.md` |
| Finish | `prodops/framework/journeys/delivery/phases/finish/README.md` |
| Finish — Done criteria | `prodops/framework/journeys/delivery/phases/finish/done-criteria.md` |
| Finish — Quality gates | `prodops/framework/journeys/delivery/phases/finish/quality-gates.md` |

## Delivery — Phases (CI Async)

| Phase | Canonical path |
|---|---|
| Ship | `prodops/framework/journeys/delivery/phases/ship/README.md` |
| Validate | `prodops/framework/journeys/delivery/phases/validate/README.md` |
| Promote | `prodops/framework/journeys/delivery/phases/promote/README.md` |

## Delivery — Pipelines

| Concern | Canonical path |
|---|---|
| CI Sync — local sequence | `prodops/framework/journeys/delivery/ci-sync.md` |
| CI Async — platform sequence | `prodops/framework/journeys/delivery/ci-async.md` |

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
| Overview | `prodops/framework/journeys/operation/README.md` |
| Operational trail | `prodops/framework/journeys/operation/operational-trail.md` |
| Incidents | `prodops/framework/journeys/operation/incidents.md` |
| Postmortems | `prodops/framework/journeys/operation/postmortems.md` |
| Runbooks | `prodops/framework/journeys/operation/runbooks.md` |

---

## Artifacts

| Artifact | Canonical path |
|---|---|
| Artifacts overview | `prodops/artifacts/README.md` |
| Business (category) | `prodops/artifacts/business/` |
| Product (category) | `prodops/artifacts/product/` |
| Governance (category) | `prodops/artifacts/governance/` |
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
| Decision Trail — architecture | `prodops/artifacts/architecture/decision-trail.md` |
| Release Trail (model docs) | `prodops/artifacts/trails/release-trail.md` |
| Release Trail (active session) | `prodops/artifacts/trails/sessions/YYYY-MM-DD-<session-id>.md` |
| Evidence (committed) | `prodops/artifacts/evidence/` |

---

## Business Intents

| Concern | Canonical path |
|---|---|
| Business Intents overview | `prodops/artifacts/business-intents/README.md` |
| Individual Business Intents | `prodops/artifacts/business-intents/<slug>.md` |
| Business Intent template | `prodops/templates/business-intents/intent.md` |

---

## Skills (Claude Code)

| Skill | Canonical path |
|---|---|
| Skills overview | `prodops/skills/README.md` |
| Downstream (orchestrates full flow) | `prodops/skills/downstream/SKILL.md` |
| Upstream (discovery and exploration) | `prodops/skills/upstream/SKILL.md` |
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

> **Note:** Products may maintain product-specific Skills in `prodops/skills/local/`. This directory is not a Framework sync target — its content belongs to the product. See `prodops/skills/local/README.en.md`.

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

---

## Templates

| Template | Canonical path |
|---|---|
| Overview | `prodops/templates/README.md` |
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

These paths may appear in migrated historical entries. **Do not use for new artifacts.**

| Legacy path | Replacement |
|---|---|
| `prodops/upstream/` | `prodops/framework/journeys/discovery/` |
| `prodops/product/` | `prodops/artifacts/product/` |
| `prodops/assessment/` | `prodops/framework/journeys/assessment/` or `prodops/artifacts/plans/` depending on the artifact |
| `prodops/assessment/reliability-plan/` | `prodops/artifacts/plans/reliability/` |
| `prodops/assessment/reliability-plans/` | `prodops/artifacts/plans/reliability/` |
| `prodops/downstream/release-trail.md` | `prodops/artifacts/trails/release-trail.md` |
| `prodops/current-state/` | `prodops/artifacts/` (product/context, business/bdd, business/obcs) |
| `prodops/current-state/features/` | `prodops/artifacts/bdd/` |
| root `templates/upstream-*.md` | `prodops/templates/discovery/` |

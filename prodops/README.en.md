[Português](README.md) · [Why is this project in Portuguese?](language.md)

# ProdOps Workspace — Payments API

This directory is the **ProdOps Workspace** for the `payments-api` product. It combines four layers in one place:

| Layer | Content | Editable by product? |
|---|---|---|
| **Framework** | Principles, glossary, flow, and operating model | No — canonical |
| **Artifacts** | OBCs, BDD Features, plans, backlogs, trails | Yes — belongs to the product |
| **Agent execution** | Skills, agent specs, execution manifest | Partial — local skills are editable |
| **Local extensions** | Product-specific skills, engineering references | Yes — local to the product |

---

## Intent-based navigation

### I want to understand the Framework

→ [framework/principles.en.md](framework/principles.en.md) — the 8 foundational principles (includes Automation First)\
→ [framework/glossary.en.md](framework/glossary.en.md) — complete canonical vocabulary\
→ [framework/flow.en.md](framework/flow.en.md) — official flow: Signal → OBC → Iteration → Delivery → Operation\
→ [framework/operating-model.en.md](framework/operating-model.en.md) — ProdOps four-level architecture\
→ [framework/knowledge-vs-execution.en.md](framework/knowledge-vs-execution.en.md) — why Markdown prevails over GitHub Issues\
→ [framework/](framework/) — full Framework index

### I want to understand the journeys

→ [journeys/README.en.md](journeys/README.en.md) — overview of the five journeys and their flows\
→ [journeys/discovery/](journeys/discovery/) — exploration, experiments, prototypes\
→ [journeys/delivery/](journeys/delivery/) — CI Sync and CI Async phases, practices, capabilities\
→ [journeys/assessment/](journeys/assessment/) — risk analysis, opportunities, Reliability Plan\
→ [journeys/operation/](journeys/operation/) — incidents, postmortems, runbooks, operational trail\
→ [journeys/diligence/](journeys/diligence/) — synchronization, workspace drift, reconciliation

### I want to execute an action (as an agent)

→ [../../AGENTS.md](../../AGENTS.md) — agent entry router: which skill to invoke and when\
→ [skills/README.en.md](skills/README.en.md) — full catalog of executable skills\
→ [exec/manifest.yaml](exec/manifest.yaml) — machine-readable source of truth (paths, gates, vocabulary)\
→ Delivery phase skills: [bootstrap](skills/bootstrap/SKILL.md) · [hack](skills/hack/SKILL.md) · [sync](skills/sync/SKILL.md) · [finish](skills/finish/SKILL.md) · [ship](skills/ship/SKILL.md) · [validate](skills/validate/SKILL.md) · [promote](skills/promote/SKILL.md)\
→ Journey skills: [upstream](skills/upstream/SKILL.md) · [downstream](skills/downstream/SKILL.md) · [diligence](skills/diligence/SKILL.md)

### I want to create an artifact

→ [templates/](templates/) — templates by type: OBC, Business Intent, Experiment, Postmortem, Release Entry, etc.\
→ [framework/artifact-governance.en.md](framework/artifact-governance.en.md) — creation rules and artifact lifecycle\
→ [framework/execution-mapping/README.en.md](framework/execution-mapping/README.en.md) — how to map artifacts to GitHub Work Items

### I want to see the current product state

→ [artifacts/governance/plans/iteration-plan.md](artifacts/governance/plans/iteration-plan.md) — what is committed for this iteration\
→ [artifacts/product/backlogs/iteration-backlog.md](artifacts/product/backlogs/iteration-backlog.md) — iteration backlog\
→ [artifacts/product/backlogs/icebox-backlog.md](artifacts/product/backlogs/icebox-backlog.md) — pending preparatory Discovery\
→ [artifacts/business/obcs/](artifacts/business/obcs/) — all active Observable Business Contracts\
→ [artifacts/governance/trails/release-trail.md](artifacts/governance/trails/release-trail.md) — delivery history\
→ [artifacts/product/architecture/overview.md](artifacts/product/architecture/overview.md) — current architecture diagram and inventory

### I want to understand how agents work

→ [../../AGENTS.md](../../AGENTS.md) — minimal router: which skill, which manifest, which card\
→ [exec/manifest.yaml](exec/manifest.yaml) — execution parameters: product, quality gates, commit types\
→ [framework/execution-mapping/matrix.en.md](framework/execution-mapping/matrix.en.md) — which operations are allowed per artifact\
→ [skills/](skills/) — skill implementations by phase and journey\
→ [execution-model/](execution-model/) — difference between Upstream and Downstream modes

---

## Directory map

| Directory | Contents | Nature |
|---|---|---|
| [framework/](framework/) | Principles, glossary, flow, backlogs, OBC, governance, execution mapping | Canonical — distributed from prodops-framework. Do not modify per product. |
| [journeys/](journeys/) | The five journeys: Discovery, Delivery, Operation, Assessment, Diligence | Canonical (structure) + local (journey artifacts such as experiments and trails) |
| [artifacts/](artifacts/) | OBCs, BDD Features, intents, plans, backlogs, architecture, trails, evidence | Local — belongs exclusively to the product |
| [skills/](skills/) | Agent-executable skills: delivery phases + journeys | Canonical + local extensions (e.g. `payments-api-local-testing`, `diligence`) |
| [templates/](templates/) | Reusable templates by artifact type | Canonical — do not modify per product |
| [exec/](exec/) | `manifest.yaml` (source of truth) + delivery cards | Local — belongs to the product |
| [execution-model/](execution-model/) | Definition of Upstream and Downstream modes | Canonical — read only |
| [scripts/](scripts/) | Automation: manifest validation, doctor check, delivery sync | Canonical + local |

---

## Core principle

```
A ProdOps artifact is NEVER a GitHub Issue.

Knowledge Space (permanent)       Execution Space (ephemeral)
───────────────────────────────   ──────────────────────────────
OBC, BDD, Intent, Signal,         Issues, PRs, Discussions,
Architecture, Plans, Evidence     Releases, Milestones

Markdown always prevails over GitHub.
```

→ [Knowledge vs Execution](framework/knowledge-vs-execution.en.md)\
→ [Execution Mapping](framework/execution-mapping/README.en.md)

---

## Flow summary

```
Origin Stream → Business Signal → Global or Local Flow
  → Local OBC Draft in Product Backlog
  → Mode: Upstream (exploration) | Downstream (commitment)
  → Discovery + Assessment → OBC Committed
  → Iteration Plan → Delivery (CI Sync → CI Async) → Operation
```

→ [Full flow](framework/flow.en.md) · [Origin Streams](framework/origin-streams.en.md) · [Journeys](journeys/README.en.md)

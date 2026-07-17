# Templates — ProdOps

Reusable templates organized by work area.

Copy the template to the canonical location indicated before filling it in. Never fill in the template in place.

---

## Discovery (Upstream)

| Template | Usage | Canonical location |
|---|---|---|
| [experiment.md](discovery/experiment.md) | New Upstream experiment | `prodops/journeys/discovery/experiments/NNN-slug/experiment.md` |
| [trail.md](discovery/trail.md) | Chronological trail of an experiment | `prodops/journeys/discovery/experiments/NNN-slug/upstream-trail.md` |
| [learning.md](discovery/learning.md) | Consolidated experiment learning | new entry in `prodops/journeys/discovery/learnings.md` |

Create an `evidence/` directory next to the experiment when you need command outputs, payloads, or provider responses.

---

## Delivery (Downstream)

| Template | Usage | Canonical location |
|---|---|---|
| [delivery/release-entry.md](delivery/release-entry.md) | Release Trail entry | append to the active session trail at `prodops/artifacts/governance/trails/sessions/` |
| [delivery/pull-request-checklist.md](delivery/pull-request-checklist.md) | PR checklist before Finish | used during Pull Request review |

---

## Engineering

| Template | Usage | Canonical location |
|---|---|---|
| [engineering/definition-of-done.md](engineering/definition-of-done.md) | Definition of Done | reference in the Finish phase |
| [engineering/test-plan.md](engineering/test-plan.md) | Test plan for a capability | used during Hack |

---

## Assessment

| Template | Usage | Canonical location |
|---|---|---|
| [assessment/decision-trail.md](assessment/decision-trail.md) | Decision record under uncertainty | `prodops/journeys/assessment/` or inline in the trail |
| [assessment/reliability-checklist.md](assessment/reliability-checklist.md) | Reliability checklist before Ship | used in Finish/Ship |

---

## Intents

| Template | Usage | Canonical location |
|---|---|---|
| [business-intents/intent.md](business-intents/intent.md) | New Intent | `prodops/artifacts/business/intents/<slug>.md` |

---

## Operation

| Template | Usage | Canonical location |
|---|---|---|
| [operation/runbook.md](operation/runbook.md) | Operational runbook | `prodops/journeys/operation/runbooks.md` (new section) |
| [operation/postmortem.md](operation/postmortem.md) | Incident postmortem | `prodops/journeys/operation/postmortems.md` (new entry) |

---

## Rules

- Never fill in templates in place — copy to the canonical destination.
- Never create product or release artifacts here — templates are structure, not content.
- When evolving a template, check whether existing instances in the artifacts need to be migrated.

# EXP-006 - Upstream Trail per Experiment

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

Make Upstream evidence easier to audit by keeping each experiment's execution
history next to the experiment itself.

This supports exploratory work that can produce code, contracts, OBC drafts,
BDD scenarios and validation evidence without forcing every activity into one
large global chronological file.

---

# Repository Scope Gate

## Repository-owned scope

- [x] Payments API behavior
- [ ] Payments domain logic
- [ ] Provider integration
- [ ] Webhook handling
- [ ] Persistence
- [ ] API/event contract owned by Payments
- [ ] Validation Workbench behavior
- [x] Local tests or executable evidence

## External dependencies

- None.

## Scope decision

- [x] Continue as executable Upstream experiment in this repository
- [ ] Record only as external dependency or release risk
- [ ] Redirect to owning repository or team

---

# Question to Answer

What is the best ProdOps structure for keeping an `upstream-trail.md` for each
Upstream experiment?

---

# Hypothesis

A directory per experiment is the best pattern because it keeps the experiment
definition, timeline and evidence together while preserving global indexes for
navigation.

---

# Scope

- Define the canonical experiment directory layout.
- Update Upstream operating guidance.
- Update templates.
- Migrate existing flat experiment files to the directory pattern.

---

# Out of Scope

- Migrating all existing legacy experiment files.
- Changing Downstream release-trail rules.
- Changing business behavior, BDD scenarios, OBC content or AWS code.

---

# Technical Findings

The previous structure mixed two concerns:

- experiment files captured hypothesis, findings and decision state;
- the global `prodops/upstream/upstream-trail.md` captured chronological
  execution for every experiment.

That made a single file responsible for every experiment's evidence history.
The better pattern is:

```text
prodops/upstream/experiments/NNN-short-slug/
  experiment.md
  upstream-trail.md
  evidence/
```

The global trail remains useful as a repository-level index, but it should not
be the primary record for experiment execution.

---

# Architecture Impact

ProdOps artifact ownership changes as follows:

- `experiment.md` owns stable experiment context and the Decision Package.
- `upstream-trail.md` inside the experiment directory owns execution history.
- `evidence/` owns detailed supporting artifacts.
- `prodops/upstream/experiments.md` owns the index.
- `prodops/upstream/upstream-trail.md` owns cross-experiment milestones only.

---

# Reliability Impact

No runtime reliability impact.

The change improves auditability of reliability evidence because validation
commands, failures, decisions and follow-ups can be attached to the experiment
that produced them.

---

# Artifacts Updated

- `AGENTS.md`
- `skills/upstream/SKILL.md`
- `prodops/upstream/README.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/experiments/README.md`
- `prodops/templates/discovery/experiment.md`
- `prodops/templates/discovery/trail.md`
- `prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`
- `prodops/upstream/experiments/006-upstream-trail-per-experiment/upstream-trail.md`
- `prodops/upstream/upstream-trail.md`

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|----------|--------|----------|
| What structure should own experiment execution history? | Answered | Directory per experiment with local `upstream-trail.md`. |
| What happens to the global trail? | Answered | It becomes a high-level index for milestones, migrations and process changes. |
| Should legacy flat experiments be migrated immediately? | Answered | Yes. Existing flat files were migrated, and EXP-004 was recovered because references existed but the source file was missing. |

---

# Recommendation

- [x] Move Downstream
- [ ] Run another Upstream experiment
- [ ] Wait for business decision
- [ ] Wait for external dependency
- [ ] Discard capability

Adopt the directory-per-experiment layout as the canonical Upstream operating
standard.

---

# Decision Package

## Executive Summary

Upstream experiments should be self-contained directories with `experiment.md`,
`upstream-trail.md` and optional `evidence/`.

## Recommended Decision

Use the new layout for every new experiment. If a flat legacy experiment returns
from history or another branch, migrate it before making further changes.

## Updated Risks

No product runtime risk.

## Updated Opportunities

Experiment evidence becomes easier to review, promote, archive and audit.

## Updated Tracking Items

None.

## Updated OBCs

None.

## Updated Reliability Plan

None.

## Recommended Downstream Scope

No product Downstream scope. This is a ProdOps operating-standard update.

---

# Exit Criteria

- [x] Original hypothesis answered
- [x] Questions classified
- [x] Knowledge gaps documented
- [x] Architecture impact documented
- [x] Reliability impact documented
- [x] Artifacts updated
- [x] Recommendation produced
- [x] Decision Package completed

---

# Next Step

Use the directory-per-experiment layout for the next Upstream experiment.

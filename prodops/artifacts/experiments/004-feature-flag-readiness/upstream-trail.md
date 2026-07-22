# Upstream Trail - EXP-004

## Experiment

Reference:

`prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`

---

# History

> Append new entries below.
> Never rewrite previous entries.

## 2026-07-02 16:08

### Activity

Started experiment after reviewing Current State, Repository Tracking List, Reliability
Plan, Premortem, Iteration Plan and existing Upstream experiments.

### Summary

The highest-priority uncertainty is the Checkout Feature Flag readiness for the
new Payments gateway. The approved release depends on enabling this route, but
the flag remains documented as blocked by a Checkout bug and lacks rollback
evidence for orders already started in Payments.

Existing experiments cover credit card uncertainty and do not cover this
release-blocking dependency, so a new Upstream experiment was created.

### Artifacts Updated

- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/learnings.md`

### Evidence

- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Continue experiment.

### Notes

Next step is to collect Checkout evidence: exact Feature Flag bug, owner, fix
status, targeting rules, auditability, rollout/pause/rollback criteria,
telemetry by order and in-flight order handling after rollback.

## 2026-07-02 16:40

### Activity

Updated BDD Features to reflect the existing Upstream experiments.

### Summary

A new Checkout Feature Flag readiness BDD was added to represent the EXP-004
learning as executable acceptance criteria for rollout, pause, rollback,
auditability, in-flight orders and promotion blocking.

This entry was migrated from the global trail and also relates to EXP-001,
EXP-002 and EXP-003.

### Artifacts Updated

- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrado: hoje `prodops/artifacts/bdd/credit-card-payment.feature`)
- `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removido: sem sucessor em `prodops/artifacts/bdd/`)

### Evidence

- Migrated from `prodops/upstream/upstream-trail.md`.
- `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removido: sem sucessor em `prodops/artifacts/bdd/`) is
  referenced by the original trail but is not present in the workspace.

### Decision

Continue experiment.

### Notes

The missing Feature file remains a repository consistency gap.

# Upstream Trail - EXP-006

## Experiment

Reference:

`prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`

---

# History

> Append new entries below.
> Never rewrite previous entries.

## 2026-07-03 18:04

### Activity

Migrated existing Upstream experiments to the per-experiment directory pattern.

### Summary

Existing flat experiment files were moved into directories with
`experiment.md`, local `upstream-trail.md` and `evidence/`. EXP-004 was
recovered as a placeholder record because repository artifacts referenced it,
but the original flat experiment file was not present in the workspace.

The local trails now preserve the relevant history that previously lived only
in the global trail.

### Artifacts Updated

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/001-credit-card-lifecycle/upstream-trail.md`
- `prodops/upstream/experiments/002-sandbox-funding/experiment.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/upstream-trail.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/upstream-trail.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/upstream-trail.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/upstream-trail.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/journeys/discovery/features/README.md` (removed: directory consolidated into `prodops/artifacts/bdd/`)

### Evidence

- `find prodops/upstream/experiments -maxdepth 2 -type f` showed flat
  experiment files for 001, 002, 003 and 005 before migration.
- `rg` showed references to missing EXP-004 artifacts.

### Decision

Ready for Assessment.

### Notes

`prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removed: no successor in `prodops/artifacts/bdd/`) is referenced
by historical trail entries but is not present in the workspace.

## 2026-07-03 17:58

### Activity

Defined the per-experiment Upstream trail pattern.

### Summary

The canonical Upstream experiment layout is now a directory containing
`experiment.md`, `upstream-trail.md` and optional `evidence/`. This keeps
chronological execution history with the experiment that produced it and
prevents the global trail from becoming the only audit source for all
experiments.

Existing flat experiment files were later migrated, and new experiments should
not use that shape. The global `prodops/upstream/upstream-trail.md` remains only for
cross-experiment milestones, migrations, promotions and repository-wide
Upstream process changes.

### Artifacts Updated

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

### Evidence

- Reviewed existing `prodops/templates/discovery/experiment.md`.
- Reviewed existing `prodops/templates/discovery/trail.md`.
- Reviewed existing `prodops/upstream/README.md`.
- Reviewed existing `prodops/upstream/experiments.md`.
- Reviewed existing flat experiment files under `prodops/upstream/experiments/`.

### Decision

Ready for Assessment.

### Notes

Existing flat files were not migrated in this change to avoid unnecessary
rewrite churn. Migrate a legacy experiment only when it is actively changed
beyond a small correction.

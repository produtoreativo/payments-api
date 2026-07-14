# EXP-004 - Checkout Gateway Feature Flag Readiness

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Recovery Note

This experiment is a recovered record.

The global Upstream Trail and Reliability Plan referenced the former flat path
`prodops/upstream/experiments/004-feature-flag-readiness.md`, but that file was
not present in the workspace during migration to the per-experiment directory
pattern.

Only context already present in repository artifacts was used here. Missing
business decisions and Checkout-owned implementation details remain open.

---

# Business Goal

Validate whether the Checkout Feature Flag that enables the new Payments
gateway is ready for controlled activation, pause and rollback.

This experiment exists because the approved release depends on enabling the new
gateway, while the Feature Flag is documented as blocked by a Checkout bug.

---

# Repository Scope Gate

## Repository-owned scope

- [ ] Payments API behavior
- [ ] Payments domain logic
- [ ] Provider integration
- [ ] Webhook handling
- [ ] Persistence
- [ ] API/event contract owned by Payments
- [ ] Validation Workbench behavior
- [ ] Local tests or executable evidence

## External dependencies

- Checkout Feature Flag implementation.
- Checkout rollout targeting.
- Feature Flag system auditability.
- Checkout telemetry by order and gateway route.
- Checkout bug fix status.

## Scope decision

- [ ] Continue as executable Upstream experiment in this repository
- [x] Record only as external dependency or release risk
- [ ] Redirect to owning repository or team

Payments API can record the dependency and required evidence, but this
repository does not own the Feature Flag implementation.

---

# Question to Answer

Is the Checkout Feature Flag ready to safely activate the new Payments gateway
for the approved release path?

Required evidence:

- exact bug that keeps the flag disabled;
- owner and status of the fix;
- targeting and gradual rollout rules;
- activation/deactivation auditability;
- telemetry that distinguishes old and new gateway by order;
- pause and rollback criteria;
- policy for orders already started in Payments when the flag is disabled.

---

# Hypothesis

The new Payments gateway should not be promoted as release-ready until Checkout
provides evidence that the Feature Flag can activate, pause and roll back the
journey without abandoning in-flight orders.

---

# Scope

- Record Feature Flag readiness as an external dependency.
- Keep P0 risk visible in Reliability Plan and Repository Tracking List.
- Define evidence required from Checkout.

---

# Out of Scope

- Implementing Checkout Feature Flag behavior.
- Implementing Checkout rollout targeting.
- Creating Checkout-owned telemetry.
- Changing Payments API runtime behavior.

---

# Technical Findings

- The Feature Flag is outside this repository.
- The release can remain blocked even if Payments API is technically ready.
- Rollback must define what happens to orders that already started the Payments
  flow before the flag is disabled.

---

# Reliability Impact

The Feature Flag is a P0 release readiness dependency because unsafe activation
or rollback can block production rollout and create inconsistent payment
journeys.

---

# Artifacts Updated

- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/upstream-trail.md`
- `prodops/upstream/experiments.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/product/tracking-list.md`
- `prodops/upstream/upstream-trail.md`

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|----------|--------|----------|
| Is the Feature Flag owned by this repository? | Answered | Reliability Plan and Premortem classify Checkout and Feature Flag as external dependencies. |
| Can this repo implement the Feature Flag? | Answered | Repository Scope Gate rejects executable work here. |
| What evidence is required from Checkout? | Answered | Risks and Repository Tracking List enumerate bug, owner, rollout, audit, telemetry, rollback and in-flight order policy. |

---

# Recommendation

- [ ] Move Downstream
- [ ] Run another Upstream experiment
- [ ] Wait for business decision
- [x] Wait for external dependency
- [ ] Discard capability

Wait for Checkout evidence before treating the release as ready for production
activation.

---

# Decision Package

## Executive Summary

EXP-004 is an external dependency record. Payments API can document the required
Feature Flag evidence, but Checkout must provide implementation and rollout
readiness.

## Recommended Decision

Wait for external dependency.

## Updated Risks

Keep the Feature Flag readiness risk as P0 until Checkout evidence is provided.

## Updated Opportunities

None.

## Updated Tracking Items

Repository Tracking List already contains Feature Flag readiness and rollback policy items.

## Updated OBCs

None.

## Updated Reliability Plan

Reliability Plan already records the Feature Flag as a release readiness risk.

## Recommended Downstream Scope

No Payments API Downstream scope until Checkout evidence is available.

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

Collect Checkout evidence for bug status, rollout targeting, auditability,
telemetry, rollback and in-flight order policy.

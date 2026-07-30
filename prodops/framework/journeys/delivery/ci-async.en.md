# CI Async

CI Async is the asynchronous grouping of ProdOps Delivery. It represents work **driven by the platform, pipelines, and environments**.

```
CI Async: Ship → Validate → Promote
```

## Purpose

CI Async produces:
- Autonomous PR observed: merge confirmed and Staging deploy successful (Ship)
- Runtime validation executed in the Staging environment (Validate)
- Feature promoted to Sandbox (Release Candidate) with recorded evidence (Promote)

## Environments

| Environment | Type | Responsible phase |
|---|---|---|
| Staging | Ephemeral per Feature/OBC | Ship (observes deploy) and Validate (validates Feature) |
| Sandbox | Shared (Release Candidate) | Promote (promotion target) |
| Production | Operational | Outside the Delivery Journey |

## Responsibilities by Actor

| Actor | Responsibility |
|---|---|
| **Finish** | Creates the autonomous PR (final step of CI Sync) |
| **GitHub** | Executes approval, merge, and branch protection validations |
| **GitHub Actions** | Executes CI pipelines and Staging deploy |
| **Ship** | Observes execution, emits Ship.Started and Ship.Completed, reacts to failures |
| **Validate** | Validates the Feature running in the Staging environment |
| **Promote** | Promotes the Feature from Staging to Sandbox after Ship.Completed |

## Stages

### Ship

Observes and orchestrates the autonomous PR flow created by Finish — checks, approval, merge, and Staging deploy.

**Ship does NOT perform deploy. Ship does NOT execute CI. Ship does NOT approve the PR.**

Ship.Completed is emitted only after merge is confirmed AND Staging deploy completes successfully.

→ [phases/ship/README.md](phases/ship/README.md)

### Validate

Verifies the Feature running in the Staging environment.

Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals.

→ [phases/validate/README.md](phases/validate/README.md)

### Promote

Promotes the Feature from the Staging environment to the Sandbox environment (Release Candidate). Starts only after Ship.Completed.

**Promote does NOT publish to Production. Production is outside the Delivery Journey.**

Capabilities: Promotion Gates, Environment Promotion (Staging → Sandbox), Release Trail, Rollback Readiness.

→ [phases/promote/README.md](phases/promote/README.md)

## Capabilities used

| Capability | Stage |
|---|---|
| [Evidence Management](capabilities/evidence-management.md) | Validate, Promote |
| [Observability](capabilities/observability.md) | Validate |
| [Reliability](capabilities/reliability.md) | Promote |
| [Contract Management](capabilities/contract-management.md) | Validate |

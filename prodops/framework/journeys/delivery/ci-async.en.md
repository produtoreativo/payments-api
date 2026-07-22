# CI Async

CI Async is the asynchronous grouping of ProdOps Delivery. It represents work **driven by the platform, pipelines, and environments**.

```
CI Async: Ship → Validate → Promote
```

## Purpose

CI Async produces:
- Artifact produced and published
- Deploy performed in the target environment
- Runtime validation executed
- Controlled promotion with recorded evidence

## Stages

### Ship

Transforms the implementation into an executable artifact and conducts the deploy.

Two families:
- **Preparation:** Build, Package, Version, Sign, SBOM, Publish Artifact
- **Deployment:** Deploy, Progressive Delivery, Feature Flags, Rollout, Rollback, Infrastructure Validation

Build, Package, and Publish are internal capabilities of Ship — they are not independent stages.

→ [phases/ship/README.md](phases/ship/README.md)

### Validate

Verifies the delivery running in the target environment.

Capabilities: Smoke Tests, Runtime Contract Validation, Synthetic Monitoring, Health Checks, Observability Validation, SLO Validation, Business Validation, Incident Signals.

→ [phases/validate/README.md](phases/validate/README.md)

### Promote

Officially records the version's evolution with formal approval and registered evidence.

Capabilities: Promotion Gates, Environment Promotion, Release Approval, Release Trail, Operational Evidence, Release Documentation, Rollback Readiness.

→ [phases/promote/README.md](phases/promote/README.md)

## Capabilities used

| Capability | Stage |
|---|---|
| [Evidence Management](capabilities/evidence-management.md) | Validate, Promote |
| [Observability](capabilities/observability.md) | Validate |
| [Reliability](capabilities/reliability.md) | Promote |
| [Contract Management](capabilities/contract-management.md) | Validate |

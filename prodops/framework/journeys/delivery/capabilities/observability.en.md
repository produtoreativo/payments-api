# Capability — Observability

## Objective

Ensure that system behavior is visible in production: structured logs, business metrics, traceability, and health checks.

## Responsibilities

- Emit business events with mandatory dimensions (tenantId, correlationId, orderId)
- Ensure no secret or PII appears in logs
- Validate traceability post-deploy (correlationId propagated, expected logs emitted)
- Verify health checks and SLOs in the target environment

## Consuming flows

| Flow | Moment of use |
|---|---|
| Hack | Step 5 — Validate observability (after Green Bar) |
| Validate | Observability Validation, SLO Validation, Incident Signals |
| Promote | Operational Evidence |

## Produced artifacts

- Structured logs with mandatory fields
- Business metrics in `src/observability/metrics.ts`
- Health check at `/health`
- Observability evidence in the Release Trail

## Canonical documentation

→ [prodops/framework/journeys/delivery/capabilities/observability-policy.md](observability-policy.md)

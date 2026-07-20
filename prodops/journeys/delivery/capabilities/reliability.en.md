# Capability — Reliability

## Objective

Define and verify reliability requirements before, during, and after implementation: timeouts, retries, idempotency, controlled degradation.

## Responsibilities

- Document reliability requirements in the OBC before implementation
- Verify during Hack that the requirements are implemented
- Record risks in the Reliability Plan
- Validate SLOs in the staging environment before promotion

## Consuming flows

| Flow | Moment of use |
|---|---|
| Bootstrap | Read risks and reliability requirements from the OBC |
| Hack | Implement timeout, retry, idempotency, exceptions |
| Finish | Definition of Done — reliability items |
| Promote | Rollback Readiness, formally accepted risks |

## Produced artifacts

- Risks documented in `prodops/journeys/assessment/risks.md`
- OBC with SLIs and Reliability Rules in `prodops/artifacts/business/obcs/`
- Reliability Plan entry in `prodops/journeys/assessment/reliability-plans/`

## Canonical documentation

→ [prodops/journeys/delivery/capabilities/reliability-policy.md](reliability-policy.md)
→ [prodops/journeys/assessment/risks.md](../../assessment/risks.md)

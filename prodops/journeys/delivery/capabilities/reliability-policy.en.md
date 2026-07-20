# Reliability Policy

Reliability is planned before implementation and validated before promotion.

## Reliability Plan

A Reliability Plan is **recommended** for every Downstream capability, but is not mandatory. It is strongly recommended for items with relevant operational risk (high complexity, financial impact, new integrations). When it exists, the plan defines:
- Risks and mitigations
- OBCs (Observable Business Contracts) with measurable success thresholds
- SLO suggestions for events on the critical path

The Reliability Plan is located at: `prodops/journeys/assessment/reliability-plans/`

## OBCs

An OBC anchors the implementation to a business outcome. It defines what "done" means in observable and measurable terms. OBCs must exist before any code is written for a Downstream item.

OBC files: `prodops/artifacts/business/obcs/`

## Definition of Done

A capability is not complete until the [Definition of Done](../../../templates/engineering/definition-of-done.en.md) is satisfied, including the reliability criteria.

## Failure modes

Known failure modes must be documented in the Reliability Plan (`risks.md`) before the capability goes to production. For each failure mode:
- Define the triggering condition.
- Define the expected system behavior (controlled degradation, error response, retry).
- Define the observable signal (log entry, metric, alert).

## Reliability requirements per behavior

For each behavior implemented in the Hack Flow, verify the following requirements during the Green Bar:

| Requirement | Description |
|---|---|
| **Timeout** | External provider calls have a configured timeout. No indefinite timeout. |
| **Retry** | Retries use the same `Idempotency-Key`. Retry without idempotency creates duplicates. |
| **Idempotency** | The same operation executed twice returns the same state, without additional side effects. |
| **Exception handling** | Provider errors are caught and transformed into an HTTP response with a meaningful `message`. |
| **Consistent messages** | Error messages are stable (do not change on retry). Facilitates diagnosis in support. |
| **HTTP codes** | Status codes match semantics: 201 (created), 400 (invalid input), 404 (not found), 409 (conflict/invalid state), 422 (business rule). |
| **Controlled degradation** | External dependency failure (provider, SQS, DynamoDB) does not bring down independent flows. |

These requirements are verified in the [Definition of Done](../../../templates/engineering/definition-of-done.en.md) — Reliability section.

For details on how to apply during the TDD cycle: [ProdOps TDD — Reliability in the cycle](../practices/prodops-tdd.en.md).

## Post-deploy validation

After deploy, validate the reliability criteria defined in the OBC. Record evidence in the active session trail at `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md` and in `prodops/journeys/operation/operational-trail.md`.

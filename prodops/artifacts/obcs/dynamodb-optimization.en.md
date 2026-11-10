# OBC - DynamoDB Persistence Optimized for Production

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-49 |
| Iteration | v0.9.0 |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-49 (#45) — v0.9.0, PR #121. Previous record: Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` — operational capability derived from EXP-011.
**Pending:** iteration completed (PR #121); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-004](../business-signals/BS-004.md) |
| Business Intent | [PI-011](../business-intents/PI-011.md) |
| Product Tracking Item | issue #45 (DS-49), see `prodops/artifacts/plans/iteration-plan.md` |
| Experiment | [EXP-011](../experiments/011-dynamodb-optimization/experiment.md) |

## Business Outcome

The Payments API production DynamoDB tables operate without throttling risk and with point-in-time recovery enabled. No payment fails due to database throttling and no payment data is unrecoverable due to absence of continuous backup. Pay-per-request billing eliminates wasted allocated capacity that is never consumed.

### In executive language

Previously, the Payments API used a database model with fixed contracted capacity: if 3 or more writes per second arrived, the database would refuse requests — like a phone line that blocks calls when busy. Now, the database scales automatically with demand, without a fixed limit and without charging for unused capacity.

Additionally, any payment data can be restored to any point within the last 35 days — equivalent to a database "Ctrl+Z" for operational errors or data corruption situations.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/dynamodb-optimization.feature`; tick after verification.

- [ ] Tabelas operam com billing PAY_PER_REQUEST
- [ ] PITR esta habilitado em todas as tabelas criticas
- [ ] GSIs sem uso foram removidos
- [ ] TransactionsTable nao possui GSIs desnecessarios
- [ ] ProvidersTable nao existe no stack de producao
- [ ] Escrita em alta carga nao gera throttling

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | n/a — platform/framework capability, not a Product Service |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `dynamodb.throttle` | [to be determined] | Request throttled by DynamoDB — must not occur with PAY_PER_REQUEST. | `table`, `operation`, `env` |
| `dynamodb.pitr.enabled` | [to be determined] | PITR enabled on table — confirmed via `describe-continuous-backups`. | `table`, `env` |
| `dynamodb.billing_mode` | [to be determined] | Billing mode confirmed as PAY_PER_REQUEST. | `table`, `env` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| DynamoDB throttling events in production in 30 days. | 0 | [to be determined] |
| Tables with PITR enabled (all 5 critical tables). | 100% | [to be determined] |
| Tables with PAY_PER_REQUEST billing. | 100% | [to be determined] |
| GSIs without documented queries removed. | 100% (GSI2 PaymentsTable, GSI1 TransactionsTable removed) | [to be determined] |

## Reliability Rules

- No table should operate with `BillingMode: PROVISIONED` without Auto Scaling — throttling at ≥2 writes/s is a critical risk for any real payment load.
- PITR must be enabled on all tables persisting payment data: PaymentsTable, TransactionsTable, CustomersTable, TenantsTable, WebhooksTable.
- GSIs should only exist when there is a documented query that uses them. Unused GSIs incur WCU cost on every write.
- ProvidersTable was removed — no table without an active repository should exist in the production stack.
- DynamoDB schema changes (adding/removing GSIs, billing changes) must be made via `api/infra/dynamodb.yaml` and deployed via CI/CD — never via the AWS console.

## Response Contract

Not applicable — persistence infrastructure change without API contract modification.

## Risks

| Risk | Severity | Handling |
|---|---|---|
| [to be determined] | [to be determined] | see `prodops/artifacts/risks/risks.md` |

## Dependencies

| Type | Dependency | Note |
|---|---|---|
| — | [to be determined] | [to be determined] |

## Decisions

| Date | Decision | Rationale | Source |
|---|---|---|---|
| 2026-11-10 | Migration to the `local-obc.en.md` template: sections added, Status normalized, events classified by Status and SLIs with Source. | Template adherence and the rule that the event name is the one emitted in the code. Fields without a source marked `[to be determined]`. | `obc` skill (`fix` mode); `check-obc.sh` |

## Related Artifacts

- BDD: `prodops/artifacts/bdd/dynamodb-optimization.feature`
- Experiment: `prodops/artifacts/experiments/011-dynamodb-optimization/experiment.md`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Related OBCs: `prodops/artifacts/obcs/production-cicd-pipeline.md`

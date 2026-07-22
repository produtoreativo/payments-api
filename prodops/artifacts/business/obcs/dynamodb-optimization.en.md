# OBC - DynamoDB Persistence Optimized for Production

## Status

Downstream. Status `Entrou` in `prodops/artifacts/governance/plans/iteration-plan.md` — operational capability derived from EXP-011.

## Business Outcome

The Payments API production DynamoDB tables operate without throttling risk and with point-in-time recovery enabled. No payment fails due to database throttling and no payment data is unrecoverable due to absence of continuous backup. Pay-per-request billing eliminates wasted allocated capacity that is never consumed.

### In executive language

Previously, the Payments API used a database model with fixed contracted capacity: if 3 or more writes per second arrived, the database would refuse requests — like a phone line that blocks calls when busy. Now, the database scales automatically with demand, without a fixed limit and without charging for unused capacity.

Additionally, any payment data can be restored to any point within the last 35 days — equivalent to a database "Ctrl+Z" for operational errors or data corruption situations.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `dynamodb.throttle` | Request throttled by DynamoDB — must not occur with PAY_PER_REQUEST. | `table`, `operation`, `env` |
| `dynamodb.pitr.enabled` | PITR enabled on table — confirmed via `describe-continuous-backups`. | `table`, `env` |
| `dynamodb.billing_mode` | Billing mode confirmed as PAY_PER_REQUEST. | `table`, `env` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| DynamoDB throttling events in production in 30 days. | 0 |
| Tables with PITR enabled (all 5 critical tables). | 100% |
| Tables with PAY_PER_REQUEST billing. | 100% |
| GSIs without documented queries removed. | 100% (GSI2 PaymentsTable, GSI1 TransactionsTable removed) |

## Reliability Rules

- No table should operate with `BillingMode: PROVISIONED` without Auto Scaling — throttling at ≥2 writes/s is a critical risk for any real payment load.
- PITR must be enabled on all tables persisting payment data: PaymentsTable, TransactionsTable, CustomersTable, TenantsTable, WebhooksTable.
- GSIs should only exist when there is a documented query that uses them. Unused GSIs incur WCU cost on every write.
- ProvidersTable was removed — no table without an active repository should exist in the production stack.
- DynamoDB schema changes (adding/removing GSIs, billing changes) must be made via `api/infra/dynamodb.yaml` and deployed via CI/CD — never via the AWS console.

## Response Contract

Not applicable — persistence infrastructure change without API contract modification.

## Related Artifacts

- BDD: `prodops/artifacts/business/bdd/dynamodb-optimization.feature`
- Experiment: `prodops/journeys/discovery/experiments/011-dynamodb-optimization/experiment.md`
- Iteration Plan: `prodops/artifacts/governance/plans/iteration-plan.md`
- Related OBCs: `prodops/artifacts/business/obcs/production-cicd-pipeline.md`

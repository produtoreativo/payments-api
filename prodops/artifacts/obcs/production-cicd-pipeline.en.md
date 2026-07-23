# OBC - Production CI/CD Pipeline with Approval Gate

## Status

Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` — operational capability derived from EXP-012.

## Business Outcome

Every production deploy of the Payments API requires explicit human approval from a designated reviewer and leaves an auditable trail in GitHub Actions with the approver's name, timestamp, commit, and deploy reason. There is no production deploy path that bypasses this gate. The time between an approved commit and the updated production environment is measurable and controlled.

### In executive language

Previously, production was updated manually via terminal: anyone with AWS credentials could deploy without approval, without record, and without automatic rollback. Now, deploying to production is like signing a high-value check — it requires a second signature, is recorded, and the system refuses any bypass attempt.

## Observable Events

| Event | Meaning | Required dimensions |
|---|---|---|
| `cicd.deploy.requested` | Production workflow triggered — awaiting Required Reviewer approval. | `actor`, `commit_sha`, `branch`, `reason` |
| `cicd.deploy.approved` | Deploy approved by Required Reviewer and started. | `approver`, `actor`, `commit_sha`, `timestamp` |
| `cicd.deploy.completed` | Production deploy completed successfully — smoke tests passed. | `commit_sha`, `api_url`, `stack_name`, `duration_seconds` |
| `cicd.deploy.smoke_passed` | Post-deploy smoke tests validated API is responding and auth guard is active. | `api_url`, `http_status` |

## Initial SLIs

| SLI | Initial target |
|---|---|
| Production deploys that passed through Required Reviewer gate. | 100% |
| Production deploys with auditable trail (approver + commit + reason). | 100% |
| Post-deploy smoke tests passing before marking deploy complete. | 100% |
| Production secrets stored in GitHub Environment — never in samconfig.toml or code. | 100% |
| Accidental deploys via branch push (without workflow_dispatch). | 0 |

## Reliability Rules

- The `deploy-production.yml` workflow can only be triggered via `workflow_dispatch` — never by automatic push on any branch.
- The deploy job is blocked until explicit approval from the Required Reviewer configured in the GitHub Environment `production`.
- `cancel-in-progress: false` — in-progress deploys are never cancelled by a new trigger.
- All non-secret parameters (EnvironmentName, DatadogEnabled, etc.) must be passed explicitly via `sam deploy` CLI — do not rely on `samconfig.toml` automatic merge (SAM CLI replaces, does not merge, `--parameter-overrides`).
- Secrets (`AsaasToken`, `AdminSecret`, `DatadogApiKey`) are injected only via GitHub Environment secrets — never stored in `samconfig.toml`.
- The smoke test validates that the auth guard returns 401 before marking the deploy complete.
- The OIDC role `payments-api-github-deploy` is defined in `api/infra/iam-deploy-role.yaml` — any permission change goes through a PR and CloudFormation deploy.

## Related Artifacts

- BDD: `prodops/artifacts/bdd/production-cicd-pipeline.feature`
- Experiment: `prodops/artifacts/experiments/012-production-cicd-pipeline/experiment.md`
- IaC: `api/infra/iam-deploy-role.yaml`, `.github/workflows/deploy-production.yml`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Related OBCs: `prodops/artifacts/obcs/observability-datadog.md`, `prodops/artifacts/obcs/dynamodb-optimization.md`

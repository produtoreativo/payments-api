# OBC - Production CI/CD Pipeline with Approval Gate

## Metadata

| Field | Value |
|---|---|
| Owner | [to be determined] |
| DS-ID | DS-48 |
| Iteration | v0.9.0 |
| Last updated | 2026-11-10 |

## Status

**State:** In Delivery
**Tracked in:** DS-48 (#46) — v0.9.0, PR #120. Previous record: Downstream. Status `Entrou` in `prodops/artifacts/plans/iteration-plan.md` — operational capability derived from EXP-012.
**Pending:** iteration completed (PR #120); candidate for `Operational` — confirm production rollout before promoting. Source: `prodops/artifacts/plans/iteration-plan.md`.

## Origin

| Link | Reference |
|---|---|
| Business Signal | [BS-004](../business-signals/BS-004.md) |
| Business Intent | [PI-012](../business-intents/PI-012.md) |
| Product Tracking Item | issue #46 (DS-48), see `prodops/artifacts/plans/iteration-plan.md` |
| Experiment | [EXP-012](../experiments/012-production-cicd-pipeline/experiment.md) |

## Business Outcome

Every production deploy of the Payments API requires explicit human approval from a designated reviewer and leaves an auditable trail in GitHub Actions with the approver's name, timestamp, commit, and deploy reason. There is no production deploy path that bypasses this gate. The time between an approved commit and the updated production environment is measurable and controlled.

### In executive language

Previously, production was updated manually via terminal: anyone with AWS credentials could deploy without approval, without record, and without automatic rollback. Now, deploying to production is like signing a high-value check — it requires a second signature, is recorded, and the system refuses any bypass attempt.

## Scope

**In scope**

- [to be determined]

**Out of scope**

- [to be determined]

## Business Rules

- [to be determined]

## Acceptance Criteria

Derived from the scenarios in `prodops/artifacts/bdd/production-cicd-pipeline.feature`; tick after verification.

- [ ] Deploy em producao requer aprovacao do Required Reviewer
- [ ] Deploy nao e acionado por push automatico
- [ ] Deploy aprovado conclui com smoke tests passando
- [ ] Secrets de producao nunca aparecem no samconfig.toml
- [ ] Dois deploys simultaneos nao sao permitidos
- [ ] Mudanca na role IAM exige PR e deploy CloudFormation

## Enterprise Context

| Item | Content |
|---|---|
| Value Stream / Product Service | n/a — platform/framework capability, not a Product Service |
| Stakeholders | [to be determined] |
| Compliance | [to be determined] |

## Observable Events

| Event | Status | Meaning | Required dimensions |
|---|---|---|---|
| `cicd.deploy.requested` | [to be determined] | Production workflow triggered — awaiting Required Reviewer approval. | `actor`, `commit_sha`, `branch`, `reason` |
| `cicd.deploy.approved` | [to be determined] | Deploy approved by Required Reviewer and started. | `approver`, `actor`, `commit_sha`, `timestamp` |
| `cicd.deploy.completed` | [to be determined] | Production deploy completed successfully — smoke tests passed. | `commit_sha`, `api_url`, `stack_name`, `duration_seconds` |
| `cicd.deploy.smoke_passed` | [to be determined] | Post-deploy smoke tests validated API is responding and auth guard is active. | `api_url`, `http_status` |

## Initial SLIs

| SLI | Initial target | Source |
|---|---|---|
| Production deploys that passed through Required Reviewer gate. | 100% | [to be determined] |
| Production deploys with auditable trail (approver + commit + reason). | 100% | [to be determined] |
| Post-deploy smoke tests passing before marking deploy complete. | 100% | [to be determined] |
| Production secrets stored in GitHub Environment — never in samconfig.toml or code. | 100% | [to be determined] |
| Accidental deploys via branch push (without workflow_dispatch). | 0 | [to be determined] |

## Reliability Rules

- The `deploy-production.yml` workflow can only be triggered via `workflow_dispatch` — never by automatic push on any branch.
- The deploy job is blocked until explicit approval from the Required Reviewer configured in the GitHub Environment `production`.
- `cancel-in-progress: false` — in-progress deploys are never cancelled by a new trigger.
- All non-secret parameters (EnvironmentName, DatadogEnabled, etc.) must be passed explicitly via `sam deploy` CLI — do not rely on `samconfig.toml` automatic merge (SAM CLI replaces, does not merge, `--parameter-overrides`).
- Secrets (`AsaasToken`, `AdminSecret`, `DatadogApiKey`) are injected only via GitHub Environment secrets — never stored in `samconfig.toml`.
- The smoke test validates that the auth guard returns 401 before marking the deploy complete.
- The OIDC role `payments-api-github-deploy` is defined in `api/infra/iam-deploy-role.yaml` — any permission change goes through a PR and CloudFormation deploy.

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

- BDD: `prodops/artifacts/bdd/production-cicd-pipeline.feature`
- Experiment: `prodops/artifacts/experiments/012-production-cicd-pipeline/experiment.md`
- IaC: `api/infra/iam-deploy-role.yaml`, `.github/workflows/deploy-production.yml`
- Iteration Plan: `prodops/artifacts/plans/iteration-plan.md`
- Related OBCs: `prodops/artifacts/obcs/observability-datadog.md`, `prodops/artifacts/obcs/dynamodb-optimization.md`

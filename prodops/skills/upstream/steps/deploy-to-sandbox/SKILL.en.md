---
name: upstream/deploy-to-sandbox
description: Deploy an experiment branch to a real AWS sandbox environment without downstream rigor. Use when an experiment needs to validate behavior against a real provider (e.g., Asaas sandbox) that cannot be exercised locally.
---

# UPSTREAM / DEPLOY TO SANDBOX

Use this step to deploy an experiment to real AWS infrastructure for Upstream validation.

No OBC commitment, no Release Trail, no downstream gates — the goal is learning.

## When to Use

- The experiment hypothesis requires a real provider response (Asaas sandbox, webhooks, payment lifecycle)
- LocalStack or mock mode is insufficient to answer the experiment question
- The team needs an accessible URL to demonstrate or validate behavior with real data

## Pre-conditions

Before running this step, confirm:

- [ ] Experiment is registered in `prodops/artifacts/experiments/`
- [ ] Experiment branch exists in the repository
- [ ] GitHub Environment `experiment` exists with the three secrets below
- [ ] IAM role `payments-api-github-experiment` exists in AWS (deploy `api/infra/iam-experiment-role.yaml` once)

## Required Setup (one-time, per repository)

### 1. GitHub Environment

Create a GitHub Environment named `experiment`:

- No required reviewers (intentional — bypass the approval gate)
- Secrets:
  - `EXPERIMENT_ASAAS_TOKEN` — Asaas sandbox API key
  - `EXPERIMENT_ASAAS_WEBHOOK_TOKEN` — Asaas sandbox webhook token
  - `EXPERIMENT_ADMIN_SECRET` — admin secret for `/admin/tokens`

### 2. IAM Role

Deploy the CloudFormation template once:

```bash
aws cloudformation deploy \
  --template-file api/infra/iam-experiment-role.yaml \
  --stack-name payments-api-iam-experiment-role \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides GitHubOrg=<org> GitHubRepo=<repo>
```

This creates `payments-api-github-experiment` — scoped to `experiment-*` resources only. It cannot touch staging or production stacks.

## How to Deploy

Trigger `.github/workflows/experiment-deploy.yml` via `workflow_dispatch`:

| Input | Value |
|---|---|
| `branch` | experiment branch name |
| `experiment_id` | e.g., `EXP-007` |
| `action` | `deploy` |

The workflow runs: `quick-check → deploy-experiment`.

`quick-check` is lint + build only — no acceptance tests. The gate is intentionally lighter than staging.

## What Gets Deployed

All AWS resources are prefixed `experiment-*`:

| Resource | Name |
|---|---|
| CloudFormation (Lambda) | `payments-api-experiment` |
| CloudFormation (DynamoDB) | `payments-api-dynamo-experiment` |
| DynamoDB tables | `experiment-TransactionsTable`, `experiment-TenantsTable`, etc. |
| Lambda function | `payments-api-experiment-*` |
| SQS queues | `experiment-*` |

Isolated from `staging-*` and `production-*` — different prefix, different tables.

## After Deploy

The Job Summary shows the API URL and Webhook URL. Register the URL in the experiment trail:

```markdown
## Sandbox Deploy Record

| Field | Value |
|---|---|
| Deploy date | YYYY-MM-DD |
| Branch | branch-name |
| API URL | https://... |
| Triggered by | name |
```

## Teardown Obligation

The experiment stack **must be torn down** when the experiment concludes.

Trigger `.github/workflows/experiment-deploy.yml` with `action=teardown`. Both CloudFormation stacks will be deleted.

Do not leave experiment stacks running after the experiment ends. They accumulate cost and are not monitored by any operational SLO.

## What This Is Not

- This is not a staging environment.
- This is not a release gate.
- Evidence collected here is Upstream evidence — it does not substitute Downstream validation.
- This does not advance work in the Release Trail.

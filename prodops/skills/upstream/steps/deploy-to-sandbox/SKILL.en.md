---
name: upstream/deploy-to-sandbox
description: Deploy an experiment branch to a real cloud sandbox environment without downstream rigor. Use when an experiment needs to validate behavior against a real external provider that cannot be exercised locally.
---

# UPSTREAM / DEPLOY TO SANDBOX

Use this step to deploy an experiment to real cloud infrastructure for Upstream validation.

No OBC commitment, no Release Trail, no downstream gates — the goal is learning.

## When to Use

- The experiment hypothesis requires a real provider response (e.g., external payment provider, webhooks, data lifecycle)
- Local simulation or mock mode is insufficient to answer the experiment question
- The team needs an accessible URL to demonstrate or validate behavior with real data

## Pre-conditions

Before running this step, confirm:

- [ ] Experiment is registered in `prodops/artifacts/experiments/`
- [ ] Experiment branch exists in the repository
- [ ] GitHub Environment `experiment` exists with the required secrets (see product setup)
- [ ] IAM role or equivalent cloud identity for experiment deployment exists (see product infrastructure)

## Required Setup (one-time, per product — defined in product local area)

### 1. GitHub Environment

Create a GitHub Environment named `experiment`:

- No required reviewers (intentional — bypass the approval gate)
- Secrets: defined by the product (provider API keys, webhook tokens, admin secrets)
- See: `prodops/skills/local/` for product-specific setup instructions

### 2. Cloud Identity

Deploy the cloud identity template once (product-defined):

```bash
# Product-specific command — see product local skills or infra scripts
```

This creates an identity scoped to `experiment-*` resources only. It must not touch staging or production stacks.

## How to Deploy

Trigger the experiment workflow via `workflow_dispatch` (product-defined workflow):

| Input | Value |
|---|---|
| `branch` | experiment branch name |
| `experiment_id` | e.g., `EXP-007` |
| `action` | `deploy` |

The workflow runs a quick-check (lint + build only — no acceptance tests). The gate is intentionally lighter than staging.

## What Gets Deployed

All cloud resources are prefixed `experiment-*`, isolated from `staging-*` and `production-*`:

- Compute (Lambda, container, or equivalent)
- Datastore (database tables, queues)
- Event infrastructure

Isolation ensures experiment resources cannot affect staging or production.

## After Deploy

Record the sandbox deployment in the experiment trail:

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

Trigger the experiment workflow with `action=teardown`. All experiment resources will be deleted.

Do not leave experiment stacks running after the experiment ends. They accumulate cost and are not monitored by any operational SLO.

## What This Is Not

- This is not a staging environment.
- This is not a release gate.
- Evidence collected here is Upstream evidence — it does not substitute Downstream validation.
- This does not advance work in the Release Trail.

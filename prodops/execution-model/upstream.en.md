# Upstream Mode

Upstream is the **exploration mode** of the ProdOps Framework.

## Canonical definition

Upstream represents an exploration mode. Its goal is to reduce uncertainty before assuming any delivery commitment. Upstream does not represent a promise — it represents a space for learning. All work done in Upstream is considered experimental.

## Purpose

Produce knowledge. Not committed software.

## Mode characteristics

In Upstream:

- no mandatory gates
- no obligation to complete artifacts
- no obligation to produce a Committed OBC
- no obligation to follow all Skills
- the engineer decides which Skills to use
- vibecoding is allowed
- experimentation is encouraged
- failing is part of the process

The goal is to learn as fast as possible.

An Upstream experiment can produce production-quality code, but that code is considered exploratory until the capability is promoted to Downstream.

## OBC in Upstream

When a Business Intent enters the Business Intent Backlog, an OBC is created as a Draft.

During Upstream:

- the OBC remains in Draft
- can be continuously updated
- can remain incomplete
- does not block the progress of experiments

The OBC works as memory of learning — not as a validation mechanism.

## When to use Upstream mode

- Hypothesis to validate, high uncertainty
- Explore a new capability
- Prototype integration with a provider
- Validate a business flow before committing
- Explore a technical approach before deciding

## How to execute in Upstream mode

→ [Discovery Journey](../journeys/discovery/README.md)

The Discovery journey documents the complete exploration workflow, experiments, Decision Package review, and the promotion process to Downstream.

## Upstream closure

At the end of Upstream, four outcomes are possible:

1. **Discard** the Business Intent — sufficient learning, but not worth advancing.
2. **Archive** for future use — learning recorded, decision deferred.
3. **Return** to the Business Intent Backlog — waiting for a business decision or external dependency.
4. **Promote** to Downstream — explicit Product Owner decision, with complete Decision Package.

Promotion to Downstream must be an explicit decision. There is no automatic transition.

## Expected outcome

At the end of an Upstream cycle, the following should exist:

- Hypothesis answered with evidence
- Complete Decision Package
- Clear recommendation (promote, requires another experiment, wait, discard)
- Updated ProdOps artifacts

## Sandbox Deploy (Upstream)

An experiment can be deployed to real AWS without going through the rigor of Downstream.

Objective: validate behavior against a real provider (e.g.: Asaas sandbox) when the local environment is not sufficient.

**Characteristics:**

- Activated manually via `workflow_dispatch` — never on push
- Ephemeral stack: `payments-api-experiment` + `payments-api-dynamo-experiment`
- AWS resources prefixed `experiment-*` — isolated from staging and production
- Dedicated IAM role `payments-api-github-experiment` — scope restricted to `experiment-*`
- No approval gate, no Release Trail, no committed OBC
- **Required:** stack destroyed at the end of the experiment via `action=teardown`

→ [Step: deploy-to-sandbox](../skills/upstream/steps/deploy-to-sandbox/SKILL.md)
→ [Workflow: experiment-deploy.yml](../../.github/workflows/experiment-deploy.yml)
→ [IAM Role: iam-experiment-role.yaml](../../api/infra/iam-experiment-role.yaml)

## Promotion to Downstream

A capability promoted from Upstream to Downstream must have:

1. BDD Feature moved from `prodops/journeys/discovery/experiments/<NNN-slug>/features/` to `prodops/artifacts/business/bdd/`
2. OBC moved from `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` to `prodops/artifacts/business/obcs/`
3. Entry in the Iteration Plan in `prodops/artifacts/governance/plans/iteration-plan.md`
4. Reliability Plan updated in `prodops/journeys/assessment/reliability-plans/`

→ [Full promotion process](../journeys/discovery/README.md#processo-de-promoção-para-downstream)

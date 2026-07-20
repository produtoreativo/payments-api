# Global Upstream Trail

## Purpose

The Global Upstream Trail records high-level milestones of exploratory engineering activities.

Each experiment has its execution history in
`prodops/journeys/discovery/experiments/NNN-short-slug/upstream-trail.md`.

This global file exists to help future contributors see the Upstream evolution of the repository without needing to read each experiment trail.

---

# Entry template

## YYYY-MM-DD HH:MM

### Experiment

Reference:

`prodops/journeys/discovery/experiments/NNN-short-slug/experiment.md`

### Activity

Describe what happened.

Examples:

- Experiment started
- Prototype updated
- Proof of concept implemented
- Validation Workbench updated
- Provider documentation reviewed
- Reliability Plan updated
- Experiment completed
- Experiment structure migrated
- Experiment promoted to Downstream

### Summary

One or two paragraphs summarizing the work done.

### Artifacts Updated

List only the artifacts updated during this activity.

Example:

- Validation Workbench
- Reliability Plan
- Repository Tracking List
- OBC
- BDD Feature

### Decision

Choose one option:

- Continue experiment
- Start another experiment
- Ready for Assessment
- Discard experiment
- Advance to Downstream
- Global process change

### Notes

Additional observations, blockers or follow-up actions.

---

# History

> Append new entries below.
> Never rewrite previous entries.

## 2026-07-07 — EXP-007

### Experiment

Reference:

`prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`

### Activity

Complete execution of the Upstream activity (exploratory mode) for the Intent "Multiple Payment Support in Checkout".

### Summary

All 10 open questions from the Intent were answered. The current domain model (1:1:1 — 1 order : 1 invoice : 1 method) was analyzed and compared with composition alternatives. Benchmark of Stripe, Adyen, MercadoPago and Asaas confirmed that the Payments API needs to absorb the composition orchestration, as Asaas has no native support for multiple methods per order.

Option A (multiple invoices per order with a new `PaymentComposition` entity) was selected because it is additive to the current model and does not break simple payments. Event Storming of the new flow identified 7 new domain events. A candidate OBC was created. The only pending product decision is the partial failure policy (A: revert all / B: keep confirmed / C: partial window) — Policy B is recommended.

### Artifacts Updated

- `prodops/journeys/discovery/experiments/007-split-payment-model/experiment.md`
- `prodops/journeys/discovery/experiments/007-split-payment-model/upstream-trail.md`
- `prodops/artifacts/business/obcs/payment-composition-draft.md`
- `prodops/journeys/discovery/upstream-trail.md`

### Decision

Ready for Assessment — awaiting product decision on partial failure policy.

### Notes

Next steps after product decision: create BDD Feature `prodops/artifacts/business/bdd/payment-composition.feature`, update Iteration Plan, Bootstrap → Hack.

## 2026-07-03 18:04

### Experiment

Reference:

`prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`

### Activity

Migration of existing experiments to the per-experiment directory pattern.

### Summary

Flat files for experiments EXP-001, EXP-002, EXP-003 and EXP-005 were moved into `experiment.md` inside their own experiment directories. Each now has a local `upstream-trail.md` and an `evidence/` directory.

EXP-004 was recovered as a reference record because the global trail, Reliability Plan and Repository Tracking List referenced it, but the original flat experiment file was not present in the workspace.

### Artifacts Updated

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/001-credit-card-lifecycle/upstream-trail.md`
- `prodops/upstream/experiments/002-sandbox-funding/experiment.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/upstream-trail.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/upstream-trail.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/upstream-trail.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/upstream-trail.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/journeys/discovery/features/README.md` (removed: directory consolidated into `prodops/artifacts/business/bdd/`)

### Decision

Ready for Assessment.

### Notes

The historical reference to `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removed: no successor in `prodops/artifacts/business/bdd/`) remains a gap: the file is referenced by trail entries but is not present in the workspace.

## 2026-07-03 17:58

### Experiment

Reference:

`prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`

### Activity

Change of the Upstream trail pattern to one trail per experiment.

### Summary

Upstream experiments now have a canonical directory layout: `experiment.md`, `upstream-trail.md` and optional `evidence/`. The experiment's local trail is the primary chronological execution record.

The global `prodops/upstream/upstream-trail.md` remains only as a high-level chronological index for cross-experiment milestones, migrations, promotions and repository-level Upstream process changes.

### Artifacts Updated

- `AGENTS.md`
- `skills/upstream/SKILL.md`
- `prodops/upstream/README.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/experiments/README.md`
- `prodops/templates/discovery/experiment.md`
- `prodops/templates/discovery/trail.md`
- `prodops/upstream/experiments/006-upstream-trail-per-experiment/experiment.md`
- `prodops/upstream/experiments/006-upstream-trail-per-experiment/upstream-trail.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Ready for Assessment.

### Notes

Existing flat experiment files were migrated. New experiments should use `prodops/journeys/discovery/experiments/NNN-short-slug/`.

## 2026-07-03 17:50

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Conversion of Asaas webhook handling to an asynchronous serverless queue path.

### Summary

The AWS/SAM template now provisions `payments-webhook-queue` and `payments-webhook-dlq`. The HTTP Lambda Function URL acts as a receiver: it validates the Asaas token, enqueues the webhook message and returns HTTP 200 quickly. A dedicated `webhook-worker` Lambda consumes SQS messages and executes the existing payment confirmation domain logic.

The local simulation now validates the end-to-end shape by creating an invoice through the API, extracting `providerPaymentId` and `externalReference` from the response and sending `PAYMENT_CONFIRMED` with those values, polling DynamoDB LocalStack until the invoice is confirmed. Local NestJS debug mode remains available with `WEBHOOK_PROCESSING_MODE=sync`; SAM/LocalStack deploy uses async mode.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/src/webhook-worker.ts`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/src/modules/invoices/services/asaas-webhook-queue.service.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/src/modules/invoices/invoices.module.ts`
- `api/scripts/deploy.sh`
- `api/scripts/start-sandbox-api.sh`
- `api/scripts/start-localstack-api.sh`
- `api/scripts/simulate-asaas-webhook.sh`
- `api/.env.example`
- `README.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Continue experiment.

### Notes

Validation evidence: shell syntax checks passed for the updated scripts, and `sam validate --lint` passed for `api/infra/lambda.yaml` and `api/infra/dynamodb.yaml`. Node/npm were not available in this shell, so the NestJS build and LocalStack execution were not run here.

## 2026-07-03 17:45

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Configuration of local validation to use LocalStack DynamoDB instead of in-memory storage.

### Summary

The local AWS path now has an explicit runtime script, `api/scripts/start-localstack-api.sh`, which starts the NestJS API with `INVOICE_REPOSITORY=dynamo`, `DYNAMO_MOCK=false` and `AWS_DYNAMODB_ENDPOINT=http://localhost.localstack.cloud:4566`.

The Asaas webhook simulation now creates an invoice through the API first, extracts `providerPaymentId` and `externalReference` from the response, and then sends `PAYMENT_CONFIRMED` with those values. This validates the same DynamoDB correlation structure used by the webhook handler instead of relying on memory state or hardcoded provider IDs.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/scripts/build.sh`
- `api/scripts/deploy.sh`
- `api/scripts/start-localstack-api.sh`
- `api/scripts/simulate-asaas-webhook.sh`
- `api/.env.example`
- `README.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Continue experiment.

### Notes

Validation evidence: shell syntax checks passed for the updated scripts, and `sam validate --lint` passed for `api/infra/lambda.yaml` and `api/infra/dynamodb.yaml`. Node/npm were not available in this shell, so the NestJS build and end-to-end simulation were not run here.

## 2026-07-03 17:35

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Adjustment of AWS infrastructure for Free Tier-oriented operation.

### Summary

The Lambda template now uses Lambda Function URL instead of API Gateway, removes Secrets Manager from Datadog key management, accepts the Datadog API key as a deployment-time `NoEcho` parameter and uses a custom Lambda role without CloudWatch Logs permissions to avoid log ingestion/storage charges.

The DynamoDB template now uses provisioned capacity with 1 RCU and 1 WCU for each table and GSI. With the current five tables and three GSIs, the total is 8 RCU and 8 WCU, staying within the classic Free Tier provisioned-capacity envelope.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/infra/dynamodb.yaml`
- `api/.env.example`
- `README.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/learnings.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Continue experiment.

### Notes

Validation evidence: `sam validate --lint --template-file api/infra/lambda.yaml` and `sam validate --lint --template-file api/infra/dynamodb.yaml` passed.

## 2026-07-03 17:17

### Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

### Activity

Investigation and removal of Serverless Framework coupling from the Datadog and local runtime path.

### Summary

The repository had two deployment/runtime models for observability: AWS SAM in `api/infra/lambda.yaml` and a newly added `api/serverless.yml` with `serverless-plugin-datadog` and `serverless-offline`. The experiment confirmed that Datadog can remain implemented through `dd-trace`, structured logs and the existing `payments.observability` bridge, while AWS deployment configuration stays in SAM.

The Serverless Framework dependencies/scripts were removed from the API package declaration, `api/serverless.yml` was removed, and SAM now accepts Datadog parameters for environment, Secrets Manager API key secret ARN and Datadog Lambda Extension layer ARN. Local execution remains the NestJS sandbox script with Datadog disabled by default.

### Artifacts Updated

- `api/package.json`
- `api/package-lock.json`
- `api/infra/lambda.yaml`
- `api/scripts/start-sandbox-api.sh`
- `README.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/learnings.md`
- `prodops/upstream/upstream-trail.md`

### Decision

Ready for Assessment.

### Notes

Automated validation was not executed because `node` and `npm` were not available in this shell. The remaining external validation is a SAM deploy with the target account's Datadog Extension layer ARN/version and the Secrets Manager secret.

## 2026-07-02 16:08

### Experiment

Reference:

`prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`

### Activity

Experiment started after reviewing Current State, Repository Tracking List, Reliability Plan, Premortem, Iteration Plan and existing Upstream experiments.

### Summary

The highest-priority uncertainty is the Checkout Feature Flag readiness for the new Payments gateway. The approved release depends on enabling this route, but the flag remains documented as blocked by a Checkout bug and lacks rollback evidence for orders already started in Payments.

Existing experiments cover credit card uncertainty and do not cover this release-blocking dependency, so a new Upstream experiment was created.

### Artifacts Updated

- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/learnings.md`

### Decision

Continue experiment.

### Notes

Next step: collect Checkout evidence — exact Feature Flag bug, owner, fix status, targeting rules, auditability, rollout/pause/rollback criteria, telemetry by order and in-flight order handling after rollback.

## 2026-07-02 16:40

### Experiment

References:

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/002-sandbox-funding/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`
- `prodops/upstream/experiments/004-feature-flag-readiness/experiment.md`

### Activity

Updated BDD Features to reflect the existing Upstream experiments.

### Summary

The credit card BDD now includes hosted confirmation, financial receipt, tokenized-card constraints, risk-analysis events, sandbox/simulation evidence and the decision to keep direct raw card capture out of the first Downstream slice.

A new Checkout Feature Flag readiness BDD was added to represent the EXP-004 learning as executable acceptance criteria for rollout, pause, rollback, auditability, in-flight orders and promotion blocking.

### Artifacts Updated

- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrated: now `prodops/artifacts/business/bdd/credit-card-payment.feature`)
- `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removed: no successor in `prodops/artifacts/business/bdd/`)

### Decision

Continue experiment.

### Notes

These features are BDD inputs for future TDD/Downstream work. They do not promote the capabilities by themselves.

## 2026-07-02 17:10

### Experiment

References:

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments/003-hosted-vs-tokenized/experiment.md`

### Activity

Updated Payments API code according to the executable scope of the credit card experiments.

### Summary

The API now makes the first credit-card slice explicit: `CREDIT_CARD` is treated as hosted card entry and rejects tokenized or direct card data fields in `POST /invoices`. This prevents the tokenized/direct-card experiments from silently becoming unsupported production behavior.

Webhook handling now records card-specific Asaas events — such as authorization, risk analysis and capture refusal — as observable card events. Authorization and risk-analysis events do not publish `payment.confirmed`; capture refusal and risk reproval mark the invoice as failed when the payment has not already been confirmed or received.

### Artifacts Updated

- `api/src/modules/invoices/dto/create-invoice.dto.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/test/create-invoice.acceptance.e2e-spec.ts` (renamed: now `api/test/criar-invoice.e2e-spec.ts`)

### Decision

Ready for Assessment.

### Notes

Validation evidence: `npm run test:acceptance` in `api/` passed with 26 tests.

## 2026-07-02 17:48

### Experiment

Reference:

`prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`

### Activity

Expanded the Asaas credit card lifecycle experiment to cover Cart/Checkout to Payments contracts, saved-card listing, new-card registration, tokenization boundary and Validation Workbench exploration.

### Summary

The experiment now separates hosted card entry, saved-card payment and new-card submission. Hosted entry remains the safest Downstream candidate. Saved-card and new-card flows remain Upstream until Product, Security and Architecture decide token storage, ownership, consent, PCI boundary, `remoteIp` handling and refund policy.

The Validation Workbench now lets agents and humans explore hosted card, saved-card and new-card payload shapes, including disposable local card registration and webhook simulation for authorization, risk analysis, confirmation, refusal, cancellation and refund.

### Artifacts Updated

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/learnings.md`
- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrated: now `prodops/artifacts/business/bdd/credit-card-payment.feature`)
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/obcs/credit-card-authorization-confirmation.md`
- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`

### Decision

Continue experiment.

### Notes

Recommendation: move only hosted card entry toward Assessment. Keep saved-card reuse and new-card registration in Upstream until token storage, PCI boundary, consent and refund decisions are recorded.

## 2026-07-07

### Experiments

- EXP-003: `prodops/journeys/discovery/experiments/003-hosted-vs-tokenized/experiment.md`
- EXP-001: `prodops/journeys/discovery/experiments/001-credit-card-lifecycle/experiment.md`

### Activity

Move-to-delivery: hosted card slice promoted to Downstream.

### Decision

PM approved. OBC and BDD Feature moved to committed locations. Iteration Plan updated. Hosted card slice enters Downstream delivery flow.

## 2026-07-08

### Activity

Normalized ProdOps framework operational paths and executable skills.

### Summary

The framework now has an explicit canonical path map and the primary executable
skills point to the current `prodops/artifacts/` and `prodops/journeys/`
structure instead of migrated legacy paths. Discovery instructions now create
new experiments under `prodops/journeys/discovery/experiments/`, root
Upstream templates are marked as legacy, and Bootstrap is available as a
first-class Delivery skill.

A lightweight `prodops/scripts/doctor.sh` check was added to verify required
ProdOps paths, experiment layout, and accidental legacy path references in
operational documents.

### Artifacts Updated

- `AGENTS.md`
- `prodops/README.md`
- `prodops/framework/canonical-paths.md`
- `prodops/framework/glossary.md`
- `prodops/framework/principles.md`
- `prodops/journeys/discovery/README.md`
- `prodops/journeys/discovery/experiments.md`
- `prodops/journeys/assessment/reliability-plans/`
- `prodops/journeys/delivery/capabilities/`
- `prodops/journeys/operation/runbooks.md`
- `prodops/skills/`
- `prodops/scripts/doctor.sh`
- `templates/upstream-*.md`

### Evidence

- `prodops/scripts/doctor.sh` passed.
- `rg` check found no legacy ProdOps path references in operational docs outside
  explicitly excluded historical trails and the canonical legacy mapping.

### Decision

Continue using the `prodops/journeys/` and `prodops/artifacts/` structure as the
operational source of truth.

### Notes

Historical trails may still mention legacy paths as migration evidence. New
operational instructions should use `prodops/framework/canonical-paths.md`.

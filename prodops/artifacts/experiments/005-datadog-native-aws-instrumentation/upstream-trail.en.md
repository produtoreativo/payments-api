# Upstream Trail - EXP-005

## Experiment

Reference:

`prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`

---

# History

> Append new entries below.
> Never rewrite previous entries.

## 2026-07-03 17:17

### Activity

Investigated and removed Serverless Framework coupling from the Datadog and
local runtime path.

### Summary

The repository had two deployment/runtime stories for observability: AWS SAM in
`api/infra/lambda.yaml` and a newly added `api/serverless.yml` with
`serverless-plugin-datadog` plus `serverless-offline`. The experiment confirmed
that Datadog can remain implemented through `dd-trace`, structured logs and the
existing `payments.observability` bridge while AWS deploy configuration lives in
SAM.

The Serverless Framework dependencies/script were removed from the API package
declaration, `api/serverless.yml` was removed, and SAM now accepts Datadog
parameters for environment, Secrets Manager API key ARN and Datadog Lambda
Extension layer ARN. Local execution remains the NestJS sandbox script with
Datadog disabled by default.

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

### Evidence

- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Ready for Assessment.

### Notes

Automated validation was not executed because `node` and `npm` are not
available in this shell. The remaining external validation is a SAM deploy with
the target account's Datadog Extension layer ARN/version and Secrets Manager
secret.

## 2026-07-03 17:35

### Activity

Adjusted AWS infrastructure for Free Tier-oriented operation.

### Summary

The Lambda template now uses Lambda Function URL instead of API Gateway,
removes Secrets Manager from Datadog key handling, accepts the Datadog API key
as a deployment-time `NoEcho` parameter and uses a custom Lambda role without
CloudWatch Logs permissions to avoid log ingestion/storage charges.

The DynamoDB template now uses provisioned capacity with 1 RCU and 1 WCU for
each table and GSI. With the current five tables and three GSIs, that totals 8
RCU and 8 WCU, staying under the classic Free Tier provisioned-capacity
envelope.

### Artifacts Updated

- `api/infra/lambda.yaml`
- `api/infra/dynamodb.yaml`
- `api/.env.example`
- `README.md`
- `prodops/upstream/experiments/005-datadog-native-aws-instrumentation/experiment.md`
- `prodops/upstream/learnings.md`
- `prodops/upstream/upstream-trail.md`

### Evidence

- `sam validate --lint --template-file api/infra/lambda.yaml` passed.
- `sam validate --lint --template-file api/infra/dynamodb.yaml` passed.
- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Continue experiment.

### Notes

No additional notes.

## 2026-07-03 17:45

### Activity

Configured local validation to use LocalStack DynamoDB instead of in-memory
storage.

### Summary

The local AWS path now has an explicit runtime script,
`api/scripts/start-localstack-api.sh`, which starts the NestJS API with
`INVOICE_REPOSITORY=dynamo`, `DYNAMO_MOCK=false` and
`AWS_DYNAMODB_ENDPOINT=http://localhost.localstack.cloud:4566`.

The Asaas webhook simulation now creates an invoice through the API first,
extracts `providerPaymentId` and `externalReference` from the response, and
then sends `PAYMENT_CONFIRMED` with those values. This validates the same
DynamoDB correlation structure used by the webhook handler instead of relying
on memory state or hardcoded provider ids.

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

### Evidence

- Shell syntax checks passed for updated scripts.
- `sam validate --lint` passed for `api/infra/lambda.yaml`.
- `sam validate --lint` passed for `api/infra/dynamodb.yaml`.
- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Continue experiment.

### Notes

Node/npm are not available in this shell, so the NestJS build and end-to-end
simulation were not executed here.

## 2026-07-03 17:50

### Activity

Converted Asaas webhook handling to an asynchronous serverless queue path.

### Summary

The AWS/SAM template now provisions `payments-webhook-queue` and
`payments-webhook-dlq`. The HTTP Lambda Function URL acts as a receiver: it
validates the Asaas token, enqueues the webhook message and returns HTTP 200
quickly. A dedicated `webhook-worker` Lambda consumes SQS messages and executes
the existing payment confirmation domain logic.

The local simulation now validates the end-to-end shape by creating an invoice,
sending `PAYMENT_CONFIRMED`, and polling DynamoDB LocalStack until the invoice
is confirmed. Local NestJS debug mode remains available with
`WEBHOOK_PROCESSING_MODE=sync`; SAM/LocalStack deploy uses async mode.

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

### Evidence

- Shell syntax checks passed for updated scripts.
- `sam validate --lint` passed for `api/infra/lambda.yaml`.
- `sam validate --lint` passed for `api/infra/dynamodb.yaml`.
- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Continue experiment.

### Notes

Node/npm are not available in this shell, so the NestJS build and LocalStack
execution were not run here.

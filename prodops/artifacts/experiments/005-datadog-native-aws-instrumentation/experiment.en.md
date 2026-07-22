# Upstream Experiment - Datadog Native AWS Instrumentation

## Status

- [x] Completed

---

# Business Goal

Keep Payments API observable in Datadog without making the repository dependent
on the Serverless Framework or `serverless-offline`.

This supports the Reliability Plan demand for complete Payments
instrumentation while preserving AWS-native deployment through SAM and local
validation through the existing sandbox.

---

# Repository Scope Gate

## Repository-owned scope

- [x] Payments API behavior
- [x] Persistence
- [x] API/event contract owned by Payments
- [x] Local tests or executable evidence

## External dependencies

- Datadog account, API key and Lambda Extension layer ARN.
- AWS deployment pipeline passing SAM parameters.
- Deployment-time Datadog API key injection.

## Scope decision

- [x] Continue as executable Upstream experiment in this repository

---

# Question to Answer

Can Payments API keep Datadog traces, logs and metrics while removing the
Serverless Framework plugin/offline path from the repository?

---

# Hypothesis

Datadog instrumentation does not need `serverless-plugin-datadog` in this repo.
The application can keep `dd-trace` bootstrap in code, use AWS SAM parameters to
attach the Datadog Lambda Extension in AWS, and use the NestJS sandbox script for
local execution.

---

# Scope

- Remove Serverless Framework scripts and plugin dependencies from the API
  package declaration.
- Remove the Serverless Framework deployment file.
- Configure Datadog Lambda Extension through `api/infra/lambda.yaml`.
- Expose the Lambda through Function URL instead of API Gateway.
- Keep DynamoDB capacity within the classic Free Tier envelope.
- Avoid CloudWatch Logs ingestion by not granting Lambda `logs:*`
  permissions.
- Remove Secrets Manager from the Datadog key path.
- Keep local execution on `api/scripts/start-sandbox-api.sh`.
- Update documentation for the supported paths.

---

# Out of Scope

- Creating Datadog dashboards.
- Selecting the final Datadog Extension layer version for each AWS region.
- Changing payment domain behavior, BDD scenarios or public API contracts.

---

# Implementation

- `api/package.json` no longer exposes `start:offline` or Serverless Framework
  dev dependencies.
- `api/serverless.yml` was removed.
- `api/infra/lambda.yaml` now accepts Datadog parameters and conditionally
  attaches the Datadog Lambda Extension layer.
- `api/infra/lambda.yaml` now uses Lambda Function URL instead of API Gateway
  and a custom role without CloudWatch Logs permissions.
- `api/infra/dynamodb.yaml` now uses provisioned capacity at 1 RCU / 1 WCU per
  table and GSI.
- `api/scripts/start-sandbox-api.sh` now declares local Datadog defaults as
  disabled.
- `README.md` now documents local sandbox execution and SAM-based AWS
  instrumentation.

---

# Code Produced

- Updated `api/infra/lambda.yaml`.
- Updated `api/infra/dynamodb.yaml`.
- Updated `api/scripts/start-sandbox-api.sh`.
- Updated `api/package.json`.
- Updated `api/package-lock.json` package-root dependency declaration.
- Removed `api/serverless.yml`.

---

# Functional Validation

No automated build or test was executed because this environment does not have
`node` or `npm` available in `PATH`.

Static validation performed:

- Searched repository references to `serverless-offline`,
  `serverless-plugin-datadog`, `start:offline` and `serverless.yml`.
- Confirmed remaining application instrumentation still uses `dd-trace`,
  `nestjs-pino`, correlation middleware and `payments.observability` metrics.

---

# Technical Findings

- The repository already had a clean AWS-native deployment base in
  `api/infra/lambda.yaml`.
- The Serverless Framework file duplicated deployment concerns and made local
  execution appear dependent on `serverless-offline`.
- Local validation does not need Lambda emulation for the main API flow; the
  existing NestJS sandbox covers the HTTP behavior with memory storage and
  provider mocks.
- Datadog runtime behavior is split cleanly:
  - local: optional DD Agent, disabled by default;
  - AWS: SAM parameters, Function URL and Datadog Lambda Extension layer.
- Lambda Function URL is sufficient for this lab API and avoids API Gateway
  cost.
- DynamoDB provisioned capacity keeps the current table/index set under 25 RCU
  and 25 WCU when each table and GSI uses 1 RCU and 1 WCU.
- Avoiding CloudWatch Logs charges means the Lambda role intentionally does not
  include `logs:*`; AWS-side application logs are unavailable unless logs are
  re-enabled in a paid/controlled environment.

---

# Business Findings

The change supports the existing observability demand (`TL-003`) without adding
a new payment capability or changing business acceptance criteria.

---

# Architecture Impact

Confirmed decision:

- Deployment ownership should stay with AWS-native SAM/CloudFormation artifacts.

Rejected decision:

- Keeping `serverless-plugin-datadog` as the Datadog deployment mechanism.

Open question:

- The deployment pipeline must choose and pass the correct Datadog Extension
  layer ARN/version for each region.

---

# Reliability Impact

- Reduces operational ambiguity between local sandbox, Lambda deployment and
  observability setup.
- Keeps Datadog API key out of repository configuration by passing it as a
  `NoEcho` deployment parameter.
- Preserves the `payments.observability` to Datadog metrics bridge.
- Requires a future AWS deployment validation with the final Datadog layer ARN.
- Removes API Gateway cost by using Lambda Function URL.
- Keeps DynamoDB provisioned capacity under 25 RCU / 25 WCU total for the
  current table/index set.
- Prevents CloudWatch Logs ingestion by removing Lambda logging permissions.

---

# Artifacts Updated

- `api/package.json`
- `api/package-lock.json`
- `api/infra/lambda.yaml`
- `api/infra/dynamodb.yaml`
- `api/scripts/start-sandbox-api.sh`
- `api/.env.example`
- `README.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/learnings.md`
- `prodops/upstream/upstream-trail.md`

---

# Recommendation

Move downstream after pipeline owners confirm the Datadog Extension layer ARN,
deployment-time key injection and SAM deploy parameters for the target AWS
account.

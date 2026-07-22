# Upstream Trail - EXP-002

## Experiment

Reference:

`prodops/upstream/experiments/002-sandbox-funding/experiment.md`

---

# History

> Append new entries below.
> Never rewrite previous entries.

## 2026-07-03 18:50

### Activity

Added a local startup script for the real Asaas Sandbox.

### Summary

The repository now has `api/scripts/start-asaas-sandbox-real.sh` to run the
Payments API against the real Asaas Sandbox instead of the local mock. The
script loads `api/.env` without expanding literal `$` characters in Sandbox API
keys, validates `ASAAS_TOKEN`, forces `ASAAS_MOCK=false`, defaults storage to
memory, starts a public webhook tunnel with `cloudflared` or `ngrok`, and uses
the Asaas Webhooks API to create or update the webhook URL.

The sandbox invoice helper now uses a due date relative to the current day
instead of a fixed historical date, making it suitable for real Sandbox charge
creation.

### Artifacts Updated

- `api/scripts/start-asaas-sandbox-real.sh`
- `api/scripts/create-invoice-sandbox.sh`
- `README.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- `bash -n api/scripts/start-asaas-sandbox-real.sh` passed.
- `bash -n api/scripts/create-invoice-sandbox.sh` passed.

### Decision

Continue experiment.

### Notes

Real Asaas Sandbox execution was not run here because it requires a valid
Sandbox API key and external webhook configuration in the Asaas account.

## 2026-07-03 19:05

### Activity

Updated the Validation Workbench for real Asaas Sandbox execution and webhook queue visibility.

### Summary

The Workbench now has an explicit runtime selector with an `Asaas Sandbox real`
mode. In that mode it keeps invoice creation against the configured Payments API
URL, forces the operational context to Asaas, shows the payment URL returned by
the provider and disables the manual webhook simulation button so the user does
not confuse local simulation with Asaas-delivered webhook events.

The Payments API now exposes `GET /webhook/payments/queue` for local inspection
of webhook processing mode and SQS queue/DLQ counters. The Workbench consumes
that endpoint through a visual `Webhook queue` panel so local validation can
see whether webhooks are processed synchronously or queued.

The Workbench README now documents that the real Sandbox path should be run
with `api/scripts/start-asaas-sandbox-real.sh`.

### Artifacts Updated

- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`
- `validation-workbench/README.md`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/src/modules/invoices/services/asaas-webhook-queue.service.ts`
- `api/infra/lambda.yaml`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- Static review confirmed there is no `GET /invoices/:invoiceId` endpoint, so
  the Workbench does not poll status after real webhook delivery.
- `npm run build` passed in `validation-workbench/`.
- `npm run build` passed in `api/`.
- `sam validate --lint --template-file api/infra/lambda.yaml` passed.
- `npm run test:acceptance` passed in `api/` with 26 acceptance tests.

### Decision

Continue experiment.

### Notes

Real Asaas Sandbox execution still requires a valid Sandbox API key and the
webhook configured in the Asaas account by the startup script.

## 2026-07-03 19:25

### Activity

Updated the real Asaas Sandbox startup script to run the complete async webhook model locally.

### Summary

`api/scripts/start-asaas-sandbox-real.sh` now prepares the full local structure
needed by the serverless webhook model before starting the NestJS API. By
default it starts or reuses LocalStack, deploys the DynamoDB tables, creates the
SQS webhook queue and DLQ, forces `WEBHOOK_PROCESSING_MODE=async`, exports the
queue URLs and starts a local worker that polls SQS and invokes the existing
`src/webhook-worker.ts` handler.

The simple synchronous mode remains available with
`USE_LOCALSTACK_WEBHOOK_QUEUE=false`.

### Artifacts Updated

- `api/scripts/start-asaas-sandbox-real.sh`
- `api/scripts/run-local-webhook-worker.js`
- `README.md`
- `validation-workbench/README.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- `bash -n api/scripts/start-asaas-sandbox-real.sh` passed.
- `node --check api/scripts/run-local-webhook-worker.js` passed.
- `npm run build` passed in `api/`.
- `npm run build` passed in `validation-workbench/`.
- `npm run test:acceptance` passed in `api/` with 26 acceptance tests.

### Decision

Continue experiment.

### Notes

The real Asaas callback was not executed here because it requires a valid
Sandbox API key and webhook delivery from the Asaas account. The script now
prepares the local queue/DLQ/worker structure required for that validation.

## 2026-07-03 20:05

### Activity

Investigated missing PIX and credit-card payment confirmations from the real Asaas Sandbox.

### Summary

The local webhook path was reachable through Cloudflare, the Asaas webhook was
enabled and pointed to the current public URL, and the local Payments API was
running with `WEBHOOK_PROCESSING_MODE=async`, SQS, DLQ and worker active.

The missing confirmation was caused by the Asaas Sandbox payments still being
`PENDING`. In the Sandbox, creating a charge does not confirm payment by
itself. The payment event is generated after simulating confirmation with the
Sandbox endpoint `POST /v3/sandbox/payment/{id}/confirm`.

After calling that endpoint for one PIX payment and one credit-card payment,
Asaas delivered the webhooks and the local DynamoDB records were updated:

- PIX payment `pay_48l3885ulhf3ptkv` moved to `RECEIVED`.
- Credit-card payment `pay_pvf359zu3vk7d60a` moved to `CONFIRMED`.

The startup script was also corrected to force `AWS_SQS_ENDPOINT` to the
LocalStack base endpoint when the full local queue model is enabled, preventing
stale `.env` values from pointing the SDK to a queue URL instead of the SQS
service endpoint.

### Artifacts Updated

- `api/scripts/start-asaas-sandbox-real.sh`
- `api/scripts/create-invoice-sandbox.sh`
- `README.md`
- `validation-workbench/README.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- `GET /webhook/payments/queue` returned async mode with SQS and DLQ configured.
- `GET /health` through the Cloudflare URL returned healthy API status.
- Asaas `GET /webhooks` returned the local Sandbox webhook enabled with payment confirmation events.
- Asaas `GET /payments?limit=10` showed recent PIX and card payments still `PENDING` before confirmation.
- Asaas `POST /sandbox/payment/{id}/confirm` returned success for PIX and credit card.
- DynamoDB LocalStack scan confirmed the corresponding local invoices changed to `RECEIVED` and `CONFIRMED`.
- `bash -n api/scripts/create-invoice-sandbox.sh` passed.
- `bash -n api/scripts/start-asaas-sandbox-real.sh` passed.
- `npm run build` passed in `api/`.
- `npm run test:acceptance` passed in `api/` with 26 acceptance tests.

### Decision

Continue experiment.

### Notes

Use `CONFIRM_SANDBOX_PAYMENT=true ./scripts/create-invoice-sandbox.sh` for PIX
and `BILLING_TYPE=CREDIT_CARD CONFIRM_SANDBOX_PAYMENT=true
./scripts/create-invoice-sandbox.sh` for card webhook validation.

## 2026-07-03 20:25

### Activity

Added visual Sandbox payment confirmation to the Validation Workbench.

### Summary

The Workbench now exposes the missing Sandbox confirmation step directly in the
`Asaas Sandbox real` runtime. After creating an invoice, the user can click
`Confirm in Asaas Sandbox`; the frontend calls the local Payments API at
`POST /sandbox/asaas/payments/:providerPaymentId/confirm`, and the backend calls
Asaas Sandbox with the server-side `ASAAS_TOKEN`.

This keeps the Asaas API key out of the browser while preserving the real
provider behavior: Asaas changes the payment status, sends the webhook to the
public tunnel, the Payments API enqueues it in SQS, and the local worker updates
DynamoDB.

### Artifacts Updated

- `api/src/infra/asaas.service.ts`
- `api/src/modules/invoices/controllers/asaas-sandbox.controller.ts`
- `api/src/modules/invoices/invoices.module.ts`
- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`
- `README.md`
- `validation-workbench/README.md`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- `npm run build` passed in `api/`.
- `npm run build` passed in `validation-workbench/`.
- `npm run test:acceptance` passed in `api/` with 26 acceptance tests.

### Decision

Continue experiment.

### Notes

The running local API must be restarted after this code change before the
Workbench can call the new Sandbox confirmation endpoint.

## 2026-07-03 20:40

### Activity

Aligned the Workbench credit-card creation UI with the currently supported hosted-card contract.

### Summary

The Workbench could still select saved-card or new-card modes and keep stale
card fields in the editable JSON payload. The Payments API correctly rejects
those fields in the first hosted-card slice with:

`Hosted credit card flow does not accept card data fields`.

The Workbench now resets credit-card creation to `HOSTED_INVOICE`, disables the
unsupported card-data modes, and clears payload dirty state when the billing
type changes to `CREDIT_CARD`. The active card payload no longer includes
`creditCardToken`, `creditCard`, `cardReference` or `remoteIp`.

### Artifacts Updated

- `validation-workbench/src/App.tsx`
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- `npm run build` passed in `validation-workbench/`.
- `npm run test:acceptance` passed in `api/` with 26 acceptance tests.

### Decision

Continue experiment.

### Notes

If the JSON editor already contains stale card fields, use `Sync` or
change the billing type again so the Workbench regenerates the hosted-card
payload.

## 2026-07-03 20:50

### Activity

Mapped repeated Asaas Sandbox confirmations to a business 4xx response.

### Summary

The Sandbox confirmation endpoint returned HTTP 500 when Asaas rejected a second
confirmation attempt with `invalid_action: Cobrança já confirmada.` because the
provider error was converted to a plain internal error. The Asaas service now
preserves the provider HTTP status and the Sandbox controller maps this
`invalid_action` case to HTTP 409 Conflict.

### Artifacts Updated

- `api/src/infra/asaas.service.ts`
- `api/src/modules/invoices/controllers/asaas-sandbox.controller.ts`
- `api/test/create-invoice.acceptance.e2e-spec.ts` (renamed: now `api/test/criar-invoice.e2e-spec.ts`)
- `prodops/upstream/experiments/002-sandbox-funding/upstream-trail.md`

### Evidence

- `npm run build` passed in `api/`.
- `npm run test:acceptance` passed in `api/` with 27 acceptance tests.
- Acceptance test `mapeia cobranca ja confirmada na Sandbox da Asaas como conflito de negocio` verifies HTTP 409.

### Decision

Continue experiment.

### Notes

The local backend must be restarted before the Workbench receives the updated
409 response for already-confirmed Sandbox charges.

## 2026-07-02 16:40

### Activity

Updated BDD Features to reflect the existing Upstream experiments.

### Summary

The credit card BDD now includes hosted confirmation, financial receipt,
tokenized-card constraints, risk-analysis events, sandbox/simulation evidence
and the decision to keep direct raw card capture out of the first Downstream
slice.

This entry was migrated from the global trail and also relates to EXP-001,
EXP-003 and the missing EXP-004 reference.

### Artifacts Updated

- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrated: now `prodops/artifacts/bdd/credit-card-payment.feature`)
- `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removed: no successor in `prodops/artifacts/bdd/`)

### Evidence

- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Continue experiment.

### Notes

These features are BDD inputs for future TDD/Downstream work. They do not
promote the capabilities by themselves.

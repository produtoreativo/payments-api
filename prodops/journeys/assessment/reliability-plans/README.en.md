# Reliability Plan - Payments Release

> Document generated from `prodops/journeys/assessment/reliability-plans/setup/reliability-plan.prompt.md`.
> Main input: `prodops/artifacts/governance/plans/iteration-plan.md`.

## Executive Summary

This Reliability Plan considers exclusively the features from the Iteration Plan whose decision is exactly `In`. Per the prompt rule, items marked as `In as MVP`, `Split`, `Deferred` or `Out` are excluded from this plan.

The scope approved for the Release therefore consists of six features with decision `In`: enable the new gateway for Checkout on the prioritized journey, create invoice via Pix, confirm payment, create invoice via Boleto, API token access validation and webhook configuration by API token. The API already has relevant implementation for invoice creation, Asaas integration, idempotency, webhook confirmation, event deduplication and observable events. The in-memory acceptance suite was previously executed with 19 passing tests.

> **Attention:** The three features added on 2026-07-06 (Boleto, API token, webhook by token) have OBC and BDD Feature created, but do not yet have complete risk analysis in this Reliability Plan. The sections on Current State, Main Risks, Analysis Per Feature and Reliability Roadmap cover only the three original features. The new features must have their risk entries added before Bootstrap.

The greatest reliability risks for this approved scope are in the difference between the local path and the production path, in the Checkout Feature Flag documented as blocked by a bug, and in documentation divergences that may cause Checkout, Asaas or operations to configure incorrect contracts. Webhook correlation in Dynamo by `providerPaymentId` and `externalReference` was implemented on 2026-06-30 and now has acceptance coverage with `DYNAMO_MOCK`.

## Features Considered

| Feature | Decision in Iteration Plan | Evidence |
| --- | --- | --- |
| Enable new gateway for Checkout on the prioritized journey | In | `prodops/artifacts/governance/plans/iteration-plan.md`, row of the "Recommended Iteration Plan" table. |
| Create invoice via Pix | In | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/bdd/create-invoice.feature`; `InvoiceController.createInvoice`; `InvoiceService.createInvoice`. |
| Payment confirmation | In | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/bdd/payment-confirmation.feature`; `AsaasWebhookController`; `InvoiceService.processProviderWebhook`. |
| Create invoice via Boleto | In (revised 2026-07-06) | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/create-invoice-boleto.md`; `prodops/artifacts/business/bdd/create-invoice-boleto.feature`. **Risk analysis pending in this Reliability Plan.** |
| API token access validation | In | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/api-token-validation.md`; `prodops/artifacts/business/bdd/api-token-validation.feature`. **Risk analysis pending in this Reliability Plan.** |
| Webhook configuration by API token | In | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/webhook-configuration.md`; `prodops/artifacts/business/bdd/webhook-configuration.feature`. **Risk analysis pending in this Reliability Plan.** |
| Create invoice via Credit Card (Hosted) | In (approved 2026-07-07) | `prodops/artifacts/governance/plans/iteration-plan.md`; `prodops/artifacts/business/obcs/credit-card-authorization-confirmation.md`; `prodops/artifacts/business/bdd/credit-card-payment.feature`. **Risk analysis pending in this Reliability Plan.** |

Items explicitly ignored for not having a decision of exactly `In`: `Payment status notification` (`In as MVP`), `Cancel pending invoice` (`Deferred`), `Corporate incident/ITSM integration` (`Out`) and `Gateway fallback/Itaú` (`Out`).

## Current State

| Feature | Existing Implementation | Dependencies | Reliability State |
| --- | --- | --- | --- |
| Enable new gateway for Checkout on the prioritized journey | No Feature Flag implementation in this repository; Premortem reports that Checkout is ready, but the flag remains disabled due to a bug. | Checkout, Feature Flag, Checkout -> Payments contract, Payments API. | Critical external dependency not yet evidenced as ready. |
| Create invoice via Pix | `POST /invoices` receives `CreateInvoiceDto`, requires `Idempotency-Key`, resolves provider, creates Asaas customer/charge and updates invoice to `OPEN`. | Asaas `/customers`, Asaas `/payments`, Payments DB, customer binding. | Implemented and covered by in-memory tests; Dynamo path and provider timeout still weaken reliability. |
| Payment confirmation | `POST /webhook/payments` validates token when configured, persists raw event, deduplicates and processes `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED` and `PAYMENT_OVERDUE`. | Asaas webhook, `ASAAS_WEBHOOK_TOKEN`, Payments DB, canonical event `payment.confirmed`. | Rules covered in memory and in Dynamo mock for correlation by `providerPaymentId` and `externalReference`; uncorrelated webhook emits observable event. |

**Relevant Inconsistencies for the Approved Scope**

| Feature | Inconsistency | Evidence | Risk |
| --- | --- | --- | --- |
| Enable new gateway for Checkout on the prioritized journey | Consumers may use a divergent contract. | Legacy documentation removed on 2026-07-12; the canonical contract uses `POST /invoices`. | Checkout integrating incorrect endpoint. |
| Create invoice via Pix | Old ODD references `/payments` and Asaas `/v3/paymentLinks`; code uses `/invoices` and `/v3/payments`. | `api/odd/create_invoice.yaml`; `AsaasService.createCharge`. | Observability/contract measuring wrong dependency. |
| Payment confirmation | Consumers may configure a legacy webhook route. | Legacy documentation removed on 2026-07-12; `AsaasWebhookController` uses `/webhook/payments`. | Asaas webhook configured at incorrect URL. |

## Main Risks

| Feature | Risk | Impact | Probability | Criticality |
| --- | --- | --- | --- | --- |
| Enable new gateway for Checkout on the prioritized journey | Feature Flag remains blocked by bug documented in Premortem. | Release not activated or activated without predictability. | High | Critical |
| Enable new gateway for Checkout on the prioritized journey | Checkout -> Payments contract may diverge from the real endpoint. | Checkout fails to create invoice after flag activation. | Medium | High |
| Enable new gateway for Checkout on the prioritized journey | No evidence in this repo of rollback criteria for orders started with the new gateway. | Orders get stuck between old and new flow. | Medium | High |
| Create invoice via Pix | Current tests use `INVOICE_REPOSITORY=memory`; Dynamo persistence may diverge. | Invoice created locally may fail in the Release environment. | High | Critical |
| Create invoice via Pix | Transient timeout marks invoice as `FAILED` with an already-saved idempotency key. | Safe retry may return the failed state without recreating the charge. | Medium | High |
| Create invoice via Pix | `AsaasService` does not define explicit timeout in the axios client. | External call may consume the Lambda window and degrade checkout. | Medium | High |
| Create invoice via Pix | Divergent documentation/ODD about endpoint and provider operation. | Team measures or integrates wrong route/dependency. | Medium | High |
| Payment confirmation | Dynamo queries by `providerPaymentId` and `externalReference` need to be validated against the real environment's tables/indexes. | Confirmed payment may not update invoice if the real index diverges from the tested model. | Medium | High |
| Payment confirmation | Uncorrelated webhook returns technical success and depends on operational consumption of the observable event. | Paid event may remain invisible if there is no monitoring on the emitted signal. | Medium | High |
| Payment confirmation | Canonical event is emitted by local `EventEmitter2`; no evidence of durable publication in the repo. | Confirmation may not reach consumers outside the process. | Medium | High |
| Payment confirmation | `ASAAS_WEBHOOK_TOKEN` is only required when configured. | Misconfigured environment may accept webhook without validation. | Medium | High |

## Analysis Per Feature

### Enable New Gateway for Checkout on the Prioritized Journey

**Risks**

- Premortem reports that Checkout is ready, but activation remains disabled by Feature Flag due to a localized bug.
- The Feature Flag is a dependency outside this repository; the API may be functional and the Release may still not be ready.
- Divergent documentation may cause integration with the wrong endpoint.
- No evidence of policy for orders created during activation and then rollback.

**Dependencies**

- Checkout.
- Feature Flag system.
- Real contract `POST /invoices`.
- Correlation identifiers sent by Checkout: `Idempotency-Key` and `X-Correlation-Id`.

**Points of Attention**

- Release readiness depends on the flag and the consumer's contract, not just the API.
- The Premortem classifies gateway activation as the central risk.
- This plan does not include Notification or cancellation because they do not have a decision of exactly `In`. Boleto, API token and webhook by token are listed in the Features Considered but await complete risk analysis in this document.

**Recommendations**

- Define technical readiness of the Feature Flag for this journey: initial state, activation criteria, rollback criteria and decision owner.
- Update the contract exposed to Checkout to reflect the real endpoint and required headers.
- Record evidence of flag activation/deactivation in a controlled environment before the Release.

### Create Invoice via Pix

**Risks**

- In-memory implementation is covered, but Dynamo still needs to be validated for the same flow.
- Transient failure retry may get stuck on a `FAILED` invoice associated with the same idempotency key.
- `AsaasService` uses axios without explicit timeout.
- The contract accepts other `billingType` values, but the feature approved here is Pix; Boleto data must not be used as evidence of Pix readiness.

**Dependencies**

- Asaas `/customers`.
- Asaas `/payments`.
- Payments DB.
- Customer provider link.
- Checkout sending Pix payload and idempotency key.

**Points of Attention**

- `InvoiceService.createInvoice` saves the invoice before the provider call, which helps auditing.
- `assertProviderChargeContract` reduces the risk of false success when the provider responds without essential data.
- Observable events of the Pix flow already have `correlationId`, `orderId`, `invoiceId`, provider and step.

**Recommendations**

- Validate the Pix flow with the same persistence intended for the Release.
- Define reliable behavior for transient failure retry with an already-persisted idempotency key.
- Configure explicit timeout and classified error for Asaas calls.
- Update Pix ODD/documentation to use `/invoices` and `/v3/payments`.

### Payment Confirmation

**Risks**

- `findByProviderPaymentId` and `findByExternalReference` work in memory and have implementation/coverage with Dynamo mock.
- `processProviderWebhook` may respond with technical success when it did not find an invoice, but now emits a specific observable event for non-correlation.
- `PAYMENT_RECEIVED` updates to `RECEIVED`; needs to preserve the rule of not republishing confirmation.
- `payment.confirmed` is emitted via local EventEmitter; no durability evidenced for external consumers.
- Webhook token depends on environment configuration.

**Dependencies**

- Asaas webhook.
- `ASAAS_WEBHOOK_TOKEN`.
- Payments DB.
- Query indexes by provider payment and external reference.
- Canonical event `payment.confirmed`.

**Points of Attention**

- Tests cover authenticated webhook, invalid, duplicate, `PAYMENT_CONFIRMED`, `PAYMENT_RECEIVED`, `PAYMENT_OVERDUE` and correlation by `externalReference`.
- Current coverage is strong for domain rule but insufficient for Dynamo mode.
- Confirmation is an approved feature as `In`; any initiative here needs to stop at confirmation reliability, without planning notification.

**Recommendations**

- Validate Dynamo queries to find invoice by `providerPaymentId` and `externalReference` against the real environment's tables/indexes.
- Connect the uncorrelated webhook event to an operational dashboard/alert and define reprocessing.
- Define a durable mechanism or explicit boundary for the canonical event `payment.confirmed`.
- Require webhook token in Release environments and fail unsafe configuration.

## Reliability Roadmap

| Feature | Initiative | Objective | Priority | Mitigated Risk | Effort | Dependencies |
| --- | --- | --- | --- | --- | --- | --- |
| Enable new gateway for Checkout on the prioritized journey | Technical readiness of the Feature Flag | Confirm that the flag allows activation, rollback and traceability of the approved journey. | P0 | Flag blocked by bug or inconsistent rollback. | Medium | Checkout, Feature Flag system, Payments. |
| Enable new gateway for Checkout on the prioritized journey | Synchronize Checkout -> Payments contract | Ensure Checkout uses `POST /invoices`, `Idempotency-Key` and `X-Correlation-Id`. | P0 | Integration with incorrect endpoint/header. | Low | Checkout, technical docs, Payments API. |
| Enable new gateway for Checkout on the prioritized journey | Evidence rollback policy for orders during rollback | Define what happens to orders already started in the new gateway when the flag is turned off. | P0 | Order stuck between old and new flow. | Medium | Checkout, Payments, release operation. |
| Create invoice via Pix | Validate Pix flow in Dynamo mode | Ensure that invoice creation, idempotency and reading work in the Release persistence. | P0 | In-memory tests masking a persistence failure. | Medium | DynamoService, PaymentsTable, local/staging environment. |
| Create invoice via Pix | Define retry policy for transient failure | Prevent provider timeout from turning a safe retry into a permanent `FAILED` return. | P0 | Customer/Checkout with no recovery after transient error. | Medium | InvoiceService, idempotency, state rules. |
| Create invoice via Pix | Configure explicit timeout for Asaas | Prevent external calls from consuming the Lambda window and degrading Checkout. | P1 | High latency and cascading failure. | Low | AsaasService, environment configuration. |
| Create invoice via Pix | Fix Pix flow documentation/ODD | Align real endpoint `/invoices` and provider operation `/v3/payments`. | P1 | Observability or integration measuring wrong dependency. | Low | Docs, ODD, Payments. |
| Create invoice via Pix | Minimum Pix creation dashboard | Expose success, error and latency for the approved creation steps. | P1 | Low visibility on Pix creation failure. | Medium | `payments.observability` events, DataDog/APM. |
| Payment confirmation | Implement Dynamo query by `providerPaymentId` | Allow webhook to find invoice in the persistent environment. | P0 | Confirmed payment without internal update. | Medium | `ProviderPaymentIndex`, InvoiceRepository. |
| Payment confirmation | Implement Dynamo query by `externalReference` | Support webhook that arrives before the provider payment id is consolidated. | P0 | Early uncorrelated event. | Medium | Dynamo model, index by order/reference. |
| Payment confirmation | Cover webhook with Dynamo/local mock repository | Validate confirmation, deduplication and correlation in the Release persistence path. | P0 | False confidence from in-memory tests. | Medium | DynamoService, LocalStack or `DYNAMO_MOCK`. |
| Payment confirmation | Observable event for uncorrelated webhook | Provide a clear signal when the provider sends payment without a found invoice. | P0 | Paid event operationally invisible. | Low | InvoiceService, observable events. |
| Payment confirmation | Validate mandatory webhook token configuration | Prevent Release environment from accepting webhook without `ASAAS_WEBHOOK_TOKEN`. | P0 | Security failure due to missing configuration. | Low | ConfigModule, deploy environment. |
| Payment confirmation | Define durability of `payment.confirmed` event | Ensure the approved confirmation does not depend solely on a local listener without persistence. | P1 | Loss of canonical event on process restart/failure. | Medium/High | Current EventEmitter, future broker or architectural decision. |
| Payment confirmation | Minimum confirmation dashboard | Expose received, confirmed, duplicate, invalid and uncorrelated webhooks. | P1 | High MTTR on confirmation failure. | Medium | Webhook events, DataDog/APM. |

## Quick Wins

| Feature | Improvement | Benefit | Effort |
| --- | --- | --- | --- |
| Enable new gateway for Checkout on the prioritized journey | Create a short Feature Flag readiness checklist. | Aligns activation and rollback criteria between Checkout and Payments. | Low |
| Enable new gateway for Checkout on the prioritized journey | Update consumer documentation with `POST /invoices`. | Reduces risk of incorrect integration. | Low |
| Create invoice via Pix | Record the result of `npm run test:acceptance` in the release trail. | Creates objective evidence of the current functional baseline. | Low |
| Create invoice via Pix | Add configurable timeout to the Asaas axios client. | Reduces risk of long external calls. | Low |
| Create invoice via Pix | Remove ODD references to `/v3/paymentLinks`. | Prevents wrong dashboard/dependency for Pix. | Low |
| Payment confirmation | Emit observable event when webhook does not find invoice. | Makes a critical failure visible quickly. | Low |
| Payment confirmation | Fail startup/deploy when webhook token is missing in non-local environments. | Prevents unsafe configuration. | Low |
| Payment confirmation | Document webhook correlation keys: `providerPaymentId` and `externalReference`. | Facilitates diagnosis and alignment with Asaas. | Low |

## Future Backlog

These improvements are related to features that are not part of the scope of risk analysis covered by this document's risk sections.

- `Payment status notification` (`In as MVP`): plan Payments -> Notification contract, end-to-end deduplication, delivery status and confirmation alerts without customer communication when a new `In` decision is made.
- `Create invoice via Boleto`, `API token access validation`, `Webhook configuration by API token` (`In` — promoted after this document was generated): OBC and BDD Feature exist. Add complete risk analysis for each before their respective Bootstrap.
- `Cancel pending invoice` (`Deferred`): resume cancellation hardening, `PAYMENT_DELETED` webhook, 404 reconciliation and concurrency with confirmation when it enters the Release.
- `Corporate incident/ITSM integration` (`Out`): plan DataDog/APM integration with ITSM as a standalone initiative.
- `Gateway fallback/Itaú` (`Out`): plan multi-provider routing/fallback only when there is a business decision and approved technical contract.

## Premises

- The word `In` was interpreted strictly as per the prompt. `In as MVP` was not considered in scope for this Reliability Plan.
- The technical scope of this Release was restricted to three features: enable gateway in Checkout, create invoice via Pix and confirm payment.
- The intended persistence for the Release is Dynamo, since the repository has `INVOICE_REPOSITORY=dynamo` and `PaymentsTable` infrastructure.
- Checkout and Feature Flag are outside this repository but are direct dependencies of the approved gateway enablement feature.
- The current acceptance suite uses an in-memory repository and Asaas stub; it validates domain rules but does not prove reliability in Dynamo.
- The initiatives in this document do not change the Iteration Plan and do not add new business features.

## Sources Consulted

- `prodops/artifacts/governance/plans/iteration-plan.md`
- `prodops/journeys/assessment/reliability-plans/premortem.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/artifacts/product/context/service-decks/compra-com-pix.md`
- `prodops/artifacts/business/bdd/create-invoice.feature`
- `prodops/artifacts/business/bdd/payment-confirmation.feature`
- `api/src/modules/invoices/controllers/invoice.controller.ts`
- `api/src/modules/invoices/controllers/asaas-webhook.controller.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/src/modules/invoices/services/invoice-repository.service.ts`
- `api/src/infra/asaas.service.ts`
- `api/infra/dynamodb.yaml`
- `api/test/criar-invoice.e2e-spec.ts`

# Risk Register — Payments Premortem

> Based on the Premortem document submitted by the user.

## Summary

The scenario describes a critical release for enabling a new payment gateway and stabilizing the notification service. The main business risk is a contractual penalty of **R$ 500 million** if activation does not occur within the deadline.

---

# Doom 2 — Delay in Activating the New Gateway

## Description

The Feature Flag that enables the new Gateway remains disabled due to a known bug. If the fix is not completed within the release window, there is a risk of a contractual penalty and significant impact on the business margin.

## Impact

- Extremely high financial impact
- Blocked production deployment
- Margin compromise
- Release delivery delay

## Suggested Mitigations

- Specific Premortem for the Feature Flag
- Canary Release
- Rollback Plan
- End-to-end observability
- Automated tests on the Feature Flag
- War Room during activation

## Required Upstream Evidence

The experiment `prodops/journeys/discovery/experiments/004-feature-flag-readiness/experiment.md`
classifies this uncertainty as P0 and requires evidence from Checkout before
final promotion:

- exact bug keeping the flag disabled;
- owner and fix status;
- targeting rule and gradual rollout;
- activation/deactivation audit;
- telemetry distinguishing old and new gateway per order;
- pause and rollback criteria;
- policy for orders already initiated in Payments when the flag is turned off.

---

# Doom 3 — Complexity of Microservices Migration

## Description

Monolith decomposition significantly increases operational and integration complexity between services.

## Impact

- Increased distributed failures
- Greater diagnosis difficulty
- Dependencies between services

## Suggested Mitigations

- Distributed Tracing
- Service Map
- Health Checks
- Dependency catalog
- Integration tests
- Gradual Chaos Engineering

---

# Doom 4 — Lack of Operational Visibility

## Description

Incidents have occurred previously and may recur without fast detection, affecting planning and operation.

## Impact

- MTTR increase
- Loss of confidence
- Recurring incidents

## Suggested Mitigations

- Full instrumentation with OpenTelemetry
- Executive dashboards
- SLO-based alerts
- ITSM integration
- Runbooks
- Mandatory RCAs

---

# Identified Structural Risks

- Dependency on the new Gateway for contractual compliance.
- Dependency on the Notifier service.
- Need for DataDog instrumentation.
- Integration with the corporate incident management process.
- Dependencies between Ecommerce, Payments, Marketing, Sales, Infrastructure and Architecture.

## Upstream Risks — Asaas Credit Card

- Checkout hosted on Asaas reduces PCI risk because the Payments API does not
  handle sensitive card data, but depends on the hosted payment experience and
  the invoice URL returned by the provider.
- Tokenized payment requires an explicit contract for `creditCardToken`,
  `remoteIp`, minimum 60-second timeout, authorization states, risk analysis
  and capture refusal.
- Direct card data capture increases the security surface and must not enter
  Downstream without a formal compliance, UX and antifraud decision.
- Events `PAYMENT_AUTHORIZED`, `PAYMENT_AWAITING_RISK_ANALYSIS`,
  `PAYMENT_REPROVED_BY_RISK_ANALYSIS` and
  `PAYMENT_CREDIT_CARD_CAPTURE_REFUSED` do not yet have complete internal states
  or accepted SLOs.
- Cancelling an open charge via `DELETE /v3/payments` does not cover the reversal
  of a confirmed payment; a confirmed card requires a refund/reversal boundary.
- Listing saved cards requires strong validation of tenant, user and
  ownership; an error here can expose another customer's card/token.
- Card token must be treated as sensitive material: it must not appear in
  logs, traces, analytics, error payloads or dead-letter queues.
- `remoteIp` must represent the payer's IP; using the Payments server IP
  reduces antifraud quality and may diverge from Asaas's model.
- Registering a new card expands the PCI boundary because `creditCard` and
  `creditCardHolderInfo` pass through the Payments API even if they are not
  persisted.
- Credit card reversal requires its own contract, idempotency and provider
  evidence; it must not be treated as a simple cancellation.

---

# Risks — Bank Slip (Boleto Bancário)

## Risk B1 — bankSlipUrl missing or expired

### Description

The Asaas provider may return the charge without `bankSlipUrl` in instability scenarios or when the boleto is being processed. The customer receives an invoice without being able to access the bank slip for payment.

### Impact

- High: customer cannot complete payment; lost conversion.
- Support increases with "bank slip did not arrive" tickets.

### Mitigations

- Validate the presence of `bankSlipUrl` in the provider response before returning status `OPEN`. If absent, mark the invoice as `FAILED` and log `payment.boleto.creation_failed`.
- Acceptance test must verify that `bankSlipUrl` is present in the response.

---

## Risk B2 — dueDate in the past or missing

### Description

The ecommerce may send a `dueDate` in the past or omit it. Asaas rejects charges with a past `dueDate` with a 400 error, but the failure occurs after an unnecessary provider call.

### Impact

- Medium: unnecessary provider call; less clear error response to ecommerce.

### Mitigations

- Validate `dueDate` in the gateway before calling the provider: mandatory and future (≥ D+1).
- Reject with `400` and a clear message before any call to Asaas.

---

## Risk B3 — Asynchronous confirmation mistaken for failure

### Description

Unlike Pix (immediate confirmation), Boleto remains in `OPEN` status for days until bank payment. Systems expecting synchronous confirmation may treat `OPEN` status as a failure.

### Impact

- Medium: Checkout or Order Management may prematurely cancel the order while waiting for confirmation.

### Mitigations

- Clearly document in the OBC and BDD Feature that `OPEN` status is the correct state after creation.
- Boleto confirmation arrives via asynchronous webhook (same flow as confirmed Pix).
- Runbook must include diagnosis for "boleto created, payment not confirmed".

---

## Risk B4 — identificationField missing in response

### Description

The barcode line (`identificationField`) is not mapped in the current `ProviderChargeResponse` or `InvoiceResponseDto`. The implementation requires extending the response contract.

### Impact

- High for implementation: fields must be added before the first test passes. Without this the BDD Feature fails in the acceptance test.

### Mitigations

- Add `identificationField` to `ProviderChargeResponse`, `InvoiceRecord` and `InvoiceResponseDto` before writing the acceptance test.
- The Hack Bootstrap must identify this dependency when reading the OBC.

---

# Recommendations for the Reliability Plan

## Before the Release

- Premortem
- Event Storming
- OBC review
- BDD scenario review
- Rollback Plan
- Canary Plan
- Load tests
- Resilience tests

## During the Release

- Real-time monitoring
- Monitored Feature Flag
- Executive dashboards
- War Room
- Clear rollback criteria

## After the Release

- Postmortem
- RCA
- Repository Tracking List update
- OBC update
- Product Deck and Service Deck update

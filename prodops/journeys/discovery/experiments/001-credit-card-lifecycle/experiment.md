# EXP-001 - Credit Card Payment Lifecycle with Asaas

## Status

- [ ] Planned
- [ ] In Progress
- [x] Completed
- [ ] Cancelled

---

# Business Goal

Validate how Payments API should support the credit card lifecycle with Asaas
without coupling Cart/Checkout directly to Asaas contracts and without crossing
an unsafe PCI boundary.

This experiment must answer what contract is needed between Cart/Checkout and
Payments when the buyer selects credit card, how saved cards are listed and
reused, how new cards may be tokenized, which data may be retained, and which
states must be observable before any Downstream delivery.

---

# Repository Scope Gate

## Repository-owned scope

- [x] Payments API behavior
- [x] Payments domain logic
- [x] Provider integration
- [x] Webhook handling
- [x] Persistence
- [x] API/event contract owned by Payments
- [x] Validation Workbench behavior
- [x] Local tests or executable evidence

## External dependencies

- Cart/Checkout implementation and UI rollout.
- Asaas Sandbox behavior and provider account configuration.
- Product decision for hosted, saved-card and new-card UX.
- Security/compliance decision for PCI scope, token retention and raw card
  transit.
- Antifraud decision for risk-analysis handling and `remoteIp` ownership.

## Scope decision

- [x] Continue as executable Upstream experiment in this repository
- [ ] Record only as external dependency or release risk
- [ ] Redirect to owning repository or team

Payments can own the API contract, provider mapping, token metadata boundary,
webhook mapping, observability requirements and Validation Workbench evidence.
Cart/Checkout implementation remains external and must not be created in this
repository.

---

# Question to Answer

Primary question:

Can Payments define a safe, observable and provider-aware credit card contract
for Cart/Checkout that supports hosted entry, saved-card reuse and new-card
tokenization with Asaas?

Subquestions:

- What must Cart/Checkout send after the buyer selects credit card?
- How should Cart/Checkout list saved cards without exposing sensitive card
  data?
- How should Payments register and keep card token metadata for reuse?
- Which Asaas fields are required for hosted payment, tokenized payment and raw
  card submission?
- Which data may be persisted and which data must never be stored?
- Which BDD scenarios and OBC events are required before Downstream?
- Which Validation Workbench screens prove the contract before promotion?

---

# Hypothesis

Payments can keep a provider-agnostic contract while mapping safely to Asaas:

- hosted credit card can use invoice creation without card fields and return a
  provider payment URL;
- saved-card payment can use `creditCardToken` plus `remoteIp`;
- new-card registration can produce a token and persist only non-sensitive card
  metadata;
- raw card fields must remain transient and should not be accepted in production
  until Security approves the PCI boundary;
- webhooks can represent authorization, confirmation, receipt, risk analysis,
  refusal, cancellation and refund as observable domain events.

---

# Scope

Included:

- Cart/Checkout to Payments API draft contracts.
- Saved card listing and new card registration contract draft.
- Pay with saved card and pay with new card contract draft.
- Asaas payload mapping for `creditCard`, `creditCardHolderInfo`,
  `creditCardToken` and `remoteIp`.
- Token and allowed metadata persistence rules.
- Card-specific webhook state mapping.
- Validation Workbench screens for hosted, saved-card and new-card flows.
- BDD scenario requirements.
- Reliability and OBC updates.

---

# Out of Scope

Not included:

- Final production implementation.
- Cart/Checkout repository implementation.
- PCI/compliance approval.
- Production storage of raw card number, CVV or full card payload.
- Production rollout of direct raw card capture.
- Final OpenAPI publication.
- Final refund settlement and finance reconciliation implementation.

---

# Implementation

The experiment should:

- study current Asaas card payment model;
- define candidate Cart/Checkout to Payments contracts;
- update the Validation Workbench with saved-card and new-card exploration;
- update BDD scenarios for saved cards, tokenization and refund boundary;
- update Reliability Plan risks and OBC draft;
- record reusable learnings;
- stop before converting the exploratory code into Downstream scope.

No production implementation is considered final during this experiment.

---

# Cart -> Payments Contract

## `GET /users/{userId}/payment-methods/credit-cards`

Objective:

Return cards already registered for the user so Cart/Checkout can render saved
payment options.

Expected request:

```http
GET /users/{userId}/payment-methods/credit-cards
X-Tenant-Id: magazine-siara
X-Correlation-Id: checkout-{orderId}
```

Expected response:

```json
{
  "userId": "customer-sandbox-001",
  "cards": [
    {
      "cardId": "card-sandbox-visa-001",
      "brand": "VISA",
      "last4": "1111",
      "expiryMonth": "12",
      "expiryYear": "2030",
      "holderName": "Cliente Sandbox Magazine Siara",
      "active": true
    }
  ]
}
```

Expected errors:

- `404` when the user is unknown.
- `403` when tenant/user ownership does not match.
- `502` when provider token metadata cannot be reconciled, if provider lookup
  is required.

Generated events:

- `payment.card.saved.listed`
- `payment.card.saved.list_failed`

Expected observability:

- Dimensions: `tenantId`, `userId`, `correlationId`, `cardsCount`,
  `provider`, `lookupSource`.
- No token, card number or CVV in logs.

Risks:

- Listing a card owned by another tenant or user.
- Treating stale token metadata as valid without provider reconciliation.

## `POST /users/{userId}/payment-methods/credit-cards`

Objective:

Register a new card token for future reuse and persist only allowed metadata.

Expected request:

```json
{
  "provider": "ASAAS",
  "remoteIp": "203.0.113.10",
  "creditCard": {
    "holderName": "Cliente Sandbox Magazine Siara",
    "number": "4111111111111111",
    "expiryMonth": "12",
    "expiryYear": "2030",
    "ccv": "123"
  },
  "creditCardHolderInfo": {
    "name": "Cliente Sandbox Magazine Siara",
    "email": "sandbox@example.com",
    "cpfCnpj": "11144477735",
    "phone": "11987654321"
  }
}
```

Expected response:

```json
{
  "cardId": "card-sandbox-visa-001",
  "brand": "VISA",
  "last4": "1111",
  "expiryMonth": "12",
  "expiryYear": "2030",
  "active": true
}
```

Expected errors:

- `400` for invalid holder data, expired card or missing `remoteIp`.
- `402` for provider refusal.
- `409` for duplicate active token metadata.
- `422` when Security has not approved this flow for the current environment.
- `502` for provider/tokenization failure.

Generated events:

- `payment.card.token.registration_requested`
- `payment.card.token.registered`
- `payment.card.token.registration_failed`

Expected observability:

- Dimensions: `tenantId`, `userId`, `provider`, `correlationId`, `brand`,
  `last4`, `providerStatus`, `failureReason`.
- Mask or suppress `creditCard`, CVV, full number, holder document and provider
  token in logs.

Risks:

- Expanding PCI scope by letting raw card data transit Payments.
- Persisting raw card data by accident in logs, traces, dead-letter queues or
  request archives.
- Using `remoteIp` from the server instead of the payer.

## `POST /invoices/credit-card`

Objective:

Create a credit-card invoice as a dedicated contract instead of relying only on
`billingType: CREDIT_CARD`.

Expected request:

```json
{
  "tenantId": "magazine-siara",
  "orderId": "MS-TEST-1",
  "customer": {
    "id": "customer-sandbox-001",
    "name": "Cliente Sandbox Magazine Siara",
    "document": "11144477735",
    "email": "sandbox@example.com",
    "mobilePhone": "11987654321"
  },
  "amount": 109.8,
  "currency": "BRL",
  "dueDate": "2026-07-09",
  "provider": "ASAAS",
  "cardFlow": "HOSTED_INVOICE"
}
```

Expected response:

```json
{
  "invoiceId": "invoice-123",
  "orderId": "MS-TEST-1",
  "provider": "ASAAS",
  "providerPaymentId": "pay_123",
  "status": "OPEN",
  "paymentUrl": "https://www.asaas.com/i/pay_123"
}
```

Expected errors:

- `400` for invalid customer or amount.
- `409` for duplicate idempotency key.
- `422` when the requested `cardFlow` is not enabled.
- `502` for provider failure.

Generated events:

- `payment.card.hosted_invoice.created`
- `payment.card.invoice.create_failed`

Expected observability:

- Dimensions: `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`,
  `cardFlow`, `provider`, `correlationId`, `idempotencyKey`.

Risks:

- Checkout treating hosted URL creation as payment confirmation.
- Provider status differences hidden behind `OPEN`.

## `POST /invoices/{invoiceId}/pay-with-credit-card`

Objective:

Pay an existing invoice using a saved card token or a new transient card payload.

Expected request with saved card:

```json
{
  "mode": "SAVED_CARD",
  "cardId": "card-sandbox-visa-001",
  "remoteIp": "203.0.113.10"
}
```

Expected request with new card:

```json
{
  "mode": "NEW_CARD",
  "saveCard": true,
  "remoteIp": "203.0.113.10",
  "creditCard": {
    "holderName": "Cliente Sandbox Magazine Siara",
    "number": "4111111111111111",
    "expiryMonth": "12",
    "expiryYear": "2030",
    "ccv": "123"
  },
  "creditCardHolderInfo": {
    "name": "Cliente Sandbox Magazine Siara",
    "email": "sandbox@example.com",
    "cpfCnpj": "11144477735",
    "phone": "11987654321"
  }
}
```

Expected response:

```json
{
  "invoiceId": "invoice-123",
  "status": "AUTHORIZED",
  "providerPaymentId": "pay_123",
  "card": {
    "cardId": "card-sandbox-visa-001",
    "brand": "VISA",
    "last4": "1111"
  }
}
```

Expected errors:

- `400` for missing `remoteIp`, invalid card or unsupported mode.
- `402` for authorization refusal.
- `403` when card does not belong to user/tenant.
- `409` for already paid invoice or idempotency conflict.
- `422` when raw-card transit is disabled.
- `504` for provider timeout with unknown outcome.

Generated events:

- `payment.card.authorization.requested`
- `payment.card.authorized`
- `payment.card.risk_analysis.awaiting`
- `payment.card.refused`
- `payment.card.token.registered` when `saveCard` succeeds

Expected observability:

- Dimensions: `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`,
  `cardMode`, `cardId`, `brand`, `last4`, `providerStatus`, `correlationId`.
- Never log raw `creditCard`, CVV or token value.

Risks:

- Double capture from repeated pay calls without idempotency.
- Incorrect ownership validation of saved card.
- Unknown provider outcome after timeout.

## `POST /invoices/{invoiceId}/cancel`

Objective:

Cancel an unpaid/open invoice before payment confirmation.

Expected request:

```json
{
  "reason": "CUSTOMER_ABORTED_CHECKOUT"
}
```

Expected response:

```json
{
  "invoiceId": "invoice-123",
  "status": "CANCELLED"
}
```

Expected errors:

- `404` when invoice does not exist.
- `409` when invoice is already confirmed/received/refunded.
- `502` for provider cancellation failure.

Generated events:

- `payment.card.invoice.cancel_requested`
- `payment.card.invoice.cancelled`

Expected observability:

- Dimensions: `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`,
  `previousStatus`, `reason`.

Risks:

- Calling cancellation for a confirmed card payment and hiding a refund need.

## `POST /invoices/{invoiceId}/refund`

Objective:

Request refund or reversal for a confirmed card payment.

Expected request:

```json
{
  "reason": "CUSTOMER_REQUEST",
  "amount": 109.8
}
```

Expected response:

```json
{
  "invoiceId": "invoice-123",
  "status": "REFUND_REQUESTED",
  "refundId": "refund-123"
}
```

Expected errors:

- `400` for invalid amount or missing reason.
- `404` when invoice does not exist.
- `409` when invoice is not confirmed/received.
- `422` when partial refund is not supported.
- `502` for provider refund failure.

Generated events:

- `payment.card.refund.requested`
- `payment.card.refunded`
- `payment.card.refund_failed`

Expected observability:

- Dimensions: `tenantId`, `orderId`, `invoiceId`, `providerPaymentId`,
  `refundId`, `amount`, `reason`, `providerStatus`.

Risks:

- Treating refund request as settled refund before provider confirmation.
- Releasing stock/order compensation before refund evidence exists.

---

# Credit Card Storage and Tokenization

## Asaas model to validate

- Use `creditCard` only when Payments receives raw card data for immediate
  provider submission or tokenization. This keeps Payments inside the card data
  transit path and needs Security approval.
- Use `creditCardHolderInfo` with new-card submission because Asaas uses holder
  identity and contact data for authorization/risk checks.
- Use `creditCardToken` when paying with a previously tokenized card. In that
  mode, raw `creditCard` and `creditCardHolderInfo` should not be sent again.
- Use `remoteIp` from the payer context for transparent card authorization and
  antifraud. It must not be replaced by the Payments server IP.
- Use tokenization when Product wants saved-card reuse or faster checkout.

## Data that may be persisted

- Internal `cardId`.
- Provider name.
- Provider customer id.
- Provider token reference, encrypted or protected as a secret.
- User id and tenant id.
- Brand.
- Last 4 digits.
- Expiry month and year.
- Holder display name when approved by privacy/security.
- Active/revoked status.
- Created, updated and last-used timestamps.
- Audit metadata without raw card data.

## Data that must not be persisted

- Full card number.
- CVV/CCV.
- Raw `creditCard` payload.
- Full provider token in logs, traces, analytics, screenshots or dead-letter
  payloads.
- Sensitive holder document in unmasked logs.

## Representation

```json
{
  "cardId": "card-sandbox-visa-001",
  "userId": "customer-sandbox-001",
  "tenantId": "magazine-siara",
  "provider": "ASAAS",
  "providerCustomerId": "cus_123",
  "providerTokenRef": "secret://payments/cards/card-sandbox-visa-001",
  "brand": "VISA",
  "last4": "1111",
  "expiryMonth": "12",
  "expiryYear": "2030",
  "active": true
}
```

---

# Saved Cards Listing

Payments should be the source for saved card metadata visible to Cart/Checkout.
Cart/Checkout must receive only display-safe fields and the internal `cardId`.
The actual provider token remains owned by Payments.

Open questions:

- Should card metadata be reconciled with Asaas on every listing or only during
  payment?
- What is the retention policy for expired or revoked cards?
- Which user identity source owns user-card association?

---

# New Card Registration

New card registration is a separate capability from invoice creation.

For Upstream, the Validation Workbench may generate a disposable card token and
metadata to validate UX and payload shape. Production registration must use
provider tokenization, secure token storage and masked observability.

Pending decisions:

- Whether Payments is allowed to receive raw card data.
- Whether tokenization happens before payment or only during first payment.
- Whether save-card consent is mandatory and how it is audited.

---

# Pay with Saved Card

Saved-card payment should send `cardId` to Payments, not `creditCardToken` to
Cart/Checkout. Payments resolves `cardId` to provider token, validates ownership
and sends `creditCardToken` plus `remoteIp` to Asaas.

The current API intentionally rejects tokenized fields in `POST /invoices`
because this is not yet Downstream-approved. This rejection is valid executable
evidence that tokenized payment cannot accidentally become production behavior.

---

# Pay with New Card

New-card payment should be treated as a higher-risk flow. It may include raw
`creditCard` and `creditCardHolderInfo` in the request to Payments only after a
formal Security/Architecture decision.

Until approved, the Workbench can generate the request shape and validate that
the API boundary rejects raw card fields.

---

# Asaas Payload Mapping

| Payments concept | Asaas field | When used | Storage rule |
| --- | --- | --- | --- |
| Hosted invoice | `billingType: CREDIT_CARD` without card fields | First Downstream candidate | No card data stored |
| New card data | `creditCard` | Direct new-card submission/tokenization | Transient only; never persist |
| Holder data | `creditCardHolderInfo` | New-card submission/tokenization | Persist only approved non-sensitive metadata |
| Saved card token | `creditCardToken` | Pay with saved card | Store protected token reference, never expose to Checkout |
| Payer IP | `remoteIp` | Transparent card authorization/risk analysis | Store only if approved for audit/fraud evidence |
| Authorization state | card webhook events | Authorization/risk/refusal/confirmation | Store status and provider ids |

---

# Validation Workbench Screens

Updated Workbench expectations:

- Select credit card in checkout payload.
- Choose `HOSTED_INVOICE`, `SAVED_CARD` or `NEW_CARD`.
- List locally saved cards with brand, last 4 digits and expiry.
- Select a saved card and generate tokenized payload shape.
- Register a new disposable card in the Workbench card list.
- Generate raw new-card payload shape for boundary validation.
- Simulate authorization approved with `PAYMENT_AUTHORIZED`.
- Simulate authorization refused with `PAYMENT_CREDIT_CARD_CAPTURE_REFUSED`.
- Simulate risk analysis with `PAYMENT_AWAITING_RISK_ANALYSIS`,
  `PAYMENT_APPROVED_BY_RISK_ANALYSIS` and
  `PAYMENT_REPROVED_BY_RISK_ANALYSIS`.
- Simulate confirmation with `PAYMENT_CONFIRMED`.
- Simulate cancellation with invoice deletion before confirmation.
- Simulate refund/reversal with `PAYMENT_REFUNDED`.

---

# Security and PCI Boundary

Current decision:

- Hosted card entry is the safest first Downstream slice.
- Saved-card and new-card flows remain Upstream until Security and Architecture
  approve token ownership, raw-card transit and observability masking.
- Direct raw card capture must not enter production by accident.

Required controls before Downstream:

- Explicit environment gate for raw-card transit.
- Request/response log redaction.
- Trace and error sanitizer.
- No raw card data in persistence, queues or dead-letter topics.
- Token storage protected as secret material.
- Ownership check on every saved-card operation.
- Idempotency key required for payment attempts.
- Timeout and unknown-outcome recovery plan.

---

# BDD Scenarios Required

Add or keep BDD coverage for:

- Listing saved cards for a user.
- Rejecting saved-card listing for a mismatched tenant/user.
- Registering a new card token while persisting only allowed metadata.
- Rejecting raw card persistence.
- Paying with a saved card using `cardId` and `remoteIp`.
- Paying with a new card only when the capability is explicitly enabled.
- Mapping authorization, confirmation, receipt, risk analysis and refusal.
- Blocking cancellation of confirmed card payments and routing to refund.
- Publishing `payment.confirmed` exactly once.
- Distinguishing simulated Workbench states from Asaas Sandbox evidence.

---

# Code Produced

Experimental code produced:

- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`

The Workbench now supports hosted card entry, saved-card selection, disposable
card registration and new-card payload exploration.

Existing Payments API code remains intentionally conservative: tokenized and
raw-card fields are rejected in `POST /invoices` until Downstream approval.

---

# Functional Validation

Use the Validation Workbench to validate:

- hosted invoice payload;
- saved-card payload shape;
- new-card payload shape;
- API rejection of unsupported raw/tokenized fields;
- cancellation before confirmation;
- webhook processing for authorization, confirmation, receipt, risk, refusal and
  refund simulation.

Expected validation evidence:

- Workbench build succeeds.
- Acceptance tests remain green.
- Screenshots or manual notes may be attached in a later Upstream entry when a
  human validates the flows visually.

---

# Technical Findings

Validated APIs:

- Asaas `POST /v3/payments`
- Asaas `POST /v3/payments/{id}/payWithCreditCard`
- Asaas `DELETE /v3/payments/{id}`

Relevant Asaas concepts:

- `creditCard`
- `creditCardHolderInfo`
- `creditCardToken`
- `remoteIp`
- payment webhooks for authorization, confirmation, receipt, deletion, refund,
  risk analysis and capture refusal.

Current architecture supports:

- `CREDIT_CARD` billing type for hosted entry;
- generic provider charge creation;
- payment deletion for unpaid invoice cancellation;
- webhook processing for confirmed, received, deleted and card-specific events.

Remaining gaps:

- saved-card storage model;
- token secret handling;
- `cardId` to provider token resolution;
- ownership validation;
- refund endpoint;
- timeout/unknown-outcome recovery;
- final OBC targets.

---

# Business Findings

Credit card is not one flow. It splits into at least three product options:

- hosted card entry, lower PCI burden and fastest Downstream candidate;
- saved-card reuse, better checkout UX but requires token storage and ownership
  rules;
- new-card transparent entry, highest UX control and highest security/compliance
  responsibility.

Product must decide whether the first delivery is only hosted card entry or also
includes saved-card reuse.

---

# Architecture Impact

Confirmed:

- Payments should own provider token resolution and webhook mapping.
- Cart/Checkout should use `cardId`, not provider token, for saved cards.
- Hosted entry can move faster because it avoids card data transit through
  Payments.

Rejected for now:

- Sending raw card data through `POST /invoices` as normal production behavior.
- Exposing `creditCardToken` directly to Cart/Checkout as the reusable public
  identifier.

Open questions:

- Where should token material be stored and rotated?
- Does Asaas tokenization require a payment attempt or can it be done as a
  standalone registration for the target account?
- What exact refund/reversal API and operational approval path should be used?
- What consent/audit record is required for saving cards?

---

# Reliability Impact

The Reliability Plan should include:

- timeout and unknown-outcome recovery for card authorization;
- duplicate payment protection for saved-card and new-card attempts;
- webhook retries and deduplication by provider id and event id;
- authorization, risk-analysis and refusal observability;
- PCI boundary and log redaction risks;
- refund vs cancellation distinction;
- saved-card ownership validation;
- token storage compromise response.

---

# Artifacts Updated

- `prodops/upstream/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/upstream-trail.md`
- `prodops/upstream/learnings.md`
- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrado: hoje `prodops/artifacts/bdd/credit-card-payment.feature`)
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/obcs/credit-card-authorization-confirmation.md`
- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|----------|--------|----------|
| Can the current Payments API create a credit card invoice? | Answered | Hosted `CREDIT_CARD` invoice shape exists and raw/tokenized fields are intentionally rejected. |
| Can Cart/Checkout list saved cards through Payments? | Partially Answered | Contract proposed; persistence and ownership implementation pending. |
| Can Payments keep token metadata safely? | Partially Answered | Allowed and forbidden data classified; secret storage decision pending. |
| Can a saved card be paid through a provider token? | Partially Answered | Contract maps `cardId` to `creditCardToken` plus `remoteIp`; Downstream implementation pending. |
| Can a new card be registered and reused? | Partially Answered | Workbench validates shape; Security/Architecture decision pending. |
| Are provider-specific states understood? | Answered | Authorization, confirmation, receipt, risk, refusal, deletion and refund states mapped. |
| Which capture model should move first? | Answered for first slice | Hosted entry remains first Downstream candidate; saved/new card require decisions. |

---

# New Backlog Items

| Item | Classification | Priority |
|------|----------------|----------|
| Implement saved-card metadata store with protected provider token reference. | Candidate for Upstream or Downstream after Security approval | P0 |
| Define Cart/Checkout contract for card listing and saved-card payment. | Repository Tracking List | P0 |
| Decide whether raw-card transit through Payments is allowed. | Security/Architecture decision | P0 |
| Define refund endpoint and financial reconciliation boundary. | Repository Tracking List | P0 |
| Add OpenAPI draft for card endpoints. | Candidate for Upstream | P1 |

---

# Recommendation

- [ ] Move Downstream
- [x] Run another Upstream experiment
- [x] Wait for business decision
- [x] Wait for security/architecture decision
- [ ] Wait for external dependency
- [ ] Discard capability

Recommendation:

- Move only the hosted card entry subset toward Assessment/Downstream.
- Keep saved-card and new-card flows in Upstream until token storage,
  ownership, consent, PCI boundary and refund policy are decided.
- Run a focused Upstream experiment for secure saved-card token storage and
  provider token lifecycle.

---

# Open Questions

- Is saving cards a must-have for the first business release or a later
  capability?
- Who owns save-card consent and card deletion UX?
- What data classification applies to provider card tokens?
- Should Payments store `remoteIp` for audit or only forward it to Asaas?
- How will Cart/Checkout handle risk-analysis pending state?
- What is the financial approval path for partial or full refund?

---

# Decision Package

## Executive Summary

Credit card support remains feasible. Hosted card entry is ready to be prepared
for Assessment because it keeps Payments outside raw card data handling.
Saved-card reuse and new-card registration need one more security and
architecture pass before Downstream.

## Recommended Decision

Prepare hosted card entry for Downstream Assessment. Keep tokenized saved-card
and new-card registration as Upstream.

## Updated Risks

- PCI boundary expansion through raw card transit.
- Token compromise or accidental exposure in logs/traces.
- Saved-card ownership mismatch.
- Unknown provider outcome after timeout.
- Risk-analysis pending state without Checkout feedback.
- Refund/cancellation confusion after confirmation.

## Updated Opportunities

- Faster first delivery with hosted card entry.
- Improved conversion later with saved-card reuse.
- Provider-agnostic `cardId` contract keeps Cart/Checkout independent from Asaas.

## Updated Tracking Items

- Define saved-card contract.
- Decide token storage/security boundary.
- Decide new-card registration model.
- Define refund/reversal contract.

## Updated OBCs

OBC draft now includes saved-card listing, token registration, authorization and
refund events.

## Updated Reliability Plan

Reliability risks now include PCI boundary, token storage, ownership validation,
`remoteIp`, timeout, risk analysis and refund distinction.

## Recommended Downstream Scope

Only hosted card entry should be considered for the next Downstream slice.
Saved-card and new-card flows need additional decisions and possibly a focused
Upstream experiment.

---

# Exit Criteria

- [x] Original hypothesis answered
- [x] Questions classified
- [x] Knowledge gaps documented
- [x] Architecture impact documented
- [x] Reliability impact documented
- [x] Validation Workbench updated for functional exploration

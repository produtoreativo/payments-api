# EXP-003 - Hosted Checkout vs Tokenized Credit Card

## Status

- [ ] Planned
- [x] In Progress
- [ ] Completed
- [ ] Cancelled

---

# Business Goal

Select the first production-ready credit card payment model for the Payments
API.

The objective is to compare the available integration models supported by Asaas
and identify the one that provides the best balance between customer experience,
implementation effort, security, observability and reliability.

The selected model will become the first Downstream implementation.

---

# Repository Scope Gate

## Repository-owned scope

- [x] Payments API behavior
- [x] Payments domain logic
- [x] Provider integration
- [x] Webhook handling
- [ ] Persistence
- [x] API/event contract owned by Payments
- [x] Validation Workbench behavior
- [x] Local tests or executable evidence

## External dependencies

- Checkout UX for hosted redirect and tokenized entry.
- Security/compliance decision for direct raw card capture.
- Asaas Sandbox support for each payment model.
- Antifraud policy and risk-analysis handling.

## Scope decision

- [x] Continue as executable Upstream experiment in this repository
- [ ] Record only as external dependency or release risk
- [ ] Redirect to owning repository or team

Payments API can compare contract, provider and webhook implications. Checkout
UX, compliance and antifraud approvals remain external inputs.

---

# Question to Answer

Which payment capture model should become the standard for the Payments API?

The experiment must compare:

- Hosted Checkout or hosted Asaas invoice URL.
- Tokenized Credit Card.
- Direct Credit Card Capture.

The comparison should consider both technical and business aspects.

---

# Hypothesis

Hosted Checkout will be the best first Downstream implementation because it
minimizes implementation complexity, reduces PCI scope and allows the current
Payments API architecture to be reused with minimal changes.

Tokenized Card should become the second evolution.

Direct Card Capture is expected to require additional security, compliance and
reliability work before being considered.

---

# Scope

Included:

- Hosted Checkout model.
- Tokenized card model.
- Direct card capture as a risk/comparison item.
- API contract impact.
- DTO impact.
- Provider request impact.
- Webhook lifecycle.
- Observability and reliability requirements.
- Validation Workbench comparison.
- Recommended first Downstream slice.

---

# Out of Scope

Not included:

- Checkout UI implementation.
- Direct raw card capture implementation.
- PCI/compliance approval.
- Production rollout.
- Gateway fallback.

---

# Implementation

Study each payment model using the official Asaas documentation.

For each model evaluate:

- implementation complexity;
- required API contracts;
- DTO changes;
- required frontend changes;
- checkout experience;
- webhook lifecycle;
- observability requirements;
- timeout behavior;
- retry behavior;
- idempotency;
- rollback strategy;
- refund strategy;
- PCI implications;
- LGPD implications.

Document every architectural impact.

## Validation Workbench

Update the Validation Workbench to simulate all supported payment models.

The Workbench should allow switching between:

- Hosted Checkout.
- Tokenized Card.
- Direct Card Capture, simulation only if unsupported.

The objective is to compare the complete business flow of each option.

---

# Code Produced

Exploratory code may be produced only for the Validation Workbench or local
Payments API evidence.

No direct card capture implementation should be produced in this repository
unless a future Downstream decision explicitly approves it.

---

# Functional Validation

Validate for each model:

- invoice creation;
- customer payment flow;
- payment confirmation;
- authorization;
- risk analysis;
- payment receipt;
- payment cancellation;
- refund;
- webhook processing;
- error scenarios.

---

# Technical Findings

## Technical Comparison

| Capability | Hosted Checkout | Tokenized Card | Direct Card |
|------------|-----------------|----------------|-------------|
| API Complexity | Low, can reuse generic invoice creation. | Medium, requires token fields and provider request changes. | High, requires raw card fields and sensitive-data handling. |
| Frontend Complexity | Medium, redirect or hosted payment UX. | Medium/high, token collection UX. | High, full card-entry UX and validation. |
| Backend Complexity | Low/medium. | Medium/high. | High. |
| PCI Scope | Lowest. | Lower than raw capture, but token ownership must be clear. | Highest. |
| Security | Best first slice. | Requires token and ownership controls. | Requires explicit security/compliance approval. |
| Idempotency | Similar to invoice creation. | Requires card authorization retry rules. | Requires strict duplicate capture protection. |
| Observability | Webhook-driven confirmation. | Needs authorization, risk and refusal states. | Needs full card-state observability. |
| Retry Strategy | Retry invoice creation and webhook processing. | Must avoid duplicate card capture. | Must avoid duplicate card capture and raw-data exposure. |
| Webhook Support | Required for confirmation/receipt. | Required for authorization, risk and confirmation. | Required for all card states. |
| Refund Flow | Required after confirmation. | Required after confirmation. | Required after confirmation. |
| User Experience | Possible hosted handoff. | Better embedded UX if approved. | Best control, highest risk. |
| Reliability | Best initial reliability profile. | Requires more state handling. | Highest operational risk. |
| Operational Complexity | Lowest. | Medium/high. | Highest. |

---

# Business Findings

Evaluate:

- customer experience;
- checkout conversion;
- abandonment risk;
- fraud exposure;
- operational support effort;
- future extensibility.

Current finding:

- Hosted Checkout is the safest first slice because it minimizes sensitive card
  handling.
- Tokenized Card remains a likely second evolution.
- Direct Card Capture should remain out of scope until security, compliance and
  antifraud explicitly approve it.

---

# Architecture Impact

Confirmed:

- Hosted Checkout can reuse the current Payments API gateway shape.
- Tokenized Card requires DTO and provider request changes.
- Direct Card Capture changes the security and compliance boundary.

Rejected:

- Direct Card Capture as the first Downstream slice.

Open questions:

- Checkout UX acceptance for hosted redirect.
- Token ownership and lifecycle.
- Exact state mapping for risk analysis and refusal.
- Refund/reversal contract.

---

# Reliability Impact

For each payment model identify:

- additional risks;
- required mitigations;
- required telemetry;
- required SLOs;
- required dashboards;
- rollback strategy;
- deployment strategy.

Current reliability impact:

- Hosted Checkout has the lowest first-slice reliability risk.
- Tokenized Card requires timeout, refusal, risk-analysis and duplicate-capture
  controls.
- Direct Card Capture should not proceed without a formal security and
  compliance decision.

---

# Artifacts Updated

Update when necessary:

- Product Deck.
- Service Deck.
- Repository Tracking List.
- Reliability Plan.
- Event Storming.
- OBC.
- BDD Features.
- Validation Workbench.

---

# Knowledge Gaps Closed

| Question | Status | Evidence |
|----------|--------|----------|
| Which model is safest as the first Downstream slice? | Answered | Hosted Checkout has the lowest API, security and operational complexity. |
| Can Tokenized Card be a future evolution? | Partially Answered | It is viable but needs DTO, token ownership, timeout and risk-state decisions. |
| Should Direct Card Capture be first? | Answered | No. It requires security/compliance approval and has the highest risk. |
| Can Checkout accept hosted payment UX? | Still Unknown | Requires Checkout/Product evidence. |
| Can sandbox reproduce the hosted/tokenized lifecycle? | Still Unknown | Requires EXP-002 evidence. |

---

# New Backlog Items

| Item | Classification | Priority |
|------|----------------|----------|
| Review hosted payment UX with Checkout/Product. | Repository Tracking List | P0 |
| Define token ownership before tokenized card Downstream. | Repository Tracking List | P0 |
| Keep direct raw card capture outside first slice. | Discarded for first slice | P0 |
| Define refund/reversal boundary for card payment. | Candidate for Iteration Backlog | P0 |

---

# Recommendation

- [x] Move Downstream
- [ ] Run another Upstream experiment
- [ ] Wait for business decision
- [ ] Wait for external dependency
- [ ] Discard capability

Move only the Hosted Checkout / hosted Asaas invoice URL slice to Downstream
after Product and Tech Lead confirm the UX and acceptance criteria.

Tokenized Card remains Upstream. Direct Card Capture remains out of scope for
the first slice.

---

# Decision Package

## Executive Summary

Hosted Checkout is the recommended first credit card payment model for Payments
API because it minimizes PCI exposure, reuses the existing invoice creation
shape and has the lowest operational complexity.

## Recommended Decision

Move Hosted Checkout to Downstream after Product and Tech Lead approval.

## Updated Risks

- Hosted redirect may affect checkout conversion.
- Webhook confirmation remains required.
- Refund boundary must be defined before release.
- Tokenized and direct card flows must not leak into the first slice.

## Updated Opportunities

- Add credit card support with limited backend change.
- Preserve future evolution path to Tokenized Card.

## Updated Tracking Items

- Product/Checkout UX review.
- Refund/reversal boundary.
- Tokenized Card as future evolution.

## Updated OBCs

Draft OBC: `prodops/journeys/discovery/obcs/credit-card-authorization-confirmation.md`.

## Updated Reliability Plan

Reliability Plan should reflect hosted card risks separately from tokenized and
direct capture risks.

## Recommended Downstream Scope

- Create Credit Card Invoice.
- Redirect customer to hosted Asaas invoice/card URL.
- Receive `PAYMENT_CONFIRMED` webhook.
- Update invoice status.
- Publish internal payment event.
- Register Release Trail evidence.

---

# Output Artifacts

Lista os artefatos de produto gerados ou promovidos por este experimento.

## Artefatos gerados

| Tipo | Artefato | Situação |
|---|---|---|
| OBC draft | `prodops/journeys/discovery/experiments/003-hosted-vs-tokenized/obcs/credit-card-authorization-confirmation.md` | Draft — mover para `prodops/artifacts/business/obcs/` ao promover |
| BDD Feature | — | Pendente |

**Promovido para Downstream:** Não — experimento em andamento.
**Nota:** Influenciou a aprovação do hosted slice via EXP-001 (2026-07-07). Tokenized e saved-card aguardam decisões de Security e Product.

---

# Exit Criteria

- [x] Original hypothesis answered
- [x] Questions classified
- [x] Knowledge gaps documented
- [x] Architecture impact documented
- [x] Reliability impact documented
- [x] Artifacts updated
- [x] Recommendation produced
- [x] Decision Package completed

---

# Next Step

Prepare Downstream intake for the hosted card slice after Product and Tech Lead
confirm Checkout UX and acceptance criteria.

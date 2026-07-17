# Upstream Trail - EXP-003

## Experiment

Reference:

`prodops/journeys/discovery/experiments/003-hosted-vs-tokenized/experiment.md`

---

# History

> Append new entries below.
> Never rewrite previous entries.

## 2026-07-02 16:40

### Activity

Updated BDD Features to reflect the existing Upstream experiments.

### Summary

The credit card BDD now includes hosted confirmation, financial receipt,
tokenized-card constraints, risk-analysis events, sandbox/simulation evidence
and the decision to keep direct raw card capture out of the first Downstream
slice.

This entry was migrated from the global trail and also relates to EXP-001,
EXP-002 and the missing EXP-004 reference.

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

## 2026-07-02 17:10

### Activity

Updated Payments API code according to the executable scope of the credit card
experiments.

### Summary

The API now makes the first credit-card slice explicit: `CREDIT_CARD` is treated
as hosted card entry and rejects tokenized or direct card data fields in
`POST /invoices`. This prevents the tokenized/direct-card experiments from
silently becoming unsupported production behavior.

Webhook handling now records card-specific Asaas events such as authorization,
risk analysis and capture refusal as observable card events. Authorization and
risk-analysis events do not publish `payment.confirmed`; capture refusal and
risk reproval mark the invoice as failed when the payment has not already been
confirmed or received.

### Artifacts Updated

- `api/src/modules/invoices/dto/create-invoice.dto.ts`
- `api/src/modules/invoices/services/invoice.service.ts`
- `api/test/create-invoice.acceptance.e2e-spec.ts` (renamed: now `api/test/criar-invoice.e2e-spec.ts`)

### Evidence

- `npm run test:acceptance` in `api/` passed with 26 tests.
- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Ready for Assessment.

### Notes

This entry also relates to EXP-001.

## 2026-07-07

### Activity

Decision Package reviewed and approved. Capability moved to Downstream delivery flow.

### Summary

PM approved the hosted card slice for Downstream. Decision Package recommendation
`Move Hosted Checkout to Downstream` was accepted. Scope restricted to hosted
card entry only — tokenized card, saved-card and direct capture remain Upstream.

### Participants

- Christiano Milfont (PM Payments) — approved

### Decision

Move to Downstream.

### Artifacts Updated

- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrated: now `prodops/artifacts/bdd/credit-card-payment.feature`) → `prodops/artifacts/bdd/credit-card-payment.feature`
- `prodops/journeys/discovery/obcs/credit-card-authorization-confirmation.md` → `prodops/artifacts/obcs/credit-card-authorization-confirmation.md` (draft marking removed)
- `prodops/artifacts/governance/plans/iteration-plan.md` — entry added: Create Credit Card Invoice (Hosted)
- `prodops/artifacts/product/tracking-list.md` — status: Candidate → Promoted to Downstream

### Next Steps

- Bootstrap: create branch for credit card hosted slice
- Hack: implement `POST /invoices` with `billingType: CREDIT_CARD` returning `paymentUrl` from Asaas
- BDD Feature `credit-card-payment.feature` is the source of scenarios for TDD

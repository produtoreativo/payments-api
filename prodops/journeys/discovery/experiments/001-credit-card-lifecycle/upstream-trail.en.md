# Upstream Trail - EXP-001

## Experiment

Reference:

`prodops/journeys/discovery/experiments/001-credit-card-lifecycle/experiment.md`

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

This entry was migrated from the global trail and also relates to EXP-002,
EXP-003 and the missing EXP-004 reference.

### Artifacts Updated

- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrated: now `prodops/artifacts/bdd/credit-card-payment.feature`)
- `prodops/journeys/discovery/features/checkout-gateway-feature-flag.feature` (removed: no successor in `prodops/artifacts/bdd/`; gap recorded in the global Discovery trail)

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

This entry also relates to EXP-003.

## 2026-07-02 17:48

### Activity

Expanded the Asaas credit card lifecycle experiment to cover Cart/Checkout to
Payments contracts, saved-card listing, new-card registration, tokenization
boundary and Validation Workbench exploration.

### Summary

The experiment now separates hosted card entry, saved-card payment and new-card
submission. Hosted entry remains the safest Downstream candidate. Saved-card and
new-card flows remain Upstream until Product, Security and Architecture decide
token storage, ownership, consent, PCI boundary, `remoteIp` handling and refund
policy.

The Validation Workbench now lets agents and humans explore hosted card,
saved-card and new-card payload shapes, including disposable local card
registration and webhook simulation for authorization, risk analysis,
confirmation, refusal, cancellation and refund.

### Artifacts Updated

- `prodops/journeys/discovery/experiments/001-credit-card-lifecycle/experiment.md`
- `prodops/upstream/experiments.md`
- `prodops/upstream/learnings.md`
- `prodops/journeys/discovery/features/credit-card-payment.feature` (migrated: now `prodops/artifacts/bdd/credit-card-payment.feature`)
- `prodops/product/tracking-list.md`
- `prodops/journeys/assessment/risks.md`
- `prodops/upstream/obcs/credit-card-authorization-confirmation.md`
- `validation-workbench/src/App.tsx`
- `validation-workbench/src/styles.css`

### Evidence

- Migrated from `prodops/upstream/upstream-trail.md`.

### Decision

Continue experiment.

### Notes

Recommendation: move only hosted card entry toward Assessment. Keep saved-card
reuse and new-card registration in Upstream until token storage, PCI boundary,
consent and refund decisions are recorded.

## 2026-07-07

### Activity

PM approval: hosted card slice promoted to Downstream. Remaining flows stay Upstream.

### Summary

Only the hosted card entry slice was approved for Downstream, consistent with
the Decision Package recommendation. Saved-card, new-card registration and
tokenized card remain Upstream pending Security, Architecture and Product
decisions on token storage, PCI boundary, consent and refund contract.

### Participants

- Christiano Milfont (PM Payments) — approved hosted slice

### Decision

Partial promotion: hosted card entry → Downstream. Remaining flows → continue Upstream.

### Artifacts Updated

- Shared with EXP-003: BDD Feature and OBC moved to committed locations.
- Repository Tracking List items for saved-card, tokenized card and refund remain Open.

### Next Steps

- Saved-card and new-card registration: open new Upstream experiment when
  token storage, PCI and consent decisions are available.
- Refund boundary: requires Financial + Operations input before Downstream.

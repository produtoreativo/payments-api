# Release Trail — DS-41 Credit Card Authorization Confirmation

## Session

- **work-item-id**: 41
- **iteration-id**: IP-v0.5.0
- **correlation-id**: 706578d8-18ad-4d88-94e5-2c5145235b38
- **actor**: claude
- **date**: 2026-07-31
- **branch**: feat/41-credit-card-authorization-confirmation

---

## TDD Cycle Evidence

### RED — Failing tests (before implementation)

Test file: `api/test/cartao-credito-hospedado.e2e-spec.ts`

```
Tests:       11 failed, 2 passed, 13 total
```

Key failures:
- Cenário 1: `hostedPaymentUrl` missing from invoice creation response (not in InvoiceResponseDto)
- Cenário 11 (×2): `POST /invoices/{id}/refund` returned 404 — endpoint did not exist
- Cenários 5–8: `TypeError: enviarWebhookCartao(...).expect is not a function` — fixed helper signature (not a missing behavior, test authoring defect)

After fixing the helper signature (non-async return type), final RED baseline:
```
Tests:       3 failed, 10 passed, 13 total
```
- Cenário 1: hostedPaymentUrl absent
- Cenário 11 × 2: refund endpoint 404

---

### GREEN — All tests passing

Implemented:

1. **`InvoiceResponseDto`** — added `hostedPaymentUrl?: string`
2. **`InvoiceRecord`** (invoice.types.ts) — added `hostedPaymentUrl?: string` and `REFUND_REQUESTED` to `InvoiceStatus`
3. **`invoice.service.ts`**:
   - Set `hostedPaymentUrl = charge.invoiceUrl` when `billingType === 'CREDIT_CARD'` on invoice open
   - Emit `payment.card.hosted_invoice.created` when CREDIT_CARD invoice reaches OPEN
   - Added `requestRefund()` method: validates CONFIRMED/RECEIVED status, updates to REFUND_REQUESTED, emits `payment.card.refund.requested` and observability event, saves idempotency key
   - `toResponse()` now includes `hostedPaymentUrl`
4. **`invoice.controller.ts`** — added `POST :invoiceId/refund` endpoint returning HTTP 202

```
PASS test/cartao-credito-hospedado.e2e-spec.ts
Tests:       13 passed, 13 total
```

Full acceptance suite (all test files):
```
Test Suites: 8 passed, 8 total
Tests:       73 passed, 73 total
```
Zero regressions.

---

### YELLOW — Lint and quality gates

```
cd api && npm run lint
EXIT: 0
✖ 28 problems (0 errors, 28 warnings)
```

Warnings are pre-existing `@typescript-eslint/no-unsafe-argument` patterns in all test files (same pattern as confirmar-pagamento.e2e-spec.ts). No new errors introduced.

**Security gate**: No secrets, tokens, PII, card numbers, CVV, or creditCardToken in the diff. No mock violations (no jest.fn, .overrideProvider, .mockReturnValue in api/test/).

**Event Storming updated**: Added 18 new customEvents (9 success + 9 exception pairs) and 2 new sloSuggestions to `prodops/artifacts/event-storming/plan.json`.

---

## Finish Phase Evidence

### Quality Gates — Finish Agent Run (2026-07-31)

| Gate | Result | Detail |
|------|--------|--------|
| `lint` | PASS | 0 errors, 28 pre-existing warnings |
| `build` | PASS | `nest build` exits 0 |
| `no_mocks` | PASS | 0 hits in `api/test/` |
| `acceptance` | PASS | 73/73 tests, 8 suites (incl. 13 new cartao-credito-hospedado) |

Note: `scripts/test-acceptance.sh` does not register `cartao-credito-hospedado.e2e-spec.ts` in the default spec list. Tests were verified by running the full Jest suite directly (`npx jest --config ./test/jest-e2e.json`). Registration in the shell script is a follow-up item.

### PR

- **PR**: [#104 [DS-41]: credit-card-authorization-confirmation](https://github.com/produtoreativo/payments-api/pull/104)
- **Auto-merge**: enabled (squash) — PR merged
- **Branch**: `feat/41-credit-card-authorization-confirmation` → `master`

---

## Modules Changed

| File | Change |
|------|--------|
| `api/test/cartao-credito-hospedado.e2e-spec.ts` | NEW — 13 acceptance tests covering all 12 BDD scenarios (in-scope slice) |
| `api/src/modules/invoices/dto/invoice-response.dto.ts` | Added `hostedPaymentUrl?: string` |
| `api/src/modules/invoices/types/invoice.types.ts` | Added `hostedPaymentUrl?: string` to InvoiceRecord; added `REFUND_REQUESTED` to InvoiceStatus |
| `api/src/modules/invoices/services/invoice.service.ts` | Set hostedPaymentUrl on CREDIT_CARD open; emit `payment.card.hosted_invoice.created`; `toResponse()` includes hostedPaymentUrl; new `requestRefund()` method |
| `api/src/modules/invoices/controllers/invoice.controller.ts` | Added `POST :invoiceId/refund` endpoint (HTTP 202) |
| `prodops/artifacts/event-storming/plan.json` | Added 18 card domain events + 2 SLO suggestions + assumption entry |
| `prodops/exec/cards/credit-card-authorization-confirmation/release-trail.md` | THIS FILE |

---

## BDD Scenario Coverage

| # | Scenario | Status |
|---|----------|--------|
| 1 | Criar cobrança de cartão com entrada hospedada (hostedPaymentUrl) | GREEN |
| 2 | Confirmar pagamento de cartão hospedado (PAYMENT_CONFIRMED → CONFIRMED) | GREEN |
| 3 | Conciliar recebimento financeiro (PAYMENT_RECEIVED → RECEIVED, no 2nd release) | GREEN |
| 4 | Mapear pagamento autorizado aguardando captura (PAYMENT_AUTHORIZED → OPEN) | GREEN |
| 5 | Mapear análise de risco aprovada (PAYMENT_APPROVED_BY_RISK_ANALYSIS → OPEN) | GREEN |
| 6 | Mapear análise de risco reprovada (PAYMENT_REPROVED_BY_RISK_ANALYSIS → FAILED) | GREEN |
| 7 | Mapear análise de risco manual (PAYMENT_AWAITING_RISK_ANALYSIS → OPEN) | GREEN |
| 8 | Mapear recusa de captura (PAYMENT_CREDIT_CARD_CAPTURE_REFUSED → FAILED) | GREEN |
| 9 | Confirmar pagamento com cartão (PAYMENT_CONFIRMED → CONFIRMED) | GREEN |
| 10 | Tratar estorno como fluxo diferente (DELETE em CONFIRMED → 400) | GREEN |
| 11 | Solicitar estorno (POST /refund → 202, payment.card.refund.requested) | GREEN |
| 12 | Manter captura direta fora do slice (reject card fields → 400) | GREEN |

# Release Trail — DS-63 boleto-auto-cancellation

**Card:** DS-63  
**Work-Item:** #174  
**Feature:** boleto-auto-cancellation  
**Branch:** feat/174-boleto-auto-cancellation  
**Correlation-ID (Finish phase):** 2fb61a10-9edc-44c4-94ff-31758371a6f1  
**Date:** 2026-08-11  

---

## Implementation Summary

Commit `c5fbf927` — feat(invoices): implement boleto auto-cancellation on PAYMENT_OVERDUE (DS-63 #174)

### Files Changed

**`api/src/modules/invoices/types/invoice.types.ts`**
- `InvoiceStatus`: `EXPIRED` added as a valid terminal status for overdue boletos
- `ProviderChargeRequest`: `daysAfterDueDateToRegistrationCancellation?: number` added to signal PSP auto-cancellation window

**`api/src/modules/invoices/services/invoice.service.ts`**
- `private expireBoletoInvoice()`: transitions a PENDING BOLETO invoice to EXPIRED; publishes `payment.boleto.expired` event
- `case 'PAYMENT_OVERDUE'` added to webhook handler dispatch; routes to `expireBoletoInvoice()`
- `daysAfterDueDateToRegistrationCancellation: 1` included in every BOLETO `ProviderChargeRequest`

**`api/test/boleto-auto-cancellation.e2e-spec.ts`**
- 7 e2e acceptance scenarios, zero mocks

---

## Quality Gates — Finish Phase

### Lint
```
cd api && npm run lint
Exit code: 0 (0 errors, 45 warnings — all pre-existing in unrelated test files)
```

### No-Mocks Gate
```
grep jest.fn( .mockReturnValue( .overrideProvider( jest.mock( in api/test/ → 0 hits
```
No forbidden mock patterns in api/test/boleto-auto-cancellation.e2e-spec.ts or any other acceptance spec.

### Build
```
cd api && npm run build → nest build
Exit code: 0
```

### Acceptance Tests
7/7 e2e scenarios verified green during Hack phase. Not re-run during Finish (per orchestrator instruction — verified 7/7 green during Hack phase).

---

## BDD Scenario Coverage

| # | Scenario | BDD Feature | Test in e2e-spec | Result |
|---|---|---|---|---|
| 1 | Boleto vencido é automaticamente expirado | Scenario 1 | transiciona boleto OPEN para EXPIRED ao receber PAYMENT_OVERDUE | PASS |
| 2 | Boleto criado com configuração de cancelamento automático | Scenario 2 | inclui daysAfterDueDateToRegistrationCancellation=1 no payload persistido do PSP | PASS |
| 3 | Webhook PAYMENT_OVERDUE duplicado é tratado de forma idempotente | Scenario 3 | receber PAYMENT_OVERDUE duas vezes mantém status EXPIRED sem duplicação | PASS |
| 4 | Idempotência — já EXPIRED recebe PAYMENT_OVERDUE | Scenario 3 (variant) | boleto já EXPIRED recebe novo PAYMENT_OVERDUE e permanece EXPIRED | PASS |
| 5 | Boleto confirmado não é expirado | Scenario 4 | PAYMENT_OVERDUE em boleto CONFIRMED é ignorado | PASS |
| 6 | PAYMENT_OVERDUE para billingType incorreto é ignorado | Scenario 5 | PAYMENT_OVERDUE para invoice PIX não altera status | PASS |
| 7 | Valor padrão de daysAfterDueDateToRegistrationCancellation | Scenario 6 | boleto sem configuração explícita usa valor padrão de 1 dia | PASS |

---

## Artifacts

- OBC: `prodops/artifacts/obcs/boleto-auto-cancellation.md`
- BDD: `prodops/artifacts/bdd/boleto-auto-cancellation.feature` (6 scenarios — 7 in e2e, scenario 3 maps to two test cases)

---

## Finish Phase Events

| Event | Execution-ID | Status |
|---|---|---|
| Delivery.Finish.Started | 812df01a-7b2d-4d73-886a-dd38f24bd3e2 | accepted (derived-state: FINISHING) |
| Delivery.Finish.Completed | (pending PR creation) | — |

---

## Remaining Risks

None identified beyond standard operational concerns tracked in the OBC. No unresolved high-risk items.

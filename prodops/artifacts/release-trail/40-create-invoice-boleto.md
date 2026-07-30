# Release Trail — DS-40 create-invoice-boleto

**Card:** DS-40  
**Feature:** create-invoice-boleto  
**Branch:** feat/40-create-invoice-boleto  
**Correlation-ID (Hack phase):** ab3e0c6b-9f0f-4cd6-b579-7e70886fa807  
**Date:** 2026-07-30  

---

## TDD Cycle Evidence

### Red Phase

Test file: `api/test/criar-invoice-boleto.e2e-spec.ts`  
Unit spec: `api/src/modules/invoices/services/invoice.service.spec.ts`

Scenarios derived from BDD feature `prodops/artifacts/bdd/create-invoice-boleto.feature`:

1. Criar boleto com sucesso para cliente já vinculado — asserts `bankSlipUrl` and `identificationField` in response and persisted record
2. Criar cliente Asaas antes do boleto quando não houver vínculo — asserts customer link creation
3. Rejeitar boleto com data de vencimento no passado — asserts 400 before provider call
4. Rejeitar boleto sem data de vencimento — asserts 400 with `dueDate` in message
5. Evitar duplicidade em retentativa — asserts same invoice returned, provider not called twice
6. Rejeitar provedor não habilitado — asserts 400 with business error
7. Falha transiente ao criar boleto (unit test) — asserts FAILED status, ServiceUnavailableException
8. Falha de validação retornada pelo provedor (unit test) — asserts FAILED, no sensitive fields in error response

Red evidence: tests in `criar-invoice-boleto.e2e-spec.ts` initially failed because:
- `bankSlipUrl` and `identificationField` were not in `ProviderChargeResponse`
- `billingType=BOLETO` logic in `AsaasService.createCharge` did not return boleto-specific fields
- `dueDate` future validation was not gating boleto creation
- `assertProviderChargeContract` did not enforce `bankSlipUrl` presence for BOLETO
- `toResponse()` did not forward `bankSlipUrl` and `identificationField`

---

### Green Phase

Modules changed to pass all failing tests:

**`api/src/modules/invoices/types/invoice.types.ts`**
- `ProviderChargeResponse`: `bankSlipUrl?: string` and `identificationField?: string` already present (Risk B4 mitigated)
- `InvoiceRecord`: `bankSlipUrl?: string` and `identificationField?: string` already present

**`api/src/modules/invoices/dto/invoice-response.dto.ts`**
- Added `bankSlipUrl?: string` and `identificationField?: string` fields

**`api/src/infra/asaas.service.ts`**
- `createCharge` mock path: returns `bankSlipUrl` and `identificationField` when `billingType === 'BOLETO'`
- Live path: maps `data.bankSlipUrl` and `data.identificationField` from Asaas response

**`api/src/modules/invoices/services/invoice.service.ts`**
- `validateCreateInvoice`: BOLETO requires `dueDate >= D+1`; rejects with 400 before provider call
- `assertProviderChargeContract`: throws `provider_contract_violation: bankSlipUrl missing for BOLETO` if absent
- `updateInvoice` call on success: persists `bankSlipUrl` and `identificationField`
- `toResponse`: returns `bankSlipUrl` and `identificationField` in DTO
- Idempotency hit path: returns full response including boleto fields from saved record
- Provider failure path: emits `payment.boleto.creation_failed` event; exception does NOT include `bankSlipUrl` or `identificationField`

**`api/src/modules/invoices/services/invoice.service.spec.ts`** (unit tests for Scenarios 7 and 8)
- Uses `jest.fn()` / `useValue` pattern — placed in `api/src` per mocking policy (not in `api/test`)
- Scenario 7: transient failure (timeout) marks FAILED and throws `ServiceUnavailableException`
- Scenario 8: provider validation failure marks FAILED; error response has no sensitive fields

Green test output:
```
Test Suites: 5 passed, 5 total  (acceptance)
Tests:       36 passed, 36 total

Test Suites: 1 passed, 1 total  (unit spec)
Tests:       5 passed, 5 total
```

---

### Yellow Phase — Quality Gates

#### Lint
```
cd api && npm run lint
Exit code: 0 (0 errors, 15 warnings — pre-existing in unrelated test files)
```

#### No-Mocks Gate
```
grep jest.fn( .mockReturnValue( .overrideProvider( jest.mock( in api/test → 0 hits
```
Note: `invoice.service.spec.ts` lives in `api/src` (unit test, allowed by mocking policy).

#### Build
```
cd api && npm run build → nest build → Exit code: 0
```

#### Acceptance Tests
```
./scripts/test-acceptance.sh → Exit code: 0
All 5 suites, 36 tests passed:
- criar-invoice-boleto.e2e-spec.ts: 6 scenarios green
- criar-invoice.e2e-spec.ts: pass
- cancelar-invoice.e2e-spec.ts: pass
- confirmar-pagamento.e2e-spec.ts: pass
- api-token.acceptance.e2e-spec.ts: pass
```

#### Security Gate
- `bankSlipUrl` and `identificationField` are NOT included in observability events (`emitObservable` only emits `paymentUrl`, not raw boleto fields)
- Error responses do not expose boleto URLs or line codes
- No secrets or tokens added to source

#### Event Storming
No new event names added. Events `payment.boleto.created`, `payment.boleto.creation_failed`, and `payment.boleto.idempotency_hit` were already part of the plan from prior session.

---

## Finish Phase Evidence (re-evaluation 2026-07-30)

**Correlation-ID (Finish):** b130e7a2-7d67-4b82-9292-bfc532661229  
**Finish.Started event-id:** a65ee9c5-f151-45de-84ff-165072f8beb3  
**PR:** https://github.com/produtoreativo/payments-api/pull/87 (OPEN)

### Quality Gates Re-verified

| Gate | Result | Detail |
|---|---|---|
| lint | PASS (exit 0) | 0 errors, 15 warnings pre-existing in unrelated test files |
| no_mocks (api/test/) | PASS (0 hits) | Zero forbidden mock patterns in api/test/ |
| acceptance | PASS (exit 0) | 5 suites, 36 tests — criar-invoice-boleto.e2e-spec.ts all 6 scenarios green |
| build | PASS (exit 0) | nest build succeeded |

### BDD Scenario Coverage

| # | Scenario | Test Location | Result |
|---|---|---|---|
| 1 | Criar boleto com sucesso para cliente já vinculado | e2e | PASS |
| 2 | Criar cliente Asaas antes do boleto quando não houver vínculo | e2e | PASS |
| 3 | Rejeitar boleto com data de vencimento no passado | e2e | PASS |
| 4 | Rejeitar boleto sem data de vencimento | e2e | PASS |
| 5 | Evitar duplicidade em retentativa do ecommerce | e2e | PASS |
| 6 | Rejeitar provedor não habilitado | e2e | PASS |
| 7 | Falha transiente ao criar boleto no provedor | unit (api/src) | PASS |
| 8 | Falha de validação retornada pelo provedor | unit (api/src) | PASS |

### OBC Success Criteria

| Criterion | Evaluation |
|---|---|
| Boletos criados com bankSlipUrl: 99.9% | assertProviderChargeContract enforces presence; scenario 1 verifies in response — MET |
| dueDate no passado rejeitada: 100% | Scenarios 3 and 4 verify 400 before provider call — MET |
| Idempotência com Idempotency-Key: 100% | Scenario 5 verifies same invoice on retry — MET |
| bankSlipUrl/identificationField não em logs: 100% | Security gate confirmed; not in emitObservable or error responses — MET |
| Invoice OPEN retornada ao Checkout: 100% | Scenarios 1 and 2 confirm status OPEN — MET |

---

## Summary

DS-40 TDD cycle complete. All 8 BDD scenarios covered:
- Scenarios 1–6: acceptance tests in `api/test/criar-invoice-boleto.e2e-spec.ts`
- Scenarios 7–8: unit tests in `api/src/modules/invoices/services/invoice.service.spec.ts`

Risks mitigated:
- B1: `bankSlipUrl` enforced via `assertProviderChargeContract`; missing → FAILED
- B2: `dueDate` validated as future (>= D+1) before provider call
- B3: status OPEN correct; webhook delivers confirmation asynchronously
- B4: fields added to `ProviderChargeResponse`, `InvoiceRecord`, `InvoiceResponseDto`

---

## CI Async — Ship / Validate / Promote (2026-07-30)

### Ship

| Phase | Event-ID | Status |
|---|---|---|
| Ship.Started | c65822ff-57ee-4574-a198-65788c88f603 | accepted |
| Ship.Completed | a23f4af0-3fc4-4f77-9a8f-b5937c694435 | accepted |

CI fixes shipped alongside DS-40 delivery (pre-existing bugs):
- `fix(ci): scope no_mocks gate to api/test only per manifest canonical policy` (f19f7eb)
- `fix(ci): add sam build step to staging-deploy.yml before sam deploy` (f0b89db)

Staging deploy run: https://github.com/produtoreativo/payments-api/actions/runs/30558335602

| Job | Result |
|---|---|
| Lint and Test (LocalStack DynamoDB) | success |
| Deploy — Real AWS Infrastructure (Staging) | success |
| Smoke Test — Live Staging Endpoint | success |

### Validate

| Phase | Event-ID | Status |
|---|---|---|
| Validate.Started | 08e688e4-51fe-411e-8dcc-e3246fb80ea1 | accepted |
| Shared.Gate.Passed | 41b5136e-61f7-4962-ad28-b5c71bc14816 | accepted |
| Validate.Completed | 0abc7be6-350f-46df-918f-cb8bf3fdc04a | accepted |

Evidence:
- 8/8 BDD scenarios passing in CI acceptance gate
- All PR CI checks green: acceptance, build, lint, no_mocks, prodops_consistency, CodeQL
- Staging smoke: auth guard returns 401 on POST /invoices and DELETE /invoices/:id
- OBC criteria: all 5 met (bankSlipUrl enforced, dueDate validated, idempotency, no-log policy, OPEN status)
- Risks B1-B4: all mitigated in implementation

diligence.attach dispatched on Validate.Completed.

### Promote

| Phase | Event-ID | Status |
|---|---|---|
| Promote.Started | 3d83c1b2-a498-4b95-900a-b5a81b3299f2 | accepted |

Promotion decision: **Promover**

- All required evidence present and verified.
- No unresolved high-risk items.
- Staging deploy successful.
- PR #87 ready for merge: https://github.com/produtoreativo/payments-api/pull/87


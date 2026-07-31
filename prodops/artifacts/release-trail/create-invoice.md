# Release Trail — DS-38 create-invoice

**Card:** DS-38  
**Feature:** create-invoice (Pix)  
**Branch:** feat/38-create-invoice  
**Correlation-ID (Hack phase):** ea2cdc10-d4a1-43cd-9774-6d25a3a0237d  
**Date:** 2026-07-31  

---

## TDD Cycle Evidence

> This is a re-execution of the TDD Hack step. The original Red → Green cycle was
> completed in session `2026-07-30-5a19bf95.md`. Tests were already green at the
> start of this execution; Red phase is recorded from the prior cycle's evidence.

### Red Phase (prior cycle — session 2026-07-30-5a19bf95)

Test file: `api/test/criar-invoice.e2e-spec.ts`  
Unit spec: `api/src/modules/invoices/services/invoice.service.spec.ts`

Scenarios derived from BDD feature `prodops/artifacts/bdd/create-invoice.feature`:

1. Criar invoice com sucesso no Asaas usando cliente já vinculado
2. Criar cliente Asaas antes da invoice quando não houver vínculo
3. Evitar duplicidade em retentativa do ecommerce
4. Rejeitar provedor não habilitado
5. Falha transiente ao criar cobrança no provedor
6. Falha de validação retornada pelo provedor

Red evidence: unit test `InvoiceService — Falhas de provedor PIX (DS-38)` initially
failed because `invoice.service.ts` always updated invoice to `FAILED` on provider
error, regardless of whether the error was transient (timeout, 5xx) or a validation
rejection. The OBC requires transient errors to produce `PROVIDER_PENDING`.

---

### Green Phase (prior cycle confirmed by this re-execution)

Modules changed:

**`api/src/modules/invoices/services/invoice.service.ts`**  
- Fixed catch block to use `isRetryableProviderError()`: transient errors (timeout,
  5xx, ECONNRESET, ETIMEDOUT) → `PROVIDER_PENDING`; validation rejections → `FAILED`.

**`api/src/modules/invoices/services/invoice.service.spec.ts`**  
- Added unit test scenarios 5 and 6 for PIX provider failures (DS-38).

### Green Evidence — re-execution 2026-07-31

Command: `bash scripts/test-acceptance.sh criar`

```
PASS test/criar-invoice.e2e-spec.ts
  Criar Invoice
    Criação bem-sucedida
      ✓ cria invoice PIX com cliente ja vinculado ao Asaas (153 ms)
      ✓ cria invoice de cartao hospedado (102 ms)
      ✓ cria cliente Asaas automaticamente quando nao ha vinculo previo (157 ms)
      ✓ retorna a mesma invoice em retentativa com mesma chave de idempotencia (320 ms)
    Validação de payload
      ✓ rejeita payload de cartao tokenizado enquanto o fluxo e hospedado (48 ms)
      ✓ rejeita provedor nao habilitado no ambiente (32 ms)

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
Time:        4.254 s
```

---

### Yellow Phase — 2026-07-31

**Lint:** `cd api && npm run lint` — exit 0  
- 0 errors  
- 15 warnings (pre-existing, in unrelated files: `cancelar-invoice.e2e-spec.ts`,
  `confirmar-pagamento.e2e-spec.ts`, `criar-invoice-boleto.e2e-spec.ts`,
  `criar-invoice.e2e-spec.ts` — all `@typescript-eslint/no-unsafe-argument` warnings,
  not errors, not in changed modules)

**No-mocks gate:** `grep -rn "jest.fn(" api/test/` — **0 hits**  
- No `jest.fn()`, `.mockReturnValue()`, `.overrideProvider()`, or `jest.mock()` in
  the e2e test directory  
- Unit spec `invoice.service.spec.ts` uses `jest.fn()` as permitted for unit-level
  isolation (not as an e2e service replacement)

**No `.only` gate:** `grep -rn "\.only" api/src api/test` — **0 hits**

**Security:** diff reviewed — no secrets, tokens, PII, or insecure configurations.

**Event Storming:** no new domain events emitted; existing `eventEmitter.emit()` calls
unchanged.

**Architecture:** no new modules, routes, external dependencies, tables, or event
topics added in this cycle.

---

## BDD Scenarios — Final Status

| # | Scenario | Test Type | Result |
|---|---|---|---|
| 1 | Criar invoice com sucesso — cliente já vinculado | e2e | PASS |
| 2 | Criar cliente Asaas antes da invoice — sem vínculo | e2e | PASS |
| 3 | Evitar duplicidade em retentativa | e2e | PASS |
| 4 | Rejeitar provedor não habilitado | e2e | PASS |
| 5 | Falha transiente → PROVIDER_PENDING | unit | PASS |
| 6 | Falha de validação → FAILED, erro claro sem segredo | unit | PASS |

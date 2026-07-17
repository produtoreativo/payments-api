# ProdOps TDD Workflow

Complete cycle: Contract → Red → Green → Yellow → Commit Workflow → Observability → Evidence.

---

## Step 1 — Read Contract / Acceptance Criteria

**What it means:** Before writing a single test line, read the OpenAPI spec, BDD Feature file, or OBC
that governs the behavior you are implementing. The contract defines the observable boundary.

**Done when:** You can state, in one sentence, what the HTTP call is, what state changes are
expected, and what the response must contain.

**Hack Flow phase:** Pre-Hack (Bootstrap). Do not start the Red Bar without this.

---

## Step 2 — Write Integration Test → Red Bar

**What it means:** Write the acceptance/E2E test in `api/test/`. Use supertest against the real
NestJS app. The test must fail for a *behavioral* reason — not a compile error, not a missing import.

**Done when:** `npm run test:e2e` fails with output like `expected 201 received 404` or
`expected "CONFIRMED" received "PENDING"`. A stack trace alone is not a valid Red Bar.

**Hack Flow phase:** Red = Hack entry point.

---

## Step 3 — Implement Minimum → Green Bar

**What it means:** Write the minimum production code that makes the failing test pass.
Use Fake It or Obvious Implementation. Do not add logic not yet tested.

**Done when:** `npm run test:e2e` passes for the target test. No other tests broken.

**Hack Flow phase:** Green = Hack in progress.

---

## Step 4 — Refactor → Stays Green

**What it means:** Improve code structure without changing behavior. Extract methods, rename
variables, remove duplication. Tests must remain green throughout.

**Done when:** Code is readable, no duplication visible, all tests still pass.

**Hack Flow phase:** Yellow = closing Hack.

---

## Step 5 — Execute Commit Workflow

Mandatory sequence before every commit:

```
npm run format        # prettier --write
npm run lint -- --fix # eslint autofix
npm run lint          # must exit 0
npm run test          # unit tests must pass
git commit
```

**Done when:** Lint exits 0, unit tests pass, commit created with descriptive message.

**Hack Flow phase:** Commit phase.

---

## Step 6 — Validate Observability

**What it means:** Confirm that logs produced during the test run include `invoiceId`, `tenantId`,
and `correlationId`. No PII, no secrets. Error paths log meaningful messages.

**Done when:** Observability checklist in `observability.md` passes. Use Log String pattern if
log output must be asserted in tests.

---

## Step 7 — Record Evidence

**What it means:** Update the active session trail (`prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`) with: what was tested, Red Bar
output (paste the failure), Green Bar confirmation, and any risk from `prodops/journeys/assessment/risks.md`
that was exercised.

**Done when:** Release trail entry exists for this iteration with test output attached.

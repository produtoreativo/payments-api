# Quality Gates

---

## Delivery Gates

These must be satisfied before any implementation is considered done for release:

- Relevant ProdOps context read before implementation (Feature file, OBC, upstream experiment)
- All behavior changes are covered by tests; BDD Feature file updated when applicable
- Reliability Plan risks impacted by the change reviewed in `prodops/journeys/assessment/risks.md`
- Build, test, and validation evidence recorded in `prodops/artifacts/trails/release-trail.md`
- Operational follow-ups (alerts, runbooks, rollback notes) recorded explicitly — not left implicit

---

## Test Quality Gates (block merge)

The following violations in `api/test/` **block merge** with no exceptions:

| Violation | Why it blocks |
|-----------|--------------|
| `jest.fn()` used as service replacement | Hides real integration behavior |
| `jest.spyOn(...).mockImplementation()` / `.mockReturnValue()` / `.mockResolvedValue()` / `.mockRejectedValue()` | Bypasses owned business logic |
| `.overrideProvider()` in `Test.createTestingModule()` | Replaces real module with stub |
| DynamoDB via in-memory or `DYNAMO_MOCK=true` | Hides schema and query bugs |
| App created inside `beforeEach` (multiple instances per file) | Resource leak, slow tests |

**Permitted exceptions:**
- `ASAAS_MOCK=true`: designed behavior mode of real `AsaasService` — not a mock
- Yellow Bar Mock Object for logger, clock, UUID generator in **unit tests** under `api/src/`
- Error injection scenarios belong in unit tests (`api/src/`), not acceptance specs (`api/test/`)

---

## Relation to Finish and Ship

**Finish** consumes these quality gates as its exit criteria. No iteration advances to Ship until
all Delivery Gates and Test Quality Gates above are satisfied. See:
`prodops/journeys/delivery/phases/finish/`

**Ship** verifies gate evidence before creating the PR: build artifacts, test output, and a
completed release trail entry must exist. Ship does not re-run the gates — it verifies evidence
that Finish recorded.

**Canonical source:** The authoritative gate definitions (the ones that block merge) live in
[`../../../../journeys/delivery/phases/finish/quality-gates.md`](../../../../journeys/delivery/phases/finish/quality-gates.md).
This file is the engineering reference; that file is the enforcement definition.

---

## Definition of Done

The per-cycle exit checklist (Red → Green → Yellow) is canonical in
[`../../../../journeys/delivery/phases/hack/quality-gates.md`](../../../../journeys/delivery/phases/hack/quality-gates.md).
This engineering reference does not duplicate it — consult that file for the gates
that a TDD iteration must satisfy before commit.

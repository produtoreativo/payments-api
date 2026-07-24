# Quality Gates

Use this file to record release Quality Gates that apply to implementation, validation, ship, and promotion.

## Delivery Gates

- The relevant ProdOps context was read before implementation.
- Behavior changes are covered by BDD-backed tests where applicable.
- Reliability Plan risks impacted by the change have been reviewed.
- Build, test, or validation evidence is recorded in the Release Trail.
- Operational follow-ups are recorded rather than left implicit.

## Static analysis gates (`validate`)

Run locally by [`/finish validate`](../../../../../skills/finish/steps/validate/SKILL.md),
replicating what the remote pipeline (`.github/workflows/pr-gates.yml`) runs. The
canonical commands live in [`prodops/exec/manifest.yaml`](../../../../../exec/manifest.yaml)
(`gates:`) — this file references them, it does not rewrite them.

- **lint** (`gates.lint`) — ESLint over the api sources, no errors (warnings do
  not block; the gate requires exit 0).
- **build** (`gates.build`) — NestJS production build compiles.
- **acceptance** (`gates.acceptance`, when behavior/contracts changed) — e2e
  suite against LocalStack. It is `validate`'s **only dynamic exception**.
- **no_mocks** (`gates.no_mocks`) — see Test Quality Gates below.

**Coverage.** A byproduct of the acceptance suite: running acceptance emits the
report as **Cobertura XML** (`api/coverage/cobertura-coverage.xml`), the format
GitHub Code Quality consumes. **Informative — it does not block merge:** there is
no threshold. Tightening it to a blocking gate (e.g. coverage may not drop) is a
later step, once there is a sufficient test base.

**A failure in any static gate does not advance Finish:** the fix is a product
change and returns to [`hack tdd`](../../../../../skills/hack/steps/tdd/SKILL.md),
not to `validate` (which writes no code).

## Branch protection for auto-approval (`review`)

Conditions that [`/finish review`](../../../../../skills/finish/steps/review/SKILL.md)
inspects **without running the pipeline**, before arming auto-merge. Each missing
condition is a **blocker** to record in Finish before any auto-approval:

- [ ] The pipeline exposes `lint`, `acceptance`, and `build` as status checks.
- [ ] Branch protection on the target branch **requires** those checks to pass
      before merge.
- [ ] No required reviewer blocks the merge of a PR with all checks green (or a
      bot auto-approves).

Arming `gh pr merge --auto --squash` without these conditions would merge ungated
code — that is why `review` is a precondition for push and `request`.

## Test Quality Gates

> **No Mocks Rule enforcement gate.** This file defines what blocks merge. For the technical definition and how to apply it in the TDD cycle, see [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../../../skills/hack/references/workflow.md). For acceptable Yellow Bar patterns (error injection, unit tests), see [`mocking-policy.md`](../../../../../skills/references/engineering/tdd-prodops/mocking-policy.md).

**Prohibition of test doubles in acceptance tests.** `api/test/` must not contain service substitutions via `jest.fn()`, `jest.spyOn(...).mockXxx()` implementations, or calls to `.overrideProvider()`. Violations block merge.

**`ASAAS_MOCK=true` is permitted.** It is a designed behavior mode of the real `AsaasService`, not a test double. The real service is instantiated; the mock flag controls which branch executes.

**Real DynamoDB via LocalStack.** All acceptance tests access a real DynamoDB-compatible API. In-memory or mocked repository modes (`INVOICE_REPOSITORY=memory`, `DYNAMO_MOCK=true`) are prohibited in `api/test/`.

**Shared app per file.** Each spec file creates the NestJS application once in `beforeAll` and tears it down in `afterAll`. Tables are truncated in `beforeEach`. Do not recreate the app per test.

**Error injection tests belong in unit tests.** Scenarios that require forcing a failure in an external service (timeout, malformed response, network error) are not acceptance test scenarios. They are unit tests targeting the service layer in isolation and live outside the acceptance specs in `api/test/`.

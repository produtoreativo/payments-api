# Quality Gates

Use this file to record release Quality Gates that apply to implementation, validation, ship, and promotion.

## Delivery Gates

- The relevant ProdOps context was read before implementation.
- Behavior changes are covered by BDD-backed tests where applicable.
- Reliability Plan risks impacted by the change have been reviewed.
- Build, test, or validation evidence is recorded in the Release Trail.
- Operational follow-ups are recorded rather than left implicit.

## Test Quality Gates

> **No Mocks Rule enforcement gate.** This file defines what blocks merge. For the technical definition and how to apply it in the TDD cycle, see [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../../../skills/hack/references/workflow.md). For acceptable Yellow Bar patterns (error injection, unit tests), see [`mocking-policy.md`](../../../../../skills/references/engineering/tdd-prodops/mocking-policy.md).

**Prohibition of test doubles in acceptance tests.** `api/test/` must not contain service substitutions via `jest.fn()`, `jest.spyOn(...).mockXxx()` implementations, or calls to `.overrideProvider()`. Violations block merge.

**`ASAAS_MOCK=true` is permitted.** It is a designed behavior mode of the real `AsaasService`, not a test double. The real service is instantiated; the mock flag controls which branch executes.

**Real DynamoDB via LocalStack.** All acceptance tests access a real DynamoDB-compatible API. In-memory or mocked repository modes (`INVOICE_REPOSITORY=memory`, `DYNAMO_MOCK=true`) are prohibited in `api/test/`.

**Shared app per file.** Each spec file creates the NestJS application once in `beforeAll` and tears it down in `afterAll`. Tables are truncated in `beforeEach`. Do not recreate the app per test.

**Error injection tests belong in unit tests.** Scenarios that require forcing a failure in an external service (timeout, malformed response, network error) are not acceptance test scenarios. They are unit tests targeting the service layer in isolation and live outside the acceptance specs in `api/test/`.

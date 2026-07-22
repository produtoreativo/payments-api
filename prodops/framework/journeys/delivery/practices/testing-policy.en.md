# Testing Policy

## Test pyramid

This repository prioritizes tests in the following order:

1. **Acceptance / E2E tests** — HTTP boundary, real DynamoDB (LocalStack), real service instances. Located in `api/test/`.
2. **Integration tests** — interactions between modules and between services.
3. **Unit tests** — isolated behavior of a single function. Used for edge cases and error paths that do not reach the HTTP boundary.

Unit tests do not replace acceptance tests for functional behavior.

## Tools

- Test runner: Jest (configured in `api/test/jest-e2e.json`)
- HTTP assertions: supertest
- Local infrastructure: LocalStack (DynamoDB, SQS)
- Acceptance test runner: `./scripts/test-acceptance.sh`

## No Mocks Rule

The prohibition of test doubles in acceptance tests is enforced as a Quality Gate that blocks merge.

- Full technical definition: [`prodops/skills/hack/references/workflow.md § No Mocks Rule`](../../../../skills/hack/references/workflow.md)
- Enforcement gate (what blocks merge): [`prodops/framework/journeys/delivery/phases/finish/quality-gates.md § Test Quality Gates`](../phases/finish/quality-gates.md)

## Error path tests

Error paths that require an external system failure belong in unit tests or service-layer tests, not in acceptance tests. See [ProdOps TDD — Yellow Bar Patterns](prodops-tdd.md).

## Shared app per file

Each acceptance test file creates the NestJS application once in `beforeAll` and closes it in `afterAll`. Tables are truncated in `beforeEach`. Recreating the app per test is prohibited.

## Coverage

Coverage thresholds (when configured in `jest.config.*`) must not be reduced without a rationale recorded in a [Decision Trail](../../../../templates/assessment/decision-trail.md).

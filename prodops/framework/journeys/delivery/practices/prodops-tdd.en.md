# ProdOps TDD

ProdOps TDD is the evolution of classic TDD for the context of observable and reliable digital products. It combines TDD, contracts, integration testing, observability, reliability, and operational evidence into a single coding practice.

**ProdOps TDD is not a separate flow.** It is the practice used inside the [Hack Flow](../phases/hack/README.md).

---

## Core definition

> Write a verifiable contract. Write an integration test against that contract. Make it fail. Make it pass with the minimum implementation. Observe. Refactor. Commit. Record evidence.

ProdOps TDD extends classic TDD (Detroit/Chicago school):
1. Starting from a contract, not just a test.
2. Prioritizing integration and acceptance tests over unit tests.
3. Requiring observability validation as part of the cycle.
4. Consuming the Commit Workflow after each Red→Green→Refactor cycle.
5. Producing recorded evidence before promotion.

---

## Principles

### Contract First
Every implementation starts from a verifiable contract. Accepted contracts: OpenAPI, AsyncAPI, JSON Schema, OBC, BDD Feature, events, existing specifications. If no contract exists, create one before writing the test.

### Integration First
Prioritize tests that exercise the application through real calls (HTTP, DynamoDB, events). Test observable behavior — not internal implementation. Unit tests cover cases that do not reach the HTTP boundary.

### Observability First
Before implementing, define how the behavior will be observed: which logs will be emitted, which metrics will be recorded, which correlationId will propagate. Observability is part of the cycle, not a post-implementation extra.

### Progressive Substitution
When a contract-based Mock Server is used as an initial step: start with the Mock Server; progressively substitute with the real API; never rewrite the tests during this substitution. Tests verify behavior through the contract — what is behind it is configuration.

### Non Intrusive Testing
Never alter payload, headers, business rules, or production behavior to facilitate tests. Use environment-based configuration (env vars). `ASAAS_MOCK=true` is a correct example — it activates a behavior mode of the real service, it does not alter the contract.

---

## Mandatory rules

1. **Prioritize integration tests.** Tests must verify behavior at the HTTP or event boundary, not internal implementation details.

2. **No mocks for business rules.** Do not substitute own services that carry business logic with test doubles. See [No Mocks Rule](../../../../skills/hack/references/workflow.md) and [quality-gates.md](../phases/finish/quality-gates.md).

3. **No mocks for domain APIs when a verifiable contract exists.** If an OpenAPI, AsyncAPI, or BDD spec exists, test against it. Mock Servers based on that contract are acceptable as temporary infrastructure.

4. **Mock Servers are infrastructure, not shortcuts.** A Mock Server simulates an external dependency based on a published contract. It must be replaceable by the real integration without rewriting the tests (Progressive Substitution principle).

5. **Do not alter payloads, headers, or production logic for tests.** Tests must exercise the real code path. Environment variables and configuration switches are acceptable; branches that only activate in tests are not.

6. **Prefer environment-based configuration.** Use env vars (e.g.: `ASAAS_MOCK=true`) to switch between test modes. `ASAAS_MOCK=true` activates a designed behavior mode of the real service — it is not a mock object.

7. **Exercise via real calls whenever possible.** Use `supertest` against the running NestJS application, real DynamoDB via LocalStack, and real service instances.

8. **Test behavior, not implementation.** Assert on HTTP responses, database state, log output, and emitted events — not on which internal methods were called.

9. **Validate HTTP responses, error messages, logs, and traceability.** A test that only checks the status code is incomplete.

10. **Use contracts when applicable.** OpenAPI, AsyncAPI, Gherkin BDD Features, and JSON schemas are valid contracts. Reference them in test plans.

11. **Maintain compatibility with Progressive Substitution.** Tests written against a Mock Server must pass without modification when the real integration is substituted.

---

## TDD Cycle (ProdOps variant)

```
1. Read contract / acceptance criteria
2. Write integration test → Red Bar (must fail for a behavioral reason)
3. Implement the minimum → Green Bar
4. Refactor → stays Green
5. Execute Commit Workflow (formatter → lint → unit tests → commit)
6. Validate observability (logs, errors, traceability, metrics)
7. Record evidence
```

Do not skip step 2. A test that was never red is not a verified test.

### Integration with Commit Workflow

ProdOps TDD does not implement formatter, lint, or commit management. That responsibility belongs to the **Commit Workflow**.

After each Red→Green→Refactor cycle (step 5 above), Hack consumes the Commit Workflow:

```
Red → Green → Refactor → [Commit Workflow] → next cycle
```

The Commit Workflow executes:
- Formatter (`npm run lint` with `--fix`)
- Lint (blocks if it does not pass)
- Fast unit tests
- Conventional Commit validation

See: [capabilities/commit-workflow/README.md](../capabilities/commit-workflow/README.md)

### Reliability in the cycle

During implementation, consider the reliability requirements for the behavior being tested:

| Aspect | What to verify |
|---|---|
| **Timeout** | Does the system have a configured timeout for provider calls? |
| **Retry** | Do retries with the same `Idempotency-Key` produce the same result? |
| **Idempotency** | Does the same operation executed twice return the same state? |
| **Exceptions** | Do provider errors produce a meaningful HTTP response (4xx/5xx with `message`)? |
| **Controlled degradation** | Does an external dependency failure not bring down the entire system? |
| **HTTP codes** | Do status codes match semantic behavior (201, 400, 404, 409)? |

These aspects do not require separate tests when already covered by the main integration test. But they must be verified at Green Bar before advancing.

---

## Patterns

### Red Bar Patterns

| Pattern | When to use |
|---|---|
| **Starter Test** | First test for a new capability; verifies the simplest possible observable outcome. |
| **One Step Test** | One behavior increment per test; avoids jumping ahead. |
| **Explanation Test** | Clarifies expected behavior for an ambiguous or poorly documented spec. |
| **Learning Test** | Explores the behavior of a third-party dependency before integrating it. |
| **Another Test** | Captures a new idea that came up while writing the current test; adds it to the list so it is not lost. |
| **Triangulation Test** | Adds a second scenario to force generalization when Fake It was used first. |
| **Regression Test** | Written before fixing a confirmed defect; ensures the defect cannot recur. |
| **Break Test** | Verifies boundary conditions: empty input, maximum values, invalid states. |
| **Do Over** | Deletes a test suite that was testing implementation instead of behavior and rewrites it from the contract. |

### Green Bar Patterns

| Pattern | When to use |
|---|---|
| **Fake It** | Returns a hardcoded value to reach green quickly; followed by Triangulate to generalize. |
| **Triangulate** | Adds a second scenario that forces the Fake It to become a real implementation. |
| **Obvious Implementation** | Used when the correct implementation is obvious and short; skips Fake It. |
| **One-to-Many** | Drives a collection-aware implementation from a single-item test, then adds the multi-item test. |

### Yellow Bar Patterns

Yellow Bar patterns manage test complexity. **They are not a license to mock business logic.**

| Pattern | Acceptable use | Not acceptable |
|---|---|---|
| **Mock Object** | Technical dependencies: logger, clock, UUID generator, telemetry adapter, email adapter, external HTTP client when no contract exists and the integration is expensive/unpredictable. | Own services, repositories, domain rules, or any component that carries business behavior. |
| **Self Shunt** | Test class implements a listener interface to observe internal events. | — |
| **Log String** | Captures log output to verify that observability behavior is correct. | — |
| **Child Test** | Splits a failing test into a smaller test when the parent test is too complex to debug. | — |
| **Crash Test Dummy** | Simulates a catastrophic failure (OOM, fatal error) that cannot be triggered in a real environment. | Simulating predictable business errors that the real system can produce. |
| **Broken Test** | Intentionally leaves a test failing with a clear comment when work is in progress and a commit is necessary. | — |
| **Clear Check-in** | Ensures all tests pass before committing, even if that means reverting a broken change. | — |

**Rule:** a Mock Object is acceptable only when it does not hide business behavior. If the mock substitutes logic that the real code would execute differently, it is hiding a defect.

---

## What ProdOps TDD is not

- Not a reason to skip acceptance tests.
- Not a reason to use mocks as the default approach.
- Not a separate flow from Hack Flow.
- Not permission to add test-only branches in production code.
- Not a substitute for observability validation.

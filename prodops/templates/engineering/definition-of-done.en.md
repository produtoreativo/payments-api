# Definition of Done

An implementation is done when all of the following are true:

## Behavior

- [ ] The expected behavior is covered by a test that was red before the implementation.
- [ ] The test verifies behavior at the HTTP or event boundary (not internal implementation).
- [ ] Relevant integration and acceptance tests pass.
- [ ] No mock substitutes owned services or business logic.

## Contracts

- [ ] The BDD Feature for this behavior reflects the implemented contract.
- [ ] The OpenAPI or AsyncAPI spec is updated if a route or event was added, changed, or removed.
- [ ] The OBC acceptance criteria are satisfied by the evidence.

## Code quality

- [ ] No test-only branches exist in production code.
- [ ] Formatter executed (`npm run lint` with `--fix` applied).
- [ ] Lint passes (`npm run lint` exit 0 in `api/`).
- [ ] Build passes.
- [ ] No new TypeScript errors introduced.
- [ ] Commits follow Conventional Commits (`<type>(<scope>): <summary>`).

## Observability

- [ ] Observable behavior defined before implementing (which log, which metric, which correlationId).
- [ ] Relevant logs are emitted with correct structure (correlationId, tenantId).
- [ ] Error responses have meaningful messages.
- [ ] No secrets or PII appear in logs.

## Reliability

- [ ] Timeout configured for calls to the external provider.
- [ ] Idempotency verified: the same operation repeated returns the same state.
- [ ] Provider exceptions produce an HTTP response with a meaningful `message`.
- [ ] Controlled degradation: failure of an external dependency does not bring down the system.
- [ ] HTTP codes correspond to semantic behavior (201, 400, 404, 409).

## Architecture

- [ ] Architecture diagram updated if the change was structural (new module, route, table, event topic).
- [ ] Event Storming updated if events were added, removed, or renamed.

## Evidence

- [ ] Evidence added to the active session trail at `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md` (Downstream) or to the experiment trail (Upstream).
- [ ] Evidence includes: test output, lint output, and a summary of what changed.

## Ready for Sync + Finish

- [ ] All items above are checked.
- [ ] The change is ready to enter [Finish](../../journeys/delivery/phases/finish/README.md).

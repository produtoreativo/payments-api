---
name: hack/tdd
description: Execute the ProdOps TDD cycle. Use after bootstrap to implement a behavior change through red, green, and yellow phases.
---

# HACK → TDD

Execute only the TDD cycle of the Hack flow.

## Inputs

Read before starting:

- Relevant BDD Feature in `prodops/artifacts/bdd/` (committed) or
  `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratory)
- Relevant OBC in `prodops/artifacts/obcs/` or experiment directory
- The module being changed and its existing tests
- Direct imports and shared contracts required to understand the change

## Phases

### Red — write the failing test

*References: [DDD](../../../references/engineering/ddd/README.en.md) (ubiquitous language, domain events) · [ProdOps TDD](../../../references/engineering/tdd-prodops/README.en.md) (integration-first, mocking policy).*

1. Derive the test scenario from the BDD Feature or OBC. Do not invent criteria.
2. Write the narrowest test that would fail because the behavior does not exist yet.
3. Run the test and confirm it fails for the right reason (missing behavior, not a
   syntax or import error).
4. Record the red output as evidence.

### Green — implement the minimum

*References: [Clean Code](../../../references/engineering/clean-code/README.en.md) (naming, functions).*

1. Write the smallest change that makes the failing test pass.
2. Do not refactor yet. Do not add behavior beyond what the test requires.
3. Run the focused test suite and confirm green.
4. Run broader tests if the change touches shared behavior.
5. Record the green output as evidence.

### Yellow — quality and artifact closure

*References: [Clean Code — refactoring](../../../references/engineering/clean-code/refactoring.en.md) · [DDD](../../../references/engineering/ddd/README.en.md) (aggregates, repositories) · [observability](../../../references/engineering/tdd-prodops/observability.en.md).*

The Yellow Bar is where refactoring **and** the transversal Security, Quality, and
Documentation validations run. These are not extra steps — they are the cycle's
exit gates. The full checklist is in
[`../../../../journeys/delivery/phases/hack/quality-gates.en.md`](../../../../journeys/delivery/phases/hack/quality-gates.en.md).

1. **Refactor** — improve names, reduce duplication, apply Clean Code rules.
   Do not change behavior. Re-run tests after each refactor step to stay green.
2. **Lint (Quality gate)** — run lint for the affected package:
   - API: `cd api && npm run lint`
   - Workbench: `cd validation-workbench && npm run build`
   Resolve all lint errors before continuing. Do not suppress rules without justification.
3. **Security gate** — confirm the diff contains no secrets, tokens, or insecure
   configs, and that no PII is written to logs.
4. **Quality gate** — confirm the diff contains no forbidden test double
   (`jest.fn()` as a service replacement, `.overrideProvider()`) and no `.only`
   left in a spec. See
   [`../../../../journeys/delivery/phases/finish/quality-gates.en.md`](../../../../journeys/delivery/phases/finish/quality-gates.en.md).
5. **Event Storming** — if the change adds, removes, or renames a domain event
   (`eventEmitter.emit()` or `@OnEvent()`), update
   `prodops/journeys/assessment/event-storming/plan.json`:
   - add both success and `_exception` variants to `customEvents`;
   - add the event to relevant flow bands;
   - add an `sloSuggestions` entry if on the critical path;
   - update `assumptions[last]` with today's date and a change summary.
   Use `prodops/journeys/assessment/event-storming/plan-model.json` as the format reference.
6. **Architecture** — if the change is structural (new module, route, external
   dependency, table, or event topic), update
   `prodops/journeys/assessment/architecture/overview.md`:
   - edit the Mermaid diagram;
   - add a row to the History table with today's date and a one-line description.
7. **Release Trail** — append evidence to `prodops/artifacts/trails/release-trail.md`:
   - red test output (or reason TDD was not applicable);
   - green test output;
   - lint result;
   - summary of what changed and why.

## Post-conditions

- All focused tests pass.
- Broader tests pass for touched shared behavior.
- Lint exits 0 for the affected package.
- No secrets or PII in the diff; no forbidden mock (`jest.fn()`, `.overrideProvider()`) or `.only` left behind.
- Impacted ProdOps artifacts updated (Event Storming, architecture, BDD if needed).
- Release Trail has the full TDD evidence entry.
- Every gate in [`quality-gates.en.md`](../../../../journeys/delivery/phases/hack/quality-gates.en.md) is satisfied.

## Guardrails

- Do not skip red — green without a prior failing test is not TDD.
- Do not implement beyond the failing test in the green phase.
- Do not refactor in the green phase — refactor only after green.
- If TDD is not applicable (e.g. pure doc change, infrastructure config), record
  the reason explicitly in the Release Trail instead of skipping silently.
- Do not change unrelated modules discovered during exploration.

## Engineering References

| Reference | When to use |
|---|---|
| [`../../../references/engineering/tdd-prodops/red-green-refactor.md`](../../../references/engineering/tdd-prodops/red-green-refactor.md) | Allowed/prohibited actions per phase |
| [`../../../references/engineering/tdd-prodops/mocking-policy.md`](../../../references/engineering/tdd-prodops/mocking-policy.md) | What is permitted in Yellow Bar |
| [`../../../references/engineering/tdd-prodops/observability.md`](../../../references/engineering/tdd-prodops/observability.md) | What to validate after Green |
| [`../../../references/engineering/clean-code/refactoring.md`](../../../references/engineering/clean-code/refactoring.md) | Refactoring techniques for Yellow phase |

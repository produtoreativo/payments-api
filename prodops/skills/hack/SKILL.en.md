---
name: hack
description: Execute implementation work with TDD. Use when changing code, behavior, contracts, tests, or release artifacts as part of a ProdOps-backed task.
---

# HACK

Use this skill to implement the smallest coherent change that satisfies the
current ProdOps release context. This skill is self-sufficient: do not pre-read
`AGENTS.md`, `prodops/framework/`, or any other framework documentation before
executing it.

For detailed execution mechanics (branching, code style, No Mocks Rule), read
`references/workflow.md` on demand.

## Required context

Read before editing — and only this:

- The card's **OBC** and **BDD Feature**. Canonical locations are defined in
  `prodops/exec/manifest.yaml`: `paths.obcs` (committed OBCs), `paths.bdd`
  (committed Features), or `paths.experiments` under
  `<NNN-slug>/features/` for exploratory work.

If the OBC or BDD Feature for the requested behavior is missing, stop and
surface the gap — Bootstrap was not completed. Do not invent acceptance
criteria.

## Steps

When invoked with a step argument (`/hack <step>`), execute only that step
instead of the full flow. Read the corresponding step file and follow it
exclusively — do not run the rest of the flow.

| Step | File | When to use |
|---|---|---|
| `start` | [steps/start/SKILL.md](steps/start/SKILL.md) | Clean stage, sync base branch, create feature branch |
| `tdd` | [steps/tdd/SKILL.md](steps/tdd/SKILL.md) | Execute red → green → yellow cycle with artifact closure |
| `commit` | [steps/commit/SKILL.md](steps/commit/SKILL.md) | Stage and commit after green + lint + trail |

If the requested step is not listed, run the full flow.

## Focused code reading

Do not read the whole repository or the whole codebase by default. Read only:

- the module being changed;
- tests for that module or behavior;
- direct imports used by the changed code;
- shared contracts, DTOs, providers, repositories or helpers required to
  understand the change;
- package scripts needed for test, lint and build validation.

Expand reading only when the focused context shows that the behavior crosses a
module boundary.

## Flow

When invoked without a step argument, execute the three steps in sequence.
Before starting, confirm the requested behavior exists in the OBC and BDD
Feature listed in Required context above.

1. **[start](steps/start/SKILL.md)** — clean working tree, sync base branch, create feature branch
2. **[tdd](steps/tdd/SKILL.md)** — Red → Green → Yellow TDD cycle with artifact closure
3. **[commit](steps/commit/SKILL.md)** — stage, review diff, commit with Conventional Commit

`start → tdd → commit` are **sequential steps**. Security, quality, and
documentation validations are **not** extra steps — they are transversal and run
inside each cycle's Yellow Bar. See
[`../../journeys/delivery/phases/hack/README.md`](../../journeys/delivery/phases/hack/README.md#steps-sequenciais-vs-validações-transversais).

## Quality Gates (mandatory — cycle exit criteria)

A Red → Green → Yellow cycle is complete — and you may only commit and move to the
next step — when every gate below is satisfied:

| Gate | Check | Command / evidence |
|---|---|---|
| Green | Focused test passing | focused e2e spec via jest e2e config (there are no unit suites — see `gates` note in the manifest) |
| Lint | Exits 0 for the affected package | manifest `gates.lint` |
| No forbidden mock | No forbidden jest mock pattern in the diff | manifest `gates.no_mocks` |
| No secrets or PII | None in the diff | review diff |
| Release Trail | Cycle evidence appended | manifest `paths.release_trail` |
| ProdOps artifacts | Event Storming / architecture updated when impacted | see [tdd step](steps/tdd/SKILL.md) |

These gates are the minimum to commit. The canonical checklist lives in
[`../../journeys/delivery/phases/hack/quality-gates.md`](../../journeys/delivery/phases/hack/quality-gates.md).
Release-blocking gates (what blocks merge) live in
[`../../journeys/delivery/phases/finish/quality-gates.md`](../../journeys/delivery/phases/finish/quality-gates.md).

## Guardrails

- Do not copy product context into this skill.
- Do not invent missing acceptance criteria.
- Use BDD Features as the source for TDD scenarios.
- If TDD is not applicable, record why in the Release Trail evidence.
- Prefer focused code reading over broad repository reading.
- Do not change unrelated modules just because they were discovered during
  exploration.
- Preserve existing architecture and module boundaries unless the BDD or
  Reliability Plan requires a contract change.

For Clean Code rules (naming, functions, refactoring) see
[`../references/engineering/clean-code/`](../references/engineering/clean-code/README.md).

## Engineering References

| Area | File | When to read |
|---|---|---|
| Clean Code | [`../references/engineering/clean-code/`](../references/engineering/clean-code/README.md) | Naming, functions, refactoring, error handling |
| TDD ProdOps | [`../references/engineering/tdd-prodops/`](../references/engineering/tdd-prodops/README.md) | Red/green/yellow cycle, mocking policy, quality gates |
| DDD | [`../references/engineering/ddd/`](../references/engineering/ddd/README.md) | Aggregates, repositories, domain events, ubiquitous language |

## Quality gates

Gates are named and defined in `prodops/exec/manifest.yaml` (`gates:`). The
commands below are inlined for execution and must stay in agreement with the
manifest.

| Gate | Command | Pass criterion |
|---|---|---|
| `lint` | `cd api && npm run lint` | exit 0 — mandatory after every code change, not optional. Runs ESLint with `--fix`; auto-corrects Prettier and fixable violations; remaining errors must be fixed in source. Run after green phase, after refactor, and before commit. |
| `acceptance` | `./scripts/test-acceptance.sh` (or `cd api && npm run test:acceptance`) | exit 0 — the test gate (the repo has no unit suites); required when payment behavior or contracts changed; runs the 4 acceptance suites and requires LocalStack |
| `no_mocks` | grep for `jest.fn(`, `.mockReturnValue(`, `.overrideProvider(`, `jest.mock(` in `api/src` and `api/test` | zero hits — see `references/workflow.md` (No Mocks Rule) |

Required evidence for code changes:

- red-phase focused test failure, when TDD applies;
- green focused test pass;
- relevant broader tests when shared behavior changed;
- `lint` gate clean for the affected package.

Validation Workbench note: `validation-workbench/` has no lint script; run
`npm run build` inside it for TypeScript and Vite validation.

Write code that satisfies the active lint rules from the start. See
`references/workflow.md` section **Code Style — Active Lint Rules** for the
Prettier and TypeScript constraints enforced in `api/`.

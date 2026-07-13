# Hack Cycle Quality Gates

Canonical exit checklist for a **Red → Green → Yellow** cycle. A cycle does not close — and you do not advance to the next step or to `commit` — until every gate below is satisfied.

This file is the canonical source for the Hack's **per-cycle** gates. The release exit gates (what blocks merge) live in [`../finish/quality-gates.en.md`](../finish/quality-gates.en.md); the engineering reference in [`tdd-prodops/quality-gates.en.md`](../../../../skills/references/engineering/tdd-prodops/quality-gates.en.md) links here instead of duplicating.

---

## Sequential steps vs. transversal validations

Hack has **three sequential, independently invocable steps** (`prodops/skills/hack/steps/`):

```
start → tdd → commit
```

The **Security, Quality, and Documentation validations are not steps.** They are **transversal**: they run during and at the end of each cycle's **Yellow Bar**, not as extra sequential steps.

| Transversal validation | What to check (in the Yellow Bar) |
|---|---|
| **Security** | No secrets in diff; no vulnerable dependencies; no insecure configs; no PII in logs |
| **Quality** | Lint clean; minimum coverage; no forbidden mock (`jest.fn()`, `.overrideProvider()`); no `.only` |
| **Documentation** | Event Storming if new event; architecture if new structure; Release Trail with cycle evidence |

---

## Cycle exit gates (minimum to commit)

A Red → Green → Yellow cycle is complete only when:

- [ ] **Green** — focused test passing
- [ ] **Lint** — `npm run lint` exits 0 for the affected package
- [ ] **No forbidden mock** in the diff (`jest.fn()`, `.overrideProvider()`)
- [ ] **No secrets or PII** in the diff
- [ ] **Release Trail** updated with the cycle evidence
- [ ] **Impacted ProdOps artifacts** updated (Event Storming, architecture)

These gates are the minimum to commit and move to the next step.

---

## Engineering references per step

| Step | References |
|---|---|
| `start` | n/a |
| `tdd` (Red) | [DDD](../../../../skills/references/engineering/ddd/README.en.md) (ubiquitous language, domain events) · [ProdOps TDD](../../../../skills/references/engineering/tdd-prodops/README.en.md) (integration-first, mocking policy) |
| `tdd` (Green) | [Clean Code](../../../../skills/references/engineering/clean-code/README.en.md) (naming, functions) |
| `tdd` (Yellow) | [Clean Code — refactoring](../../../../skills/references/engineering/clean-code/refactoring.en.md) · [DDD](../../../../skills/references/engineering/ddd/README.en.md) (aggregates, repositories) · [observability](../../../../skills/references/engineering/tdd-prodops/observability.en.md) |
| `commit` | [Conventional Commits](../../capabilities/commit-workflow/README.md#conventional-commits) · commit scope |

---

## Relation to Finish and Ship

**Finish** consumes the release gates in [`../finish/quality-gates.en.md`](../finish/quality-gates.en.md) as the CI Sync exit criteria. This file's gates operate **per cycle**, inside Hack; the Finish gates operate **per release**, before the PR. A Hack cycle closed with these gates is a pre-condition for Finish, not a replacement for it.

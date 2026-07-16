→ [Back to Delivery](../../README.md)

# Finish

---

## Overview

**What it's for:** It is the exit gate of CI Sync. It validates quality locally
with the same rigor as the pipeline, confirms the automatic-PR rules are valid,
publishes the commits, and opens the PR in auto-approval mode.

**How it works — four sub-steps, each with a single responsibility and an
explicit boundary of what it does *not* do** (so each step is auditable in
isolation, with no cross-cutting side effects):

```
validate → review → push origin → request
(static     (pipeline   (git,        (opens PR with
 analysis)   inspection) no force)    auto-approval)
```

1. **`validate`** — static quality analysis (runs all static-analysis steps;
   acceptance/integration is the only dynamic exception). If something fails, the
   fix belongs to Hack's TDD cycle — return to `hack tdd`, do not fix it here.
2. **`review`** — inspects the pipeline and ensures the rules for an automatic PR
   are valid, **without running the pipeline**. A missing branch-protection
   condition is a **blocker**.
3. **push origin** — publishes the commits to the origin branch (git, no force push).
4. **`request`** — opens the PR in auto-approval mode (auto-merge if CI passes).

**Main guardrails:**

- Do not mark as complete without evidence
- Do not hide skipped tests — record the reason
- Do not expand scope during Finish
- Do not force push
- Do not enable auto-approval without branch protection configured

**Position in the flow:**

```
CI Sync  →  Bootstrap → Hack → Sync → [Finish]
                                               ↓
CI Async →                               Ship → Validate → Promote
```

---

Objective: confirm that all Quality Gates pass before marking the work as ready to ship.

Checklist:
- [ ] Lint passes (`npm run lint` exit 0).
- [ ] All tests pass (unit + acceptance).
- [ ] Build passes.
- [ ] No unresolved TODOs or FIXMEs introduced in this change.
- [ ] Definition of Done satisfied. See [definition-of-done.md](../../../../../templates/engineering/definition-of-done.md).
- [ ] Evidence added to the Release Trail.

An implementation does not leave Finish until all items are checked.

---

## Sub-steps and responsibilities

Each sub-step has a single responsibility and a boundary of what it is **not**
responsible for. The execution mechanics of each live in the skill.

| Sub-step | Responsibility | **Not** its responsibility | Skill |
|---|---|---|---|
| `validate` | Static analysis (format, lint, build) + acceptance/coverage as the dynamic exception | Committing, writing/reading code, writing to artifacts, pushing | [steps/validate](../../../../skills/finish/steps/validate/SKILL.md) |
| `review` | Confirm required checks, branch protection, and absence of a blocking reviewer allow safe auto-approval | Running the pipeline, committing, writing/reading code, pushing, opening a PR | [steps/review](../../../../skills/finish/steps/review/SKILL.md) |
| push origin | Publish the commits to the origin branch, no force push | Validating, inspecting the pipeline, opening a PR | — (plain git, see skill router) |
| `request` | Open **one** PR with the template filled and auto-merge armed (`--auto --squash`) | Validating, pushing, committing, writing/reading code | [steps/request](../../../../skills/finish/steps/request/SKILL.md) |

Mandatory order: green `validate` → blocker-free `review` → push → `request`. If
`validate` fails, the fix goes back to
[`hack tdd`](../../../../skills/hack/steps/tdd/SKILL.md) — Finish does not write
product code.

Complete checklist: [capabilities/commit-workflow/README.md — Finish Checklist](../../capabilities/commit-workflow/README.md#checklist-do-finish)

PR template: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

For execution mechanics, see [`prodops/skills/finish/`](../../../../../skills/finish/).

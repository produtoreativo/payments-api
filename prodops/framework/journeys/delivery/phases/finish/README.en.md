→ [Back to Delivery](../../README.md)

# Finish

---

## Overview

**What it's for:** It is the exit gate of CI Sync. It ensures that all quality gates pass before marking the work as ready to ship — lint, build, tests, Definition of Done, and evidence recorded in the Release Trail.

**How it works:**

```
Review diff scope → Run lint + build + tests
→ Confirm ProdOps artifacts updated → Evidence in Release Trail → Publish PR
```

**Main guardrails:**

- Do not mark as complete without evidence
- Do not hide skipped tests — record the reason
- Do not expand scope during Finish

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

## Commit Workflow in Finish

Finish is responsible for:

1. Validating commit history (all follow Conventional Commits).
2. Running formatter + lint (no errors).
3. Running build (no TypeScript errors).
4. Running unit and acceptance tests.
5. Validating contracts (BDD Features, OpenAPI, AsyncAPI).
6. Filling the PR template with evidence.
7. Publishing the Pull Request.
8. Marking the Task as complete with the template [task-closing.md](../../capabilities/commit-workflow/templates/task-closing.md).

Complete checklist: [capabilities/commit-workflow/README.md — Finish Checklist](../../capabilities/commit-workflow/README.md#checklist-do-finish)

PR template: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

For execution mechanics, see [`prodops/skills/finish/`](../../../../../skills/finish/).

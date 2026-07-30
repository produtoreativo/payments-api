→ [Back to Delivery](../../README.md)

# Finish

---

## Overview

**What it's for:** It is the exit gate of CI Sync. It delivers a fully autonomous Pull Request — a PR that traverses the entire CI Async (Ship → Validate → Promote) without human intervention.

**What Finish is NOT:** Finish does NOT deliver software. Finish delivers the PR.

**How it works:**

```
Review diff scope → Run lint + build + tests + contracts
→ Confirm ProdOps artifacts updated → Evidence in Release Trail
→ Publish PR → Auto-approval → Auto-merge → Verify workflows
→ Confirm repository readiness for automated execution
```

**If any requirement cannot be satisfied: Finish does NOT complete. Stop and investigate.**

**Main guardrails:**

- Do not mark as complete without evidence
- Do not hide skipped tests — record the reason
- Do not expand scope during Finish
- If auto-approval or auto-merge fails: blocker — investigate before proceeding

**Position in the flow:**

```
CI Sync  →  Bootstrap → Hack → Sync → [Finish]
                                               ↓
CI Async →                               Ship → Validate → Promote
```

---

Objective: deliver a fully autonomous Pull Request — all Quality Gates satisfied, PR created with complete evidence, auto-approval and auto-merge configured, repository ready for automated execution.

Checklist:
- [ ] Lint passes (`npm run lint` exit 0).
- [ ] All tests pass (unit + acceptance).
- [ ] Build passes.
- [ ] No unresolved TODOs or FIXMEs introduced in this change.
- [ ] Definition of Done satisfied. See [definition-of-done.md](../../../../../templates/engineering/definition-of-done.md).
- [ ] Evidence added to the Release Trail.
- [ ] PR created with template filled.
- [ ] Auto-approval executed (or result recorded if not supported).
- [ ] Auto-merge enabled (or result recorded if not supported).
- [ ] Existing workflows verified and valid.
- [ ] Repository confirmed ready for automated execution.

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
8. Executing auto-approval on the PR (when the repository supports it).
9. Enabling auto-merge on the PR (when the repository supports it).
10. Verifying existing workflows and repository readiness for automated execution.
11. Marking the Task as complete with the template [task-closing.md](../../capabilities/commit-workflow/templates/task-closing.md).

Complete checklist: [capabilities/commit-workflow/README.md — Finish Checklist](../../capabilities/commit-workflow/README.md#checklist-do-finish)

PR template: [commit-workflow/templates/pull_request.md](../../capabilities/commit-workflow/templates/pull_request.md)

For execution mechanics, see [`prodops/skills/finish/`](../../../../../skills/finish/).

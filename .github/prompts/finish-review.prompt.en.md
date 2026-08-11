# Finish → Review

Read `prodops/skills/finish/steps/review/SKILL.md` and execute the Review step.

**Step objective:** ensure the **rules for an automatic PR are valid** — that the conditions for safe auto-approval are present in the repository — **without running the pipeline**. This is a configuration-inspection step (via `gh` and config reads), not an execution step.

**Conditions to confirm (each missing one is a blocker):**

- [ ] The pipeline exposes `lint`, `acceptance` and `build` as status checks.
- [ ] Branch protection on the target branch **requires** those checks to pass before merge.
- [ ] No required reviewer blocks the merge of a PR with all checks green (or a bot auto-approves).

**Completion criteria:** every condition confirmed, or the branch-protection blocker recorded in Finish. Enabling auto-merge without branch protection would merge code with no gate — that is why `review` is a precondition of both the push and `request`.

**Out of scope:** does not run pipelines, does not commit, does not write/read product code, does not push, does not open a PR (`request`). If the conditions cannot be read (permissions) or are not configured, treat that as an explicit blocker, not as "probably fine".

Execute only the `review` step. Import context from `AGENTS.md`, `prodops/framework/journeys/delivery/phases/finish/quality-gates.md` and `.github/workflows/pr-gates.yml` when a boundary is unclear.

# Finish

Read `prodops/skills/finish/SKILL.md` and execute the full Finish flow.

Finish has **four sub-steps**, each with a single responsibility and an explicit boundary of what it does **not** do. Execute them in order; to run only one, use that sub-step's prompt:

1. **validate** (`#finish-validate`) — static code-quality analysis (format, lint, build) plus acceptance/coverage as the dynamic exception. A failure returns to `hack tdd`.
2. **review** (`#finish-review`) — inspects the pipeline and confirms the automatic-PR rules, without running it. Missing branch protection is a blocker.
3. **push origin** — publishes the commits to the origin branch, without force push.
4. **request** (`#finish-request`) — opens the PR in auto-approval mode (`gh pr merge --auto --squash`) and updates the Release Trail.

Mandatory order: `validate` green → `review` with no blockers → push → `request`.

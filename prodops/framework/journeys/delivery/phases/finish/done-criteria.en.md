# Done Criteria

A task is ready when:

- The implemented change corresponds to the current ProdOps context.
- Impacted BDD, Reliability Plan, or operational artifacts have been updated.
- Tests or validation evidence have been executed, or their absence has been documented with justification.
- The Release Trail has a new entry for the significant work performed.
- Remaining risks and next steps are explicit.

## Criteria per Finish sub-step

Finish is complete when, **in order**:

- [ ] **`validate`** passed — static analysis (format, lint, build) plus
      acceptance when behavior or contracts changed. The acceptance run also
      emits **coverage** as Cobertura XML
      (`api/coverage/cobertura-coverage.xml`) — there is no separate coverage
      step. A failure here does not advance: the fix returns to `hack tdd`.
- [ ] **`review`** confirmed the automatic-PR rules — required checks, branch
      protection on the target branch, and no blocking reviewer — or **recorded
      the branch-protection blocker** before any auto-approval.
- [ ] **push** performed to the origin branch, no force push.
- [ ] **`request`** opened **one** PR with title and body from the template,
      filled with evidence, and auto-approval armed (`gh pr merge --auto
      --squash`).
- [ ] Release Trail updated with the PR link (active session trail in
      `prodops/artifacts/trails/sessions/`).

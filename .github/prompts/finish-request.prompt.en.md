# Finish → Request

Read `prodops/skills/finish/steps/request/SKILL.md` and execute the Request step.

**Step objective:** open **one** Pull Request in auto-approval mode — if every GitHub Actions check passes, the PR merges automatically with no manual intervention. That is this step's only responsibility.

**Preconditions (do not open the PR without them):** `validate` clean, `review` with no blockers, commits already published to the origin branch (the `push origin` step). Opening the PR with auto-merge without these prerequisites can merge code with no gate.

**Action:** fill the body with the [PR template](../../prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md) and real evidence (output of `validate`, changed contracts, updated ProdOps artifacts); open the PR against the target branch confirmed by `review`; arm auto-merge with `gh pr merge --auto --squash`; record the PR link in the Release Trail (the active session trail in `prodops/artifacts/trails/sessions/`).

**Completion criteria:** a single PR opened against the correct target branch, body following the template with evidence, auto-merge armed, Release Trail carrying the PR link.

**Out of scope:** any action other than opening the PR — does not validate (`validate`), does not inspect the pipeline (`review`), does not push (`push origin`), does not commit, does not write/read code. Do not open duplicate PRs.

Execute only the `request` step. Import context from `AGENTS.md` and `prodops/framework/journeys/delivery/phases/finish/README.md` when a boundary is unclear.

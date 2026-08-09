# Finish → Validate

Read `prodops/skills/finish/steps/validate/SKILL.md` and execute the Validate step.

**Step objective:** inspect quality by running **every static code-analysis step** (format, lint, build), reproducing locally what the remote pipeline (`.github/workflows/pr-gates.yml`) runs. The acceptance/integration suite is the **only dynamic exception** — and it is what emits coverage in Cobertura XML (`api/coverage/cobertura-coverage.xml`); there is no separate coverage step.

**Source of the commands:** `prodops/exec/manifest.yaml` (`gates.lint`, `gates.build`, `gates.acceptance`, `gates.no_mocks`) — reference it, do not rewrite it.

**Completion criteria:** every static gate passes locally (lint exit 0, build compiles) and acceptance passes when behavior or contracts changed. Coverage is informational and does not block.

**On failure:** do not fix it here. `validate` is inspection, with no writes to code — fixing a red lint/build/acceptance is a product change and returns to `hack tdd` (Red → Green → Refactor). Only re-run `validate` after it closes green.

**Out of scope:** does not commit, does not write/read code, does not write to artifacts, does not push, does not inspect the pipeline (`review`), does not open a PR (`request`).

Execute only the `validate` step. Import context from `AGENTS.md` and `prodops/framework/journeys/delivery/phases/finish/README.md` when a boundary is unclear.

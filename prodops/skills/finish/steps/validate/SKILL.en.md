---
name: finish/validate
description: Static quality analysis before push. Use to replicate locally what the remote pipeline will run, so failures surface before a push instead of on a red PR.
---

# FINISH → VALIDATE

Execute only the static quality-analysis step of the Finish flow.

**Responsibility:** inspect quality by running **all static code-analysis
steps**. Because acceptance tests are integration tests, they are the **only
dynamic-analysis exception** admitted in this step.

**Not the responsibility of `validate`:** committing; writing or reading code;
writing to artifacts; pushing. It is an **inspection** step, not a mutation one.

## Inputs

- `prodops/exec/manifest.yaml` — canonical gate commands and criteria
  (`gates.lint`, `gates.acceptance`, `gates.build`, `gates.no_mocks`,
  `gates.coverage`, `gates.dependencies`, `gates.sast`). The last three are
  `blocks: auto_merge_only` — they disarm auto-merge, not manual merge — but
  they **run in this step like every other gate**: they are static quality
  analysis.
- `prodops/framework/journeys/delivery/phases/finish/quality-gates.md` — what blocks merge
- Current diff — to decide whether the dynamic exception (acceptance) applies

## Action

### 1. Static analysis suite (repository scripts)

Source of truth for the commands: `prodops/exec/manifest.yaml`. The scripts
exist in `api/package.json` and jest is installed — but not all serve as a gate
without adjustment (see notes):

```bash
cd api

# format — Prettier (clean gate)
npm run format     # prettier --write "src/**/*.ts" "test/**/*.ts"

# lint — ESLint (see note: --fix)
npm run lint       # eslint "{src,apps,libs,test}/**/*.ts" --fix

# build — compilation check (clean gate)
npm run build      # nest build
```

> **Coverage** does not belong here: in this repo it is a byproduct of the
> acceptance suite, which is dynamic. See section 3.

**`lint` note:** the script uses `--fix`, which **rewrites** files instead of
failing — useless as a CI gate. To inspect without mutating (what `validate`
requires), run eslint without `--fix`, as `pr-gates.yml` does:
`npx eslint "{src,apps,libs,test}/**/*.ts"` (errors fail; warnings do not — the
repo carries pre-existing warnings and the gate only requires exit 0).

### 2. Security — SAST and dependencies

Two complementary security gates, both `blocks: auto_merge_only`: a red result
disarms auto-merge, but never prevents a manual merge.

**SAST** (`gates.sast` in the manifest — local SonarQube, `api/src` source code):

```bash
./scripts/check-sast.sh          # starts/reuses the container and analyzes
./scripts/check-sast.sh --keep   # keeps the container up to inspect the UI
```

Runs **locally**, via an ephemeral SonarQube container — the same shape as
LocalStack in the acceptance gate. Requires no secret: the script provisions the
token on the freshly started server. `SONAR_TOKEN` in the environment (or in
`api/.env`) takes precedence if present. The first run takes ~1-2 min until the
server is healthy.

**SAST does not measure coverage.** The script provisions its own quality gate
(`prodops-sast`) with violations, duplication, and security hotspots, and
**removes** the `new_coverage` condition SonarQube automatically injects into
every new gate (via CAYC — "Clean as You Code"). Coverage is the exclusive
responsibility of `gates.coverage`, which is strictly stricter: branches at 100%
over the whole codebase, versus lines at 80% over new code only. Without that
removal SAST would fail on 0.0% coverage — the scanner receives no report in
this flow — masking the security verdict it exists to deliver.

Exit 0 releases; exit 1 **blocks** auto-merge (red quality gate); exit 2 = the
gate could not run (no Docker, invalid token, server down) — auto-merge stays
disarmed and the reason is recorded on the PR.

The verdict comes from the SonarQube **API** (`/api/qualitygates/project_status`),
not from the `sonar-scanner` exit code: the scanner's codes are undocumented by
SonarSource and do not distinguish "red gate" from "execution error" (an invalid
token also exits 1). Reading the status from the API is the path SonarSource
itself recommends.

In CI, remote SAST remains covered by CodeQL (job
`Analyze (javascript-typescript)`); there is no Sonar job in `pr-gates.yml`, to
avoid two SAST tools doing the same work.

**Dependencies / SCA** (`gates.dependencies` in the manifest — Snyk):

```bash
./scripts/check-dependencies.sh
```

Analyzes third-party libraries, not the source code. Requires `SNYK_TOKEN`.

### 2b. Tools not yet present as a script

To configure before making the gate mandatory (gap of this refinement):

```bash
# commit lint — Conventional Commits messages
npx --no-install commitlint --edit $1
```

### 3. Dynamic exception (acceptance/integration) — and coverage

When behavior or contracts changed (`gates.acceptance.when:
behavior_or_contract_changed`):

```bash
./scripts/test-acceptance.sh   # also emits api/coverage/cobertura-coverage.xml
```

Requires LocalStack (the app fixture provisions DynamoDB tables even with the
in-memory repository).

**Coverage origin.** There are no unit suites over `api/src`
(`jest --coverage` via `test:cov` uses `rootDir: src` + `testRegex: .*\.spec\.ts$`
and finds 0 tests). Effective coverage comes from this acceptance suite
(`test/*.e2e-spec.ts`, config `test/jest-e2e.json`). The `jest-e2e.json` was
configured to **instrument `src` during the acceptance run**
(`collectCoverage` + `collectCoverageFrom: src/**/*.ts`) and emit the report in
**Cobertura XML format** (`coverageReporters: [text-summary, cobertura]`), which
is the format GitHub Code Quality consumes. That is why running acceptance
already produces `api/coverage/cobertura-coverage.xml` — there is no separate
coverage step.

In CI, the `acceptance` job in `pr-gates.yml` runs on `pull_request` **and**
`push`; the XML upload via `actions/upload-code-coverage@v1` happens in **two
cases**: a push to `master` publishes the default-branch **baseline**, and the
`pull_request` event (non-fork) attaches the PR's coverage, compared against that
baseline. A push to a feature branch with no PR does **not** upload — the server
only accepts an upload without a PR on the default branch. Informative — it does
not block merge.

## Criterion

If any of these fails locally, the step fails and **does not advance**. The
rationale is simple: failing on the remote pipeline after a push costs more
(rework, notifications, red PR status) than failing locally before.

**On failure, return to `hack tdd` — do not fix it here.** `validate` is an
inspection step with no code writes (see Guardrails); fixing a failure (lint,
build, or red acceptance) is a product change and belongs to Hack's TDD cycle.
Route the failure to [`hack tdd`](../../../hack/steps/tdd/SKILL.md)
(Red → Green → Refactor) and only re-run `validate` after Hack closes green. A
green `validate` is a precondition for `review` and the push.

## Guardrails

- Do not commit, do not write/read code, do not write to artifacts, do not push.
- Do not skip an analysis step without recording the reason.

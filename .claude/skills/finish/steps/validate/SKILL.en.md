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
  `gates.coverage`, `gates.dependencies`, `gates.code-analysis`). The last three are
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

# format — Prettier in check mode (do NOT use `npm run format`: it is
# `--write` and rewrites files)
npx prettier --check "src/**/*.ts" "test/**/*.ts"

# lint — ESLint without --fix (do NOT use `npm run lint`: it is `--fix`)
npx eslint "{src,apps,libs,test}/**/*.ts"

# build — compilation check (clean gate)
npm run build      # nest build
```

> **Why not the `package.json` scripts here.** `npm run format` is
> `prettier --write` and `npm run lint` is `eslint --fix`: both **rewrite**
> files. Running them in this step would violate its own Guardrail ("do not
> write code") and would dirty the tree that the guard below requires clean.
> Fixing what they report is Hack-cycle work.
>
> The `npx eslint` above is **exactly** the command in `pr-gates.yml`'s `lint`
> job. `prettier --check`, by contrast, has no corresponding CI job: it is a
> local check, to catch formatting drift before the push. The manifest records
> `gates.lint` as `cd api && npm run lint` — the form without `--fix` is the
> correct reading of that gate as inspection, and is what CI runs.

> **Coverage** does not belong here: in this repo it is a byproduct of the
> acceptance suite, which is dynamic. See section 3.

**`lint` note:** the script uses `--fix`, which **rewrites** files instead of
failing — useless as a CI gate. To inspect without mutating (what `validate`
requires), run eslint without `--fix`, as `pr-gates.yml` does:
`npx eslint "{src,apps,libs,test}/**/*.ts"` (errors fail; warnings do not — the
repo carries pre-existing warnings and the gate only requires exit 0).

> **Clean-tree guard.** The Hack cycle runs `npm run lint` **with** `--fix`: it
> corrects in place and declares green. If those corrections were never
> committed, CI — which runs without `--fix`, over what is committed — fails on
> exactly the points Hack considered resolved. The divergence is silent: green
> locally, red remotely. Before running lint, confirm the tree is clean:
>
> ```bash
> git status --porcelain   # empty = what you inspect is what CI will see
> ```
>
> A dirty tree is a **blocker**: the pending corrections belong to a commit in
> the Hack cycle, not to this step (`validate` does not commit — see Guardrails).
> Return to [`hack commit`](../../../hack/steps/commit/SKILL.md) before moving on.

### 2. Source code and dependencies

Two complementary gates, both `blocks: auto_merge_only`: a red result disarms
auto-merge, but never prevents a manual merge. They look at different targets —
one the code we write, the other the libraries we import.

**Code analysis** (`gates.code-analysis` in the manifest — local SonarQube,
`api/src` source code):

```bash
./scripts/check-code-analysis.sh          # starts/reuses the container, analyzes
./scripts/check-code-analysis.sh --keep   # keeps the container up for the UI
```

Evaluates maintainability, reliability **and** security. It is not a
security-only gate: SAST is a subset of what SonarQube does, and treating the
two as equivalent understates what a red result is saying.

Runs **locally**, via an ephemeral SonarQube container — the same shape as
LocalStack in the acceptance gate. Requires no secret: the script provisions the
token on the freshly started server. `SONAR_TOKEN` in the environment (or in
`api/.env`) takes precedence if present. The first run takes ~1-2 min until the
server is healthy.

**This gate does not measure coverage.** The script provisions its own quality
gate (`prodops-code-analysis`) with violations, duplication, and security
hotspots, and **removes** the `new_coverage` condition SonarQube automatically
injects into every new gate (via CAYC — "Clean as You Code"). Coverage is the
exclusive responsibility of `gates.coverage`, which is strictly stricter:
branches at 100% over the whole codebase, versus lines at 80% over new code only.
Without that removal the gate would fail on 0.0% coverage — the scanner receives
no report in this flow — masking the verdict it exists to deliver.

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
avoid two tools analyzing the same source code.

**Dependencies / SCA** (`gates.dependencies` in the manifest — Snyk):

```bash
./scripts/check-dependencies.sh
```

SCA (Software Composition Analysis): resolves the dependency tree from
`api/package.json` — direct and transitive — against the Snyk Intel DB. It does
not look at a single line of `api/src`. Requires `SNYK_TOKEN`.

> Three tools, three targets, so the acronyms do not blur:
> `code-analysis` (Sonar, local) analyzes the source code; `dependencies`
> (Snyk, SCA) analyzes third-party libraries; CodeQL (SAST, remote in CI)
> analyzes the source code for vulnerabilities.

### 2b. Commit validator — conditional

Commit messages have **already been validated**: the `commit-msg` hook runs on
every `git commit`, so every commit reaching this point has passed through it.
There is nothing left to re-validate about the messages in this step.

What may have changed is the **validator itself**. When the diff touches the
commit-workflow scripts, run the regression suite — it exercises the validator
through a real `git commit`, in a throwaway repository:

```bash
./prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts/check-commit-msg-suite.sh
```

The script decides for itself whether it needs to run: it compares the current
branch against its base and, if the commit-workflow scripts are not in the diff,
exits 0 without doing anything.

If the diff does **not** touch those scripts, it skips — the validator cannot
have broken. Exit 0 releases; exit 1 means a validator rule regressed, and the
fix belongs to the Hack cycle like any other failure in this step. Exit 2 means
the check **could not decide** (undeterminable base) — in that case the script
runs the suite anyway instead of skipping.

> Why a script and not an inline `git diff | grep`: the inline form fails
> **open**. If the base ref does not exist locally (stale fetch, a placeholder
> pasted literally), `git diff` aborts, `grep` does not match, and the command
> skips the suite silently — exactly when it should have run. The script treats
> an undeterminable base as "run it anyway".

> Why it does not run every time, and why it does not run in CI: a validator
> broken in the restrictive direction (reading the whole message instead of the
> subject) blocks `git commit` itself — the failure shows up immediately,
> locally. And in CI every commit has by definition already passed the hook, so
> there it would be too late to be useful. The suite serves whoever **edits**
> the validator, not every delivery.

### 3. Dynamic exception (acceptance/integration) — and coverage

When behavior or contracts changed (`gates.acceptance.when:
behavior_or_contract_changed`):

```bash
./scripts/test-acceptance.sh          # ~25s; emits api/coverage/cobertura-coverage.xml
./scripts/check-coverage-threshold.sh # gates.coverage: evaluates the fresh XML
```

Requires LocalStack (the app fixture provisions DynamoDB tables even with the
in-memory repository).

**Coverage is evaluated here**, immediately after acceptance: acceptance is what
generates the XML, so this is the only point in the flow where the report is
fresh by construction. `request` does not re-evaluate — it reads the verdict
produced here.

Exit 0 releases; exit 1 **disarms auto-merge**; exit 2 = the gate could not run
(XML missing or invalid).

`blocks: auto_merge_only` describes what the gate blocks **at merge time** — it
disarms auto-merge, it does not prevent a manual merge. It is not permission for
the agent to move on: like every gate in this step, a non-green result **stops
`validate`** (see "Criterion"). The fix goes back to the Hack cycle.

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

**Report the verdict of the three auto-merge gates** — `gates.coverage`,
`gates.dependencies` and `gates.code-analysis` — in this step's summary:
released, blocked, or could not run (and why). `request` reads that report to
decide whether to arm auto-merge, and has no other source: it does not re-run the
gates. Without the report, `request` treats all three as not released and opens
the PR without auto-merge.

## Guardrails

- Do not commit, do not write/read code, do not write to artifacts, do not push.
- Do not skip an analysis step without recording the reason.

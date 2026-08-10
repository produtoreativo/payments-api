# Capability — Commit Workflow

→ [Capabilities](../README.md)

Standardizes the complete cycle of commits, local validations, Pull Request generation and Task closing, using only native Git mechanisms.

## Directory Structure

```
commit-workflow/
├── README.md          ← this file — operational reference for the capability
├── hooks/             ← Git hooks: delegate execution to scripts/
│   ├── pre-commit         pre-commit: format → lint → unit tests
│   ├── prepare-commit-msg applies the message template (without -m, merge or squash)
│   ├── commit-msg         validates Conventional Commits
│   └── pre-push           pre-push: build → integration tests (contracts/quality gates only with Makefile)
├── scripts/           ← validation logic: called by hooks and by CI
│   ├── pre-commit.sh
│   ├── prepare-commit-msg.sh
│   ├── commit-msg.sh
│   ├── pre-push.sh
│   ├── test-commit-msg.sh  commit-msg regression suite (via real `git commit`)
│   └── check-commit-msg-suite.sh  runs the suite only when the scripts changed
└── templates/         ← reusable templates for PR, task-closing and commit message
    ├── commit-template.txt
    ├── pull_request.md
    └── task-closing.md
```

**Hooks** contain only one delegation line — all logic resides in **scripts**. This allows testing scripts independently and reusing them in CI without depending on hooks.

### Testing `commit-msg`

```bash
./prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts/test-commit-msg.sh
```

Runs the validator through a **real** `git commit`, in a throwaway repository
with the same `core.hooksPath` as this repo — the integration path, not just the
script in isolation. Exit 0 = every case passed.

The property the suite protects: **Conventional Commits rules apply to the
subject, not to the whole message**. Reading the entire message (`cat "$1"`)
instead of the subject (`head -1 "$1"`) makes the hook reject any commit with a
body or trailer — and every ProdOps-flow commit carries a `Co-Authored-By:`. The
suite was mutation-verified: injecting that `cat` makes the four subject-scope
cases fail and the suite exit 1.

---

## Principles

- **Git First** — no Husky, no commitlint, no external tools.
- **Language Agnostic** — automatically discovers project commands; never hardcodes a specific technology.
- **Zero dependency** — hooks call scripts from the repository itself; the only external tool used is the `node` already required by the project (to read `package.json`).
- **Maximum reuse** — never duplicates scripts already present in the project.
- **CI = Local** — CI reuses exactly the same commands used locally.

---

## Configuration

### Full environment setup

```bash
./scripts/setup-dev.sh
```

Checks prerequisites, installs npm dependencies, configures `core.hooksPath`, verifies hook permissions. Idempotent.

### Configure hooks only

```bash
git config core.hooksPath prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

To verify:

```bash
git config core.hooksPath
# prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks
```

To remove:

```bash
git config --unset core.hooksPath
```

### Permissions

```bash
chmod +x prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks/*
chmod +x prodops/framework/journeys/delivery/capabilities/commit-workflow/scripts/*.sh
```

The repository stores permissions via `git update-index --chmod=+x`. Verify with:

```bash
git ls-files --stage prodops/framework/journeys/delivery/capabilities/commit-workflow/hooks/
```

---

## Validation Pipeline

| Moment | Hook | What it runs |
|---|---|---|
| Before commit | `pre-commit` | Formatter → Lint → Unit tests |
| On message | `commit-msg` | Conventional Commit format |
| Before push | `pre-push` | Build → Integration tests → Contracts and Quality gates (only when a `Makefile` exists) |

Any step with exit code ≠ 0 blocks the commit or push. There is no "warn only" mode — it either passes or blocks.

### Automatic command discovery

Scripts discover the available commands in this order:

1. `Makefile` — targets: `format`, `lint`, `test`, `build`, `test:acceptance`
2. `Taskfile.yml` / `Taskfile.yaml`
3. `justfile`
4. `api/package.json` — scripts: `lint`, `test`, `build`, `test:acceptance`, `format`
5. `package.json` (root)
6. `Gradle` (`./gradlew`)
7. `Maven` (`./mvnw`)
8. `Go` (`go test`, `go build`)
9. `Python` (`pytest`, `ruff`)
10. `.NET` (`dotnet build`, `dotnet test`)
11. Scripts in `scripts/` (e.g.: `scripts/test-acceptance.sh`)

### Commands in this repository (Node/NestJS)

| Step | Command |
|---|---|
| Formatter | `cd api && npm run format` (prettier) |
| Lint | `cd api && npm run lint` (includes `--fix`) |
| Unit tests | `cd api && npm run test` |
| Build | `cd api && npm run build` |
| Acceptance tests | `./scripts/test-acceptance.sh` |

---

## Conventional Commits

Format:

```
<type>(<scope>): <summary>

[optional body]

[optional footer]
```

- **type** — required, defines the nature of the change.
- **scope** — optional, lowercase, delimits the affected module or domain.
- **summary** — required, imperative mood, lowercase, no trailing period, maximum 72 characters.
- **body** — optional, explains the "why", not the "what".
- **footer** — optional, references to issues, breaking changes (`BREAKING CHANGE:`).

### Types

| Type | When to use |
|---|---|
| `feat` | New functionality visible to the user or API consumer. Increments MINOR in SemVer. |
| `fix` | Correction of incorrect behavior. Increments PATCH. |
| `docs` | Changes exclusively in documentation (`.md`, comments, specs). |
| `test` | Addition or correction of tests without altering production code. |
| `refactor` | Internal change without altering external behavior and without fixing a bug. |
| `perf` | Performance improvement without changing external behavior. |
| `build` | Changes to the build system, dependencies, infrastructure scripts. |
| `ci` | Changes to CI/CD workflows (GitHub Actions, pipeline configurations). |
| `style` | Formatting, spacing, commas — no impact on logic. |
| `chore` | Maintenance tasks that do not fit any type above. |
| `revert` | Reverts a previous commit. The summary must reference the reverted commit. |

### Breaking changes

```
feat(invoices)!: remove billingType PIX from create endpoint
```

Or via footer:

```
BREAKING CHANGE: PIX billing type removed from POST /invoices
```

### Suggested scopes in this repository

| Scope | Module |
|---|---|
| `invoices` | Invoice creation, cancellation, confirmation |
| `auth` | API token validation, admin token management |
| `webhook` | Webhook processing, Asaas events |
| `asaas` | AsaasService, provider integration |
| `dynamo` | DynamoDB, repositories |
| `prodops` | ProdOps documentation |
| `scripts` | Utility scripts |
| `ci` | GitHub Actions workflows |

### Examples

```
feat(invoices): add hosted credit card payment flow
fix(webhook): prevent duplicate PAYMENT_CONFIRMED processing
docs(prodops): unify commit-workflow as capability
test(invoices): add boleto acceptance scenarios
refactor(auth): extract token validation to TokenRepository
chore: update STAGING_ADMIN_SECRET in GitHub Actions
ci: replace --runInBand with --maxWorkers=1 in acceptance tests
```

---

## Integrated flow

```
Hack  → small commit → pre-commit (format + lint + unit tests)
                     → commit-msg (Conventional Commit validated)
Sync  → pre-push (build + integration tests; contracts only with Makefile)
Finish → PR generated with template
```

---

## Finish Checklist

Execute in the order below before publishing the Pull Request.

### 1. Commit history

```bash
git log --oneline origin/HEAD..HEAD
```

- [ ] All commits follow Conventional Commits.
- [ ] There are no unresolved "WIP", "temp", or "fixup" commits.
- [ ] The history tells the story of the change coherently.

### 2. Formatter + Lint

```bash
cd api && npm run format && npm run lint
```

- [ ] Lint passes without errors (exit 0).

### 3. Build

```bash
cd api && npm run build
```

- [ ] Build compiles without TypeScript errors.

### 4. Tests

```bash
cd api && npm run test
./scripts/test-acceptance.sh
```

- [ ] All unit tests pass.
- [ ] All acceptance tests pass.
- [ ] No new test uses business rule mocks.

### 5. Contracts

- [ ] BDD Feature updated if behavior changed.
- [ ] OpenAPI spec updated if a route was added/changed.
- [ ] AsyncAPI updated if an event was added/changed.

### 6. ProdOps Artifacts

- [ ] Architecture diagram updated (if structural change).
- [ ] Event Storming updated (if new events).
- [ ] Release Trail with evidence of this implementation.

### 7. Definition of Done

- [ ] All items in [definition-of-done.md](../../../../../templates/engineering/definition-of-done.md) satisfied.

### Pull Request Generation

```bash
# 1. Review the template
cat prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md

# 2. Create the PR using gh CLI
gh pr create \
  --title "<type>(<scope>): <summary>" \
  --body-file prodops/framework/journeys/delivery/capabilities/commit-workflow/templates/pull_request.md \
  --base main
```

---

## Bypass (emergency)

```bash
git commit --no-verify -m "chore: emergency fix"
git push --no-verify
```

Use only in real emergencies. Document the rationale in the commit body or Decision Trail.

---

## Consuming phases

| Phase | Moment |
|---|---|
| Hack | After each Red→Green→Refactor cycle |
| Sync | After rebase/branch update |
| Finish | Final validation before PR |

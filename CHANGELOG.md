# Changelog — ProdOps Framework

All notable changes to the ProdOps Framework are documented here.

Format: [Semantic Versioning](https://semver.org/). Each entry links to the source
export from `payments-api` (empirical upstream) when applicable.

---

## [1.11.0] — 2026-08-16

### Added

- `prodops/scripts/setup-mac.sh` — bootstrap completo para macOS via Homebrew:
  - Instala Homebrew se ausente; configura `brew shellenv` em `.zshrc`/`.bash_profile` no Apple Silicon
  - Instala `bash ≥ 4`, `git`, `curl`, `jq`, `gawk`, `diffutils`, `gnu-sed`, `python3`, `PyYAML`
  - Instala `nvm` + `Node.js 20`, `gh` (GitHub CLI), `Docker Desktop` (via `brew cask`)
  - Suporte a `GITHUB_TOKEN` para autenticação sem browser
  - Clona `payments-api`, executa `npm install` e valida com `check-env.sh`
  - Flag `--optional` instala `aws-cli`, `aws-cdk`, `cdklocal`, `awslocal`, `ripgrep`
  - Relatório de instalação no final: tabela com nome, descrição, status e detalhe de cada ferramenta
  - Adicionado ao `export-manifest.yaml` e ao gate `validate-export-manifest.sh`

### Changed

- `setup-wsl.sh` e `setup-mac.sh` — `PRODOPS_VERSION` exibida no cabeçalho de execução

### Fixed

- `setup-wsl.sh` — `DOCKER_INSTALLED` não era marcado `true` após instalação via winget,
  fazendo o fallback de download direto sempre executar mesmo com winget bem-sucedido
- `setup-mac.sh` — `declare -A` (array associativo) substituído por array indexado simples,
  corrigindo falha de syntax com bash 3.2 (padrão do macOS) antes da instalação do bash 4

---

## [1.10.0] — 2026-08-16

### Added

- `setup-wsl.sh` — instalação automática do Docker Desktop no contexto Windows (Contexto A):
  - Detecta Docker via WSL e `Get-Command docker` no Windows
  - Instala via `winget` (preferencial) com detecção de arquitetura AMD64/ARM64
  - Fallback para download direto do instalador oficial
  - Orienta habilitação da integração WSL2 após instalação

- `setup-wsl.sh` — relatório de instalação no final do Contexto B (Ubuntu):
  - Tabela com tecnologia, descrição, status (`OK` / `JÁ INSTALADO` / `ATENÇÃO` / `FALHOU`) e detalhe
  - Contador de totais por categoria ao final

---

## [1.9.0] — 2026-08-12

### Changed

- `prodops/scripts/setup-wsl.sh` — reescrito como bootstrap completo de ambiente:
  - **Contexto A — Windows (Git Bash/MSYS2):** detecta Ubuntu no WSL2; se ausente,
    instala `Ubuntu-24.04` via `wsl --install` e reinvoca o script dentro dele
  - **Contexto B — Ubuntu/WSL2 ou nativo:** instala todas as dependências,
    autentica `gh`, clona `payments-api`, executa `npm install` e valida com
    `check-env.sh` ao final
  - Suporte a `--optional` para `aws-cli v2`, `aws-cdk`, `cdklocal`, `awslocal`, `ripgrep`
  - One-liner funcional: `curl -fsSL <url> | bash`
  - Exit code `1` em SO não suportado ou falha fatal

---

## [1.8.0] — 2026-08-12

### Added

- `prodops/scripts/setup-wsl.sh` — script de instalação automática de ambiente para
  WSL2 (Ubuntu/Debian), cobrindo todas as ferramentas exigidas por `check-env.sh`:
  - Instala `git`, `curl`, `jq`, `awk`, `diff`, `sed`, `uuid-runtime`, `python3`,
    `PyYAML` via `apt` e `pip3`
  - Instala `nvm` + `Node.js 20` e configura `~/.bashrc` / `~/.zshrc`
  - Instala `gh` (GitHub CLI) via repositório oficial
  - Valida presença do Docker e guia integração WSL2 com Docker Desktop
  - Flag `--optional` instala `aws-cli v2`, `aws-cdk`, `cdklocal`, `awslocal`, `ripgrep`
  - Orientações pós-instalação: `gh auth login` e `check-env.sh --fix-hints`
  - Adicionado ao `export-manifest.yaml` e ao gate `validate-export-manifest.sh`

---

## [1.7.0] — 2026-08-12

### Added

- `prodops/scripts/check-env.sh` — novo script canônico que verifica se todas as
  ferramentas e configurações de runtime necessárias estão presentes no ambiente
  de desenvolvimento:
  - Suporte a `--fix-hints` para exibir comandos de instalação de cada ferramenta ausente
  - Saída com símbolos ✅ / ⚠️ / ❌ e exit code `1` quando qualquer ferramenta está ausente
  - Adicionado ao `export-manifest.yaml` como script canônico exportável
  - Validação pelo `validate-export-manifest.sh` no gate de exports

---

## [1.6.2] — 2026-08-11

### Fixed

- `prodops/scripts/install-prodops.sh` — consumer root files are now explicitly
  protected from being overwritten by the framework file-copy step:
  - `is_protected()` returns unconditionally for `README.md`, `README.en.md`,
    `.gitignore`, `.gitattributes`, `LICENSE`, and `CHANGELOG.md` — these paths
    are always skipped, regardless of whether they exist in the target repo
  - Step 4 adds a paranoia guard that rejects any path not starting with
    `prodops/`, making the architectural boundary auditable even if the `find`
    scope changes in the future

---

## [1.6.1] — 2026-08-11

### Fixed

- `prodops/scripts/install-prodops.sh` — Steps 11 and 12 now detect changes and
  update on re-runs instead of skipping silently:
  - **CLAUDE.md** (Step 11): compares existing file with the canonical framework
    template; if different, backs up as `CLAUDE.md.bak.YYYYMMDD-HHMMSS` and
    writes the updated template. Reports `up to date` when content matches.
  - **AGENTS.md** (Step 12): same backup-and-overwrite logic; the update path
    regenerates the template (substituting `PRODUCT_NAME`) into a temp file, diffs
    against the installed copy, and only overwrites when content diverges. Backup
    path is added to manual steps so operators can re-apply their customizations.

---

## [1.6.0] — 2026-08-11

### Changed

- `prodops/scripts/install-prodops.sh` — now works as both **install** and **update**:
  - Detects mode automatically: reads `framework-lock.yaml` to determine if it is a
    fresh install or a version update; prints `Mode: fresh install` or
    `Mode: update (vX → vY)` in the header
  - **Step 5** — on update, rewrites version fields in the existing `framework-lock.yaml`
    in place (preserves consumer content); on fresh install, creates the file as before
  - **Step 5b** (new) — updates `framework-version` in `prodops/runtime/runtime.yaml`
    after every install or update, eliminating silent version drift between the lock file
    and the runtime config
  - `is_protected()` now guards `prodops/runtime/runtime.yaml` against being overwritten
    by the framework file-copy step
  - `.prodopsignore` template now includes `prodops/runtime/runtime.yaml` with an
    explanatory comment, so `sync-from-framework.sh` also skips it
  - Commit message suggestion switches to
    `chore(prodops): update ProdOps Framework vX → vY` on update mode

- `prodops/scripts/sync-from-framework.sh` — after updating `framework-lock.yaml`,
  now also updates `framework-version` in `prodops/runtime/runtime.yaml` if present;
  PR body lists `prodops/runtime/runtime.yaml` as a protected path

### Fixed

- `prodops/scripts/diligence/ensure-fields.sh` — all custom field names changed from
  space separator to hyphen separator to match `sync.sh` expectations and the project 25
  canonical structure (e.g. `oem state` → `oem-state`, `diligence status` →
  `diligence-status`, `runtime sync` → `runtime-sync`); `oem cycle` renamed to `Cycle`
  to align with `sync.sh` and project 25
- `prodops/scripts/diligence/ensure-views.sh` — replaced 4 views (Iteration Backlog,
  Delivery Board, Delivery Blocked, Delivery Done) with the single board view
  `"01 — Delivery Timeline"` that matches project 25; removed `ITERATION_ID` /
  `JOURNEY_VALUE` env vars that are no longer needed
- `prodops/scripts/diligence/ensure-issues.sh` — field name references updated from
  space to hyphen convention, consistent with `ensure-fields.sh`

---

## [1.5.0] — 2026-08-11

### Added

- `prodops/framework/product-deck.md` + `.en.md` — canonical Product Deck artifact
  definition distributed as a framework file. Previously referenced in glossary and
  artifact-types (v1.4.0) but not distributed to consumers.
- `prodops/framework/service-deck.md` + `.en.md` — canonical Service Deck artifact
  definition distributed as a framework file. Same promotion path as product-deck.

### Changed

- `prodops/scripts/install-prodops.sh` — complete rewrite. Now runs all installation
  steps autonomously in a single command:
  - Step 9: configures `git config core.hooksPath` automatically; detects non-git repos
  - Step 10: calls `install-claude.sh` to set up `.claude/` structure
  - Step 11: generates `CLAUDE.md` with canonical agent instruction template
  - Step 12: generates `AGENTS.md` with full work-reception protocol, journey table,
    and pre-authorized permissions for subagents
  - Step 13: runs `doctor.sh` and surfaces only `FAIL:` lines
  - Step 14: runs `validate-manifest.sh` (skips automatically when placeholders remain)
  - Adds colored terminal output: section headers, per-step `[OK]` / `[SKIP]` / `[WARN]`
  - Collects warnings and pending manual steps; prints actionable summary at the end
  - New flags: `--skip-hooks`, `--skip-claude`

---

## [1.4.0] — 2026-08-07

### Added

- `prodops/framework/artifact-types.md` / `.en.md` — sections for Product Deck and
  Service Deck artifacts (canonical path, relations, journeys)
- `prodops/framework/glossary.md` / `.en.md` — definitions for Product Deck and
  Service Deck (when to use, relations, location)
- `prodops/framework/README.md` / `.en.md` — artifact table updated with Product Deck
  and Service Deck entries

### Changed

- `prodops/runtime/tools/emit-event/scripts/emit-event` — auto-loads `DD_API_KEY`
  from `api/.env` if not set in the environment, eliminating silent metric emission
  failures in local development

---

## [1.3.0] — 2026-08-06

### Changed

- `prodops/scripts/install-prodops.sh` — generalized install flow; removed
  product-specific references from generated templates
- `prodops/scripts/doctor.sh` — fixed false positives on optional paths

---

## [1.2.0] — 2026-08-06

### Added

- `prodops/scripts/install-prodops.sh` — new installation script: clones framework at
  a specified version, creates directory structure, generates `manifest.yaml` and
  `framework-lock.yaml` templates, creates `.prodopsignore`, seeds `artifacts/` tree
- `prodops/scripts/install-claude.sh` — installs `.claude/` structure (skills, agents,
  `settings.json`) into any consumer repository
- `prodops/scripts/sync-from-framework.sh` — manual sync script for consumers to pull
  framework updates as a PR

---

## [1.1.0] — 2026-08-05

### Added

- `prodops/runtime/` — Reference Implementation (RI) of the ProdOps delivery runtime,
  validated with Datadog and GitHub integrations. Consumers copy `runtime.yaml.example`,
  fill in their config, and extend in their own repo.
  - `catalog/events.yaml` — 47-event canonical catalog covering Delivery and Diligence journeys
  - `consumer/` — `derive-state.sh`, `derive-diligence-state.sh`
  - `datadog/` — `send.sh` (metrics publisher), `runtime-dashboard.json`, `dashboards/v3.4.0.json`
  - `dispatcher/` — `dispatch.sh` (subscription router), `trail.sh` (GitHub trail comments)
  - `docs/contract.md` — CloudEvent contract reference
  - `github/sync.sh` — idempotent GitHub Project v2 field sync
  - `producer/emit.sh` — CloudEvent factory
  - `subscriptions/delivery-diligence.yaml` — canonical subscription declarations
  - `timeline/append.sh` — append-only CloudEvent timeline writer
  - `tools/emit-event/` — complete 5-step CLI tool with JSON-in/JSON-out contract,
    unit tests (01–10), chain tests, and cross-player conformance test suite
  - `tools/restart-feature/` — non-destructive Delivery Journey restart tool
  - `scripts/` — `validate-event.sh`, `runtime-doctor.sh`, `project-cleanup.sh`,
    `create-github-views.sh`
  - `runtime.yaml.example` — consumer configuration template

### Changed (RI generalization)

- `datadog/send.sh`: removed `../api/.env` credential fallback; `DD_API_KEY` must
  be set as an environment variable
- `scripts/runtime-doctor.sh`: same credential change; removed `EXP-013` experiment
  label from banner
- `dispatcher/trail.sh`: translated all 13 event message templates from Portuguese
  to English; removed hardcoded branch name from sync message
- `tools/emit-event/scripts/emit-event`: removed hardcoded `"experiment":"EXP-015"`
  from evidence `_meta` block
- `tools/restart-feature/scripts/restart-feature`: added `--iteration-id` parameter;
  removed three hardcoded `"IP-EXP016-F03-RESTART"` iteration ID values

---

## [1.0.0] — 2026-08-05

### Breaking changes

- Removed duplicate root-level layout (`framework/`, `journeys/`, `skills/`,
  `templates/`, `execution-model/`). All canonical content now lives under `prodops/`.
- Removed product-specific experiments leaked from `payments-api`
  (`journeys/discovery/experiments/001–007`).

### Added

- `prodops/framework/artifact-types.md` + `.en.md` — canonical artifact type reference
- `prodops/framework/principles.md` + `.en.md` — 11 canonical ProdOps principles
- `prodops/framework/ontology.md` + `.en.md` — framework ontology
- `prodops/framework/positioning.md` — framework positioning document
- `prodops/skills/diligence/` — full Diligence Sync, Diligence Async, Workspace Reconciliation
- `prodops/skills/upstream/steps/deploy-to-sandbox/` — sandbox deploy step
- `consumers.yaml` — consumer registry for CI propagation

### Structure

```
prodops-framework/
  prodops/
    framework/     ← canonical framework docs
    skills/        ← canonical skills
    templates/     ← canonical templates
    scripts/       ← doctor.sh, validate-manifest.sh, validate-export-manifest.sh
  LICENSE
  README.md / README.en.md
  CHANGELOG.md
  consumers.yaml
```

---

## [0.1.0] — 2026-08-04

Initial export from `payments-api` empirical upstream via `export-framework.sh`.
Established base structure for framework distribution.

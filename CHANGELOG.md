# Changelog — ProdOps Framework

All notable changes to the ProdOps Framework are documented here.

Format: [Semantic Versioning](https://semver.org/). Each entry links to the source
export from `payments-api` (empirical upstream) when applicable.

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

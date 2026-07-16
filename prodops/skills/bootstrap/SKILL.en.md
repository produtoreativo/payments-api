---
name: bootstrap
description: Prepare the local environment required by a ProdOps execution before Git flow, tests, or implementation begin.
---

# BOOTSTRAP

Bootstrap prepares the execution environment. It does not assess product readiness, read implementation code or tests, create branches, or implement behavior.

Product readiness belongs to the `/downstream` orchestrator. Git flow belongs to `/hack start`.

## Inputs

- Repository setup scripts and package manifests
- Environment variable names from example files
- Local infrastructure configuration
- Bootstrap and smoke gates from `prodops/exec/manifest.yaml`

OBCs, BDD Features, risks, Reliability Plans and the Iteration Plan are not Bootstrap inputs.

## Flow

1. Identify the packages and local services required by the repository.
2. Verify required runtimes and command-line tools are available.
3. Install dependencies using the repository's declared package manager.
4. Prepare local infrastructure through the repository setup scripts.
5. Verify required environment variable names without reading or exposing secret values.
6. Run the smoke gate defined in `prodops/exec/manifest.yaml`.
7. Report the environment as ready or return a concrete blocker.

## Guardrails

- Do not read or modify production implementation code.
- Do not inspect or execute behavior tests; those belong to Hack and Finish.
- Do not create, switch, merge, rebase, stash, or delete Git branches.
- Do not read or create OBCs, BDD Features, risks, Reliability Plans or Iteration Plan entries.
- Do not generate a context capsule.
- Do not expose `.env` values, tokens, credentials or PII.
- Do not silently discard local work.

## Post-conditions

- Dependencies are installed.
- Required local services are available.
- Environment configuration requirements are known without secrets being exposed.
- The smoke gate passes, or the environment blocker is explicit.
- `/hack start` can establish the Git flow after Downstream readiness is reached.

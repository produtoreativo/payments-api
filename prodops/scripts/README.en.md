# prodops/scripts/

Deterministic automation scripts for the ProdOps Framework.

---

## Skill vs. Script

| | Skill | Script |
|---|---|---|
| **Nature** | Interpretive, decision-making instruction | Deterministic automation of a step |
| **Executed by** | Agent (Claude Code, Copilot, Codex) | Shell (bash) |
| **Replaces the other?** | No | No |
| **Context** | Reads artifacts, makes decisions, guides the agent | Executes a fixed sequence, validates state, reports |

A Script **does not replace** its corresponding Skill. The Skill describes the intent and the decision; the Script automates the deterministic part of the execution.

---

## Canonical scripts

Generic and reusable scripts. They contain no product knowledge. They work in any repository that follows the ProdOps Framework.

| Script | Responsibility | Related Skill |
|---|---|---|
| `doctor.sh` | Validates the canonical ProdOps structure in the repository: required paths, markdown links, absence of legacy paths, `framework-lock.yaml` integrity, and `.prodopsignore` protections. | Used as a gate in all phases |
| `validate-manifest.sh` | Validates the declarative consistency of `prodops/exec/manifest.yaml`: declared paths exist, `commit_types` matches the `commit-msg.sh` hook, `commit_summary_max` is aligned. | Any phase — manifest maintenance |

These scripts are protected for Framework sync. They are listed in `prodops/framework/canonical-paths.en.md`.

---

## Product-local scripts

Scripts specific to the payments-api product. They may depend on directory structures, runtime commands, and conventions of this API. They are not portable without modification.

Location: `prodops/scripts/local/`

Protected from sync by `.prodopsignore` — see `prodops/scripts/local/README.en.md`.

---

## Application runtime scripts

Application build, start, test, and deploy scripts do **not** reside in `prodops/scripts/`. They remain alongside the application (`api/`, `Makefile`, `package.json`).

---

## Dependency direction

```
Framework Skill      → may invoke canonical scripts (doctor.sh, validate-manifest.sh)
Framework Skill      → does NOT know specific local script names
Product Skill        → may invoke canonical, local, or application scripts
Canonical scripts    → do NOT depend on local scripts
Local scripts        → may read the manifest, artifacts, and invoke canonical scripts
```

---

## Discovery

```bash
# List all available scripts
find prodops/scripts -name "*.sh" | sort

# Run canonical validation
./prodops/scripts/doctor.sh

# Validate manifest consistency
./prodops/scripts/validate-manifest.sh

# Local automation: Sync (rebase + align)
./prodops/scripts/local/sync.sh --help
```

---

## Relationship with manifest, artifacts, and .prodopsignore

- **manifest.yaml** — canonical and local scripts may read the manifest as a declarative source of truth.
- **prodops/artifacts/** — canonical scripts validate the existence of artifact paths; local scripts may inspect content.
- **.prodopsignore** — protects `prodops/scripts/local/` from Framework sync overwrites.

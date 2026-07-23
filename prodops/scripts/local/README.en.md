# scripts/local/

Automations and adapters specific to the payments-api product.

- Belong to this repository, not to the canonical ProdOps Framework.
- Remain versioned — never delete without a recorded deprecation.
- May consume the manifest, artifacts, and canonical scripts as inputs.
- Canonical scripts (`doctor.sh`, `validate-manifest.sh`) **do not depend** on any specific local script.
- Product Skills may invoke them by name — the script name is conventional, not mandated by the Framework.
- Application runtime scripts (build, start, test) remain alongside the application and are **not** copied here.
- Protected from sync by `.prodopsignore` — Framework updates do not overwrite this directory.

## Available scripts

| Script | Purpose |
|---|---|
| `sync.sh` | Automation for the Sync phase (rebase + ProdOps align). Replaces manual execution of git and artifact alignment steps. See the Skill at `prodops/skills/sync/SKILL.md`. |

## Usage

```bash
# Full flow (rebase → align)
./prodops/scripts/local/sync.sh

# Rebase only
./prodops/scripts/local/sync.sh rebase

# Align only
./prodops/scripts/local/sync.sh align

# Dry-run (prints commands without executing)
./prodops/scripts/local/sync.sh --dry-run
```

## Dependencies

`sync.sh` requires:
- `git` (rebase/merge operations)
- `npm` (API lint and tests — `cd api && npm run lint / test`)
- `api/src/modules/` structure for NestJS module detection

## Ownership

These scripts belong to the product. Before modifying them, consult the corresponding Skill (`prodops/skills/sync/SKILL.md`) to ensure behavior remains aligned with the Framework.

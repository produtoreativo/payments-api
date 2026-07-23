# Empirical Upstream Role

The `payments-api` repository temporarily acts as the empirical upstream of the ProdOps Framework.

---

## What `status: self` means

`status: self` in `prodops/exec/framework-lock.yaml` indicates that this repository is simultaneously:
- the consumer product of the Framework;
- the temporary source of truth for the Framework itself.

This does **not** mean that the Payments domain is part of ProdOps.
It means that the canonical definitions are still evolving empirically in this repository.

---

## Why this state exists

The separate `prodops-framework` repository exists and is being prepared to receive the
reconciled canonical content. During this phase, all Framework evolution occurs here,
with a clear semantic separation of local areas.

---

## Active boundaries

**What is canonical (will be exported to `prodops-framework`):**
- `prodops/framework/` — principles, glossary, ontology, flow, canonical-paths, journeys
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/` — canonical Framework engineering practice
- `prodops/templates/` — canonical templates
- `prodops/scripts/doctor.sh`, `prodops/scripts/validate-manifest.sh`, `prodops/scripts/validate-export-manifest.sh`

**What is product-local (never exported):**
- `prodops/artifacts/` — OBCs, BDD, plans, trails, intents, evidence
- `prodops/skills/local/` — Skills specific to this API
- `prodops/skills/references/local/` — local product literature and conventions
- `prodops/scripts/local/` — local product automations
- `prodops/exec/` — entire operational execution space

The declarative export contract is at: `prodops/exec/export-manifest.yaml`

---

## What NOT to do during this phase

- **Do not execute** `scripts/sync-framework-docs.sh` — disabled by an explicit guard (see inline in the file).
  The script is disabled because it references stale paths and does not respect the declarative export boundary.
- **Do not change** `status: self` manually without completing the transition described in `export-boundary.en.md`.
- **Do not export** local artifacts as if they were canonical.
- **Do not treat** Payments examples as mandatory Framework structure.
- **Do not rewrite** historical trail entries (append-only).

---

## Current state of canonical content

The canonical content in `prodops/framework/` has been generalized and no longer contains
structural references to the Payments domain. Pedagogical product examples have been replaced
with generic placeholders (`feature-name-v2`, `product-a`, `<entity>.*`).

Product runbooks have been moved to `prodops/artifacts/runbooks/`.

The discovery trail at `prodops/framework/journeys/discovery/upstream-trail.en.md` contains
a `# History` section marked as an empirical record — preserve it as append-only.

---

## Future transition

When `prodops-framework` is ready to receive the reconciled content:

1. Export canonical content per `prodops/exec/export-manifest.yaml`.
2. Publish initial version with tag and LICENSE in `prodops-framework`.
3. Update `prodops/exec/framework-lock.yaml`:
   - `status: self` → `status: consumer`
   - Fill in `external_source`, `synchronization_mechanism`, `version`
4. Align `scripts/sync-framework-docs.sh` with `export-manifest.yaml` before any use.
5. Run `prodops/scripts/doctor.sh` — must continue passing.
6. Local areas (`artifacts/`, `skills/local/`, etc.) remain untouched.

---

## References

- Export contract: `prodops/exec/export-manifest.yaml`
- Boundary documentation: `prodops/exec/export-boundary.en.md`
- Distribution lock: `prodops/exec/framework-lock.yaml`
- Canonical paths: `prodops/framework/canonical-paths.md`

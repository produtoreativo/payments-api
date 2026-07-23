# ProdOps Framework Export Boundary

This document explains the ownership and distribution model of the ProdOps Framework
while this repository (`payments-api`) acts as the empirical upstream. The declarative
contract lives in `prodops/exec/export-manifest.yaml`; this document explains the
model — it does not replicate it.

---

## Purpose of this boundary

The ProdOps Framework evolved empirically in this repository. To reconcile with
the existing canonical `prodops-framework` repository, it is necessary to define precisely:

1. What belongs to the Framework and must be exported.
2. What belongs to the product and must never be overwritten.
3. What the Framework defines as consumer space (convention-only).
4. What describes how the consumer installed the Framework (installation-state).

This boundary allows the extraction to be performed safely and ensures that the
sync mechanism respects ownership invariants.

---

## Fundamental distinction: export, installation, and synchronization

| Concept | Definition | Who executes |
|---|---|---|
| **Export** | Copy exportable content from this repository to `prodops-framework`. | Human or extraction tool. Happens once. |
| **Installation** | Initialize a consumer product with the Framework (create `exec/manifest.yaml`, `exec/framework-lock.yaml`, directory structure). | CI or product operator. Happens on adoption. |
| **Synchronization** | Propagate Framework updates from the canonical repository to installed consumers. | Future mechanism (CI+PR). Happens on updates. |

These three processes are distinct and must not be confused. This file and
`export-manifest.yaml` describe **export** only.

---

## The four content classifications

### 1. Exportable

Content that belongs to the Framework and must be copied to the
`prodops-framework` repository.

**Examples:**
- `prodops/framework/` — principles, glossary, ontology, flow, canonical-paths
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/` — canonical engineering references (TDD ProdOps)
- `prodops/templates/` — canonical templates
- `prodops/scripts/doctor.sh`, `prodops/scripts/validate-manifest.sh`, `prodops/scripts/validate-export-manifest.sh`

### 2. Consumer-owned

Content that belongs to the consumer product and must never be overwritten by sync.
Declared in `.prodopsignore`.

**Examples:**
- `prodops/artifacts/` — OBCs, BDD, plans, trails, intents, product evidence
- `prodops/exec/manifest.yaml` — product operational configuration
- `prodops/exec/framework-lock.yaml` — product distribution lock
- `prodops/exec/cards/` — execution work cards (ephemeral)
- `prodops/skills/local/` — product-local Skills
- `prodops/skills/references/local/` — product-local references
- `prodops/scripts/local/` — product-local scripts

### 3. Convention-only

Paths whose **schema** is defined by the Framework, but whose **content**
belongs to the consumer. The Framework declares that these spaces exist and
documents them — but does not export or control their content.

| Path | What the Framework defines | What the consumer controls |
|---|---|---|
| `prodops/artifacts/` | Directory structure, artifact schemas | All product artifacts |
| `prodops/skills/local/` | Directory existence and its README | Product-specific Skills |
| `prodops/skills/references/local/` | Existence and purpose | Local literature and conventions |
| `prodops/templates/local/` | Existence and purpose | Local template adaptations |
| `prodops/scripts/local/` | Existence and purpose | Local automations and adapters |

### 4. Installation state

Files that describe how a consumer installed or tracks the Framework.
Not simply canonical nor simply local — they require special treatment.
Generated locally on initial installation and never overwritten by sync.

| File | Role |
|---|---|
| `prodops/exec/manifest.yaml` | Product operational configuration (generated on adoption) |
| `prodops/exec/framework-lock.yaml` | Installed version and drift status (generated on adoption) |
| `.prodopsignore` | Product area protection declaration |

---

## What is included and why

The `export-manifest.yaml` includes:

- **`framework/**`** — The Framework's conceptual structure: principles, glossary,
  ontology, flow, journeys, capabilities, practices, execution model, and canonical-paths.
  This is the core of the distribution.

- **`skills/**`** — The Framework's canonical Skills (excluding `skills/local/**` and
  `skills/references/local/**`). These are the Framework's execution mechanism for agents.

- **`templates/**`** — Canonical artifact templates (excluding `templates/local/**`).
  They allow consumers to create Framework-conformant artifacts.

- **`scripts/doctor.sh`** — Canonical structural validation. Exportable because it
  validates Framework structure, not product content.

- **`scripts/validate-manifest.sh`** — Manifest consistency validation.
  Exportable for the same reason.

- **`scripts/validate-export-manifest.sh`** — Export boundary validation.
  Exportable as a transitional canonical script.

---

## What is excluded and why

- **`skills/local/**`** — Consumer-owned. Each product has its own local Skills.

- **`skills/references/local/**`** — Literature and conventions chosen by the product.
  Other products make different choices.

- **`templates/local/**`** — Local template adaptations. Product-specific.

- **`scripts/local/**`** — Local automations and adapters. Not portable.

- **`artifacts/**`** — Product Knowledge Space: OBCs, BDD, plans, trails,
  intents, evidence. Entirely product-specific.

- **`exec/**`** — Installation state and product operational configuration.
  Generated locally; never distributed by the Framework.

---

## State of transformations after internal canonicalization

Internal canonicalization is complete. The transformations previously identified
have been applied to this repository. Exportable content in `framework/` is now generic.

### 1. `remove-empirical-references` — **RESOLVED**

Structural references to `payments-api` have been generalized:
- `framework/operating-model.md` and `.en.md` — generic
- `framework/glossary.md` and `.en.md` — generic
- `framework/README.md` and `.en.md` — generic
- `framework/artifact-governance.md` — generic
- `framework/principles.md` and `.en.md` — `ASAAS_MOCK=true` replaced with generic placeholder

### 2. `generalize-product-examples` — **RESOLVED**

Product-specific examples have been generalized:
- `framework/journeys/operation/runbooks.md` and `.en.md` — now canonical Runbook definition
- `framework/execution-mapping/matrix.md` — NestJS/DynamoDB/SQS replaced with placeholders
- `framework/execution-mapping/work-item-schema.md` — payments-invoice-v2 replaced with feature-name-v2
- `framework/dora-metrics.md` and `.en.md` — specific events replaced with generic patterns
- `framework/backlogs.md` and `.en.md` — specific product names removed
- `framework/knowledge-vs-execution.md` and `.en.md` — examples generalized
- `framework/journeys/operation/README.md` and `.en.md` — webhook/payment refs generalized

The product runbook was preserved in `prodops/artifacts/runbooks/payments-api-runbook.en.md`.

### 3. `extract-discovery-history` — **SEPARATED (not moved)**

The discovery trail at `framework/journeys/discovery/upstream-trail.md` has a `# History`
section with an explicit contextual note identifying it as a product empirical record.
The separation is semantic (via section marker) — files remain in place as append-only records.

Files **not** to export as canonical content:
- `framework/journeys/discovery/upstream-trail.md` (section `# History`) — product history
- `framework/journeys/discovery/experiments.md` — product experiment index
- `framework/journeys/discovery/learnings.md` — product learnings

### 4. `disable-sync-script` — **COMPLETED**

`scripts/sync-framework-docs.sh` has been disabled with an explicit guard that returns
exit code 1 before any operation. The original content was preserved below the guard for
future reference.

---

## Current state of the boundary

**Content in `framework/` is generic and ready for extraction.**

Non-blocking pending items (do not prevent export, must be addressed before any
automated sync mechanism):

1. **Export mechanism:** `scripts/sync-framework-docs.sh` needs to be aligned with
   `export-manifest.yaml` before any use. The script is disabled.
2. **`framework/journeys/discovery/upstream-trail.md`:** the `# History` section is product-specific
   and must not be included in the canonical export. The `export-manifest.yaml` must include
   an explicit exclusion or transformation for this file.
3. **Link validation:** after export to `prodops-framework`, relative links must be verified.

---

## Layout of the prodops-framework repository

### Alternative A — Preserve prodops/ level (recommended)

```
prodops-framework/
├── README.md
├── README.en.md
├── LICENSE
└── prodops/
    ├── framework/
    ├── skills/
    ├── templates/
    └── scripts/
```

### Alternative B — Promote to root

```
prodops-framework/
├── README.md
├── framework/
├── skills/
├── templates/
└── scripts/
```

**Recommendation: Alternative A.**

Justification:

1. **Relative links are calibrated.** All relative links in Framework files are
   computed from within `prodops/`. For example, `../../artifacts/` assumes the
   file is two levels below `prodops/`. Alternative A preserves this geometry
   without modifications.

2. **Consistency with consumers.** Consumers install the Framework under `prodops/` —
   the path `prodops/framework/` is consistent between the canonical repository and
   consumer repositories.

3. **Zero link transformation cost.** Alternative B would require rewriting all
   relative links in all exported files before distribution.

4. **Purpose clarity.** The `prodops/` directory explicitly signals content scope —
   this is not a generic project; it is ProdOps content.

---

## Minimum root files for the prodops-framework repository

| File | Necessity | Version |
|---|---|---|
| `README.md` | Required | 0.1.0 |
| `README.en.md` | Recommended | 0.1.0 |
| `LICENSE` | Required | 0.1.0 |
| `CHANGELOG.md` or tag strategy | Required | 0.1.0 |
| `AGENTS.md` | Required (Framework parts only) | 0.1.0 |
| `CONTRIBUTING.md` | Recommended | later |
| `CODE_OF_CONDUCT.md` | Recommended | later |
| `SECURITY.md` | Not required | later |
| `.github/` | Partial (Framework-relevant templates only) | later |

**Note on AGENTS.md:** The payments-api `AGENTS.md` contains both Framework canonical
routing and product-specific configuration (gates with `npm run lint`, LocalStack,
NestJS, etc.). The prodops-framework repository must have an `AGENTS.md` that
extracts only the Framework's canonical parts.

---

## Version 0.1.0 entry criteria

- [ ] Export boundary validated (`export-manifest.yaml` exists and passes `validate-export-manifest.sh`)
- [ ] Doctor exits 0 with zero FAILs
- [ ] Internal links valid
- [ ] No product-specific content in exportable files (transformations applied)
- [ ] Canonical templates complete
- [ ] Canonical Skills discoverable via manifest
- [ ] Export manifest valid (YAML)
- [ ] Minimum root documentation (`README.md`, `README.en.md`)
- [ ] License defined
- [ ] Versioning strategy defined (CHANGELOG or tag strategy)

---

## Future self → consumer transition process

**This process is documented only. Do not execute.**

The sequence for transitioning payments-api from `status: self` to
`status: consumer`:

1. Extract the Framework to the `prodops-framework` repository (applying the
   transformations identified in this document).
2. Publish the initial version (`0.1.0`) with tag and LICENSE.
3. Record source and version in payments-api's `prodops/exec/framework-lock.yaml`.
4. Change payments-api's `prodops/exec/framework-lock.yaml`:
   `status: self` → `status: consumer`.
5. Validate installed content against the published version.
6. Preserve local areas (`artifacts/`, `skills/local/`, etc.) — untouched.
7. Open a transition PR with evidence.
8. Run `doctor.sh` — must continue passing.
9. Remove empirical upstream role: this file (`export-manifest.yaml`) and
   `export-boundary.md` may be removed or kept as historical record.

**Expected framework-lock.yaml after transition:**

```yaml
prodops_framework:
  version: "0.1.0"
  status: consumer
  source_repository: prodops-framework
  external_source: https://github.com/<org>/prodops-framework
  synchronization_mechanism: ci-pr-sync

distribution:
  state: installed
  lock_mode: managed
  update_procedure: open-pr-from-framework

drift:
  status: ok
  reason: Content matches installed version 0.1.0.
```

**Note:** The fields `external_source`, `synchronization_mechanism`, and
`distribution.update_procedure` already exist in the current `framework-lock.yaml`
schema (as `null`). The transition will populate these fields without requiring
schema evolution. The `distribution.state` field will change from `empirical` to
`installed`.

---

## Future synchronizer invariants

Any future synchronization mechanism (CI+PR sync) **MUST**:

1. Never overwrite `artifacts/`
2. Never overwrite `skills/local/`
3. Never overwrite `skills/references/local/`
4. Never overwrite `templates/local/`
5. Never overwrite `scripts/local/`
6. Preserve the local manifest (`exec/manifest.yaml`)
7. Preserve the lock, modifying only controlled metadata (version, drift)
8. Update only exportable content
9. Detect local divergence in canonical content before overwriting
10. Produce a reviewable diff (PR, not a silent commit)
11. Prefer PR over silent modification
12. Never rewrite historical trails
13. Validate links and paths after update
14. Run `doctor.sh` before and after the update

---

## Out-of-scope inconsistencies

The following observations were identified during analysis. Those marked **RESOLVED**
were addressed during internal canonicalization.

- **`framework/journeys/operation/runbooks.md`** — **RESOLVED.** The file was
  rewritten as a canonical Runbook definition. Product-specific content was preserved
  in `prodops/artifacts/runbooks/payments-api-runbook.en.md`.

- **`framework/journeys/discovery/`** — **PARTIALLY RESOLVED.** The `upstream-trail.md`
  received an explicit section marker in the `# History` section. The `export-manifest.yaml`
  must include an exclusion or transformation for the history section before export.

- **`AGENTS.md` at root** — **RESOLVED.** AGENTS.md was updated to include the area
  map, the empirical upstream note, and an explicit prohibition on running the sync script.
  AGENTS.md is a product-local artifact — it is not exported.

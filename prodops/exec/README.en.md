# prodops/exec/

Product operational execution space. Contains configurations, runtime controls,
and Framework distribution contracts for this repository.

---

## Files

| File | Responsibility |
|---|---|
| `manifest.yaml` | Product operational configuration: active skills, local paths, gates, canonical vocabulary, GitHub Projects |
| `framework-lock.yaml` | Framework distribution lock: installed version, sync status, drift state |
| `export-manifest.yaml` | **Declarative extraction contract** — defines the exportable Framework boundary *(empirical upstream only, `status: self`)* |
| `export-boundary.md` | Boundary model documentation: ownership, classifications, layout, transformations, and sync invariants *(empirical upstream only)* |
| `empirical-upstream.en.md` | Orientation on this repository's empirical upstream role and the meaning of `status: self` |
| `cards/` | Execution work cards (active phase context — ephemeral) |

> **Distinct contracts:** `manifest.yaml`, `framework-lock.yaml`, and
> `export-manifest.yaml` answer different questions and do not substitute
> one another. See the section below.

> **Sync mechanism disabled:** `scripts/sync-framework-docs.sh` is disabled with
> an explicit guard. It must not be executed until aligned with `export-manifest.yaml`.
> See `export-boundary.en.md` for the current state.

---

## Content categories in prodops/

Three content categories coexist in this repository:

### 1. Temporary canonical upstream (Framework)

Content that belongs to the ProdOps Framework and will be synchronized from the
existing canonical `prodops-framework` repository after reconciliation.

- `prodops/framework/` — principles, glossary, ontology, flow, canonical-paths
- `prodops/framework/execution-model/` — upstream and downstream modes
- `prodops/framework/journeys/*/` — structure and capabilities of each journey
- `prodops/skills/<framework-skills>/` — bootstrap, hack, sync, finish, ship, validate, promote, upstream, downstream, diligence
- `prodops/skills/references/engineering/tdd-prodops/` — canonical Framework engineering practice
- `prodops/templates/` — canonical templates

**Protected by sync:** These areas will receive updates from the sync mechanism after reconciliation with prodops-framework.

### 2. Product-local

Content that belongs to this product and must never be overwritten by sync.
Declared in `.prodopsignore`.

- `prodops/artifacts/` — OBCs, BDD, plans, trails, intents (local Knowledge Space)
- `prodops/exec/manifest.yaml` — product operational configuration
- `prodops/exec/framework-lock.yaml` — product distribution lock
- `prodops/exec/cards/` — execution work cards
- `prodops/skills/local/` — local Skills for this API (e.g., `payments-api-local-testing`)
- `prodops/skills/references/local/engineering/clean-code/` — optional product reference
- `prodops/skills/references/local/engineering/ddd/` — optional product reference
- `prodops/scripts/local/` — product-specific scripts (local automations and adapters)

**Protected by `.prodopsignore`:** Never overwritten by Framework sync.

### 3. Runtime or generated state

Ephemeral or execution-generated content — not a permanent artifact.

- `prodops/exec/cards/` — active phase context (cleared after Promote)

---

## Three contracts, three distinct questions

| | `manifest.yaml` | `framework-lock.yaml` | `export-manifest.yaml` |
|---|---|---|---|
| **Purpose** | Execution configuration | Distribution control | Export boundary |
| **Question answered** | *How does this product execute the Framework?* | *Which Framework version is installed?* | *What belongs to the Framework and must be exported?* |
| **Who writes** | Product team | Sync mechanism (or product, in empirical phase) | Empirical upstream (this repository) |
| **When it changes** | When product execution configuration changes | When the Framework is updated | When the export boundary is revised |
| **Content** | Skills, paths, gates, vocabulary, GitHub | Version, status, drift, sync mechanism | Includes, excludes, transforms, convention-only paths |
| **Scope** | Every consumer product | Every consumer product | Empirical upstream only |

The three files are complementary and do not substitute one another.

`export-manifest.yaml` and `export-boundary.md` exist **only while this
repository is the empirical upstream** (`status: self`). After transitioning to
`status: consumer`, they may be removed or kept as historical record.

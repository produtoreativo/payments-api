# Artifacts

Living artifacts of the product — local instances organized by artifact type. Conceptual definitions live in `prodops/framework/`. Paths are resolved via `prodops/exec/manifest.yaml`.

## Type-based structure

| Directory | Artifact type | Mutability |
|---|---|---|
| [obcs/](obcs/) | Observable Business Contracts — committed observable contracts | Curated |
| [bdd/](bdd/) | BDD Features — executable behavior specifications | Curated |
| [business-intents/](business-intents/) | Business Intents — exploratory business intents | Curated |
| [architecture/](architecture/) | Operational architectural view — decisions, inventory, integrations | Curated |
| [event-storming/](event-storming/) | Event Storming — domain model in JSON | Generated/curated |
| [plans/](plans/) | Plans — iteration plan and reliability plans | Curated |
| [trails/](trails/) | Historical trails — release trail, sessions, workspace sync | Append-only |
| [evidence/](evidence/) | Delivery evidence | Generated |
| [experiments/](experiments/) | Upstream experiments — hypotheses, upstream trail, evidence | Curated + append-only |
| [risks/](risks/) | Risks and opportunities | Curated |
| [product/](product/) | Product context — Product Deck, Service Decks, backlogs | Curated |

## Model → Template → Instance

For each artifact type there is:

1. **Model** — concept definition in `prodops/framework/glossary.md`
2. **Template** — creation structure in `prodops/templates/`
3. **Instance** — produced artifact, stored here in `prodops/artifacts/`

Trails (trails/) may be append-only — historical references to old paths are valid history and must not be rewritten.

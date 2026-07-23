# OBCs

This directory contains committed **Local OBCs** for this product repository. It is the canonical source for observable contracts used in Downstream.

**All OBCs here are Local OBCs** — by definition, a product repository contains only product implementation contracts. Global OBCs belong to the platform portfolio repository.

## Rules

- Every committed Local OBC must have its own file in this directory: `prodops/artifacts/obcs/<slug>.md`
- Exploratory OBCs (Draft/Refining) remain under `prodops/artifacts/experiments/<NNN-slug>/obcs/` until formal promotion.
- Each Local OBC must reference its corresponding Global OBC (or indicate "Local — direct flow" if none).
- Product Decks, BDD Features, Reliability Plans, and other artifacts must reference the OBC without duplicating its definition.

## States

| State | Meaning | Location |
|---|---|---|
| Draft | Newly created, no refinement | Experiment dir |
| Refining | In active Discovery/Exploration | Experiment dir |
| Committed | Ready for Delivery, approved | `prodops/artifacts/obcs/<slug>.md` |
| In Delivery | In execution in the Iteration Plan | `prodops/artifacts/obcs/<slug>.md` |
| Operational | In production with evidence | `prodops/artifacts/obcs/<slug>.md` |
| Archived | Closed | Kept here for traceability |

## References

→ **Full OBC definition (what it is, composition, states, lifecycle):** [`prodops/framework/obc.en.md`](../../framework/obc.en.md)
→ **Template for Local OBC:** [`prodops/templates/obcs/local-obc.en.md`](../../templates/obcs/local-obc.en.md)
→ **Template for Global OBC** *(for use in the portfolio repository):* [`prodops/templates/obcs/global-obc.en.md`](../../templates/obcs/global-obc.en.md)

# OBCs

This directory contains committed OBCs and is the canonical source for observable contracts used in Downstream.

## Two types of OBC

The OBC model has two levels:

| Type | Description | Subdirectory |
|---|---|---|
| **Global OBC** | Strategic business contract. Belongs to BIB/Portfolio. Covers the entire business intent. | `global/` |
| **Local OBC** | Product implementation contract. Belongs to one PIB. Specializes/partitions the Global OBC. | `local/` |

**Relationship:** 1 Global OBC → N Local OBCs (via OBC Partitioning)

## Rules

- Every committed OBC must have its own file in the corresponding subdirectory.
- Product Decks, Service Decks, BDD Features, Reliability Plans, and other artifacts must reference the corresponding OBC without duplicating its definition.
- Local OBCs **never duplicate** strategic content from the Global OBC — they only specify the product's specific responsibility.
- Exploratory OBCs (Draft/Refining) remain under `prodops/journeys/discovery/experiments/<NNN-slug>/obcs/` until formal promotion.

## States

| State | Meaning | Where it lives |
|---|---|---|
| Draft | Newly created, no refinement | Experiment dir or local directory |
| Refining | In active Discovery/Exploration | Experiment dir |
| Committed | Ready for Delivery, approved | `obcs/local/<slug>.md` |
| Implemented | In Delivery or recently delivered | `obcs/local/<slug>.md` |
| Operational | In production with evidence | `obcs/local/<slug>.md` or `obcs/global/<slug>.md` |
| Archived | Closed | Kept in subdirectory for traceability |

## References

→ **Full OBC definition (what it is, composition, states, lifecycle):** [`prodops/framework/obc.en.md`](../framework/obc.en.md)
→ **Template for Global OBC:** [`prodops/templates/obcs/global-obc.en.md`](../templates/obcs/global-obc.en.md)
→ **Template for Local OBC:** [`prodops/templates/obcs/local-obc.en.md`](../templates/obcs/local-obc.en.md)

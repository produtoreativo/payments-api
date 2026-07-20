# Capability — Contract Management

## Objective

Define, maintain, and verify contracts that describe the expected behavior of the system — before, during, and after implementation.

## Responsibilities

- Create and maintain BDD Features as behavioral contracts
- Create and maintain OBCs as measurable success criteria
- Keep OpenAPI and AsyncAPI in sync with the implemented behavior
- Verify that the contract exists before starting any Downstream implementation

## Consuming flows

| Flow | Moment of use |
|---|---|
| Bootstrap | Verify that the contract exists — pre-condition of Hack |
| Hack | Write the first test from the contract (Red Bar) |
| Sync | Confirm that the contract reflects the implemented behavior |
| Validate | Execute Runtime Contract Validation in the target environment |

## Produced artifacts

- BDD Feature in `prodops/artifacts/business/bdd/` (committed) or `prodops/journeys/discovery/experiments/<NNN-slug>/features/` (exploratory)
- OBC in `prodops/artifacts/business/obcs/`
- Updated OpenAPI spec
- Updated AsyncAPI spec

## Dependencies

- Product Deck (`prodops/artifacts/product/product-deck.md`)
- Reliability Plan (`prodops/journeys/assessment/reliability-plans/`)

## References

→ [prodops/framework/glossary.md](../../../framework/glossary.md) — definitions of OBC and BDD Feature
→ [prodops/journeys/delivery/phases/bootstrap/README.md](../phases/bootstrap/README.md) — how to verify the contract in Bootstrap

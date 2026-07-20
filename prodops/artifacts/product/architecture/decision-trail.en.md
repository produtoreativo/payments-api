# Decision Trail — Payments SOR and PSP Boundary

## Decision

On 2026-07-12, duplicated documentation under `docs/` was consolidated. The Product Deck now declares Payments as the payments domain System of Record, and the Architecture Overview declares providers such as Asaas as external PSPs.

This consolidation organizes existing context; it does not approve new states, events, SLOs or runtime behavior. Such changes still require the artifacts and prerequisites of the applicable ProdOps flow.

## Context

The definition existed only in non-canonical documents that diverged from the canonical Product Deck, BDD Features and Event Storming plan. Keeping both sources allowed consumers to adopt obsolete contracts.

## Alternatives considered

| Alternative | Why it was rejected |
|---|---|
| Keep a separate SOR/PSP document | It would create a third source for product and architecture. |
| Move every legacy document without review | It would preserve obsolete endpoints and competing BDDs. |
| Discard the SOR/PSP definition completely | It would lose a useful responsibility boundary compatible with the current architecture. |

## Test impact

No test or committed contract changed. Additional scenarios from the alternative BDD were not automatically promoted.

## Observability impact

The canonical Event Storming plan was preserved. Events and tags found only in the legacy copy were not incorporated without corresponding OBCs and BDD Features.

## Reliability impact

Removing obsolete documents reduces the risk of integration through divergent endpoints. Timeout, retry, webhook security and PII protection remain governed by the Reliability Plan.

## Pending work

- PM and Tech Lead should review the SOR/PSP wording during the next Product Deck review.
- Additional states or events must follow the ProdOps flow before entering committed contracts.

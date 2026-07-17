# Assessment

## Responsibility

Produce analyses to support decisions.

Assessment does not implement software. It produces inputs for product, architecture and reliability decisions.

## When it occurs

Assessment can occur in both Upstream and Downstream.

- **In Upstream:** evaluates hypotheses, experiments and learnings to decide whether a capability should advance to Downstream.
- **In Downstream:** evaluates risks, opportunities and OBCs to decide whether an item is ready for Delivery.

## What it produces

- risk and opportunity analyses
- product diagnostics
- Premortem
- Reliability Plans
- Decision Packages
- prioritization recommendations

## Artifacts

| Artifact | Location |
|---|---|
| Risks | [risks.md](risks.md) |
| Opportunities | [opportunities.md](opportunities.md) |
| Reliability Plans | [reliability-plans/](reliability-plans/) |
| Event Storming | [event-storming/](event-storming/) |
| Architecture | [../../artifacts/product/architecture/](../../artifacts/product/architecture/) |
| OBCs (reference) | [../../artifacts/business/obcs/](../../artifacts/business/obcs/) |
| Iteration Plans (reference) | [../../artifacts/governance/plans/](../../artifacts/governance/plans/) |

## Relationship With Other Journeys

- **Discovery** produces experiments and learnings that Assessment uses to issue recommendations.
- **Delivery** consumes Assessment decisions (committed OBC, Reliability Plan, documented risks).
- **Operation** sends incident and postmortem signals that Assessment uses to update risks.
- **Diligence** synchronizes Assessment decisions across backlogs and operational representations.

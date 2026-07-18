# Downstream Mode

Downstream is the **commitment mode** of the ProdOps Framework.

## Canonical definition

Downstream represents a commitment mode. From the moment a Business Intent enters Downstream, there is a commitment to delivery, quality, and reliability. All work must mandatorily follow the ProdOps operational model.

## Purpose

Deliver software with traceability, verifiable acceptance criteria, and evidence recorded at each step.

## Mode characteristics

In Downstream:

- there is an implementation commitment
- there is a reliability commitment
- there is governance
- there is mandatory validation
- there is traceability
- there is evidence generation
- there is conformance with the operational model

Skills are no longer optional. They become part of the execution process — they participate in journey validation, produce evidence, and guarantee consistency.

## OBC in Downstream

When entering Downstream, the OBC is no longer just a record. It becomes the operational contract of the work.

During Discovery (in the Icebox), it will be refined until reaching the Committed state. That OBC controls the evolution of the subsequent journeys: Iteration Backlog → Iteration Plan → Delivery.

## When to use Downstream mode

- Item approved in the Iteration Plan
- Implement existing OBC + BDD Feature
- Deliver feature with formal commitment
- Execute item from the Reliability Plan

## Mandatory preconditions

Downstream has three explicit moments:

1. **Downstream Declared** — commitment exists; the mode guides the item toward readiness.
2. **Downstream Ready** — every applicable gate is satisfied.
3. **Delivery Started** — Bootstrap has started for a Ready item.

Before executing any Delivery phase, all requirements below must be satisfied:

1. OBC in `prodops/artifacts/business/obcs/`
2. BDD Feature in `prodops/artifacts/business/bdd/`
3. Risks documented in `prodops/journeys/assessment/risks.md`
4. Iteration Plan entry with status `In` in `prodops/artifacts/governance/plans/iteration-plan.md`

5. Reliability Plan when there is money movement, an external integration, an SLO change, high/critical risk, or a persistence or security change

When a mandatory requirement is missing, Downstream stops before Delivery, identifies the owner, and guides the next action.

## Mandatory sequence

```
Bootstrap → Hack → Sync → Finish → Ship → Validate → Promote
```

Work is divided into two cycles:

```
CI Sync: Bootstrap → Hack → Sync → Finish     (local work, synchronous)
CI Async: Ship → Validate → Promote            (platform, pipelines, environments)
```

## Phases

| Phase | Description | Link |
|---|---|---|
| Bootstrap | Dependencies + local infrastructure + configuration + smoke gate | [../journeys/delivery/phases/bootstrap/README.en.md](../journeys/delivery/phases/bootstrap/README.en.md) |
| Hack | Implementation via ProdOps TDD | [../journeys/delivery/phases/hack/README.en.md](../journeys/delivery/phases/hack/README.en.md) |
| Sync | Branch sync (rebase) + artifact alignment (align) | [../journeys/delivery/phases/sync/README.en.md](../journeys/delivery/phases/sync/README.en.md) |
| Finish | Quality Gates + PR | [../journeys/delivery/phases/finish/README.en.md](../journeys/delivery/phases/finish/README.en.md) |
| Ship | Preparation + Deployment | [../journeys/delivery/phases/ship/README.en.md](../journeys/delivery/phases/ship/README.en.md) |
| Validate | Runtime + observability + SLO | [../journeys/delivery/phases/validate/README.en.md](../journeys/delivery/phases/validate/README.en.md) |
| Promote | Formal approval + Release Trail | [../journeys/delivery/phases/promote/README.en.md](../journeys/delivery/phases/promote/README.en.md) |

## Evidence

Record significant delivery evidence in the active session trail at `prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`.

## Downstream must preserve

Traceability from the current state and assessment through implementation, validation, and promotion.

# Downstream Mode

Downstream is the governed delivery mode of the ProdOps Framework.

## Purpose

Deliver software with traceability, verifiable acceptance criteria, and evidence recorded at each step.

## Mode characteristics

- Formal commitment to acceptance criteria (OBC + BDD Feature)
- Complete governance and traceability
- Mandatory artifacts before start
- Evidence recorded at each step
- Full mandatory sequence

## When to use Downstream mode

- Item approved in the Iteration Plan
- Implement existing OBC + BDD Feature
- Deliver feature with formal commitment
- Execute item from the Reliability Plan

## Mandatory preconditions

Downstream may start to guide a committed item toward readiness. Before executing any Delivery phase, all requirements below must be satisfied:

1. OBC in `prodops/artifacts/obcs/`
2. BDD Feature in `prodops/artifacts/bdd/`
3. Risks documented in `prodops/journeys/assessment/risks.md`
4. Reliability Plan entry produced by Assessment in `prodops/journeys/assessment/reliability-plans/`
5. Iteration Plan entry with status `Entrou` in `prodops/artifacts/plans/iteration-plan.md`

When a requirement is missing, Downstream stops before Delivery, identifies the owner, and guides the next action. Reliability precedes the Iteration Plan readiness decision.

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
| Bootstrap | Dependencies + local infrastructure + configuration + smoke gate | [../journeys/delivery/phases/bootstrap/README.md](../journeys/delivery/phases/bootstrap/README.md) |
| Hack | Implementation via ProdOps TDD | [../journeys/delivery/phases/hack/README.md](../journeys/delivery/phases/hack/README.md) |
| Sync | Branch sync (rebase) + artifact alignment (align) | [../journeys/delivery/phases/sync/README.md](../journeys/delivery/phases/sync/README.md) |
| Finish | Quality Gates + PR | [../journeys/delivery/phases/finish/README.md](../journeys/delivery/phases/finish/README.md) |
| Ship | Preparation + Deployment | [../journeys/delivery/phases/ship/README.md](../journeys/delivery/phases/ship/README.md) |
| Validate | Runtime + observability + SLO | [../journeys/delivery/phases/validate/README.md](../journeys/delivery/phases/validate/README.md) |
| Promote | Formal approval + Release Trail | [../journeys/delivery/phases/promote/README.md](../journeys/delivery/phases/promote/README.md) |

## Evidence

Record significant delivery evidence in `prodops/artifacts/trails/release-trail.md`.

## Downstream must preserve

Traceability from the current state and assessment through implementation, validation, and promotion.

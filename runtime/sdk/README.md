# @prodops/runtime-sdk

Contracts, models, and enums for the ProdOps Runtime.

Used by all runtime components: RT-01 Event Producer, RT-02 Timeline Processor,
RT-03 GitHub Synchronizer, RT-04 Datadog Adapter, RT-05 Delivery Dashboard,
RT-06 Diligence Dashboard.

## Structure

```
src/
  enums/          # Canonical value sets from COR and OEM schema
  models/         # Immutable data types (depend only on enums)
  contracts/      # Behavioral interfaces (depend on models and enums)
  index.ts        # Public API
```

## Dependency rules

```
enums  ←  models  ←  contracts
```

No circular dependencies. Models never import from contracts.

## Enums

| File | Enum | Values |
|---|---|---|
| `journey.ts` | `Journey` | Delivery, Diligence, Assessment |
| `cycle.ts` | `Cycle` | Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework |
| `phase.ts` | `PhaseAction` | Started, Completed |
| `state.ts` | `State` | BOOTSTRAPPING, HACKING, SYNCING, FINISHING, SHIPPING, VALIDATING, PROMOTING, DONE, BLOCKED, REWORKING |
| `event-category.ts` | `EventCategory` | Phase Lifecycle, Gate, Rework, Impediment, Diligence, Correction |
| `producer.ts` | `ProducerType` | Human, System, Agent |
| `consumer.ts` | `ConsumerType` | Timeline, GitHubSync, Metrics, Diligence, Assessment |

## Models

| File | Type | Notes |
|---|---|---|
| `event-instance.ts` | `EventInstance` | Canonical schema — see `prodops/framework/events/event-instance-schema.md` |
| `derived-state.ts` | `DerivedState` | Computed projection — never stored directly |
| `timeline-state.ts` | `TimelineState` | Full timeline with derived state |
| `work-item.ts` | `WorkItem` | Identity fields mirrored from GitHub Projects COR |
| `finding.ts` | `Finding`, `FindingType`, `FindingSeverity` | Drift / diligence findings |

## Contracts

| File | Interface | Implemented by |
|---|---|---|
| `event-producer.ts` | `EventProducer` | RT-01 |
| `event-consumer.ts` | `EventConsumer` | RT-02, RT-03, RT-04 |
| `timeline.ts` | `Timeline` | RT-02 |
| `github-sync.ts` | `GitHubSync` | RT-03 |
| `telemetry.ts` | `Telemetry` | RT-04 |

## Canonical sources

- `prodops/framework/events/event-instance-schema.md` — EventInstance schema
- `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-cor.md` — COR field values
- `runtime/workspace/workspace.yaml` — authoritative enum values for journey, cycle, phase, state

# @prodops/runtime-sdk

Contracts, models, and enums for the ProdOps Runtime.

Used by all runtime components: RT-01 Event Producer, RT-02 Timeline Processor,
RT-03 GitHub Synchronizer, RT-04 Datadog Adapter, RT-05 Delivery Dashboard,
RT-06 Diligence Dashboard.

## Structure

```
src/
  enums/          # Canonical value sets (Journey, Cycle, Phase, State, EventCategory, …)
  models/         # Immutable data types (depend only on enums)
  contracts/      # Behavioral interfaces (depend on models and enums)
  examples/       # Compilable usage examples — not part of the public API
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
| `journey.ts` | `Journey` | Delivery, Diligence, Assessment, Discovery, Operation |
| `cycle.ts` | `Cycle` | CI Sync, CI Async, Diligence Sync, Diligence Async |
| `phase.ts` | `Phase` | Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote, Rework |
| `phase-lifecycle.ts` | `PhaseLifecycle` | Started, Completed |
| `state.ts` | `State` | BOOTSTRAPPING, HACKING, SYNCING, FINISHING, SHIPPING, VALIDATING, PROMOTING, DONE, BLOCKED, REWORKING |
| `event-category.ts` | `EventCategory` | Phase Lifecycle, Gate, Human Decision, Blocking, Rework, System, Diligence, Correction |
| `producer.ts` | `ProducerType` | Human, System, Agent |
| `consumer.ts` | `ConsumerType` | Timeline, GitHubSync, Metrics, Diligence, Assessment |

## Models

| File | Type | Notes |
|---|---|---|
| `event-id.ts` | `EventId` | Branded string — UUID v7 format (RFC 9562), no domain semantics |
| `event-instance.ts` | `EventInstance`, `OperationalEvent` | Canonical OEM record; `OperationalEvent` is the domain alias |
| `event-type.ts` | `EventNamespace`, `EventTypeId` | `<Namespace>.<Subject>.<Action>[.<Qualifier>]` type format |
| `derived-state.ts` | `DerivedState` | Computed projection — never persisted directly |
| `timeline-state.ts` | `TimelineState` | Full timeline with derived state |
| `work-item.ts` | `WorkItem` | Identity fields mirrored from GitHub Projects COR |
| `finding.ts` | `Finding`, `FindingType`, `FindingSeverity` | Drift and diligence findings |

### EventId

`EventId` is a branded `string` — it prevents mixing opaque identifiers with plain strings at compile time. At runtime it is a UUID v7. Cast with `as EventId` in tests; real producers use a UUIDv7 library:

```typescript
import type { EventId } from '@prodops/runtime-sdk';
// production: import { uuidv7 } from 'uuidv7'; const id = uuidv7() as EventId;
const id = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6a' as EventId;
```

### OperationalEvent

`OperationalEvent` is a type alias for `EventInstance` — same structure, domain name:

```typescript
import type { OperationalEvent } from '@prodops/runtime-sdk';
const event: OperationalEvent = { id, event_type, work_item_id, ... };
```

## Contracts — CloudEvents

| File | Interface / Type | Notes |
|---|---|---|
| `cloud-events.ts` | `CloudEventSource` | Branded URI-reference string (CloudEvents 1.0 §3.1) |
| `cloud-events.ts` | `CloudEventEnvelope<TData>` | Transport envelope — no external lib dependency |
| `cloud-events.ts` | `CloudEventEncoder` | Encodes `OperationalEvent` → `CloudEventEnvelope` |
| `cloud-events.ts` | `CloudEventDecoder` | Decodes `CloudEventEnvelope` → `EventInstance` |

OEM → CloudEvents field mapping:

| EventInstance field | CloudEventEnvelope field |
|---|---|
| `id` | `id` |
| `event_type` | `type` |
| `work_item_id` | `subject` |
| `producer_identity` | `source` (as `CloudEventSource`) |
| `timestamp` | `time` |
| *(whole record)* | `data` |

## Contracts — Event flow

| File | Interface | Implemented by |
|---|---|---|
| `event-producer.ts` | `EventProducer` | RT-01 — assembles and emits `CloudEventEnvelope` |
| `event-publisher.ts` | `EventPublisher` | RT-01 — publishes envelope to the transport layer |
| `event-consumer.ts` | `EventConsumer` | RT-02, RT-03, RT-04 |
| `event-query.ts` | `EventQuery` | RT-02 — reads from the event store |

## Contracts — Timeline & OSE

| File | Interface | Notes |
|---|---|---|
| `timeline.ts` | `Timeline` | Read-only logical projection; reconstructed via `EventQuery` |
| `operational-state-engine.ts` | `OperationalStateEngine` | Pure in-memory processor — no I/O |
| `operational-state-engine.ts` | `ValidationResult` | Output of `validate()` |
| `operational-state-engine.ts` | `StateHistoryEntry` | DerivedState snapshot + causedBy event |
| `operational-state-engine.ts` | `StateHistory` | Full sequence of state transitions for a Work Item |

### OSE processing pipeline

The OSE is a pure function — it does not read from or write to any store. Callers source events via `EventQuery`, then apply in order:

```
validate → deduplicate → order → applyCorrections → effectiveState / stateHistory
```

- `validate` — structural and semantic check on a single event
- `deduplicate` — removes events with duplicate `id`
- `order` — sorts by `timestamp` ASC, `sequence_number` as tiebreaker
- `applyCorrections` — resolves `Event.Corrected` records
- `replay` — final `DerivedState` from full stream
- `replayUntil(events, timestamp)` — `DerivedState` at a point in time
- `effectiveState` — alias for `replay` on a prepared stream
- `stateHistory` — full `StateHistory` (one entry per state-altering event)

### Timeline

`Timeline` is a read-only logical projection over the event store — it has no `append()`. Publishing is the responsibility of `EventProducer` → `EventPublisher`.

## Contracts — Telemetry

Telemetry is split into four focused ports:

| File | Interface | Notes |
|---|---|---|
| `event-publisher.ts` | `EventPublisher` | CloudEvent transport (event side) |
| `event-query.ts` | `EventQuery` | Read from event store |
| `metric-publisher.ts` | `MetricPublisher` | Push metric points |
| `metric-query.ts` | `MetricQuery` | Read metric series |
| `tag-projection.ts` | `TagProjection` | Derives metric tags from event or state at publish time |

Tags are derived by the adapter at publish time — they are **not** stored in `EventInstance`.

## Contracts — GitHub sync

| File | Interface | Implemented by |
|---|---|---|
| `github-sync.ts` | `GitHubSync` | RT-03 — materializes `DerivedState` into GitHub Projects COR |

GitHub Projects COR materializes `DerivedState` only — it is not the source of truth.

## Canonical sources

- `prodops/framework/events/event-instance-schema.md` — EventInstance schema
- `prodops/framework/events/taxonomy.md` — 8 canonical EventCategory values
- `prodops/framework/journeys/delivery/phases/` — Phase definitions
- `prodops/artifacts/experiments/013-runtime-validation/runtime-validation-cor.md` — COR field values
- `runtime/workspace/workspace.yaml` — authoritative enum values for journey, cycle, phase, state

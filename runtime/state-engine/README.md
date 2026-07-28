# @prodops/runtime-state-engine

**RT-02 — Operational State Engine**

Pure, deterministic state computation from `OperationalEvent` streams. The OSE is the brain of the ProdOps Runtime: it transforms a sequence of events into operational state, history, and effective state snapshots.

## Concept

The OSE is a pure function over a stream of events. It has no internal state, no I/O, and no external dependencies beyond `@prodops/runtime-sdk`. Given the same event stream, it always produces the same output.

```
OperationalEvent[]
      │
      ▼
  OemOperationalStateEngine
      │
      ├─ replay()               → DerivedState | null
      ├─ replayUntil(ts)        → DerivedState | null
      ├─ lookback(ts)           → DerivedState | null
      ├─ effectiveState()       → DerivedState | null
      ├─ stateHistory()         → StateHistory (SDK type)
      ├─ fullHistory()          → ExtendedStateHistory
      └─ effectiveOperationalState() → EffectiveOperationalState
```

## Processing pipeline

Before calling terminal operations, raw events must be prepared:

```
validate → deduplicate → order → applyCorrections → replay / stateHistory / effectiveState
```

```typescript
const ose = new OemOperationalStateEngine();
const prepared = ose.prepare(rawEvents); // dedup + order + corrections

const state = ose.replay(prepared);
const history = ose.stateHistory(prepared);
const eos = ose.effectiveOperationalState(prepared);
```

Or use the convenience wrapper that applies the full pipeline:

```typescript
const state = ose.replayRaw(rawEvents);
```

## Ordering

Events are sorted deterministically by:
1. `timestamp` — ISO-8601 lexicographic (equivalent to chronological for UTC)
2. `sequence_number` — ascending; events without a sequence number sort last
3. `id` — UUID v7 lexicographic (time-ordered, safe tiebreaker)

Tie-breaking is documented: two events with the same timestamp and no sequence number are ordered by their UUID v7 id. Callers should assign `sequence_number` for co-temporal events.

## State machine

State transitions are driven by `event_type` format `<Namespace>.<Subject>.<Action>`:

| Event type pattern | State transition |
|---|---|
| `*.Bootstrap.Started` | → BOOTSTRAPPING |
| `*.Hack.Started` | → HACKING |
| `*.Sync.Started` | → SYNCING |
| `*.Finish.Started` | → FINISHING |
| `*.Ship.Started` | → SHIPPING |
| `*.Validate.Started` | → VALIDATING |
| `*.Promote.Started` | → PROMOTING |
| `*.Promote.Completed` | → DONE (terminal) |
| `*.Rework.Started` | → REWORKING, rework_count++ |
| `*.Rework.Completed` | → restore pre-rework state |
| `*.*.Blocked` | → BLOCKED, set blocked_since |
| `*.*.Raised` | → BLOCKED (impediment raised) |
| `*.*.Resolved` | → restore pre-block state |
| `*.*.Unblocked` | → restore pre-block state |
| `*.*.Corrected` | → no state change (correction resolved by applyCorrections) |
| All other actions | → no state change (Gate, HumanDecision, System, Diligence) |

## Event.Corrected

The Timeline is append-only. Corrections are never applied by mutating stored events.

When a correction event (`<Namespace>.Event.Corrected`) is present in the stream:
- Its `payload.corrected_event_id` identifies the superseded event
- `applyCorrections()` removes the superseded event from the effective stream
- The correction event itself remains in the stream

```typescript
// e1 is wrong — correction arrives as e2
const e2: OperationalEvent = {
  event_type: 'Delivery.Event.Corrected',
  payload: { corrected_event_id: e1.id },
  ...
};

const prepared = ose.prepare([e1, e2, e3]);
// e1 is gone from prepared; e2 (correction) and e3 remain
```

## Replay

`replay(events)` computes `DerivedState` from a fully prepared stream:

```typescript
const prepared = ose.prepare(rawEvents);
const state = ose.replay(prepared);
// state.state — current State enum value
// state.journey — Delivery, Diligence, etc.
// state.phase — current Phase
// state.rework_count — cumulative rework cycles
// state.blocked_since — set when BLOCKED
```

## ReplayUntil

`replayUntil(events, until)` replays events up to and including the given ISO-8601 timestamp:

```typescript
const stateAt10am = ose.replayUntil(prepared, '2026-07-26T10:00:00Z');
```

Strict temporal semantics: corrections that arrive after `until` are not applied. This answers "what was the state AT time T?"

## Lookback

`lookback(events, reference)` answers the same question as `replayUntil` with semantic emphasis on historical inspection:

```typescript
// Equivalent — both apply full pipeline bounded to reference
const s = ose.lookback(rawEvents, '2026-07-26T10:30:00Z');
```

Lookback resolves within the temporal window:
- `Impediment.Resolved` — if both Raised and Resolved events are ≤ reference
- `Rework.Completed` — if both Started and Completed are ≤ reference
- `Event.Corrected` — if both original and correction are ≤ reference

## Derived State

`DerivedState` is computed exclusively from the event stream — no external state, no side effects:

```typescript
const s: DerivedState = ose.replay(prepared)!;
// s.work_item_id   — from events
// s.state          — State enum
// s.journey        — Journey enum
// s.phase          — Phase enum (optional)
// s.last_event_type
// s.last_event_id
// s.computed_at    — last event timestamp
// s.rework_count
// s.blocked_since  — set only when BLOCKED
```

## Effective Operational State

`effectiveOperationalState(events)` returns an `EffectiveOperationalState` with contextual flags:

```typescript
const eos = ose.effectiveOperationalState(prepared);
// eos.current       — current DerivedState
// eos.previous      — previous DerivedState (before last event)
// eos.transitionedAt — timestamp of last transition
// eos.causedBy      — event responsible for current state
// eos.isBlocked     — true when State.Blocked
// eos.isReworking   — true when State.Reworking
// eos.hasCorrections — true if any correction events were applied
```

## State History

`stateHistory(events)` returns one entry per state transition:

```typescript
const h = ose.stateHistory(prepared);
// h.workItemId
// h.entries[] — one per state-altering event
//   entry.causedBy — the OperationalEvent that caused the transition
//   entry.state    — DerivedState after the event
```

`fullHistory(events)` returns one entry per event (including non-state-changing) with `previousState`:

```typescript
const h = ose.fullHistory(prepared);
// h.entries[].previousState — state before the event
// h.entries[].timestamp     — event timestamp
```

## What RT-02 deliberately does NOT do

| Capability | Responsible component |
|---|---|
| Read events from Datadog / store | RT-04 Datadog Adapter (implements `EventQuery`) |
| Publish events to any transport | RT-01 Operational Event Producer |
| Synchronize GitHub Projects | RT-03 GitHub Synchronizer |
| Push metrics to Datadog | RT-04 Datadog Adapter |
| Serve dashboards | RT-05 / RT-06 |
| Make HTTP requests | No HTTP in RT-02 |

## Relationship with RT-01 and RT-04

```
RT-01 (Producer) → CloudEventEnvelope → EventPublisher (RT-04)
                                                  ↓
                                         Event store (e.g. Datadog)
                                                  ↓
RT-04 (Adapter) → EventQuery → OperationalEvent[] → RT-02 (OSE)
                                                          ↓
                                                   DerivedState
                                                          ↓
                                              RT-03 (GitHub Sync)
```

RT-02 receives an event stream (sourced by RT-04 via `EventQuery`) and computes state. It does not know where events come from.

## Development

```bash
npm install         # SDK must be built first: cd ../sdk && npx tsc
npm test            # 98 tests, 0 failures
npm run typecheck   # tsc --noEmit, Exit 0
```

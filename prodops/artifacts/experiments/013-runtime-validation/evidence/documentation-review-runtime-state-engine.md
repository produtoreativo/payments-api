# Documentation Review — RT-02 Operational State Engine

**Date:** 2026-07-26
**Reviewer:** Claude (automated)
**Scope:** `runtime/state-engine/` — RT-02 initial implementation
**SDK version:** @prodops/runtime-sdk 0.1.1
**Related reviews:** `documentation-review-runtime-producer.md`, `documentation-review-runtime-sdk-v0.1.1-final.md`

---

## Summary

RT-02 (Operational State Engine) implemented as a standalone TypeScript package at `runtime/state-engine/`. The engine is a pure, deterministic computation over `OperationalEvent` streams — no I/O, no external dependencies beyond the SDK. Implements the full `OperationalStateEngine` SDK contract plus three extended methods.

**npm test:** 98 tests, 0 failures ✅
**tsc --noEmit:** Exit 0 ✅

---

## Adherence to OEM

| OEM requirement | Implemented |
|---|---|
| EventInstance is the immutable source of truth — never mutated | ✅ All inputs are `ReadonlyArray<OperationalEvent>`; no event is modified |
| Timeline is append-only — corrections never alter stored events | ✅ `applyCorrections()` filters the effective stream view; original input unchanged |
| State is derived exclusively from events — no stored state | ✅ No class-level mutable state; `OemOperationalStateEngine` is fully stateless |
| `MutableOseState` is internal — not part of the public API | ✅ Not exported from `index.ts`; `createInitialState` is internal |
| Replay must be deterministic | ✅ Given same input, output is identical (verified by test: "result depends exclusively on events") |
| `rework_count` accumulates — never decremented on `Rework.Completed` | ✅ Stack-based restore; count increment only on `Rework.Started` |
| `blocked_since` cleared on unblock | ✅ `Gate.Resolved`, `Impediment.Unblocked`, and `*.Unblocked` clear `blocked_since` |
| Correction events remain in effective stream | ✅ Only superseded events are filtered; correction events persist |

---

## Implementation of OEM / Timeline algorithms

### Processing pipeline

Implemented per SDK contract comment:
```
validate → deduplicate → order → applyCorrections → replay / stateHistory / effectiveState
```

Each step is a separate exported function. `prepare()` convenience method chains all four.

### State machine (derived-state.ts)

Transition table verified against OEM:

| Event pattern | State | Implemented in |
|---|---|---|
| `*.Bootstrap.Started` | BOOTSTRAPPING | `PHASE_START_STATE` lookup |
| `*.Hack.Started` | HACKING | `PHASE_START_STATE` lookup |
| `*.Sync.Started` | SYNCING | `PHASE_START_STATE` lookup |
| `*.Finish.Started` | FINISHING | `PHASE_START_STATE` lookup |
| `*.Ship.Started` | SHIPPING | `PHASE_START_STATE` lookup |
| `*.Validate.Started` | VALIDATING | `PHASE_START_STATE` lookup |
| `*.Promote.Started` | PROMOTING | `PHASE_START_STATE` lookup |
| `*.Promote.Completed` | DONE (terminal) | explicit branch |
| `*.Rework.Started` | REWORKING, rework_count++ | stack push |
| `*.Rework.Completed` | restore pre-rework | stack pop |
| `*.*.Blocked` | BLOCKED | `BLOCKING_ACTIONS` set |
| `*.*.Raised` | BLOCKED (Impediment) | `BLOCKING_ACTIONS` set |
| `*.*.Resolved` | restore pre-block | `UNBLOCKING_ACTIONS` set |
| `*.*.Unblocked` | restore pre-block | `UNBLOCKING_ACTIONS` set |
| `*.*.Corrected` | flag only, no state change | correction events are pre-filtered |
| all other actions | no state change | fall-through (Gate, HumanDecision, System, Diligence) |

### Ordering (ordering.ts)

Three-level sort: timestamp → sequence_number → UUID v7 id. Stable, documented.

Tiebreaking rationale documented in source:
- Events without `sequence_number` sort last (after those with any value)
- UUID v7 as final tiebreaker is safe because v7 is time-ordered

### Event.Corrected (corrections.ts)

- `isCorrectionEvent(event)` — `event_type` third segment === `'Corrected'`
- `getCorrectedEventId(event)` — reads `payload.corrected_event_id`
- `applyCorrections(events)` — single-pass scan; O(n) via Set

Strict temporal semantics: corrections applied only within the filtered window for `replayUntil`/`lookback`. Documented and tested.

### Lookback (lookback.ts)

Applies full pipeline on the temporally-bounded stream:
```
dedup → order → filter(≤ reference) → corrections → computeDerivedState
```

Resolves within temporal window: Impediment.Resolved, Rework.Completed, Event.Corrected — all handled if both cause and resolution are ≤ reference.

---

## Replay determinism

Verified by:
- Test: "result depends exclusively on events (no internal state between calls)" — calls `replay()` twice on same input, asserts `deepEqual`
- No class-level mutable state — `OemOperationalStateEngine` can be safely shared across calls
- `createInitialState()` always returns a fresh object

---

## Lookback conformance

| Scenario | Test | Status |
|---|---|---|
| lookback at block time → BLOCKED | `blocking + lookback` #2 | ✅ |
| lookback before block → HACKING | `blocking + lookback` #3 | ✅ |
| lookback after resolve → HACKING | `blocking + lookback` #4 | ✅ |
| lookback before correction → sees original | `Event.Corrected` #3 | ✅ |
| lookback after correction → sees corrected | `Event.Corrected` #4 | ✅ |

---

## Derived State consistency

| Property | Verified |
|---|---|
| `computed_at` = last event timestamp | ✅ |
| `last_event_type` = last event type | ✅ |
| `last_event_id` = last event id | ✅ |
| `effectiveState` === `replay` on same stream | ✅ |
| No external dependency in derivation | ✅ (no I/O, no class state) |

---

## Test coverage

| File | Suites | Tests | Scenarios covered |
|---|---|---|---|
| `tests/ordering.test.ts` | 2 | 13 | dedup (6), ordering (7) — idempotency, mutation safety, empty stream, stable sort, tiebreakers |
| `tests/corrections.test.ts` | 3 | 12 | isCorrectionEvent (3), getCorrectedEventId (3), applyCorrections (6) |
| `tests/state-machine.test.ts` | 7 | 30 | empty stream, full lifecycle, blocking/unblocking, rework (2 cycles), gate events, journey inference |
| `tests/state-engine.test.ts` | 11 | 43 | happy path, out-of-order, duplicates, rework, blocking+lookback, Event.Corrected, replayUntil (5 cases), derived state, stateHistory, extended history, validate |
| **Total** | **23** | **98** | **All 0 failures** |

### Required scenarios (per Prompt 17)

| Scenario | Covered |
|---|---|
| Happy Path | ✅ `happy path — full delivery lifecycle` (8 assertions) |
| Rework | ✅ `computeDerivedState — rework` (5) + `rework` integration (3) |
| Blocking + Lookback | ✅ `blocking + lookback` (4) + state-machine blocking (5) |
| Event.Corrected | ✅ `Event.Corrected` (4) + `applyCorrections` (6) |
| Events fora de ordem | ✅ `out-of-order events` (3) |
| Eventos duplicados | ✅ `duplicate events` (2) + `deduplicateEvents` (6) |
| Timeline vazia | ✅ `empty timeline` (5 methods) |
| ReplayUntil | ✅ `replayUntil` (5 boundary cases) |
| Derived State | ✅ `derived state consistency` (5 properties) |
| State History | ✅ `stateHistory` (5: entries, workItemId, causedBy, exclusion of non-transitions) |

---

## Typecheck result

```bash
cd runtime/state-engine && npx tsc --noEmit
Exit: 0
```

---

## File inventory

| File | Purpose |
|---|---|
| `src/validation.ts` | Single-event validation — UUID v7, event type, timestamp, required fields |
| `src/ordering.ts` | `deduplicateEvents`, `orderEvents` — pure, stable, input-safe |
| `src/corrections.ts` | Correction detection, `applyCorrections` — append-only, O(n) |
| `src/derived-state.ts` | State machine; `MutableOseState`; `computeDerivedState`; incremental helpers |
| `src/replay.ts` | `prepareStream`, `replayPrepared`, `replayRaw`, `replayUntilPrepared` |
| `src/lookback.ts` | `lookback` — temporally bounded replay with full pipeline |
| `src/history.ts` | `buildStateHistory`, `buildExtendedHistory`, `buildEffectiveState`; extended types |
| `src/state-engine.ts` | `OemOperationalStateEngine` — implements `OperationalStateEngine` + extensions |
| `src/index.ts` | Public API exports |
| `tests/ordering.test.ts` | 13 tests |
| `tests/corrections.test.ts` | 12 tests |
| `tests/state-machine.test.ts` | 30 tests |
| `tests/state-engine.test.ts` | 43 tests |
| `package.json` | `file:../sdk` dependency; tsx devDep |
| `tsconfig.json` | NodeNext ESM; includes src + tests |
| `README.md` | Concept, algorithms, examples, relationship to RT-01 and RT-04 |

---

## Readiness for RT-04 (Datadog Event Adapter)

RT-04 must implement `EventQuery` to source events for the OSE:

```typescript
import type { EventQuery, EventQueryResult } from '@prodops/runtime-sdk';

class DatadogEventQuery implements EventQuery {
  async queryByWorkItem(workItemId: string, options?): Promise<EventQueryResult> {
    // fetch from Datadog Events API
  }
}
```

Integration with RT-02:

```typescript
const { events } = await eventQuery.queryByWorkItem('wf-delivery-0042');
const prepared = ose.prepare(events);
const state = ose.replay(prepared);
const history = ose.stateHistory(prepared);
```

No changes to RT-02 code are needed when RT-04 is implemented. The `EventQuery` interface is the complete boundary.

---

## Absence of infrastructure dependencies

| Dependency | Status |
|---|---|
| Datadog | ✅ Absent |
| GitHub API | ✅ Absent |
| HTTP client | ✅ Absent |
| Database | ✅ Absent |
| File system | ✅ Absent |

Runtime dependencies: `@prodops/runtime-sdk` only.

---

## Out of scope (confirmed absent)

- RT-04 Datadog Adapter — ✅ not implemented
- RT-03 GitHub Synchronizer — ✅ not implemented
- Metrics / telemetry — ✅ not implemented
- Dashboards — ✅ not implemented
- Diligence Engine — ✅ not implemented
- HTTP requests — ✅ none
- Commit — ✅ not created

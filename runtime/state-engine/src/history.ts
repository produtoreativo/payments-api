import type { OperationalEvent, StateHistory, StateHistoryEntry, DerivedState } from '@prodops/runtime-sdk';
import { createInitialState, applyEventToState, snapshotDerivedState } from './derived-state.js';

// ---------------------------------------------------------------------------
// Extended types (not in SDK — local to state-engine package)
// ---------------------------------------------------------------------------

/**
 * A single entry in the full state transition history.
 * Includes previousState for audit and debugging contexts.
 */
export interface ExtendedStateHistoryEntry {
  readonly causedBy: OperationalEvent;
  readonly previousState: DerivedState | null;
  readonly state: DerivedState;
  readonly timestamp: string;
}

/**
 * Complete state transition history including previous-state context.
 * Superset of SDK's StateHistory — use when previous-state is needed.
 */
export interface ExtendedStateHistory {
  readonly workItemId: string;
  readonly entries: ReadonlyArray<ExtendedStateHistoryEntry>;
}

/**
 * Effective Operational State: current moment snapshot with contextual flags.
 * Returned by effectiveOperationalState() — not exposed via SDK's OSE interface.
 */
export interface EffectiveOperationalState {
  readonly current: DerivedState;
  readonly previous: DerivedState | null;
  readonly transitionedAt: string;
  readonly causedBy: OperationalEvent;
  readonly isBlocked: boolean;
  readonly isReworking: boolean;
  readonly hasCorrections: boolean;
}

// ---------------------------------------------------------------------------
// History builders
// ---------------------------------------------------------------------------

/**
 * Builds a full StateHistory (SDK contract type) from a prepared event stream.
 *
 * Includes one entry per event that causes a state transition.
 * Events that do not change state (e.g. Gate, HumanDecision, System)
 * are omitted from the history entries.
 *
 * Pre-condition: events are ordered, deduplicated, and corrections applied.
 */
export function buildStateHistory(events: ReadonlyArray<OperationalEvent>): StateHistory {
  if (events.length === 0) {
    return { workItemId: '', entries: [] };
  }

  const workItemId = events[0].work_item_id;
  const entries: StateHistoryEntry[] = [];
  const s = createInitialState(events[0]);
  let prevStateValue = s.state;

  for (const event of events) {
    const stateBefore = s.state;
    applyEventToState(event, s);
    const stateAfter = s.state;

    // Include entry only when state actually transitions
    if (stateAfter !== stateBefore) {
      entries.push({
        causedBy: event,
        state: snapshotDerivedState(event, s),
      });
      prevStateValue = stateAfter;
    }
  }

  // Always include at least one entry (the final state from the last event)
  if (entries.length === 0 && events.length > 0) {
    const lastEvent = events[events.length - 1];
    entries.push({
      causedBy: lastEvent,
      state: snapshotDerivedState(lastEvent, s),
    });
  }

  void prevStateValue; // suppress unused var warning

  return { workItemId, entries };
}

/**
 * Builds an ExtendedStateHistory that includes previousState per entry.
 * Includes ALL events (not just state-changing ones) for complete audit trail.
 */
export function buildExtendedHistory(
  events: ReadonlyArray<OperationalEvent>,
): ExtendedStateHistory {
  if (events.length === 0) {
    return { workItemId: '', entries: [] };
  }

  const workItemId = events[0].work_item_id;
  const entries: ExtendedStateHistoryEntry[] = [];
  const s = createInitialState(events[0]);
  let prevSnapshot: DerivedState | null = null;

  for (const event of events) {
    applyEventToState(event, s);
    const current = snapshotDerivedState(event, s);
    entries.push({
      causedBy: event,
      previousState: prevSnapshot,
      state: current,
      timestamp: event.timestamp,
    });
    prevSnapshot = current;
  }

  return { workItemId, entries };
}

/**
 * Returns the EffectiveOperationalState from the last processed event.
 * Returns null for an empty stream.
 */
export function buildEffectiveState(
  events: ReadonlyArray<OperationalEvent>,
): EffectiveOperationalState | null {
  if (events.length === 0) return null;

  const ext = buildExtendedHistory(events);
  if (ext.entries.length === 0) return null;

  const last = ext.entries[ext.entries.length - 1];
  const lastStateChangeIdx = [...ext.entries]
    .reverse()
    .findIndex((e, i, arr) => i > 0 && e.state.state !== arr[i - 1]?.state.state);
  const transitionEntry =
    lastStateChangeIdx >= 0
      ? ext.entries[ext.entries.length - 1 - lastStateChangeIdx]
      : ext.entries[0];

  const s = createInitialState(events[0]);
  for (const event of events) {
    applyEventToState(event, s);
  }

  return {
    current: last.state,
    previous: last.previousState,
    transitionedAt: transitionEntry.timestamp,
    causedBy: last.causedBy,
    isBlocked: last.state.state === 'BLOCKED',
    isReworking: last.state.state === 'REWORKING',
    hasCorrections: s.hasCorrections,
  };
}

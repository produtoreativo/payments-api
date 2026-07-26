import type { EventInstance } from '../models/event-instance.js';
import type { DerivedState } from '../models/derived-state.js';
export interface ValidationResult {
    readonly valid: boolean;
    readonly violations: ReadonlyArray<string>;
}
/**
 * A snapshot of DerivedState at a specific point in time.
 * Paired with the event that caused the transition.
 */
export interface StateHistoryEntry {
    readonly state: DerivedState;
    readonly causedBy: EventInstance;
}
/**
 * Ordered sequence of state snapshots over a Work Item's lifetime.
 * First entry = earliest known state; last entry = current effective state.
 */
export interface StateHistory {
    readonly workItemId: string;
    readonly entries: ReadonlyArray<StateHistoryEntry>;
}
/**
 * Port contract for the Operational State Engine (OSE).
 *
 * The OSE is a pure function over an ordered, deduplicated, corrected event stream.
 * It has no I/O: it does not read from or write to any store.
 * The caller is responsible for sourcing events via EventQuery.
 *
 * Processing pipeline (caller applies in order):
 *   validate → deduplicate → order → applyCorrections → replay / stateHistory / effectiveState
 */
export interface OperationalStateEngine {
    /**
     * Validates structural and semantic rules for a single event.
     * Does not check ordering or duplication — call before any persistence.
     */
    validate(event: EventInstance): ValidationResult;
    /**
     * Removes duplicate events (same id). Returns a new array — input is not mutated.
     * Idempotent: safe to call multiple times on the same stream.
     */
    deduplicate(events: ReadonlyArray<EventInstance>): ReadonlyArray<EventInstance>;
    /**
     * Orders events by timestamp ascending, then by sequence_number as tiebreaker.
     * Returns a new array — input is not mutated.
     */
    order(events: ReadonlyArray<EventInstance>): ReadonlyArray<EventInstance>;
    /**
     * Applies Event.Corrected records: marks corrected events as superseded.
     * Returns the effective stream with corrections resolved.
     */
    applyCorrections(events: ReadonlyArray<EventInstance>): ReadonlyArray<EventInstance>;
    /**
     * Replays all events and returns the final DerivedState.
     * Returns null if the stream is empty or produces no valid state.
     */
    replay(events: ReadonlyArray<EventInstance>): DerivedState | null;
    /**
     * Replays events up to and including the given ISO-8601 timestamp.
     * Events after `until` are ignored. Returns null if no events qualify.
     */
    replayUntil(events: ReadonlyArray<EventInstance>, until: string): DerivedState | null;
    /**
     * Returns DerivedState as of `until` — alias for replayUntil for temporal lookback.
     * Kept separate for semantic clarity in audit and debugging contexts.
     */
    lookback(events: ReadonlyArray<EventInstance>, until: string): DerivedState | null;
    /**
     * Returns the current effective DerivedState — equivalent to replay on a fully
     * prepared stream (validated, deduplicated, ordered, corrections applied).
     */
    effectiveState(events: ReadonlyArray<EventInstance>): DerivedState | null;
    /**
     * Produces the full StateHistory: one entry per state-altering event.
     * Useful for audit trails, timeline visualization, and debugging state transitions.
     */
    stateHistory(events: ReadonlyArray<EventInstance>): StateHistory;
}
//# sourceMappingURL=operational-state-engine.d.ts.map
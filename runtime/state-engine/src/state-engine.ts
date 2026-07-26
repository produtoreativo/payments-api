import type {
  OperationalStateEngine,
  ValidationResult,
  StateHistory,
  StateHistoryEntry,
  DerivedState,
  OperationalEvent,
} from '@prodops/runtime-sdk';
import { validateEvent } from './validation.js';
import { deduplicateEvents, orderEvents } from './ordering.js';
import { applyCorrections } from './corrections.js';
import { computeDerivedState } from './derived-state.js';
import { buildStateHistory, buildExtendedHistory, buildEffectiveState } from './history.js';
import { prepareStream, replayUntilPrepared } from './replay.js';
import { lookback as lookbackImpl } from './lookback.js';
import type { ExtendedStateHistory, EffectiveOperationalState } from './history.js';

/**
 * RT-02 — Operational State Engine implementation.
 *
 * Implements the SDK's OperationalStateEngine contract.
 * All methods are pure: no internal mutable state, no I/O.
 *
 * Processing pipeline (callers may apply steps individually):
 *   validate → deduplicate → order → applyCorrections → replay / stateHistory / effectiveState
 *
 * For convenience, raw-stream methods (replayRaw, fullHistory) apply the full pipeline
 * internally. The individual pipeline methods conform exactly to the SDK interface.
 */
export class OemOperationalStateEngine implements OperationalStateEngine {
  // ---------------------------------------------------------------------------
  // SDK interface — pipeline steps
  // ---------------------------------------------------------------------------

  validate(event: OperationalEvent): ValidationResult {
    return validateEvent(event);
  }

  deduplicate(events: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    return deduplicateEvents(events);
  }

  order(events: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    return orderEvents(events);
  }

  applyCorrections(events: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    return applyCorrections(events);
  }

  // ---------------------------------------------------------------------------
  // SDK interface — terminal operations (work on prepared streams)
  // ---------------------------------------------------------------------------

  /**
   * Replays a prepared event stream (ordered, deduplicated, corrections applied).
   * Returns the final DerivedState, or null for an empty stream.
   */
  replay(events: ReadonlyArray<OperationalEvent>): DerivedState | null {
    return computeDerivedState(events);
  }

  /**
   * Replays prepared events up to and including `until` (ISO-8601).
   * Strict temporal semantics: corrections after `until` are excluded.
   */
  replayUntil(events: ReadonlyArray<OperationalEvent>, until: string): DerivedState | null {
    return replayUntilPrepared(events, until);
  }

  /**
   * Returns DerivedState as of `until` — semantic alias for replayUntil.
   * Preferred in audit and debugging contexts where temporal framing matters.
   */
  lookback(events: ReadonlyArray<OperationalEvent>, until: string): DerivedState | null {
    return lookbackImpl(events, until);
  }

  /**
   * Returns the current effective DerivedState from a prepared stream.
   * Equivalent to replay() — separated for semantic clarity.
   */
  effectiveState(events: ReadonlyArray<OperationalEvent>): DerivedState | null {
    return computeDerivedState(events);
  }

  /**
   * Builds StateHistory (SDK type) from a prepared stream.
   * Contains one entry per state transition (events that do not change state are omitted).
   */
  stateHistory(events: ReadonlyArray<OperationalEvent>): StateHistory {
    return buildStateHistory(events);
  }

  // ---------------------------------------------------------------------------
  // Extended methods (beyond SDK interface)
  // ---------------------------------------------------------------------------

  /**
   * Applies the full preparation pipeline to a raw event stream.
   * Use this before calling the terminal operations above.
   */
  prepare(rawEvents: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    return prepareStream(rawEvents);
  }

  /**
   * Convenience: full pipeline + replay on a raw event stream.
   */
  replayRaw(rawEvents: ReadonlyArray<OperationalEvent>): DerivedState | null {
    return computeDerivedState(prepareStream(rawEvents));
  }

  /**
   * Extended state history including previousState per entry and all events (not just transitions).
   * Useful for audit trails, timeline visualisation, and debugging.
   */
  fullHistory(events: ReadonlyArray<OperationalEvent>): ExtendedStateHistory {
    return buildExtendedHistory(events);
  }

  /**
   * Returns EffectiveOperationalState: current state with contextual flags.
   * Includes previous state, transition timestamp, responsible event, and
   * boolean flags (isBlocked, isReworking, hasCorrections).
   */
  effectiveOperationalState(
    events: ReadonlyArray<OperationalEvent>,
  ): EffectiveOperationalState | null {
    return buildEffectiveState(events);
  }
}

export type { StateHistoryEntry, ExtendedStateHistory, EffectiveOperationalState };

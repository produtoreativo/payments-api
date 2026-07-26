import type { EventInstance } from '../models/event-instance.js';
import type { DerivedState } from '../models/derived-state.js';

export interface ValidationResult {
  readonly valid: boolean;
  readonly violations: ReadonlyArray<string>;
}

/**
 * Core processing engine for the Operational Event Model.
 * Separates computation from persistence — the OSE operates on in-memory event arrays.
 * Implemented by RT-02 (Timeline Processor).
 *
 * Responsibilities:
 *   - Validate EventInstance against schema rules (VAL-I-01..VAL-I-10)
 *   - Order events deterministically (timestamp ASC, sequence_number ASC)
 *   - Apply Event.Corrected records to produce an effective event view
 *   - Replay a sequence to produce DerivedState
 *   - Lookback: compute DerivedState at a point in the past
 *   - Calculate Effective Operational State from a full replay
 */
export interface OperationalStateEngine {
  validate(event: EventInstance): ValidationResult;
  order(events: ReadonlyArray<EventInstance>): ReadonlyArray<EventInstance>;
  applyCorrections(events: ReadonlyArray<EventInstance>): ReadonlyArray<EventInstance>;
  replay(events: ReadonlyArray<EventInstance>): DerivedState | null;
  lookback(events: ReadonlyArray<EventInstance>, until: string): DerivedState | null;
  effectiveState(events: ReadonlyArray<EventInstance>): DerivedState | null;
}

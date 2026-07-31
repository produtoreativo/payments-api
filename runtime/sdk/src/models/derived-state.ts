import type { State } from '../enums/state.js';
import type { Journey } from '../enums/journey.js';
import type { Cycle } from '../enums/cycle.js';
import type { Phase } from '../enums/phase.js';

/**
 * Projection of a Work Item's current state, computed from its Timeline.
 * This is never stored — it is always re-derived from the event stream.
 * Persisting it to GitHub Projects COR is a read-optimisation, not the source of truth.
 */
export interface DerivedState {
  readonly work_item_id: string;
  readonly state: State;
  readonly journey: Journey;
  readonly cycle?: Cycle;
  readonly phase?: Phase;
  readonly last_event_type: string;
  readonly last_event_id: string;
  readonly computed_at: string;
  readonly rework_count: number;
  readonly blocked_since?: string;
}

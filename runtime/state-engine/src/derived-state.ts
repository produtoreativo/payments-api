import type { OperationalEvent, DerivedState } from '@prodops/runtime-sdk';
import { State, Journey, Phase } from '@prodops/runtime-sdk';

// ---------------------------------------------------------------------------
// Event type parsing
// ---------------------------------------------------------------------------

export interface EventTypeParts {
  readonly namespace: string;
  readonly subject: string;
  readonly action: string;
  readonly qualifier?: string;
}

export function parseEventType(eventType: string): EventTypeParts | null {
  const parts = eventType.split('.');
  if (parts.length < 3) return null;
  return {
    namespace: parts[0],
    subject: parts[1],
    action: parts[2],
    qualifier: parts[3],
  };
}

// ---------------------------------------------------------------------------
// Lookup tables
// ---------------------------------------------------------------------------

const NAMESPACE_TO_JOURNEY: Readonly<Record<string, Journey>> = {
  Delivery: Journey.Delivery,
  Diligence: Journey.Diligence,
  Assessment: Journey.Assessment,
  Discovery: Journey.Discovery,
  Operation: Journey.Operation,
};

const SUBJECT_TO_PHASE: Readonly<Record<string, Phase>> = {
  Bootstrap: Phase.Bootstrap,
  Hack: Phase.Hack,
  Sync: Phase.Sync,
  Finish: Phase.Finish,
  Ship: Phase.Ship,
  Validate: Phase.Validate,
  Promote: Phase.Promote,
  Rework: Phase.Rework,
};

// State entered when <Subject>.Started fires
const PHASE_START_STATE: Readonly<Record<string, State>> = {
  Bootstrap: State.Bootstrapping,
  Hack: State.Hacking,
  Sync: State.Syncing,
  Finish: State.Finishing,
  Ship: State.Shipping,
  Validate: State.Validating,
  Promote: State.Promoting,
  Rework: State.Reworking,
};

// Actions that cause a transition to BLOCKED
const BLOCKING_ACTIONS = new Set(['Blocked', 'Raised']);

// Actions that undo BLOCKED (restore pre-block state)
const UNBLOCKING_ACTIONS = new Set(['Resolved', 'Unblocked']);

// ---------------------------------------------------------------------------
// Incremental mutable state (internal — not exported as public API)
// ---------------------------------------------------------------------------

export interface MutableOseState {
  state: State;
  journey: Journey;
  phase: Phase | undefined;
  reworkCount: number;
  blockedSince: string | undefined;
  /** State to restore when an unblocking event arrives */
  preBlockState: State;
  /** Stack for nested rework — each Rework.Started pushes, Rework.Completed pops */
  reworkStack: State[];
  hasCorrections: boolean;
}

export function createInitialState(firstEvent?: OperationalEvent): MutableOseState {
  const journey =
    firstEvent != null
      ? (NAMESPACE_TO_JOURNEY[firstEvent.event_type.split('.')[0]] ?? Journey.Delivery)
      : Journey.Delivery;

  return {
    state: State.Bootstrapping,
    journey,
    phase: undefined,
    reworkCount: 0,
    blockedSince: undefined,
    preBlockState: State.Bootstrapping,
    reworkStack: [],
    hasCorrections: false,
  };
}

/**
 * Applies a single event to the mutable OSE state (in-place).
 *
 * State transition rules:
 *   <Phase>.Started          → enter phase's active state
 *   Promote.Completed        → DONE
 *   Rework.Started           → REWORKING, reworkCount++, push current state
 *   Rework.Completed         → pop pre-rework state from stack (or stay REWORKING)
 *   <*>.Blocked|Raised       → BLOCKED, save preBlockState, set blocked_since
 *   <*>.Resolved|Unblocked   → restore preBlockState, clear blocked_since
 *   <*>.Corrected            → flag hasCorrections; no state change (corrections
 *                              are resolved by applyCorrections before replay)
 *   All other actions        → no state change (Gate, HumanDecision, System, Diligence)
 */
export function applyEventToState(event: OperationalEvent, s: MutableOseState): void {
  const parts = parseEventType(event.event_type);
  if (!parts) return;

  const { namespace, subject, action } = parts;

  // Update journey from namespace
  const journey = NAMESPACE_TO_JOURNEY[namespace];
  if (journey !== undefined) s.journey = journey;

  // Update phase from subject
  const phase = SUBJECT_TO_PHASE[subject];
  if (phase !== undefined) s.phase = phase;

  // Correction events: flag but don't mutate state
  // (corrections are applied upstream by applyCorrections before replay)
  if (action === 'Corrected') {
    s.hasCorrections = true;
    return;
  }

  // Blocking events → BLOCKED
  if (BLOCKING_ACTIONS.has(action)) {
    s.preBlockState = s.state;
    s.state = State.Blocked;
    s.blockedSince = event.timestamp;
    return;
  }

  // Unblocking events → restore pre-block state
  if (UNBLOCKING_ACTIONS.has(action)) {
    s.state = s.preBlockState;
    s.blockedSince = undefined;
    return;
  }

  // Rework lifecycle
  if (subject === 'Rework') {
    if (action === 'Started') {
      s.reworkStack.push(s.state);
      s.state = State.Reworking;
      s.reworkCount++;
    } else if (action === 'Completed') {
      const restored = s.reworkStack.pop();
      if (restored !== undefined) s.state = restored;
      // If no pre-rework state on stack (orphaned Completed), keep current state
    }
    return;
  }

  // Promote.Completed → terminal DONE state
  if (subject === 'Promote' && action === 'Completed') {
    s.state = State.Done;
    return;
  }

  // Phase.Started events → enter active state for that phase
  if (action === 'Started') {
    const newState = PHASE_START_STATE[subject];
    if (newState !== undefined) s.state = newState;
    return;
  }

  // All other actions (Completed except Promote, Gate events, HumanDecision,
  // Diligence, System) do not alter state.
}

/**
 * Snapshots the current MutableOseState into an immutable DerivedState.
 * `causedBy` is the event that triggered this snapshot.
 */
export function snapshotDerivedState(
  causedBy: OperationalEvent,
  s: Readonly<MutableOseState>,
): DerivedState {
  return {
    work_item_id: causedBy.work_item_id,
    state: s.state,
    journey: s.journey,
    phase: s.phase,
    last_event_type: causedBy.event_type,
    last_event_id: causedBy.id,
    computed_at: causedBy.timestamp,
    rework_count: s.reworkCount,
    blocked_since: s.blockedSince,
  };
}

/**
 * Computes DerivedState from a prepared event stream (ordered, deduped, corrections applied).
 * Returns null for an empty stream.
 * Pure function — no external I/O, no internal state.
 */
export function computeDerivedState(
  events: ReadonlyArray<OperationalEvent>,
): DerivedState | null {
  if (events.length === 0) return null;

  const s = createInitialState(events[0]);
  for (const event of events) {
    applyEventToState(event, s);
  }

  return snapshotDerivedState(events[events.length - 1], s);
}

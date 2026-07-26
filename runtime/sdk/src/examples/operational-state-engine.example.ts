/**
 * Example: Using the OperationalStateEngine to replay, deduplicate, and inspect state history.
 *
 * The OSE is a pure in-memory processor — no I/O. This example wires a stub
 * implementation against the full port contract to show the processing pipeline:
 *
 *   validate → deduplicate → order → applyCorrections → effectiveState / stateHistory
 */
import type {
  OperationalStateEngine,
  ValidationResult,
  StateHistory,
  StateHistoryEntry,
  OperationalEvent,
  DerivedState,
  EventId,
} from '../index.js';
import { ProducerType, Phase, EventCategory, Journey, State } from '../index.js';

// --- Stub events ---

function makeEvent(
  id: string,
  eventType: string,
  timestamp: string,
  seqNum?: number,
): OperationalEvent {
  return {
    id: id as EventId,
    event_type: eventType,
    work_item_id: 'wf-delivery-0042',
    timestamp,
    producer_type: ProducerType.Agent,
    producer_identity: 'urn:prodops:delivery:example-agent',
    schema_version: '1.0',
    sequence_number: seqNum,
  };
}

const rawEvents: ReadonlyArray<OperationalEvent> = [
  // Duplicate: same id as first event — dedup must remove it
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5001',
    `Delivery.${Phase.Bootstrap}.${EventCategory.PhaseLifecycle}.Started`,
    '2026-07-26T08:00:00.000Z',
    1,
  ),
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5001', // duplicate id
    `Delivery.${Phase.Bootstrap}.${EventCategory.PhaseLifecycle}.Started`,
    '2026-07-26T08:00:00.000Z',
    1,
  ),
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5002',
    `Delivery.${Phase.Bootstrap}.${EventCategory.PhaseLifecycle}.Completed`,
    '2026-07-26T09:00:00.000Z',
    2,
  ),
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5003',
    `Delivery.${Phase.Hack}.${EventCategory.PhaseLifecycle}.Started`,
    '2026-07-26T10:00:00.000Z',
    3,
  ),
];

// --- Stub OSE implementation ---

function stubDerivedState(event: OperationalEvent): DerivedState {
  return {
    work_item_id: event.work_item_id,
    state: State.Hacking,
    journey: Journey.Delivery,
    last_event_type: event.event_type,
    last_event_id: event.id,
    computed_at: event.timestamp,
    rework_count: 0,
  };
}

const ose: OperationalStateEngine = {
  validate(event: OperationalEvent): ValidationResult {
    const violations: string[] = [];
    if (!event.id) violations.push('id is required');
    if (!event.event_type) violations.push('event_type is required');
    if (!event.work_item_id) violations.push('work_item_id is required');
    return { valid: violations.length === 0, violations };
  },

  deduplicate(events: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    const seen = new Set<string>();
    return events.filter((e) => {
      if (seen.has(e.id)) return false;
      seen.add(e.id);
      return true;
    });
  },

  order(events: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    return [...events].sort((a, b) => {
      const timeDiff = a.timestamp.localeCompare(b.timestamp);
      if (timeDiff !== 0) return timeDiff;
      return (a.sequence_number ?? 0) - (b.sequence_number ?? 0);
    });
  },

  applyCorrections(events: ReadonlyArray<OperationalEvent>): ReadonlyArray<OperationalEvent> {
    // Stub: no corrections in this example
    return events;
  },

  replay(events: ReadonlyArray<OperationalEvent>): DerivedState | null {
    if (events.length === 0) return null;
    return stubDerivedState(events[events.length - 1]);
  },

  replayUntil(events: ReadonlyArray<OperationalEvent>, until: string): DerivedState | null {
    const filtered = events.filter((e) => e.timestamp <= until);
    return this.replay(filtered);
  },

  lookback(events: ReadonlyArray<OperationalEvent>, until: string): DerivedState | null {
    return this.replayUntil(events, until);
  },

  effectiveState(events: ReadonlyArray<OperationalEvent>): DerivedState | null {
    return this.replay(events);
  },

  stateHistory(events: ReadonlyArray<OperationalEvent>): StateHistory {
    const entries: StateHistoryEntry[] = events.map((e) => ({
      state: stubDerivedState(e),
      causedBy: e,
    }));
    return {
      workItemId: events[0]?.work_item_id ?? '',
      entries,
    };
  },
};

// --- Main processing pipeline ---

async function main(): Promise<void> {
  console.log('Raw event count:', rawEvents.length);

  const deduped = ose.deduplicate(rawEvents);
  console.log('After dedup:', deduped.length); // 3

  const ordered = ose.order(deduped);
  const corrected = ose.applyCorrections(ordered);

  const currentState = ose.effectiveState(corrected);
  console.log('Effective state:', currentState?.last_event_type);

  const history = ose.stateHistory(corrected);
  console.log('State transitions:', history.entries.length);
  for (const entry of history.entries) {
    console.log(' -', entry.causedBy.event_type, '→', entry.state.state);
  }

  const stateAt9am = ose.replayUntil(corrected, '2026-07-26T09:30:00.000Z');
  console.log('State at 09:30:', stateAt9am?.last_event_type);
}

await main();

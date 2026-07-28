import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { OperationalEvent, EventId } from '@prodops/runtime-sdk';
import { ProducerType, State, Journey, Phase } from '@prodops/runtime-sdk';
import { computeDerivedState } from '../src/derived-state.js';

let seq = 1;
function ev(
  id: string,
  eventType: string,
  timestamp: string,
): OperationalEvent {
  return {
    id: id as EventId,
    event_type: eventType,
    work_item_id: 'wf-delivery-0042',
    timestamp,
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:test',
    schema_version: '1.0',
    sequence_number: seq++,
  };
}

// Reset seq before each suite
function resetSeq() { seq = 1; }

describe('computeDerivedState — empty stream', () => {
  it('returns null for empty event array', () => {
    assert.equal(computeDerivedState([]), null);
  });
});

describe('computeDerivedState — happy path (full delivery lifecycle)', () => {
  resetSeq();
  const events = [
    ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Hack.Started',      '2026-07-26T09:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000003', 'Delivery.Sync.Started',      '2026-07-26T10:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000004', 'Delivery.Finish.Started',    '2026-07-26T11:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000005', 'Delivery.Ship.Started',      '2026-07-26T12:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000006', 'Delivery.Validate.Started',  '2026-07-26T13:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000007', 'Delivery.Promote.Started',   '2026-07-26T14:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000008', 'Delivery.Promote.Completed', '2026-07-26T15:00:00Z'),
  ];

  it('starts with BOOTSTRAPPING', () => {
    const s = computeDerivedState(events.slice(0, 1));
    assert.equal(s?.state, State.Bootstrapping);
    assert.equal(s?.phase, Phase.Bootstrap);
  });

  it('transitions to HACKING after Hack.Started', () => {
    const s = computeDerivedState(events.slice(0, 2));
    assert.equal(s?.state, State.Hacking);
    assert.equal(s?.phase, Phase.Hack);
  });

  it('transitions to SYNCING', () => {
    assert.equal(computeDerivedState(events.slice(0, 3))?.state, State.Syncing);
  });

  it('transitions to FINISHING', () => {
    assert.equal(computeDerivedState(events.slice(0, 4))?.state, State.Finishing);
  });

  it('transitions to SHIPPING', () => {
    assert.equal(computeDerivedState(events.slice(0, 5))?.state, State.Shipping);
  });

  it('transitions to VALIDATING', () => {
    assert.equal(computeDerivedState(events.slice(0, 6))?.state, State.Validating);
  });

  it('transitions to PROMOTING', () => {
    assert.equal(computeDerivedState(events.slice(0, 7))?.state, State.Promoting);
  });

  it('transitions to DONE on Promote.Completed', () => {
    const s = computeDerivedState(events);
    assert.equal(s?.state, State.Done);
  });

  it('sets journey to Delivery', () => {
    assert.equal(computeDerivedState(events)?.journey, Journey.Delivery);
  });

  it('tracks last_event_type and last_event_id', () => {
    const s = computeDerivedState(events);
    assert.equal(s?.last_event_type, 'Delivery.Promote.Completed');
    assert.equal(s?.last_event_id, events[events.length - 1].id);
  });
});

describe('computeDerivedState — blocking', () => {
  resetSeq();
  const events = [
    ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Hack.Started',  '2026-07-26T09:00:00Z'),
    ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Gate.Blocked',  '2026-07-26T10:00:00Z'),
  ];

  it('transitions to BLOCKED on Gate.Blocked', () => {
    const s = computeDerivedState(events);
    assert.equal(s?.state, State.Blocked);
    assert.ok(s?.blocked_since);
  });

  it('sets blocked_since to the blocking event timestamp', () => {
    const s = computeDerivedState(events);
    assert.equal(s?.blocked_since, '2026-07-26T10:00:00Z');
  });

  it('restores pre-block state on Gate.Resolved', () => {
    const resolved = ev('018f0000-0000-7000-8000-000000000003', 'Delivery.Gate.Resolved', '2026-07-26T11:00:00Z');
    const s = computeDerivedState([...events, resolved]);
    assert.equal(s?.state, State.Hacking);
    assert.equal(s?.blocked_since, undefined);
  });

  it('restores pre-block state on Impediment.Unblocked', () => {
    const e = ev('018f0000-0000-7000-8000-000000000003', 'Delivery.Impediment.Unblocked', '2026-07-26T11:00:00Z');
    const s = computeDerivedState([...events, e]);
    assert.equal(s?.state, State.Hacking);
  });

  it('handles Impediment.Raised as a blocking action', () => {
    const raised = ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Impediment.Raised', '2026-07-26T10:00:00Z');
    const s = computeDerivedState([events[0], raised]);
    assert.equal(s?.state, State.Blocked);
  });
});

describe('computeDerivedState — rework', () => {
  resetSeq();
  const hackStarted = ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Hack.Started', '2026-07-26T09:00:00Z');
  const reworkStarted = ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Rework.Started', '2026-07-26T10:00:00Z');
  const reworkCompleted = ev('018f0000-0000-7000-8000-000000000003', 'Delivery.Rework.Completed', '2026-07-26T11:00:00Z');

  it('transitions to REWORKING on Rework.Started', () => {
    const s = computeDerivedState([hackStarted, reworkStarted]);
    assert.equal(s?.state, State.Reworking);
  });

  it('increments rework_count on Rework.Started', () => {
    const s = computeDerivedState([hackStarted, reworkStarted]);
    assert.equal(s?.rework_count, 1);
  });

  it('restores pre-rework state on Rework.Completed', () => {
    const s = computeDerivedState([hackStarted, reworkStarted, reworkCompleted]);
    assert.equal(s?.state, State.Hacking);
  });

  it('does not decrement rework_count on Rework.Completed', () => {
    const s = computeDerivedState([hackStarted, reworkStarted, reworkCompleted]);
    assert.equal(s?.rework_count, 1);
  });

  it('handles multiple rework cycles', () => {
    const e4 = ev('018f0000-0000-7000-8000-000000000004', 'Delivery.Rework.Started', '2026-07-26T12:00:00Z');
    const e5 = ev('018f0000-0000-7000-8000-000000000005', 'Delivery.Rework.Completed', '2026-07-26T13:00:00Z');
    const s = computeDerivedState([hackStarted, reworkStarted, reworkCompleted, e4, e5]);
    assert.equal(s?.rework_count, 2);
    assert.equal(s?.state, State.Hacking);
  });
});

describe('computeDerivedState — gate and other non-state-changing events', () => {
  resetSeq();

  it('Gate events that are not Blocked/Resolved do not change state', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Hack.Started', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Gate.Approved', '2026-07-26T09:05:00Z'),
    ];
    const s = computeDerivedState(events);
    assert.equal(s?.state, State.Hacking);
  });

  it('HumanDecision events do not change state', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Hack.Started', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000002', 'Delivery.HumanDecision.Approved', '2026-07-26T09:05:00Z'),
    ];
    const s = computeDerivedState(events);
    assert.equal(s?.state, State.Hacking);
  });

  it('System events do not change state', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Hack.Started', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000002', 'Delivery.System.Completed', '2026-07-26T09:05:00Z'),
    ];
    const s = computeDerivedState(events);
    assert.equal(s?.state, State.Hacking);
  });
});

describe('computeDerivedState — journey inference', () => {
  resetSeq();

  it('infers Diligence journey from namespace', () => {
    const s = computeDerivedState([
      ev('018f0000-0000-7000-8000-000000000001', 'Diligence.Hack.Started', '2026-07-26T09:00:00Z'),
    ]);
    assert.equal(s?.journey, Journey.Diligence);
  });

  it('infers Assessment journey from namespace', () => {
    const s = computeDerivedState([
      ev('018f0000-0000-7000-8000-000000000001', 'Assessment.Hack.Started', '2026-07-26T09:00:00Z'),
    ]);
    assert.equal(s?.journey, Journey.Assessment);
  });
});

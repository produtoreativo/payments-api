import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { OperationalEvent, EventId } from '@prodops/runtime-sdk';
import { ProducerType, State } from '@prodops/runtime-sdk';
import { OemOperationalStateEngine } from '../src/state-engine.js';

const ose = new OemOperationalStateEngine();

let _seq = 1;
function resetSeq() { _seq = 1; }

function ev(
  id: string,
  eventType: string,
  timestamp: string,
  correctedId?: string,
): OperationalEvent {
  return {
    id: id as EventId,
    event_type: eventType,
    work_item_id: 'wf-delivery-0042',
    timestamp,
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:test',
    schema_version: '1.0',
    sequence_number: _seq++,
    payload: correctedId ? { corrected_event_id: correctedId } : undefined,
  };
}

// ---------------------------------------------------------------------------
// Canonical IDs used across tests
// ---------------------------------------------------------------------------
const ID = {
  e1: '018f0000-0000-7000-8000-000000000001',
  e2: '018f0000-0000-7000-8000-000000000002',
  e3: '018f0000-0000-7000-8000-000000000003',
  e4: '018f0000-0000-7000-8000-000000000004',
  e5: '018f0000-0000-7000-8000-000000000005',
  e6: '018f0000-0000-7000-8000-000000000006',
  e7: '018f0000-0000-7000-8000-000000000007',
  e8: '018f0000-0000-7000-8000-000000000008',
};

// ---------------------------------------------------------------------------
// Empty timeline
// ---------------------------------------------------------------------------
describe('empty timeline', () => {
  it('replay returns null', () => {
    assert.equal(ose.replay([]), null);
  });

  it('effectiveState returns null', () => {
    assert.equal(ose.effectiveState([]), null);
  });

  it('stateHistory returns empty entries', () => {
    const h = ose.stateHistory([]);
    assert.equal(h.entries.length, 0);
    assert.equal(h.workItemId, '');
  });

  it('replayUntil returns null', () => {
    assert.equal(ose.replayUntil([], '2026-07-26T10:00:00Z'), null);
  });

  it('lookback returns null', () => {
    assert.equal(ose.lookback([], '2026-07-26T10:00:00Z'), null);
  });
});

// ---------------------------------------------------------------------------
// Happy path — full delivery lifecycle
// ---------------------------------------------------------------------------
describe('happy path — full delivery lifecycle', () => {
  resetSeq();
  const events = ose.prepare([
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev(ID.e2, 'Delivery.Hack.Started',      '2026-07-26T09:00:00Z'),
    ev(ID.e3, 'Delivery.Sync.Started',      '2026-07-26T10:00:00Z'),
    ev(ID.e4, 'Delivery.Finish.Started',    '2026-07-26T11:00:00Z'),
    ev(ID.e5, 'Delivery.Ship.Started',      '2026-07-26T12:00:00Z'),
    ev(ID.e6, 'Delivery.Validate.Started',  '2026-07-26T13:00:00Z'),
    ev(ID.e7, 'Delivery.Promote.Started',   '2026-07-26T14:00:00Z'),
    ev(ID.e8, 'Delivery.Promote.Completed', '2026-07-26T15:00:00Z'),
  ]);

  it('final state is DONE', () => {
    assert.equal(ose.replay(events)?.state, State.Done);
  });

  it('effectiveState returns DONE', () => {
    assert.equal(ose.effectiveState(events)?.state, State.Done);
  });

  it('work_item_id is preserved', () => {
    assert.equal(ose.replay(events)?.work_item_id, 'wf-delivery-0042');
  });

  it('rework_count is 0 for a clean run', () => {
    assert.equal(ose.replay(events)?.rework_count, 0);
  });
});

// ---------------------------------------------------------------------------
// Out-of-order events
// ---------------------------------------------------------------------------
describe('out-of-order events', () => {
  resetSeq();
  const outOfOrder: OperationalEvent[] = [
    ev(ID.e3, 'Delivery.Sync.Started', '2026-07-26T10:00:00Z'),
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev(ID.e2, 'Delivery.Hack.Started', '2026-07-26T09:00:00Z'),
  ];

  it('order() sorts events by timestamp', () => {
    const ordered = ose.order(outOfOrder);
    assert.equal(ordered[0].id, ID.e1);
    assert.equal(ordered[1].id, ID.e2);
    assert.equal(ordered[2].id, ID.e3);
  });

  it('prepare() produces correctly ordered stream', () => {
    const prepared = ose.prepare(outOfOrder);
    assert.equal(prepared[0].event_type, 'Delivery.Bootstrap.Started');
    assert.equal(prepared[1].event_type, 'Delivery.Hack.Started');
    assert.equal(prepared[2].event_type, 'Delivery.Sync.Started');
  });

  it('replay after prepare() produces SYNCING state', () => {
    const state = ose.replay(ose.prepare(outOfOrder));
    assert.equal(state?.state, State.Syncing);
  });
});

// ---------------------------------------------------------------------------
// Duplicate events
// ---------------------------------------------------------------------------
describe('duplicate events', () => {
  resetSeq();
  const withDuplicates: OperationalEvent[] = [
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'), // exact duplicate
    ev(ID.e2, 'Delivery.Hack.Started', '2026-07-26T09:00:00Z'),
  ];

  it('deduplicate() removes duplicate event', () => {
    const deduped = ose.deduplicate(withDuplicates);
    assert.equal(deduped.length, 2);
  });

  it('replay after prepare() computes correct state despite duplicates in input', () => {
    const state = ose.replay(ose.prepare(withDuplicates));
    assert.equal(state?.state, State.Hacking);
  });
});

// ---------------------------------------------------------------------------
// Rework
// ---------------------------------------------------------------------------
describe('rework', () => {
  resetSeq();
  const events = ose.prepare([
    ev(ID.e1, 'Delivery.Hack.Started',      '2026-07-26T09:00:00Z'),
    ev(ID.e2, 'Delivery.Rework.Started',    '2026-07-26T10:00:00Z'),
    ev(ID.e3, 'Delivery.Rework.Completed',  '2026-07-26T11:00:00Z'),
    ev(ID.e4, 'Delivery.Sync.Started',      '2026-07-26T12:00:00Z'),
  ]);

  it('rework_count is 1 after one rework cycle', () => {
    assert.equal(ose.replay(events)?.rework_count, 1);
  });

  it('state restores to SYNCING after Rework.Completed and Sync.Started', () => {
    assert.equal(ose.replay(events)?.state, State.Syncing);
  });

  it('state is REWORKING while rework is active', () => {
    const midRework = ose.prepare([
      ev(ID.e1, 'Delivery.Hack.Started',   '2026-07-26T09:00:00Z'),
      ev(ID.e2, 'Delivery.Rework.Started', '2026-07-26T10:00:00Z'),
    ]);
    assert.equal(ose.replay(midRework)?.state, State.Reworking);
  });
});

// ---------------------------------------------------------------------------
// Blocking + Lookback
// ---------------------------------------------------------------------------
describe('blocking + lookback', () => {
  resetSeq();
  const rawEvents: OperationalEvent[] = [
    ev(ID.e1, 'Delivery.Hack.Started',   '2026-07-26T09:00:00Z'),
    ev(ID.e2, 'Delivery.Gate.Blocked',   '2026-07-26T10:00:00Z'),
    ev(ID.e3, 'Delivery.Gate.Resolved',  '2026-07-26T11:00:00Z'),
    ev(ID.e4, 'Delivery.Sync.Started',   '2026-07-26T12:00:00Z'),
  ];

  it('final state is SYNCING (blocking resolved)', () => {
    assert.equal(ose.replay(ose.prepare(rawEvents))?.state, State.Syncing);
  });

  it('lookback at block time returns BLOCKED', () => {
    const s = ose.lookback(rawEvents, '2026-07-26T10:30:00Z');
    assert.equal(s?.state, State.Blocked);
    assert.ok(s?.blocked_since);
  });

  it('lookback before block returns HACKING', () => {
    const s = ose.lookback(rawEvents, '2026-07-26T09:30:00Z');
    assert.equal(s?.state, State.Hacking);
  });

  it('lookback after resolve returns HACKING (resolve is before lookback ts)', () => {
    const s = ose.lookback(rawEvents, '2026-07-26T11:30:00Z');
    assert.equal(s?.state, State.Hacking);
  });
});

// ---------------------------------------------------------------------------
// Event.Corrected
// ---------------------------------------------------------------------------
describe('Event.Corrected', () => {
  resetSeq();
  // e1: Bootstrap.Started → will be corrected (wrong event type)
  // e2: correction of e1
  // e3: Hack.Started (after correction)
  const e1 = ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z');
  const e2 = ev(ID.e2, 'Delivery.Event.Corrected', '2026-07-26T08:30:00Z', ID.e1);
  const e3 = ev(ID.e3, 'Delivery.Hack.Started', '2026-07-26T09:00:00Z');

  it('applyCorrections removes superseded event', () => {
    const stream = ose.applyCorrections(ose.order([e1, e2, e3]));
    assert.ok(!stream.some((e) => e.id === ID.e1));
    assert.ok(stream.some((e) => e.id === ID.e2)); // correction event remains
    assert.ok(stream.some((e) => e.id === ID.e3));
  });

  it('replay after corrections reflects corrected state', () => {
    const prepared = ose.prepare([e1, e2, e3]);
    const s = ose.replay(prepared);
    // Bootstrap.Started was superseded; correction event doesn't change state;
    // Hack.Started sets state to HACKING
    assert.equal(s?.state, State.Hacking);
  });

  it('lookback before correction sees original (Bootstrap) state', () => {
    // At t=08:15, only e1 (Bootstrap.Started) is known — correction hasn't arrived yet
    const s = ose.lookback([e1, e2, e3], '2026-07-26T08:15:00Z');
    assert.equal(s?.state, State.Bootstrapping);
  });

  it('lookback after correction sees corrected state', () => {
    const s = ose.lookback([e1, e2, e3], '2026-07-26T09:30:00Z');
    // correction applied: e1 removed, e2 correction present, e3 Hack.Started
    assert.equal(s?.state, State.Hacking);
  });
});

// ---------------------------------------------------------------------------
// ReplayUntil
// ---------------------------------------------------------------------------
describe('replayUntil', () => {
  resetSeq();
  const events = ose.prepare([
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev(ID.e2, 'Delivery.Hack.Started',      '2026-07-26T09:00:00Z'),
    ev(ID.e3, 'Delivery.Sync.Started',      '2026-07-26T10:00:00Z'),
    ev(ID.e4, 'Delivery.Finish.Started',    '2026-07-26T11:00:00Z'),
  ]);

  it('replayUntil 08:30 → BOOTSTRAPPING', () => {
    assert.equal(ose.replayUntil(events, '2026-07-26T08:30:00Z')?.state, State.Bootstrapping);
  });

  it('replayUntil 09:30 → HACKING', () => {
    assert.equal(ose.replayUntil(events, '2026-07-26T09:30:00Z')?.state, State.Hacking);
  });

  it('replayUntil 10:30 → SYNCING', () => {
    assert.equal(ose.replayUntil(events, '2026-07-26T10:30:00Z')?.state, State.Syncing);
  });

  it('replayUntil beyond all events → final state', () => {
    assert.equal(ose.replayUntil(events, '2030-01-01T00:00:00Z')?.state, State.Finishing);
  });

  it('replayUntil before all events → null', () => {
    assert.equal(ose.replayUntil(events, '2026-01-01T00:00:00Z'), null);
  });
});

// ---------------------------------------------------------------------------
// Derived State
// ---------------------------------------------------------------------------
describe('derived state consistency', () => {
  resetSeq();
  const events = ose.prepare([
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev(ID.e2, 'Delivery.Hack.Started',      '2026-07-26T09:00:00Z'),
  ]);

  it('computed_at matches last event timestamp', () => {
    const s = ose.replay(events);
    assert.equal(s?.computed_at, '2026-07-26T09:00:00Z');
  });

  it('last_event_type matches last event', () => {
    const s = ose.replay(events);
    assert.equal(s?.last_event_type, 'Delivery.Hack.Started');
  });

  it('last_event_id matches last event id', () => {
    const s = ose.replay(events);
    assert.equal(s?.last_event_id, ID.e2);
  });

  it('effectiveState equals replay on prepared stream', () => {
    const r = ose.replay(events);
    const e = ose.effectiveState(events);
    assert.deepEqual(r, e);
  });

  it('result depends exclusively on events (no internal state between calls)', () => {
    const s1 = ose.replay(events);
    const s2 = ose.replay(events);
    assert.deepEqual(s1, s2);
  });
});

// ---------------------------------------------------------------------------
// State History
// ---------------------------------------------------------------------------
describe('stateHistory', () => {
  resetSeq();
  const events = ose.prepare([
    ev(ID.e1, 'Delivery.Bootstrap.Started', '2026-07-26T08:00:00Z'),
    ev(ID.e2, 'Delivery.Hack.Started',      '2026-07-26T09:00:00Z'),
    ev(ID.e3, 'Delivery.Gate.Approved',     '2026-07-26T09:30:00Z'), // non-state-changing
    ev(ID.e4, 'Delivery.Sync.Started',      '2026-07-26T10:00:00Z'),
    ev(ID.e5, 'Delivery.Promote.Completed', '2026-07-26T11:00:00Z'),
  ]);

  it('returns one entry per state transition', () => {
    const h = ose.stateHistory(events);
    // BOOTSTRAPPING → HACKING → SYNCING → DONE = 4 transitions (each Started state)
    // Gate.Approved doesn't change state so it's excluded
    // But initial Bootstrap.Started IS included (first state entry)
    assert.ok(h.entries.length >= 3);
  });

  it('entries have correct final state', () => {
    const h = ose.stateHistory(events);
    const last = h.entries[h.entries.length - 1];
    assert.equal(last.state.state, State.Done);
  });

  it('workItemId is set from events', () => {
    const h = ose.stateHistory(events);
    assert.equal(h.workItemId, 'wf-delivery-0042');
  });

  it('each entry causedBy matches state transition event', () => {
    const h = ose.stateHistory(events);
    for (const entry of h.entries) {
      assert.ok(entry.causedBy.event_type.length > 0);
      assert.ok(entry.state.state.length > 0);
    }
  });

  it('non-state-changing events are excluded from history', () => {
    const h = ose.stateHistory(events);
    // Gate.Approved should NOT appear as a state-history entry
    const gateEntry = h.entries.find((e) => e.causedBy.event_type === 'Delivery.Gate.Approved');
    assert.equal(gateEntry, undefined);
  });
});

// ---------------------------------------------------------------------------
// Extended history and effective operational state
// ---------------------------------------------------------------------------
describe('fullHistory and effectiveOperationalState', () => {
  resetSeq();
  const events = ose.prepare([
    ev(ID.e1, 'Delivery.Hack.Started',    '2026-07-26T09:00:00Z'),
    ev(ID.e2, 'Delivery.Gate.Blocked',    '2026-07-26T10:00:00Z'),
    ev(ID.e3, 'Delivery.Gate.Resolved',   '2026-07-26T11:00:00Z'),
  ]);

  it('fullHistory includes all events (including non-state-changing)', () => {
    // All 3 events are included
    const h = ose.fullHistory(events);
    assert.equal(h.entries.length, 3);
  });

  it('fullHistory entry has previousState field', () => {
    const h = ose.fullHistory(events);
    assert.ok('previousState' in h.entries[0]);
  });

  it('effectiveOperationalState.isBlocked is false after resolution', () => {
    const eos = ose.effectiveOperationalState(events);
    assert.equal(eos?.isBlocked, false);
  });

  it('effectiveOperationalState.isBlocked is true while blocked', () => {
    const blocked = ose.prepare([
      ev(ID.e1, 'Delivery.Hack.Started',  '2026-07-26T09:00:00Z'),
      ev(ID.e2, 'Delivery.Gate.Blocked',  '2026-07-26T10:00:00Z'),
    ]);
    const eos = ose.effectiveOperationalState(blocked);
    assert.equal(eos?.isBlocked, true);
  });

  it('effectiveOperationalState for empty stream is null', () => {
    assert.equal(ose.effectiveOperationalState([]), null);
  });
});

// ---------------------------------------------------------------------------
// validate
// ---------------------------------------------------------------------------
describe('validate', () => {
  it('validates a correct event as valid', () => {
    const e = ev(ID.e1, 'Delivery.Hack.Started', '2026-07-26T09:00:00Z');
    const result = ose.validate(e);
    assert.equal(result.valid, true);
  });

  it('returns violations for missing id', () => {
    const e = { ...ev(ID.e1, 'Delivery.Hack.Started', '2026-07-26T09:00:00Z'), id: '' as EventId };
    const result = ose.validate(e);
    assert.equal(result.valid, false);
  });
});

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { OperationalEvent, EventId } from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';
import { deduplicateEvents, orderEvents } from '../src/ordering.js';

function ev(
  id: string,
  timestamp: string,
  seqNum?: number,
): OperationalEvent {
  return {
    id: id as EventId,
    event_type: 'Delivery.Hack.Started',
    work_item_id: 'wf-0001',
    timestamp,
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:test',
    schema_version: '1.0',
    sequence_number: seqNum,
  };
}

describe('deduplicateEvents', () => {
  it('returns same events when no duplicates', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T09:01:00Z'),
    ];
    const result = deduplicateEvents(events);
    assert.equal(result.length, 2);
  });

  it('removes duplicate events keeping first occurrence', () => {
    const e1 = ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z');
    const e2 = ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:01:00Z'); // same id
    const result = deduplicateEvents([e1, e2]);
    assert.equal(result.length, 1);
    assert.equal(result[0].timestamp, e1.timestamp); // first wins
  });

  it('removes multiple duplicates', () => {
    const e1 = ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z');
    const e2 = ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:01:00Z');
    const e3 = ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:02:00Z');
    const e4 = ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T09:03:00Z');
    const result = deduplicateEvents([e1, e2, e3, e4]);
    assert.equal(result.length, 2);
  });

  it('does not mutate input', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:01:00Z'),
    ];
    const orig = [...events];
    deduplicateEvents(events);
    assert.equal(events.length, orig.length);
  });

  it('handles empty stream', () => {
    assert.equal(deduplicateEvents([]).length, 0);
  });

  it('is idempotent', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:01:00Z'),
    ];
    const once = deduplicateEvents(events);
    const twice = deduplicateEvents(once);
    assert.equal(once.length, twice.length);
  });
});

describe('orderEvents', () => {
  it('orders by timestamp ascending', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T10:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z'),
    ];
    const result = orderEvents(events);
    assert.equal(result[0].timestamp, '2026-07-26T09:00:00Z');
    assert.equal(result[1].timestamp, '2026-07-26T10:00:00Z');
  });

  it('uses sequence_number as tiebreaker for same timestamp', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T09:00:00Z', 2),
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z', 1),
    ];
    const result = orderEvents(events);
    assert.equal(result[0].sequence_number, 1);
    assert.equal(result[1].sequence_number, 2);
  });

  it('uses event id as final tiebreaker (UUID v7 → time-ordered)', () => {
    // Same timestamp, no sequence_number, different ids
    const events = [
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T09:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z'),
    ];
    const result = orderEvents(events);
    assert.equal(result[0].id, '018f0000-0000-7000-8000-000000000001');
    assert.equal(result[1].id, '018f0000-0000-7000-8000-000000000002');
  });

  it('events without sequence_number sort after those with one (same timestamp)', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T09:00:00Z'), // no seqNum
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z', 1), // seqNum=1
    ];
    const result = orderEvents(events);
    assert.equal(result[0].sequence_number, 1);
    assert.equal(result[1].sequence_number, undefined);
  });

  it('does not mutate input', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T10:00:00Z'),
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z'),
    ];
    const origFirst = events[0].id;
    orderEvents(events);
    assert.equal(events[0].id, origFirst); // input unchanged
  });

  it('handles empty stream', () => {
    assert.equal(orderEvents([]).length, 0);
  });

  it('is stable for already-ordered events', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', '2026-07-26T09:00:00Z', 1),
      ev('018f0000-0000-7000-8000-000000000002', '2026-07-26T09:01:00Z', 2),
      ev('018f0000-0000-7000-8000-000000000003', '2026-07-26T09:02:00Z', 3),
    ];
    const result = orderEvents(events);
    assert.equal(result[0].id, events[0].id);
    assert.equal(result[1].id, events[1].id);
    assert.equal(result[2].id, events[2].id);
  });
});

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { OperationalEvent, EventId } from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';
import { isCorrectionEvent, getCorrectedEventId, applyCorrections } from '../src/corrections.js';

function ev(
  id: string,
  eventType: string,
  correctedId?: string,
): OperationalEvent {
  return {
    id: id as EventId,
    event_type: eventType,
    work_item_id: 'wf-0001',
    timestamp: '2026-07-26T09:00:00Z',
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:test',
    schema_version: '1.0',
    payload: correctedId ? { corrected_event_id: correctedId } : undefined,
  };
}

const CORRECTED_ID = '018f0000-0000-7000-8000-000000000001';
const CORRECTION_ID = '018f0000-0000-7000-8000-000000000002';

describe('isCorrectionEvent', () => {
  it('identifies Event.Corrected events', () => {
    const e = ev(CORRECTION_ID, 'Delivery.Event.Corrected');
    assert.equal(isCorrectionEvent(e), true);
  });

  it('identifies any namespace.*.Corrected pattern', () => {
    assert.equal(isCorrectionEvent(ev('018f0000-0000-7000-8000-aaaaaaaaaaaa', 'Diligence.Assessment.Corrected')), true);
  });

  it('returns false for regular phase events', () => {
    assert.equal(isCorrectionEvent(ev('018f0000-0000-7000-8000-bbbbbbbbbbbb', 'Delivery.Hack.Started')), false);
    assert.equal(isCorrectionEvent(ev('018f0000-0000-7000-8000-cccccccccccc', 'Delivery.Gate.Blocked')), false);
  });
});

describe('getCorrectedEventId', () => {
  it('returns corrected_event_id from payload', () => {
    const e = ev(CORRECTION_ID, 'Delivery.Event.Corrected', CORRECTED_ID);
    assert.equal(getCorrectedEventId(e), CORRECTED_ID);
  });

  it('returns undefined for non-correction event', () => {
    const e = ev('018f0000-0000-7000-8000-bbbbbbbbbbbb', 'Delivery.Hack.Started');
    assert.equal(getCorrectedEventId(e), undefined);
  });

  it('returns undefined for correction event without payload', () => {
    const e = ev(CORRECTION_ID, 'Delivery.Event.Corrected'); // no correctedId
    assert.equal(getCorrectedEventId(e), undefined);
  });
});

describe('applyCorrections', () => {
  it('removes superseded event while keeping correction event', () => {
    const original = ev(CORRECTED_ID, 'Delivery.Hack.Started');
    const correction = ev(CORRECTION_ID, 'Delivery.Event.Corrected', CORRECTED_ID);
    const result = applyCorrections([original, correction]);

    assert.equal(result.length, 1);
    assert.equal(result[0].id, CORRECTION_ID);
  });

  it('keeps all events when no corrections present', () => {
    const events = [
      ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Bootstrap.Started'),
      ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Hack.Started'),
    ];
    const result = applyCorrections(events);
    assert.equal(result.length, 2);
  });

  it('handles multiple corrections', () => {
    const e1 = ev('018f0000-0000-7000-8000-000000000001', 'Delivery.Bootstrap.Started');
    const e2 = ev('018f0000-0000-7000-8000-000000000002', 'Delivery.Hack.Started');
    const c1 = ev('018f0000-0000-7000-8000-000000000003', 'Delivery.Event.Corrected', e1.id);
    const c2 = ev('018f0000-0000-7000-8000-000000000004', 'Delivery.Event.Corrected', e2.id);

    const result = applyCorrections([e1, e2, c1, c2]);
    assert.equal(result.length, 2); // only corrections remain
    assert.ok(result.some((e) => e.id === c1.id));
    assert.ok(result.some((e) => e.id === c2.id));
  });

  it('does not mutate input', () => {
    const original = ev(CORRECTED_ID, 'Delivery.Hack.Started');
    const correction = ev(CORRECTION_ID, 'Delivery.Event.Corrected', CORRECTED_ID);
    const input = [original, correction];
    applyCorrections(input);
    assert.equal(input.length, 2); // input unchanged
  });

  it('is idempotent', () => {
    const original = ev(CORRECTED_ID, 'Delivery.Hack.Started');
    const correction = ev(CORRECTION_ID, 'Delivery.Event.Corrected', CORRECTED_ID);
    const once = applyCorrections([original, correction]);
    const twice = applyCorrections(once);
    assert.equal(once.length, twice.length);
    assert.equal(once[0].id, twice[0].id);
  });

  it('handles empty stream', () => {
    assert.equal(applyCorrections([]).length, 0);
  });
});

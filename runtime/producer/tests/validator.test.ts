import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type { OperationalEvent, EventId } from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';
import { validateOperationalEvent } from '../src/validator.js';

const VALID_UUID_V7 = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6a' as EventId;

function validEvent(): OperationalEvent {
  return {
    id: VALID_UUID_V7,
    event_type: 'Delivery.Hack.Started',
    work_item_id: 'wf-delivery-0042',
    timestamp: '2026-07-26T09:00:00.000Z',
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:hack-start-agent',
    schema_version: '1.0',
  };
}

describe('validateOperationalEvent', () => {
  it('accepts a fully valid event', () => {
    const result = validateOperationalEvent(validEvent());
    assert.equal(result.valid, true);
    assert.equal(result.violations.length, 0);
  });

  it('accepts event with optional fields', () => {
    const event: OperationalEvent = {
      ...validEvent(),
      payload: { branch: 'feat/wf-0042' },
      notes: 'manual correction',
      sequence_number: 42,
    };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, true);
  });

  // EventId

  it('rejects a plain string that is not a UUID', () => {
    const event = { ...validEvent(), id: 'not-a-uuid' as EventId };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('id')));
  });

  it('rejects a UUID v4 (wrong version nibble)', () => {
    // v4 UUID: version nibble is 4, not 7
    const uuidV4 = '550e8400-e29b-41d4-a716-446655440000' as EventId;
    const event = { ...validEvent(), id: uuidV4 };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('id')));
  });

  it('accepts a valid UUID v7', () => {
    const anotherV7 = '018f7e9b-0000-7000-8000-000000000000' as EventId;
    const event = { ...validEvent(), id: anotherV7 };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, true);
  });

  // EventType

  it('rejects event_type with only 2 segments', () => {
    const event = { ...validEvent(), event_type: 'Delivery.Hack' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('event_type')));
  });

  it('rejects event_type with empty segment (leading dot)', () => {
    const event = { ...validEvent(), event_type: '.Delivery.Hack.Started' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
  });

  it('accepts event_type with 4 segments (with qualifier)', () => {
    const event = { ...validEvent(), event_type: 'Delivery.Hack.Started.Override' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, true);
  });

  // Timestamp

  it('rejects a non-date timestamp', () => {
    const event = { ...validEvent(), timestamp: 'not-a-date' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('timestamp')));
  });

  it('rejects an empty timestamp', () => {
    const event = { ...validEvent(), timestamp: '' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('timestamp')));
  });

  // WorkItemId

  it('rejects blank work_item_id', () => {
    const event = { ...validEvent(), work_item_id: '' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('work_item_id')));
  });

  it('rejects whitespace-only work_item_id', () => {
    const event = { ...validEvent(), work_item_id: '   ' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
  });

  // SchemaVersion

  it('rejects blank schema_version', () => {
    const event = { ...validEvent(), schema_version: '' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('schema_version')));
  });

  // ProducerIdentity

  it('rejects blank producer_identity', () => {
    const event = { ...validEvent(), producer_identity: '' };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.some((v) => v.includes('producer_identity')));
  });

  // Multiple violations

  it('accumulates multiple violations', () => {
    const event = {
      ...validEvent(),
      id: 'bad' as EventId,
      event_type: 'Bad',
      timestamp: 'nope',
    };
    const result = validateOperationalEvent(event);
    assert.equal(result.valid, false);
    assert.ok(result.violations.length >= 3);
  });
});

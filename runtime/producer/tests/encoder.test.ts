import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type {
  OperationalEvent,
  EventId,
  CloudEventSource,
  CloudEventEncodingContext,
} from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';
import { OemCloudEventEncoder } from '../src/encoder.js';

const SOURCE = 'prodops://payments-api/runtime' as CloudEventSource;
const VALID_UUID_V7 = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6a' as EventId;

const event: OperationalEvent = {
  id: VALID_UUID_V7,
  event_type: 'Delivery.Hack.Started',
  work_item_id: 'wf-delivery-0042',
  timestamp: '2026-07-26T09:00:00.000Z',
  producer_type: ProducerType.Agent,
  producer_identity: 'agent:hack-start-agent',
  schema_version: '1.0',
};

const context: CloudEventEncodingContext = { source: SOURCE };

describe('OemCloudEventEncoder', () => {
  it('produces a CloudEvents 1.0 envelope with specversion 1.0', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.specversion, '1.0');
  });

  it('maps event.id → envelope.id', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.id, event.id);
  });

  it('maps event.event_type → envelope.type', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.type, event.event_type);
  });

  it('maps event.work_item_id → envelope.subject', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.subject, event.work_item_id);
  });

  it('maps event.timestamp → envelope.time', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.time, event.timestamp);
  });

  it('maps context.source → envelope.source (not producer_identity)', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.source, SOURCE);
    assert.notEqual(envelope.source, event.producer_identity as string);
  });

  it('sets datacontenttype to application/json', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.datacontenttype, 'application/json');
  });

  it('places the full EventInstance in data', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.deepEqual(envelope.data, event);
  });

  it('preserves producer_identity inside data', () => {
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, context);
    assert.equal(envelope.data?.producer_identity, event.producer_identity);
  });

  it('uses the provided source, not a hardcoded fallback', () => {
    const altSource = 'prodops://payments-api/github-actions' as CloudEventSource;
    const altContext: CloudEventEncodingContext = { source: altSource };
    const encoder = new OemCloudEventEncoder();
    const envelope = encoder.encode(event, altContext);
    assert.equal(envelope.source, altSource);
  });
});

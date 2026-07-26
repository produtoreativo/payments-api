/**
 * Example: Encoding an OperationalEvent into a CloudEvents 1.0 envelope.
 *
 * Demonstrates the OEM → CloudEvents field mapping without any external library.
 * The encoder is an application-layer adapter — this example shows the shape
 * a compliant implementation must produce.
 */
import type {
  OperationalEvent,
  EventId,
  CloudEventEnvelope,
  CloudEventSource,
  CloudEventEncoder,
} from '../index.js';
import { ProducerType, Phase, EventCategory } from '../index.js';

const eventId = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6b' as EventId;

const event: OperationalEvent = {
  id: eventId,
  event_type: `Delivery.${Phase.Hack}.${EventCategory.PhaseLifecycle}.Started`,
  work_item_id: 'wf-delivery-0042',
  timestamp: '2026-07-26T09:00:00.000Z',
  producer_type: ProducerType.Agent,
  producer_identity: 'urn:prodops:delivery:hack-start-agent',
  schema_version: '1.0',
};

/**
 * Minimal inline encoder — illustrates the OEM → CloudEvents mapping.
 * RT-01 (Event Producer) provides the real implementation.
 */
const encoder: CloudEventEncoder = {
  encode(e: OperationalEvent): CloudEventEnvelope<OperationalEvent> {
    return {
      specversion: '1.0',
      id: e.id,
      type: e.event_type,
      source: e.producer_identity as CloudEventSource,
      subject: e.work_item_id,
      time: e.timestamp,
      datacontenttype: 'application/json',
      data: e,
    };
  },
};

const envelope = encoder.encode(event);

console.log('specversion:', envelope.specversion);  // '1.0'
console.log('type:', envelope.type);                // 'Delivery.Hack.Phase Lifecycle.Started'
console.log('subject:', envelope.subject);          // 'wf-delivery-0042'
console.log('source:', envelope.source);            // 'urn:prodops:delivery:hack-start-agent'

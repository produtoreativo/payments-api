import type {
  CloudEventEncoder,
  CloudEventEncodingContext,
  CloudEventEnvelope,
  EventInstance,
} from '@prodops/runtime-sdk';

/**
 * OEM implementation of CloudEventEncoder.
 *
 * Maps EventInstance fields to CloudEvents 1.0 envelope per the canonical mapping:
 *   event.id             → envelope.id
 *   event.event_type     → envelope.type
 *   event.work_item_id   → envelope.subject
 *   context.source       → envelope.source  (technical origin — never derived from producer_identity)
 *   event.timestamp      → envelope.time
 *   event (full record)  → envelope.data    (producer_identity preserved inside data)
 */
export class OemCloudEventEncoder implements CloudEventEncoder {
  encode(
    event: EventInstance,
    context: CloudEventEncodingContext,
  ): CloudEventEnvelope<EventInstance> {
    return {
      specversion: '1.0',
      id: event.id,
      type: event.event_type,
      source: context.source,
      subject: event.work_item_id,
      time: event.timestamp,
      datacontenttype: 'application/json',
      data: event,
    };
  }
}

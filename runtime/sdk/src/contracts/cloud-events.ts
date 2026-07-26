import type { EventInstance } from '../models/event-instance.js';

declare const _sourceBrand: unique symbol;

/**
 * URI-reference identifying the technical origin of a CloudEvent.
 * Maps to EventInstance.producer_identity in the OEM → CloudEvents encoding.
 * Format: absolute URI or URI-relative-reference (CloudEvents 1.0 spec §3.1).
 * Example: 'urn:prodops:delivery:hack-start-agent' or '/agents/diligence-agent'
 */
export type CloudEventSource = string & { readonly [_sourceBrand]: 'CloudEventSource' };

/**
 * CloudEvents 1.0 envelope — transport-agnostic container for OEM events.
 * The SDK does not import any CloudEvents library; this is a structural contract only.
 *
 * OEM → CloudEvents field mapping:
 *   EventInstance.id               → id
 *   EventInstance.event_type       → type
 *   EventInstance.work_item_id     → subject
 *   EventInstance.producer_identity → source (as CloudEventSource URI-reference)
 *   EventInstance.timestamp        → time
 *   EventInstance (full record)    → data
 *
 * Canonical spec: https://cloudevents.io (not a runtime dependency)
 */
export interface CloudEventEnvelope<TData = unknown> {
  readonly specversion: '1.0';
  readonly id: string;
  readonly type: string;
  readonly source: CloudEventSource;
  readonly subject: string;
  readonly time: string;
  readonly datacontenttype?: string;
  readonly dataschema?: string;
  readonly data?: TData;
}

/**
 * Encodes an OEM EventInstance into a CloudEvents 1.0 envelope.
 * Implemented by RT-01 (Event Producer) or RT-04 (Telemetry Adapter).
 *
 * Conceptual flow: OperationalEvent → CloudEventEnvelope → EventPublisher
 */
export interface CloudEventEncoder {
  encode(event: EventInstance): CloudEventEnvelope<EventInstance>;
}

/**
 * Decodes a CloudEvents 1.0 envelope back into an OEM EventInstance.
 * Implemented by RT-02 (Timeline Processor) when reading from the event store.
 */
export interface CloudEventDecoder {
  decode(envelope: CloudEventEnvelope<unknown>): EventInstance;
}

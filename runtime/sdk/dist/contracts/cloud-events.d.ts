import type { EventInstance } from '../models/event-instance.js';
declare const _sourceBrand: unique symbol;
/**
 * URI-reference identifying the stable technical origin of a CloudEvent.
 *
 * This is NOT the same as EventInstance.producer_identity:
 *   - producer_identity = the human, agent, or system that produced this specific event
 *   - CloudEventSource  = the stable technical context from which events are emitted
 *
 * Format: absolute URI or URI-relative-reference (CloudEvents 1.0 spec §3.1).
 * Examples:
 *   'prodops://payments-api/github-actions'
 *   'prodops://payments-api/runtime'
 *   'prodops://payments-api/human-cli'
 */
export type CloudEventSource = string & {
    readonly [_sourceBrand]: 'CloudEventSource';
};
/**
 * Encoding context provided to CloudEventEncoder at publish time.
 * Carries the technical producer origin (source) separately from the EventInstance,
 * because source is a deployment-time concern, not an event-schema concern.
 */
export interface CloudEventEncodingContext {
    readonly source: CloudEventSource;
}
/**
 * CloudEvents 1.0 envelope — transport-agnostic container for OEM events.
 * The SDK does not import any CloudEvents library; this is a structural contract only.
 *
 * OEM → CloudEvents field mapping:
 *   EventInstance.id         → id
 *   EventInstance.event_type → type
 *   EventInstance.work_item_id → subject
 *   context.source           → source  (technical producer origin — NOT producer_identity)
 *   EventInstance.timestamp  → time
 *   EventInstance (full record, including producer_identity) → data
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
 * The `context` carries the stable technical source URI — never derived from
 * EventInstance.producer_identity, which is an identity field, not a URI origin.
 *
 * Conceptual flow: OperationalEvent + CloudEventEncodingContext → CloudEventEnvelope → EventPublisher
 */
export interface CloudEventEncoder {
    encode(event: EventInstance, context: CloudEventEncodingContext): CloudEventEnvelope<EventInstance>;
}
/**
 * Decodes a CloudEvents 1.0 envelope back into an OEM EventInstance.
 * Implemented by RT-02 (Timeline Processor) when reading from the event store.
 */
export interface CloudEventDecoder {
    decode(envelope: CloudEventEnvelope<unknown>): EventInstance;
}
export {};
//# sourceMappingURL=cloud-events.d.ts.map
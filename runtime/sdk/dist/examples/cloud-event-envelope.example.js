import { ProducerType, Phase } from '../index.js';
const eventId = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6b';
const event = {
    id: eventId,
    // Format: <Namespace>.<Subject>.<Action>  — Event Category is NOT part of the type
    event_type: `Delivery.${Phase.Hack}.Started`,
    work_item_id: 'wf-delivery-0042',
    timestamp: '2026-07-26T09:00:00.000Z',
    producer_type: ProducerType.Agent,
    // producer_identity = who produced the event — identity field, not transport origin
    producer_identity: 'agent:hack-start-agent',
    schema_version: '1.0',
};
// source = stable technical URI of the emitting context — provided at encoding time,
// never derived from producer_identity
const context = {
    source: 'prodops://payments-api/runtime',
};
/**
 * Minimal inline encoder — illustrates the OEM → CloudEvents mapping.
 * RT-01 (Event Producer) provides the real implementation.
 *
 * Mapping:
 *   event.id             → envelope.id
 *   event.event_type     → envelope.type
 *   event.work_item_id   → envelope.subject
 *   context.source       → envelope.source  (technical origin, NOT producer_identity)
 *   event.timestamp      → envelope.time
 *   event (full record)  → envelope.data    (retains producer_identity inside data)
 */
const encoder = {
    encode(e, ctx) {
        return {
            specversion: '1.0',
            id: e.id,
            type: e.event_type,
            source: ctx.source,
            subject: e.work_item_id,
            time: e.timestamp,
            datacontenttype: 'application/json',
            data: e,
        };
    },
};
const envelope = encoder.encode(event, context);
console.log('specversion:', envelope.specversion); // '1.0'
console.log('type:', envelope.type); // 'Delivery.Hack.Started'
console.log('subject:', envelope.subject); // 'wf-delivery-0042'
console.log('source:', envelope.source); // 'prodops://payments-api/runtime'
// producer_identity is preserved inside data — NOT in source
console.log('producer_identity in data:', envelope.data?.producer_identity); // 'agent:hack-start-agent'
//# sourceMappingURL=cloud-event-envelope.example.js.map
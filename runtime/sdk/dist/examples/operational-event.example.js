import { ProducerType, Phase } from '../index.js';
// In production: import { uuidv7 } from 'uuidv7'; const id = uuidv7() as EventId;
const eventId = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6a';
const hackStarted = {
    id: eventId,
    // Format: <Namespace>.<Subject>.<Action> — Event Category does NOT appear here
    event_type: `Delivery.${Phase.Hack}.Started`,
    work_item_id: 'wf-delivery-0042',
    timestamp: '2026-07-26T09:00:00.000Z',
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:hack-start-agent',
    schema_version: '1.0',
    payload: {
        branch: 'feat/wf-delivery-0042-payment-retry',
    },
};
// OperationalEvent is the domain alias for EventInstance — identical at runtime
const asEventInstance = hackStarted;
console.log('event_type:', hackStarted.event_type);
console.log('work_item_id:', hackStarted.work_item_id);
console.log('is same reference:', hackStarted === asEventInstance);
//# sourceMappingURL=operational-event.example.js.map
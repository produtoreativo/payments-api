import { ProducerType, Phase } from '../index.js';
// --- Stub EventQuery implementation ---
function makeEvent(id, eventType, workItemId) {
    return {
        id: id,
        event_type: eventType,
        work_item_id: workItemId,
        timestamp: new Date().toISOString(),
        producer_type: ProducerType.Agent,
        producer_identity: 'agent:example-agent',
        schema_version: '1.0',
    };
}
const stubEvents = [
    makeEvent('018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5001', `Delivery.${Phase.Bootstrap}.Started`, 'wf-delivery-0042'),
    makeEvent('018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5002', `Delivery.${Phase.Bootstrap}.Completed`, 'wf-delivery-0042'),
    makeEvent('018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5003', `Delivery.${Phase.Hack}.Started`, 'wf-delivery-0042'),
];
const eventQuery = {
    async queryByWorkItem(workItemId, options) {
        const filtered = stubEvents.filter((e) => e.work_item_id === workItemId);
        return {
            events: filtered,
            total: filtered.length,
        };
    },
};
// --- Usage ---
async function main() {
    const result = await eventQuery.queryByWorkItem('wf-delivery-0042', { limit: 10 });
    console.log(`Found ${result.total ?? result.events.length} events`);
    for (const event of result.events) {
        console.log(' -', event.event_type);
    }
}
await main();
//# sourceMappingURL=event-query.example.js.map
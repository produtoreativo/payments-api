/**
 * Example: Querying events for a Work Item via the EventQuery port.
 *
 * Shows how a Timeline Processor (RT-02) or any consumer would source events
 * for replay. EventQuery is an infrastructure port — this example uses a
 * typed stub that satisfies the contract without any real I/O.
 */
import type {
  EventQuery,
  EventQueryResult,
  EventQueryOptions,
  OperationalEvent,
  EventId,
} from '../index.js';
import { ProducerType, Phase, EventCategory } from '../index.js';

// --- Stub EventQuery implementation ---

function makeEvent(id: string, eventType: string, workItemId: string): OperationalEvent {
  return {
    id: id as EventId,
    event_type: eventType,
    work_item_id: workItemId,
    timestamp: new Date().toISOString(),
    producer_type: ProducerType.Agent,
    producer_identity: 'urn:prodops:delivery:example-agent',
    schema_version: '1.0',
  };
}

const stubEvents: ReadonlyArray<OperationalEvent> = [
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5001',
    `Delivery.${Phase.Bootstrap}.${EventCategory.PhaseLifecycle}.Started`,
    'wf-delivery-0042',
  ),
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5002',
    `Delivery.${Phase.Bootstrap}.${EventCategory.PhaseLifecycle}.Completed`,
    'wf-delivery-0042',
  ),
  makeEvent(
    '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5003',
    `Delivery.${Phase.Hack}.${EventCategory.PhaseLifecycle}.Started`,
    'wf-delivery-0042',
  ),
];

const eventQuery: EventQuery = {
  async queryByWorkItem(
    workItemId: string,
    options?: EventQueryOptions,
  ): Promise<EventQueryResult> {
    const filtered = stubEvents.filter((e) => e.work_item_id === workItemId);
    return {
      events: filtered,
      total: filtered.length,
    };
  },
};

// --- Usage ---

async function main(): Promise<void> {
  const result = await eventQuery.queryByWorkItem('wf-delivery-0042', { limit: 10 });

  console.log(`Found ${result.total ?? result.events.length} events`);
  for (const event of result.events) {
    console.log(' -', event.event_type);
  }
}

await main();
